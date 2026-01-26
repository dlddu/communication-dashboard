"""
Tests for SlackPlugin functionality.

This test suite verifies the SlackPlugin implementation including:
- BasePlugin inheritance
- Token validation (xoxb- format)
- Configuration error handling
- Fetch functionality with channel filtering
- Slack message to PluginData conversion

Tests follow TDD style with AAA (Arrange-Act-Assert) pattern.
"""

from datetime import datetime
from unittest.mock import MagicMock, patch

import pytest

from backend.plugins.base import BasePlugin
from backend.plugins.exceptions import ConfigurationError
from backend.plugins.schemas import PluginConfig, PluginData
from backend.plugins.slack_plugin import SlackPlugin


class TestSlackPluginBasics:
    """Test cases for basic SlackPlugin functionality."""

    def test_slack_plugin_inherits_base_plugin(self) -> None:
        """
        Test that SlackPlugin properly inherits from BasePlugin.

        Expected behavior:
        - SlackPlugin should be a subclass of BasePlugin
        - isinstance check should return True
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
        )

        # Act
        plugin = SlackPlugin(config)

        # Assert
        assert isinstance(plugin, BasePlugin)
        assert issubclass(SlackPlugin, BasePlugin)


class TestSlackPluginConfig:
    """Test cases for SlackPlugin configuration validation."""

    def test_valid_token_format(self) -> None:
        """
        Test that xoxb- format token is accepted.

        Expected behavior:
        - Token starting with 'xoxb-' should be valid
        - No exception should be raised
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={
                "token": "xoxb-123456789-123456789012-abcdefghijklmnopqrstuvwx"
            },
        )

        # Act & Assert
        plugin = SlackPlugin(config)
        assert plugin.config == config

    def test_invalid_token_format_raises_error(self) -> None:
        """
        Test that non-xoxb- format token raises ConfigurationError.

        Expected behavior:
        - Token not starting with 'xoxb-' should raise ConfigurationError
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "invalid-token-format"},
        )

        # Act & Assert
        with pytest.raises(ConfigurationError) as exc_info:
            SlackPlugin(config)

        assert "xoxb-" in str(exc_info.value).lower()

    def test_xoxa_token_raises_error(self) -> None:
        """
        Test that xoxa- (user token) format raises ConfigurationError.

        Expected behavior:
        - xoxa- token should not be accepted, only xoxb-
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={
                "token": "xoxa-123456789-123456789012-abcdefghijklmnopqrstuvwx"
            },
        )

        # Act & Assert
        with pytest.raises(ConfigurationError) as exc_info:
            SlackPlugin(config)

        assert "xoxb-" in str(exc_info.value).lower()

    def test_missing_token_raises_error(self) -> None:
        """
        Test that missing token raises ConfigurationError.

        Expected behavior:
        - credentials without token should raise ConfigurationError
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={},
        )

        # Act & Assert
        with pytest.raises(ConfigurationError) as exc_info:
            SlackPlugin(config)

        assert "token" in str(exc_info.value).lower()

    def test_missing_credentials_raises_error(self) -> None:
        """
        Test that missing credentials raises ConfigurationError.

        Expected behavior:
        - credentials=None should raise ConfigurationError
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials=None,
        )

        # Act & Assert
        with pytest.raises(ConfigurationError) as exc_info:
            SlackPlugin(config)

        assert (
            "credentials" in str(exc_info.value).lower()
            or "token" in str(exc_info.value).lower()
        )


