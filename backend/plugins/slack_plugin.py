"""
Slack plugin for fetching unread messages from Slack channels.

This module provides SlackPlugin, a plugin that fetches unread messages from Slack.
It supports:
- Token validation (xoxb- format required)
- Channel filtering via configuration
- Unread message retrieval
- Message to PluginData mapping
"""

from datetime import datetime, timezone
from typing import Any

import httpx

from .base import BasePlugin
from .exceptions import ConfigurationError
from .schemas import PluginConfig, PluginData

SLACK_API_BASE_URL = "https://slack.com/api"


class SlackPlugin(BasePlugin):
    """
    Slack plugin that fetches unread messages from Slack channels.

    This plugin connects to Slack's Web API and retrieves unread messages from channels.
    It validates token format and supports channel filtering.

    Attributes:
        config: Plugin configuration with Slack credentials
        _token: Slack Bot token extracted from credentials

    Example:
        >>> config = PluginConfig(
        ...     name="slack",
        ...     enabled=True,
        ...     credentials={"token": "xoxb-your-token"}
        ... )
        >>> plugin = SlackPlugin(config)
        >>> data = await plugin.fetch()
    """

    def __init__(self, config: PluginConfig) -> None:
        """
        Initialize the Slack plugin with configuration.

        Args:
            config: Plugin configuration with credentials containing 'token'

        Raises:
            ConfigurationError: If token is missing or has invalid format
        """
        super().__init__(config)
        self._validate_config()
        self._token = self.config.credentials["token"]  # type: ignore[index]

    def _validate_config(self) -> None:
        """
        Validate that required credentials are present and properly formatted.

        Raises:
            ConfigurationError: If credentials or token is missing or invalid
        """
        # Check if credentials exist
        if self.config.credentials is None:
            raise ConfigurationError("Slack token is required")

        # Check if token key exists
        if "token" not in self.config.credentials:
            raise ConfigurationError("Slack token is required")

        # Get token value
        token = self.config.credentials.get("token")

        # Check if token value is None or empty
        if token is None or token == "":
            raise ConfigurationError("Slack token is required")

        # Validate token format (must start with xoxb-)
        if not token.startswith("xoxb-"):
            raise ConfigurationError("Invalid Slack token format: token must start with xoxb-")

    async def _get_channels(self, client: httpx.AsyncClient) -> list[dict[str, Any]]:
        """
        Fetch list of Slack channels using conversations.list API.

        Args:
            client: httpx.AsyncClient instance

        Returns:
            List of channel dictionaries from Slack API
        """
        url = f"{SLACK_API_BASE_URL}/conversations.list"
        headers = {"Authorization": f"Bearer {self._token}"}

        response = await client.get(url, headers=headers)
        data = response.json()

        channels: list[dict[str, Any]] = data.get("channels", [])
        return channels

    async def _get_messages(
        self, client: httpx.AsyncClient, channel_id: str
    ) -> list[dict[str, Any]]:
        """
        Fetch message history for a specific channel.

        Args:
            client: httpx.AsyncClient instance
            channel_id: Slack channel ID

        Returns:
            List of message dictionaries from Slack API
        """
        url = f"{SLACK_API_BASE_URL}/conversations.history"
        headers = {"Authorization": f"Bearer {self._token}"}
        params = {"channel": channel_id}

        response = await client.get(url, headers=headers, params=params)
        data = response.json()

        messages: list[dict[str, Any]] = data.get("messages", [])
        return messages

    def _convert_slack_timestamp(self, ts: str) -> datetime:
        """
        Convert Slack timestamp to datetime object.

        Slack timestamps are in the format "1234567890.123456".

        Args:
            ts: Slack timestamp string

        Returns:
            datetime object in UTC
        """
        unix_timestamp = float(ts.split(".")[0])
        return datetime.fromtimestamp(unix_timestamp, tz=timezone.utc)

    async def fetch(self) -> list[PluginData]:  # type: ignore[override]
        """
        Fetch unread messages from Slack channels.

        Returns empty list if plugin is disabled.
        Respects channel filter if specified in options.
        Only returns messages with type='message'.

        Returns:
            List of PluginData instances containing unread Slack messages
        """
        # Return empty list if plugin is disabled
        if not self.config.enabled:
            return []

        async with httpx.AsyncClient() as client:
            # Fetch all channels
            channels = await self._get_channels(client)

            if not channels:
                return []

            # Apply channel filter if configured
            options = self.config.options or {}
            channel_filter = options.get("channels")

            if channel_filter:
                # Filter channels by name
                channels = [c for c in channels if c.get("name") in channel_filter]

            # Fetch messages from each channel
            items: list[PluginData] = []

            for channel in channels:
                channel_id = channel.get("id", "")
                channel_name = channel.get("name", "unknown")

                messages = await self._get_messages(client, channel_id)

                for msg in messages:
                    # Filter only 'message' type events
                    if msg.get("type") != "message":
                        continue

                    msg_ts = msg.get("ts", "0")

                    # Create PluginData instance
                    data = PluginData(
                        id=msg_ts,
                        source="slack",
                        title=channel_name,
                        content=msg.get("text", ""),
                        timestamp=self._convert_slack_timestamp(msg_ts),
                        metadata={
                            "channel_id": channel_id,
                            "user_id": msg.get("user", ""),
                            "type": msg.get("type", ""),
                        },
                        read=False,  # All messages are unread
                    )
                    items.append(data)

            return items
