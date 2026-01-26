"""
Tests for SlackPlugin configuration and fetch functionality.

This test suite verifies the SlackPlugin implementation including:
- Token format validation (xoxb- prefix required)
- ConfigurationError handling for invalid/missing tokens
- Fetch filtering for unread messages only
- Channel filtering based on configuration
- Slack message to PluginData mapping accuracy

Tests follow TDD style (Red Phase) and will fail until implementation is complete.
These tests define the expected behavior for DLD-116.
"""

from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from backend.plugins.schemas import PluginConfig, PluginData


class ConfigurationError(Exception):
    """Exception raised when plugin configuration is invalid."""

    pass


class TestSlackPluginConfig:
    """Test cases for SlackPlugin configuration validation."""

    def test_valid_token_format(self) -> None:
        """
        Test that SlackPlugin accepts valid xoxb- token format.

        Expected behavior:
        - Token starting with 'xoxb-' should be accepted
        - Plugin should initialize successfully
        - No exception should be raised

        This is the positive test case for token validation.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-1234567890-1234567890123-abcdefghijklmnopqrstuvwx"},
        )

        # Act & Assert: Should not raise any exception
        plugin = SlackPlugin(config)
        assert plugin is not None
        assert plugin.config.credentials["token"].startswith("xoxb-")

    def test_invalid_token_format_raises_error(self) -> None:
        """
        Test that SlackPlugin rejects tokens not starting with xoxb-.

        Expected behavior:
        - Token without 'xoxb-' prefix should raise ConfigurationError
        - Error message should indicate invalid token format
        - Various invalid formats should all be rejected

        This tests security and correctness of token validation.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        invalid_tokens = [
            "xoxp-1234567890-1234567890123-abcdefghijklmnopqrstuvwx",  # User token
            "xoxa-1234567890-1234567890123-abcdefghijklmnopqrstuvwx",  # App token
            "slack-bot-token-12345",  # Random format
            "Bearer xoxb-12345",  # Bearer prefix
            "",  # Empty string
            "xoxb",  # Just prefix without dash
        ]

        # Act & Assert: Each invalid token should raise ConfigurationError
        for invalid_token in invalid_tokens:
            config = PluginConfig(
                name="slack",
                enabled=True,
                interval_minutes=60,
                credentials={"token": invalid_token},
            )

            with pytest.raises(ConfigurationError, match="xoxb-|token format|invalid"):
                SlackPlugin(config)

    def test_missing_token_raises_error(self) -> None:
        """
        Test that SlackPlugin raises ConfigurationError when token is missing.

        Expected behavior:
        - Missing credentials should raise ConfigurationError
        - Missing token in credentials should raise ConfigurationError
        - Error message should clearly indicate token is required

        This ensures proper error handling for configuration issues.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        # Test case 1: No credentials at all
        config_no_creds = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials=None,
        )

        # Act & Assert
        with pytest.raises(ConfigurationError, match="token|required|missing"):
            SlackPlugin(config_no_creds)

        # Test case 2: Credentials exist but token key is missing
        config_no_token = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"api_key": "some-other-key"},
        )

        # Act & Assert
        with pytest.raises(ConfigurationError, match="token|required|missing"):
            SlackPlugin(config_no_token)

        # Test case 3: Token key exists but value is None
        config_token_none = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": None},
        )

        # Act & Assert
        with pytest.raises(ConfigurationError, match="token|required|missing"):
            SlackPlugin(config_token_none)


class TestSlackPluginFetch:
    """Test cases for SlackPlugin fetch() method."""

    @pytest.mark.asyncio
    async def test_fetch_returns_unread_messages(self) -> None:
        """
        Test that fetch() returns only unread messages.

        Expected behavior:
        - Should call Slack API to get messages
        - Should filter out messages that have been read
        - Should only return messages with read=False
        - Returned items should be PluginData instances

        This is the core functionality for unread message filtering.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
        )

        # Mock Slack API responses
        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C1234567890", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        # Simulate messages with different read states
        messages_data = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U1234567890",
                    "text": "Unread message 1",
                    "ts": "1609459200.000100",
                },
                {
                    "type": "message",
                    "user": "U1234567891",
                    "text": "Unread message 2",
                    "ts": "1609459201.000100",
                },
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response_channels = MagicMock()
            mock_response_channels.status_code = 200
            mock_response_channels.json.return_value = channels_data

            mock_response_messages = MagicMock()
            mock_response_messages.status_code = 200
            mock_response_messages.json.return_value = messages_data

            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_messages,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) == 2  # Both messages are unread

        for item in result:
            assert isinstance(item, PluginData)
            assert item.read is False  # All returned messages should be unread
            assert item.source == "slack"
            assert "Unread message" in item.content

    @pytest.mark.asyncio
    async def test_fetch_filters_by_channel(self) -> None:
        """
        Test that fetch() only retrieves messages from configured channels.

        Expected behavior:
        - Should read 'channels' from config options
        - Should only fetch messages from specified channels
        - Should skip channels not in the filter list
        - Should handle multiple channels correctly

        This ensures channel filtering works as expected.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
            options={"channels": ["general", "engineering"]},
        )

        # Mock Slack API responses with 3 channels
        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C001", "name": "general", "is_channel": True, "created": 1609459200},
                {"id": "C002", "name": "random", "is_channel": True, "created": 1609459200},
                {
                    "id": "C003",
                    "name": "engineering",
                    "is_channel": True,
                    "created": 1609459200,
                },
            ],
        }

        messages_general = {
            "ok": True,
            "messages": [
                {"type": "message", "user": "U001", "text": "General message", "ts": "1609459200.0"}
            ],
        }

        messages_engineering = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U002",
                    "text": "Engineering message",
                    "ts": "1609459201.0",
                }
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response_channels = MagicMock()
            mock_response_channels.status_code = 200
            mock_response_channels.json.return_value = channels_data

            mock_response_general = MagicMock()
            mock_response_general.status_code = 200
            mock_response_general.json.return_value = messages_general

            mock_response_engineering = MagicMock()
            mock_response_engineering.status_code = 200
            mock_response_engineering.json.return_value = messages_engineering

            # Should only call history for general and engineering (not random)
            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_general,
                mock_response_engineering,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert len(result) == 2
        assert mock_async_client.get.call_count == 3  # 1 for channels + 2 for filtered channels

        # Verify messages are from the correct channels
        channel_names = {item.title for item in result}
        assert channel_names == {"general", "engineering"}
        assert "random" not in channel_names

    @pytest.mark.asyncio
    async def test_fetch_maps_to_plugin_data(self) -> None:
        """
        Test that Slack messages are accurately mapped to PluginData.

        Expected behavior:
        - id should map to message timestamp
        - source should be "slack"
        - title should be channel name
        - content should be message text
        - timestamp should be converted from Slack format
        - metadata should include channel_id, user_id, type
        - read should default to False

        This verifies data transformation accuracy.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
        )

        # Mock Slack API with specific data for mapping verification
        channels_data = {
            "ok": True,
            "channels": [
                {
                    "id": "CHANNEL123",
                    "name": "test-channel",
                    "is_channel": True,
                    "created": 1609459200,
                }
            ],
        }

        messages_data = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "USER456",
                    "text": "Test message content",
                    "ts": "1609459200.000100",
                }
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response_channels = MagicMock()
            mock_response_channels.status_code = 200
            mock_response_channels.json.return_value = channels_data

            mock_response_messages = MagicMock()
            mock_response_messages.status_code = 200
            mock_response_messages.json.return_value = messages_data

            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_messages,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert len(result) == 1
        plugin_data = result[0]

        # Verify all field mappings
        assert plugin_data.id == "1609459200.000100"  # Slack timestamp
        assert plugin_data.source == "slack"
        assert plugin_data.title == "test-channel"  # Channel name
        assert plugin_data.content == "Test message content"
        assert isinstance(plugin_data.timestamp, datetime)
        assert plugin_data.timestamp.tzinfo == timezone.utc  # Should be UTC
        assert plugin_data.read is False

        # Verify metadata contains expected fields
        assert plugin_data.metadata["channel_id"] == "CHANNEL123"
        assert plugin_data.metadata["user_id"] == "USER456"
        assert plugin_data.metadata["type"] == "message"

        # Verify timestamp conversion is correct (1609459200 = 2021-01-01 00:00:00 UTC)
        assert plugin_data.timestamp.year == 2021
        assert plugin_data.timestamp.month == 1
        assert plugin_data.timestamp.day == 1

    @pytest.mark.asyncio
    async def test_fetch_with_no_channels_configured(self) -> None:
        """
        Test fetch() behavior when no channel filter is configured.

        Expected behavior:
        - Should fetch messages from all channels
        - Should not filter by channel name
        - Should process all available channels

        This tests the default behavior without channel filtering.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
            options={},  # No channels specified
        )

        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C001", "name": "channel1", "is_channel": True, "created": 1609459200},
                {"id": "C002", "name": "channel2", "is_channel": True, "created": 1609459200},
            ],
        }

        messages_data = {
            "ok": True,
            "messages": [
                {"type": "message", "user": "U001", "text": "Message", "ts": "1609459200.0"}
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response_channels = MagicMock()
            mock_response_channels.status_code = 200
            mock_response_channels.json.return_value = channels_data

            mock_response_messages = MagicMock()
            mock_response_messages.status_code = 200
            mock_response_messages.json.return_value = messages_data

            # Should call history for both channels
            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_messages,
                mock_response_messages,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert len(result) == 2  # Messages from both channels
        assert mock_async_client.get.call_count == 3  # 1 channels + 2 histories

    @pytest.mark.asyncio
    async def test_fetch_respects_enabled_flag(self) -> None:
        """
        Test that fetch() returns empty list when plugin is disabled.

        Expected behavior:
        - enabled=False should return empty list immediately
        - Should not make any API calls
        - Should not raise any exceptions

        This tests the plugin disable mechanism.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=False,  # Plugin disabled
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
        )

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert result == []
        mock_async_client.get.assert_not_called()