class TestSlackPluginFetch:
    """Test cases for SlackPlugin fetch functionality."""

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_returns_unread_messages(
        self, mock_webclient_class: MagicMock
    ) -> None:
        """
        Test that fetch() returns only unread messages.

        Expected behavior:
        - Only messages that are unread should be returned
        """
        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        # Mock conversations_list response
        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {"id": "C123", "name": "general", "is_member": True},
            ],
        }

        # Mock conversations_info for unread count
        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": "C123",
                "unread_count": 2,
                "last_read": "1609459200.000000",
            },
        }

        # Mock conversations_history with messages
        mock_client.conversations_history.return_value = {
            "ok": True,
            "messages": [
                {
                    "ts": "1609459250.000100",
                    "text": "Unread message 1",
                    "user": "U123",
                },
                {
                    "ts": "1609459260.000200",
                    "text": "Unread message 2",
                    "user": "U456",
                },
                {
                    "ts": "1609459100.000000",
                    "text": "Read message (older)",
                    "user": "U789",
                },
            ],
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
        )
        plugin = SlackPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 2  # Only unread messages
        for item in result:
            assert isinstance(item, PluginData)
            assert item.read is False

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_filters_by_channel(
        self, mock_webclient_class: MagicMock
    ) -> None:
        """
        Test that fetch() filters messages by configured channels.

        Expected behavior:
        - Only messages from channels specified in options should be returned
        """
        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        # Mock conversations_list response with multiple channels
        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {"id": "C001", "name": "general", "is_member": True},
                {"id": "C002", "name": "random", "is_member": True},
                {"id": "C003", "name": "engineering", "is_member": True},
            ],
        }

        # Mock conversations_info for each channel
        def mock_conversations_info(channel: str) -> dict:
            return {
                "ok": True,
                "channel": {
                    "id": channel,
                    "unread_count": 1,
                    "last_read": "1609459200.000000",
                },
            }

        mock_client.conversations_info.side_effect = mock_conversations_info

        # Mock conversations_history for each channel
        def mock_conversations_history(
            channel: str, oldest: str = None, limit: int = None
        ) -> dict:
            return {
                "ok": True,
                "messages": [
                    {
                        "ts": "1609459250.000100",
                        "text": f"Message from {channel}",
                        "user": "U123",
                    },
                ],
            }

        mock_client.conversations_history.side_effect = mock_conversations_history

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
            options={"channels": ["general", "engineering"]},
        )
        plugin = SlackPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 2  # Only messages from filtered channels
        channel_sources = {item.metadata.get("channel_name") for item in result}
        assert (
            "general" in channel_sources
            or any("general" in str(item.metadata) for item in result)
        )
        assert (
            "random" not in channel_sources
            and not any("random" in str(item.metadata) for item in result)
        )

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_maps_to_plugin_data(
        self, mock_webclient_class: MagicMock
    ) -> None:
        """
        Test that Slack messages are correctly mapped to PluginData.

        Expected behavior:
        - Each Slack message should be converted to PluginData
        - All required fields should be properly mapped
        """
        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        # Mock conversations_list
        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {"id": "C123", "name": "general", "is_member": True},
            ],
        }

        # Mock conversations_info
        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": "C123",
                "unread_count": 1,
                "last_read": "1609459200.000000",
            },
        }

        # Mock conversations_history with a specific message
        mock_client.conversations_history.return_value = {
            "ok": True,
            "messages": [
                {
                    "ts": "1609459250.000100",
                    "text": "Test message content",
                    "user": "U123",
                    "type": "message",
                },
            ],
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
        )
        plugin = SlackPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert len(result) == 1
        data = result[0]

        # Verify PluginData structure
        assert isinstance(data, PluginData)
        assert isinstance(data.id, str)
        assert len(data.id) > 0
        assert data.source == "slack"
        assert isinstance(data.title, str)
        assert data.content == "Test message content"
        assert isinstance(data.timestamp, datetime)
        assert isinstance(data.metadata, dict)
        assert data.read is False

        # Verify metadata contains Slack-specific info
        assert "channel_id" in data.metadata or "channel_name" in data.metadata
        assert "user_id" in data.metadata


class TestSlackPluginDisabled:
    """Test cases for disabled SlackPlugin."""

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_returns_empty_when_disabled(
        self, mock_webclient_class: MagicMock
    ) -> None:
        """
        Test that fetch() returns empty list when plugin is disabled.

        Expected behavior:
        - enabled=False should return empty list
        - Slack API should not be called
        """
        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        config = PluginConfig(
            name="slack",
            enabled=False,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
        )
        plugin = SlackPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert result == []
        mock_client.conversations_list.assert_not_called()


class TestSlackPluginEdgeCases:
    """Test cases for SlackPlugin edge cases."""

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_handles_empty_channels(
        self, mock_webclient_class: MagicMock
    ) -> None:
        """
        Test that fetch() handles empty channel list gracefully.

        Expected behavior:
        - Empty channel list should return empty result
        """
        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [],
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
        )
        plugin = SlackPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert result == []

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_handles_no_unread_messages(
        self, mock_webclient_class: MagicMock
    ) -> None:
        """
        Test that fetch() handles channels with no unread messages.

        Expected behavior:
        - Channels with 0 unread messages should contribute no items
        """
        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {"id": "C123", "name": "general", "is_member": True},
            ],
        }

        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": "C123",
                "unread_count": 0,
                "last_read": "1609459200.000000",
            },
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-123456-789012-abcdefghijklmnop"},
        )
        plugin = SlackPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert result == []
