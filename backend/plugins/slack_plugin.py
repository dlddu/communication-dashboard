"""
Slack plugin implementation.

This module implements the SlackPlugin class for fetching unread messages
from Slack channels using the Slack API.
"""

from datetime import datetime
from typing import Any, cast

from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

from .base import BasePlugin
from .exceptions import ConfigurationError
from .schemas import PluginConfig, PluginData, ValidationResult


class SlackPlugin(BasePlugin):
    """
    Slack plugin for fetching unread messages.

    This plugin connects to Slack using a bot token and fetches unread messages
    from specified channels.

    Attributes:
        config: Plugin configuration containing credentials and options
        client: Slack WebClient instance
    """

    def __init__(self, config: PluginConfig) -> None:
        """
        Initialize the Slack plugin.

        Args:
            config: Plugin configuration with Slack credentials

        Raises:
            ConfigurationError: If credentials are missing or invalid
        """
        super().__init__(config)
        self._validate_credentials()
        token = config.credentials.get("token", "") if config.credentials else ""
        self.client = WebClient(token=token)

    def _validate_credentials(self) -> None:
        """
        Validate that required credentials exist.

        Raises:
            ConfigurationError: If credentials or token is missing
        """
        if self.config.credentials is None:
            raise ConfigurationError("Credentials are required for Slack plugin")

        if "token" not in self.config.credentials:
            raise ConfigurationError("Token is required in credentials")

    def validate_config(self) -> ValidationResult:
        """
        Validate the plugin configuration.

        Validates that:
        - Token is not empty
        - Token has valid xoxb- format (bot token)

        Returns:
            ValidationResult with is_valid=True if valid, or errors list if invalid
        """
        errors: list[str] = []

        token = self.config.credentials.get("token", "") if self.config.credentials else ""

        if not token:
            errors.append("Token cannot be empty")
            return ValidationResult(is_valid=False, errors=errors)

        if not token.startswith("xoxb-"):
            errors.append("Token must start with 'xoxb-' (bot token format)")
            return ValidationResult(is_valid=False, errors=errors)

        return ValidationResult(is_valid=True)

    def fetch(self) -> list[PluginData]:
        """
        Fetch unread messages from Slack channels.

        Returns:
            List of PluginData objects representing unread messages

        Notes:
            - Returns empty list if plugin is disabled
            - Filters by channels specified in options if provided
            - Only fetches from channels with unread messages
            - Handles API errors gracefully by returning empty list
        """
        if not self.config.enabled:
            return []

        try:
            return self._fetch_unread_messages()
        except SlackApiError:
            return []

    def _fetch_unread_messages(self) -> list[PluginData]:
        """
        Internal method to fetch unread messages from Slack.

        Returns:
            List of PluginData objects
        """
        result: list[PluginData] = []

        # Get list of channels
        channels_response = self.client.conversations_list()
        channels: list[dict[str, Any]] = channels_response.get("channels", [])

        # Filter channels if specified in options
        filter_channels = self._get_channel_filter()
        if filter_channels:
            channels = [ch for ch in channels if ch.get("name") in filter_channels]

        # Fetch messages from channels with unread messages
        for channel in channels:
            channel_id: str = channel.get("id", "")
            channel_name: str = channel.get("name", "")

            # Check if channel has unread messages
            info_response = self.client.conversations_info(channel=channel_id)
            channel_info: dict[str, Any] = info_response.get("channel", {})
            unread_count: int = channel_info.get("unread_count", 0)

            if unread_count > 0:
                # Fetch messages from this channel
                history_response = self.client.conversations_history(channel=channel_id)
                messages: list[dict[str, Any]] = history_response.get("messages", [])

                # Convert messages to PluginData
                for message in messages:
                    plugin_data = self._convert_to_plugin_data(
                        message, channel_id, channel_name
                    )
                    result.append(plugin_data)

        return result

    def _get_channel_filter(self) -> list[str]:
        """
        Get list of channels to filter from options.

        Returns:
            List of channel names to filter, or empty list for no filter
        """
        if self.config.options is None:
            return []
        channels = self.config.options.get("channels", [])
        return cast(list[str], channels)

    def _convert_to_plugin_data(
        self, message: dict[str, Any], channel_id: str, channel_name: str
    ) -> PluginData:
        """
        Convert a Slack message to PluginData.

        Args:
            message: Raw Slack message dictionary
            channel_id: Slack channel ID
            channel_name: Slack channel name

        Returns:
            PluginData instance representing the message
        """
        ts: str = message.get("ts", "")
        user_id: str = message.get("user", "")
        text: str = message.get("text", "")

        return PluginData(
            id=ts,
            source="slack",
            title=f"#{channel_name}",
            content=text,
            timestamp=self._convert_slack_timestamp(ts),
            metadata={
                "channel_id": channel_id,
                "channel_name": channel_name,
                "user_id": user_id,
            },
            read=False,
        )

    def _convert_slack_timestamp(self, ts: str) -> datetime:
        """
        Convert Slack timestamp to datetime.

        Args:
            ts: Slack timestamp string (e.g., "1234567890.123456")

        Returns:
            datetime object
        """
        timestamp_float = float(ts)
        return datetime.fromtimestamp(timestamp_float)