class TestSlackPluginEdgeCases:
    """Test cases for edge cases and error scenarios."""

    @pytest.mark.asyncio
    async def test_fetch_with_empty_message_list(self) -> None:
        """
        Test fetch() behavior when channel has no messages.

        Expected behavior:
        - Should return empty list
        - Should not crash
        - Should handle gracefully

        This tests robustness with empty data.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
        )

        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C001", "name": "empty", "is_channel": True, "created": 1609459200}
            ],
        }

        messages_data = {"ok": True, "messages": []}  # No messages

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response_channels = MagicMock()
            mock_response_channels.status_code = 200
            mock_response_channels.json.return_value = channels_data

            mock_response_messages = MagicMock()
            mock_response_messages.status_code = 200
            mock_response_messages.json.return_value = messages_data

            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_messages,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert result == []

    @pytest.mark.asyncio
    async def test_fetch_filters_non_message_types(self) -> None:
        """
        Test that fetch() filters out non-message type events.

        Expected behavior:
        - Should only include items with type='message'
        - Should skip bot messages, channel join events, etc.
        - Should not include system messages

        This ensures only actual messages are returned.
        """
        # Arrange
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
        )

        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C001", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        # Mix of message types
        messages_data = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U001",
                    "text": "Real message",
                    "ts": "1609459200.0",
                },
                {"type": "channel_join", "user": "U002", "ts": "1609459201.0"},
                {"type": "channel_purpose", "purpose": "New purpose", "ts": "1609459202.0"},
                {
                    "type": "message",
                    "user": "U003",
                    "text": "Another real message",
                    "ts": "1609459203.0",
                },
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response_channels = MagicMock()
            mock_response_channels.status_code = 200
            mock_response_channels.json.return_value = channels_data

            mock_response_messages = MagicMock()
            mock_response_messages.status_code = 200
            mock_response_messages.json.return_value = messages_data

            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_messages,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            plugin = SlackPlugin(config)
            result = await plugin.fetch()

        # Assert
        assert len(result) == 2  # Only the two 'message' type items
        for item in result:
            assert item.metadata["type"] == "message"

    def test_plugin_inherits_base_plugin(self) -> None:
        """
        Test that SlackPlugin properly inherits from BasePlugin.

        Expected behavior:
        - SlackPlugin should be a subclass of BasePlugin
        - Should implement the fetch() method
        - Should follow plugin interface contract

        This verifies proper plugin system integration.
        """
        # Arrange & Act
        from backend.plugins.base import BasePlugin
        from backend.plugins.slack_plugin import SlackPlugin

        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token-12345"},
        )

        plugin = SlackPlugin(config)

        # Assert
        assert isinstance(plugin, BasePlugin)
        assert issubclass(SlackPlugin, BasePlugin)
        assert hasattr(plugin, "fetch")
        assert callable(plugin.fetch)
