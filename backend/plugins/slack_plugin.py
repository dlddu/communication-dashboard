"""
Slack plugin implementation using slack_sdk.

This module provides the SlackPlugin class that fetches unread messages
from Slack channels using the official Slack SDK.
"""

from datetime import datetime, timezone
from typing import Any, Optional

from slack_sdk import WebClient

from .base import BasePlugin
from .exceptions import ConfigurationError
from .schemas import PluginConfig, PluginData


class SlackPlugin(BasePlugin):
    """
    Slack plugin for fetching unread messages.

    This plugin uses slack_sdk.WebClient to connect to Slack and fetch
    unread messages from configured channels.

    Attributes:
        config: Plugin configuration
        client: Slack WebClient instance
    """

    def __init__(self, config: PluginConfig) -> None:
        """
        Initialize the SlackPlugin with configuration.

        Args:
            config: Plugin configuration with credentials containing Slack token

        Raises:
            ConfigurationError: If credentials are missing or token is invalid
        """
        super().__init__(config)
        self._validate_credentials()
        token = config.credentials["token"]  # type: ignore[index]
        self.client = WebClient(token=token)

    def _validate_credentials(self) -> None:
        """
        Validate that credentials contain a valid Slack bot token.

        Raises:
            ConfigurationError: If credentials are missing or token is invalid
        """
        if self.config.credentials is None:
            raise ConfigurationError("Credentials are required. Token is missing.")

        if "token" not in self.config.credentials:
            raise ConfigurationError("Token is required in credentials.")

        token = self.config.credentials["token"]
        if not isinstance(token, str) or not token.startswith("xoxb-"):
            raise ConfigurationError(
                "Invalid token format. Token must start with 'xoxb-' (bot token)."
            )

    def fetch(self) -> list[PluginData]:
        """
        Fetch unread messages from Slack channels.

        Returns:
            List of PluginData instances containing unread messages

        Note:
            Returns empty list if plugin is disabled or no unread messages exist.
        """
        if not self.config.enabled:
            return []

        result: list[PluginData] = []

        # Get list of channels
        channels_response = self.client.conversations_list()
        if not channels_response.get("ok"):
            return []

        channels: list[Any] = channels_response.get("channels", [])

        # Filter channels if specified in options
        channel_filter: Optional[set[str]] = None
        if self.config.options and "channels" in self.config.options:
            channel_filter = set(self.config.options["channels"])

        for channel in channels:
            channel_id: str = channel.get("id", "")
            channel_name: str = channel.get("name", "")

            # Skip if not in channel filter
            if channel_filter and channel_name not in channel_filter:
                continue

            # Get channel info for unread count
            info_response = self.client.conversations_info(channel=channel_id)
            if not info_response.get("ok"):
                continue

            channel_info: dict[str, Any] = info_response.get("channel", {})
            unread_count: int = channel_info.get("unread_count", 0)
            last_read: str = channel_info.get("last_read", "0")

            # Skip if no unread messages
            if unread_count == 0:
                continue

            # Fetch messages newer than last_read
            history_response = self.client.conversations_history(
                channel=channel_id,
                oldest=last_read,
                limit=100,
            )
            if not history_response.get("ok"):
                continue

            messages: list[Any] = history_response.get("messages", [])

            # Filter to only unread messages (ts > last_read)
            for msg in messages:
                msg_ts: str = msg.get("ts", "0")
                if float(msg_ts) <= float(last_read):
                    continue

                # Convert to PluginData
                plugin_data = self._message_to_plugin_data(msg, channel_id, channel_name)
                result.append(plugin_data)

        return result

    def _message_to_plugin_data(
        self, message: dict[str, Any], channel_id: str, channel_name: str
    ) -> PluginData:
        """
        Convert a Slack message to PluginData.

        Args:
            message: Slack message dictionary
            channel_id: Channel ID
            channel_name: Channel name

        Returns:
            PluginData instance
        """
        ts: str = message.get("ts", "")
        text: str = message.get("text", "")
        user: str = message.get("user", "")

        # Convert Slack timestamp to datetime
        timestamp = datetime.fromtimestamp(float(ts), tz=timezone.utc)

        # Generate unique ID
        unique_id = f"slack_{channel_id}_{ts}"

        # Build title from channel name
        title = f"Message in #{channel_name}"

        return PluginData(
            id=unique_id,
            source="slack",
            title=title,
            content=text,
            timestamp=timestamp,
            metadata={
                "channel_id": channel_id,
                "channel_name": channel_name,
                "user_id": user,
                "ts": ts,
            },
            read=False,
        )
