"""
Tests for Slack plugin functionality.

This test suite verifies the Slack plugin implementation including:
- SlackPlugin configuration validation (token format, required fields)
- Fetching unread messages from Slack
- Channel filtering
- Message to PluginData mapping

These tests are written in TDD style (Red Phase) and will fail until implementation is complete.
"""

from datetime import datetime
from typing import Any
from unittest.mock import MagicMock, Mock, patch

import pytest

from backend.plugins.exceptions import ConfigurationError
from backend.plugins.schemas import PluginConfig


class TestSlackPluginConfig:
    """Test cases for SlackPlugin configuration validation."""

    def test_valid_token_format(self) -> None:
        """
        Test that SlackPlugin accepts valid xoxb- token format.

        Expected behavior:
        - Token starting with 'xoxb-' should be accepted
        - validate_config() should return ValidationResult with is_valid=True
        - No ConfigurationError should be raised
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-1234567890-1234567890123-abcdefghijklmnopqrstuvwx"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.validate_config()

        # Assert
        assert result.is_valid is True
        assert result.errors is None or len(result.errors) == 0

    def test_invalid_token_format_raises_error(self) -> None:
        """
        Test that SlackPlugin rejects invalid token formats.

        Expected behavior:
        - Token not starting with 'xoxb-' should be rejected
        - validate_config() should return ValidationResult with is_valid=False
        - errors list should contain message about invalid token format
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: Invalid token format (xoxa- instead of xoxb-)
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxa-invalid-token-format"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.validate_config()

        # Assert
        assert result.is_valid is False
        assert result.errors is not None
        assert len(result.errors) > 0
        assert any("xoxb-" in error.lower() for error in result.errors)

    def test_missing_token_raises_error(self) -> None:
        """
        Test that SlackPlugin raises ConfigurationError when token is missing.

        Expected behavior:
        - Missing token in credentials should raise ConfigurationError
        - Error message should indicate that token is required
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: No token in credentials
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={},
            options={},
        )

        # Act & Assert
        with pytest.raises(ConfigurationError) as exc_info:
            plugin = SlackPlugin(config)
            plugin.validate_config()

        assert "token" in str(exc_info.value).lower()

    def test_none_credentials_raises_error(self) -> None:
        """
        Test that SlackPlugin raises ConfigurationError when credentials is None.

        Expected behavior:
        - credentials=None should raise ConfigurationError
        - Error message should indicate that credentials are required
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: credentials is None
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials=None,
            options={},
        )

        # Act & Assert
        with pytest.raises(ConfigurationError) as exc_info:
            plugin = SlackPlugin(config)
            plugin.validate_config()

        assert "credentials" in str(exc_info.value).lower() or "token" in str(
            exc_info.value
        ).lower()

    def test_empty_token_raises_error(self) -> None:
        """
        Test that SlackPlugin rejects empty token string.

        Expected behavior:
        - Empty string token should be rejected
        - validate_config() should return ValidationResult with is_valid=False
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: Empty token
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": ""},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.validate_config()

        # Assert
        assert result.is_valid is False
        assert result.errors is not None
        assert len(result.errors) > 0


class TestSlackPluginFetch:
    """Test cases for SlackPlugin fetch functionality."""

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_returns_unread_messages(self, mock_webclient_class: Mock) -> None:
        """
        Test that fetch() returns only unread messages.

        Expected behavior:
        - Should fetch conversations list
        - Should filter for unread messages (unread_count > 0 or similar mechanism)
        - Should return list of PluginData with read=False
        - All returned messages should be marked as unread

        Implementation note:
        - Uses Slack API's conversations_info to check unread_count
        - Or uses conversations_history with oldest parameter based on last read timestamp
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: Mock WebClient and its methods
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        # Mock conversations_list response
        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {
                    "id": "C123456",
                    "name": "general",
                    "is_member": True,
                },
                {
                    "id": "C789012",
                    "name": "random",
                    "is_member": True,
                },
            ],
        }

        # Mock conversations_info to indicate unread messages
        def mock_conversations_info(channel: str) -> dict[str, Any]:
            if channel == "C123456":
                return {
                    "ok": True,
                    "channel": {
                        "id": "C123456",
                        "name": "general",
                        "unread_count": 2,
                        "unread_count_display": 2,
                    },
                }
            else:
                return {
                    "ok": True,
                    "channel": {
                        "id": "C789012",
                        "name": "random",
                        "unread_count": 0,
                        "unread_count_display": 0,
                    },
                }

        mock_client.conversations_info.side_effect = mock_conversations_info

        # Mock conversations_history for channel with unread messages
        mock_client.conversations_history.return_value = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U123456",
                    "text": "Unread message 1",
                    "ts": "1234567890.123456",
                },
                {
                    "type": "message",
                    "user": "U789012",
                    "text": "Unread message 2",
                    "ts": "1234567891.123456",
                },
            ],
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0
        # All messages should be unread
        for data in result:
            assert data.read is False
        # Should only fetch from channels with unread messages
        assert mock_client.conversations_info.called

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_filters_by_channel(self, mock_webclient_class: Mock) -> None:
        """
        Test that fetch() filters messages by specified channels.

        Expected behavior:
        - If options['channels'] is specified, only fetch from those channels
        - Should not fetch from channels not in the filter list
        - Should handle channel names and/or IDs
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: Mock WebClient
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        # Mock conversations_list with multiple channels
        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {
                    "id": "C123456",
                    "name": "general",
                    "is_member": True,
                },
                {
                    "id": "C789012",
                    "name": "random",
                    "is_member": True,
                },
                {
                    "id": "C345678",
                    "name": "team",
                    "is_member": True,
                },
            ],
        }

        # Mock conversations_info
        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": "C123456",
                "name": "general",
                "unread_count": 1,
                "unread_count_display": 1,
            },
        }

        # Mock conversations_history
        mock_client.conversations_history.return_value = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U123456",
                    "text": "Message in general",
                    "ts": "1234567890.123456",
                },
            ],
        }

        # Configure plugin to only fetch from 'general' channel
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={"channels": ["general"]},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()
        assert isinstance(result, list)  # Verify result is returned

        # Assert
        # Should only call conversations_history for filtered channels
        history_calls = mock_client.conversations_history.call_args_list
        # Verify that only 'general' channel was fetched
        called_channels = [call.kwargs.get("channel") for call in history_calls]
        assert "C123456" in called_channels  # general channel ID
        # random and team channels should not be fetched
        assert "C789012" not in called_channels
        assert "C345678" not in called_channels

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_maps_to_plugin_data(self, mock_webclient_class: Mock) -> None:
        """
        Test that fetch() correctly maps Slack messages to PluginData objects.

        Expected behavior:
        - PluginData.id should be message timestamp (ts)
        - PluginData.source should be 'slack'
        - PluginData.title should be channel name or channel + user
        - PluginData.content should be message text
        - PluginData.timestamp should be datetime from ts
        - PluginData.metadata should contain channel_id, user_id, etc.
        - PluginData.read should be False
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: Mock WebClient with specific message data
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        test_message_ts = "1234567890.123456"
        test_user_id = "U123456789"
        test_channel_id = "C987654321"
        test_channel_name = "engineering"
        test_message_text = "This is a test message from Slack"

        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {
                    "id": test_channel_id,
                    "name": test_channel_name,
                    "is_member": True,
                },
            ],
        }

        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": test_channel_id,
                "name": test_channel_name,
                "unread_count": 1,
                "unread_count_display": 1,
            },
        }

        mock_client.conversations_history.return_value = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": test_user_id,
                    "text": test_message_text,
                    "ts": test_message_ts,
                },
            ],
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()

        # Assert
        assert len(result) == 1
        message_data = result[0]

        # Verify PluginData mapping
        assert message_data.id == test_message_ts
        assert message_data.source == "slack"
        assert test_channel_name in message_data.title.lower()
        assert message_data.content == test_message_text
        assert isinstance(message_data.timestamp, datetime)
        assert message_data.read is False

        # Verify metadata contains Slack-specific information
        assert "channel_id" in message_data.metadata
        assert message_data.metadata["channel_id"] == test_channel_id
        assert "user_id" in message_data.metadata
        assert message_data.metadata["user_id"] == test_user_id
        assert "channel_name" in message_data.metadata
        assert message_data.metadata["channel_name"] == test_channel_name

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_handles_no_unread_messages(self, mock_webclient_class: Mock) -> None:
        """
        Test that fetch() returns empty list when no unread messages exist.

        Expected behavior:
        - Should return empty list when all channels have unread_count = 0
        - Should not raise any exceptions
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {
                    "id": "C123456",
                    "name": "general",
                    "is_member": True,
                },
            ],
        }

        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": "C123456",
                "name": "general",
                "unread_count": 0,
                "unread_count_display": 0,
            },
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()

        # Assert
        assert result == []
        # Should not call conversations_history if no unread messages
        assert not mock_client.conversations_history.called

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_handles_api_error_gracefully(self, mock_webclient_class: Mock) -> None:
        """
        Test that fetch() handles Slack API errors gracefully.

        Expected behavior:
        - Should catch API errors
        - Should return empty list or partial results
        - Should not crash the application
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange: Mock API error
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        from slack_sdk.errors import SlackApiError

        mock_client.conversations_list.side_effect = SlackApiError(
            message="invalid_auth", response={"ok": False, "error": "invalid_auth"}
        )

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-invalid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()

        # Assert
        # Should return empty list on error, not crash
        assert isinstance(result, list)
        assert len(result) == 0

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_fetch_converts_timestamp_correctly(self, mock_webclient_class: Mock) -> None:
        """
        Test that fetch() correctly converts Slack timestamp to datetime.

        Expected behavior:
        - Slack ts format (Unix timestamp with microseconds) should be converted to datetime
        - Timezone handling should be correct
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        # Slack timestamp: 1234567890.123456 = 2009-02-13 23:31:30.123456 UTC
        slack_ts = "1234567890.123456"

        mock_client.conversations_list.return_value = {
            "ok": True,
            "channels": [
                {
                    "id": "C123456",
                    "name": "test",
                    "is_member": True,
                },
            ],
        }

        mock_client.conversations_info.return_value = {
            "ok": True,
            "channel": {
                "id": "C123456",
                "name": "test",
                "unread_count": 1,
            },
        }

        mock_client.conversations_history.return_value = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U123456",
                    "text": "Test message",
                    "ts": slack_ts,
                },
            ],
        }

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()

        # Assert
        assert len(result) == 1
        timestamp = result[0].timestamp
        assert isinstance(timestamp, datetime)
        # Verify timestamp is reasonable (year should be 2009)
        assert timestamp.year == 2009
        assert timestamp.month == 2
        assert timestamp.day == 13


class TestSlackPluginIntegration:
    """Integration tests for SlackPlugin."""

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_plugin_inherits_from_base_plugin(self, mock_webclient_class: Mock) -> None:
        """
        Test that SlackPlugin properly inherits from BasePlugin.

        Expected behavior:
        - SlackPlugin should be instance of BasePlugin
        - Should implement fetch() method
        - Should accept PluginConfig in constructor
        """
        from backend.plugins.base import BasePlugin
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)

        # Assert
        assert isinstance(plugin, BasePlugin)
        assert hasattr(plugin, "fetch")
        assert callable(plugin.fetch)
        assert hasattr(plugin, "config")
        assert plugin.config == config

    @patch("backend.plugins.slack_plugin.WebClient")
    def test_disabled_plugin_returns_empty_list(self, mock_webclient_class: Mock) -> None:
        """
        Test that disabled SlackPlugin returns empty list.

        Expected behavior:
        - When config.enabled = False, fetch() should return empty list
        - Should not make any API calls
        """
        from backend.plugins.slack_plugin import SlackPlugin

        # Arrange
        mock_client = MagicMock()
        mock_webclient_class.return_value = mock_client

        config = PluginConfig(
            name="slack",
            enabled=False,  # Disabled
            interval_minutes=30,
            credentials={"token": "xoxb-valid-token"},
            options={},
        )

        # Act
        plugin = SlackPlugin(config)
        result = plugin.fetch()

        # Assert
        assert result == []
        # Should not make API calls when disabled
        assert not mock_client.conversations_list.called
