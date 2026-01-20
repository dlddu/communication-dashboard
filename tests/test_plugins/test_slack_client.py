"""
Tests for SlackClient functionality.

This test suite verifies the SlackClient implementation including:
- BasePlugin inheritance
- Slack API conversation list retrieval
- Slack API message history retrieval
- Rate limit handling (HTTP 429 with exponential backoff)
- Network error retry logic (max 3 attempts)
- Cursor-based pagination support
- Integration with plugin system

Tests follow TDD style with AAA (Arrange-Act-Assert) pattern.
"""

from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest

from backend.plugins.base import BasePlugin
from backend.plugins.schemas import PluginConfig, PluginData
from backend.plugins.slack_client import SlackClient


class TestSlackClientBasics:
    """Test cases for basic SlackClient functionality."""

    def test_slack_client_inherits_base_plugin(self) -> None:
        """
        Test that SlackClient properly inherits from BasePlugin.

        Expected behavior:
        - SlackClient should be a subclass of BasePlugin
        - isinstance check should return True
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        # Act
        client = SlackClient(config)

        # Assert
        assert isinstance(client, BasePlugin)
        assert issubclass(SlackClient, BasePlugin)

    def test_slack_client_requires_credentials(self) -> None:
        """
        Test that SlackClient validates token in credentials.

        Expected behavior:
        - Should raise ValueError if credentials is None
        - Should raise ValueError if token is missing
        """
        # Arrange
        config_no_creds = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials=None,
        )
        config_no_token = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"api_key": "wrong-key"},
        )

        # Act & Assert
        with pytest.raises(ValueError, match="token"):
            SlackClient(config_no_creds)

        with pytest.raises(ValueError, match="token"):
            SlackClient(config_no_token)


class TestSlackClientConversationsList:
    """Test cases for Slack conversations.list API."""

    @pytest.mark.asyncio
    async def test_conversations_list_success(self) -> None:
        """
        Test successful retrieval of Slack channel list.

        Expected behavior:
        - Should call conversations.list API
        - Should return list of channels
        - Should parse channel metadata correctly
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        mock_response_data = {
            "ok": True,
            "channels": [
                {
                    "id": "C1234567890",
                    "name": "general",
                    "is_channel": True,
                    "created": 1609459200,
                },
                {
                    "id": "C9876543210",
                    "name": "random",
                    "is_channel": True,
                    "created": 1609459200,
                },
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_async_client.get.return_value = mock_response
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            channels = await client._get_conversations_list()

        # Assert
        assert len(channels) == 2
        assert channels[0]["id"] == "C1234567890"
        assert channels[0]["name"] == "general"
        assert channels[1]["id"] == "C9876543210"
        assert channels[1]["name"] == "random"

    @pytest.mark.asyncio
    async def test_conversations_list_with_pagination(self) -> None:
        """
        Test conversations.list with cursor-based pagination.

        Expected behavior:
        - Should follow cursor pagination
        - Should aggregate results from multiple pages
        - Should stop when no next_cursor provided
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        # Mock paginated responses
        page1_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "channel1", "is_channel": True, "created": 1609459200}
            ],
            "response_metadata": {"next_cursor": "cursor-2"},
        }
        page2_data = {
            "ok": True,
            "channels": [
                {"id": "C2", "name": "channel2", "is_channel": True, "created": 1609459200}
            ],
            "response_metadata": {"next_cursor": ""},
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response1 = MagicMock()
            mock_response1.status_code = 200
            mock_response1.json.return_value = page1_data

            mock_response2 = MagicMock()
            mock_response2.status_code = 200
            mock_response2.json.return_value = page2_data

            mock_async_client.get.side_effect = [mock_response1, mock_response2]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            channels = await client._get_conversations_list()

        # Assert
        assert len(channels) == 2
        assert channels[0]["id"] == "C1"
        assert channels[1]["id"] == "C2"
        assert mock_async_client.get.call_count == 2


class TestSlackClientConversationsHistory:
    """Test cases for Slack conversations.history API."""

    @pytest.mark.asyncio
    async def test_conversations_history_success(self) -> None:
        """
        Test successful retrieval of Slack channel messages.

        Expected behavior:
        - Should call conversations.history API with channel_id
        - Should return list of messages
        - Should parse message content correctly
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        mock_response_data = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U1234567890",
                    "text": "Hello, world!",
                    "ts": "1609459200.000100",
                },
                {
                    "type": "message",
                    "user": "U9876543210",
                    "text": "Hi there!",
                    "ts": "1609459201.000100",
                },
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_async_client.get.return_value = mock_response
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            messages = await client._get_conversations_history("C1234567890")

        # Assert
        assert len(messages) == 2
        assert messages[0]["text"] == "Hello, world!"
        assert messages[0]["user"] == "U1234567890"
        assert messages[1]["text"] == "Hi there!"
        assert messages[1]["user"] == "U9876543210"

    @pytest.mark.asyncio
    async def test_conversations_history_with_pagination(self) -> None:
        """
        Test conversations.history with cursor-based pagination.

        Expected behavior:
        - Should follow cursor pagination
        - Should aggregate messages from multiple pages
        - Should preserve message order
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        page1_data = {
            "ok": True,
            "messages": [
                {"type": "message", "user": "U1", "text": "Message 1", "ts": "1609459200.0"}
            ],
            "response_metadata": {"next_cursor": "cursor-2"},
        }
        page2_data = {
            "ok": True,
            "messages": [
                {"type": "message", "user": "U2", "text": "Message 2", "ts": "1609459201.0"}
            ],
            "response_metadata": {"next_cursor": ""},
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response1 = MagicMock()
            mock_response1.status_code = 200
            mock_response1.json.return_value = page1_data

            mock_response2 = MagicMock()
            mock_response2.status_code = 200
            mock_response2.json.return_value = page2_data

            mock_async_client.get.side_effect = [mock_response1, mock_response2]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            messages = await client._get_conversations_history("C1234567890")

        # Assert
        assert len(messages) == 2
        assert messages[0]["text"] == "Message 1"
        assert messages[1]["text"] == "Message 2"


class TestSlackClientRateLimiting:
    """Test cases for rate limit handling."""

    @pytest.mark.asyncio
    async def test_rate_limit_handling_with_retry_after(self) -> None:
        """
        Test HTTP 429 rate limit handling with exponential backoff.

        Expected behavior:
        - Should detect HTTP 429 response
        - Should wait using Retry-After header if present
        - Should retry the request after waiting
        - Should eventually succeed
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        success_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                mock_async_client = AsyncMock()

                # First call returns 429, second succeeds
                mock_response_429 = MagicMock()
                mock_response_429.status_code = 429
                mock_response_429.headers = {"Retry-After": "2"}

                mock_response_success = MagicMock()
                mock_response_success.status_code = 200
                mock_response_success.json.return_value = success_data

                mock_async_client.get.side_effect = [
                    mock_response_429,
                    mock_response_success,
                ]
                mock_client.return_value.__aenter__.return_value = mock_async_client

                client = SlackClient(config)
                channels = await client._get_conversations_list()

        # Assert
        assert len(channels) == 1
        assert channels[0]["id"] == "C1"
        mock_sleep.assert_called_once_with(2)  # Should wait for Retry-After value

    @pytest.mark.asyncio
    async def test_rate_limit_exponential_backoff(self) -> None:
        """
        Test exponential backoff when Retry-After header is not present.

        Expected behavior:
        - Should use exponential backoff (1s, 2s, 4s, etc.)
        - Should retry multiple times
        - Should eventually succeed
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        success_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                mock_async_client = AsyncMock()

                # Multiple 429 responses, then success
                mock_response_429_1 = MagicMock()
                mock_response_429_1.status_code = 429
                mock_response_429_1.headers = {}

                mock_response_429_2 = MagicMock()
                mock_response_429_2.status_code = 429
                mock_response_429_2.headers = {}

                mock_response_success = MagicMock()
                mock_response_success.status_code = 200
                mock_response_success.json.return_value = success_data

                mock_async_client.get.side_effect = [
                    mock_response_429_1,
                    mock_response_429_2,
                    mock_response_success,
                ]
                mock_client.return_value.__aenter__.return_value = mock_async_client

                client = SlackClient(config)
                channels = await client._get_conversations_list()

        # Assert
        assert len(channels) == 1
        assert mock_sleep.call_count == 2
        # Check exponential backoff: 1s, 2s
        sleep_calls = [call.args[0] for call in mock_sleep.call_args_list]
        assert sleep_calls[0] == 1  # First backoff
        assert sleep_calls[1] == 2  # Second backoff (exponential)

    @pytest.mark.asyncio
    async def test_rate_limit_max_retries_exceeded(self) -> None:
        """
        Test that rate limit retries have a maximum limit.

        Expected behavior:
        - Should retry up to max_retries times
        - Should raise exception if all retries exhausted
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        # Act & Assert
        with patch("httpx.AsyncClient") as mock_client:
            with patch("asyncio.sleep", new_callable=AsyncMock):
                mock_async_client = AsyncMock()

                # Always return 429
                mock_response_429 = MagicMock()
                mock_response_429.status_code = 429
                mock_response_429.headers = {}
                mock_async_client.get.return_value = mock_response_429
                mock_client.return_value.__aenter__.return_value = mock_async_client

                client = SlackClient(config)

                with pytest.raises(Exception, match="rate limit|retry|429|Rate"):
                    await client._get_conversations_list()


class TestSlackClientNetworkErrorRetry:
    """Test cases for network error retry logic."""

    @pytest.mark.asyncio
    async def test_network_error_retry_success(self) -> None:
        """
        Test retry logic for transient network errors.

        Expected behavior:
        - Should catch network errors (ConnectionError, TimeoutError)
        - Should retry up to 3 times
        - Should succeed if network recovers
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        success_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                mock_async_client = AsyncMock()

                # First two calls raise network error, third succeeds
                mock_response_success = MagicMock()
                mock_response_success.status_code = 200
                mock_response_success.json.return_value = success_data

                mock_async_client.get.side_effect = [
                    httpx.ConnectError("Connection failed"),
                    httpx.ConnectError("Connection failed"),
                    mock_response_success,
                ]
                mock_client.return_value.__aenter__.return_value = mock_async_client

                client = SlackClient(config)
                channels = await client._get_conversations_list()

        # Assert
        assert len(channels) == 1
        assert channels[0]["id"] == "C1"
        assert mock_async_client.get.call_count == 3
        assert mock_sleep.call_count == 2  # Two retries = two sleeps

    @pytest.mark.asyncio
    async def test_network_error_max_retries_exceeded(self) -> None:
        """
        Test that network errors fail after max retries (3 attempts).

        Expected behavior:
        - Should retry up to 3 times
        - Should raise exception after 3 failed attempts
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        # Act & Assert
        with patch("httpx.AsyncClient") as mock_client:
            with patch("asyncio.sleep", new_callable=AsyncMock):
                mock_async_client = AsyncMock()

                # Always raise network error
                mock_async_client.get.side_effect = httpx.ConnectError("Connection failed")
                mock_client.return_value.__aenter__.return_value = mock_async_client

                client = SlackClient(config)

                with pytest.raises((httpx.ConnectError, Exception)):
                    await client._get_conversations_list()

                # Should try initial + 3 retries = 4 total attempts
                assert mock_async_client.get.call_count <= 4

    @pytest.mark.asyncio
    async def test_timeout_error_retry(self) -> None:
        """
        Test retry logic for timeout errors.

        Expected behavior:
        - Should catch timeout errors
        - Should retry with backoff
        - Should eventually succeed
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        success_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            with patch("asyncio.sleep", new_callable=AsyncMock):
                mock_async_client = AsyncMock()

                mock_response_success = MagicMock()
                mock_response_success.status_code = 200
                mock_response_success.json.return_value = success_data

                mock_async_client.get.side_effect = [
                    httpx.TimeoutException("Request timeout"),
                    mock_response_success,
                ]
                mock_client.return_value.__aenter__.return_value = mock_async_client

                client = SlackClient(config)
                channels = await client._get_conversations_list()

        # Assert
        assert len(channels) == 1
        assert mock_async_client.get.call_count == 2


class TestSlackClientFetchIntegration:
    """Test cases for fetch() method integration."""

    @pytest.mark.asyncio
    async def test_fetch_returns_plugin_data_list(self) -> None:
        """
        Test that fetch() returns list of PluginData.

        Expected behavior:
        - Should call conversations.list to get channels
        - Should call conversations.history for each channel
        - Should return list of PluginData instances
        - Each PluginData should have correct structure
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        messages_data = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U1",
                    "text": "Hello!",
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

            client = SlackClient(config)
            result = await client.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0
        for item in result:
            assert isinstance(item, PluginData)
            assert item.source == "slack"
            assert isinstance(item.id, str)
            assert isinstance(item.title, str)
            assert isinstance(item.content, str)
            assert isinstance(item.timestamp, datetime)
            assert isinstance(item.metadata, dict)
            assert isinstance(item.read, bool)
            assert item.read is False

    @pytest.mark.asyncio
    async def test_fetch_respects_enabled_flag(self) -> None:
        """
        Test that fetch() returns empty list when disabled.

        Expected behavior:
        - enabled=False should return empty list
        - Should not make any API calls
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=False,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            result = await client.fetch()

        # Assert
        assert result == []
        mock_async_client.get.assert_not_called()

    @pytest.mark.asyncio
    async def test_fetch_with_channel_filter_option(self) -> None:
        """
        Test fetch() with channel filter option.

        Expected behavior:
        - Should only fetch messages from specified channels
        - Should skip other channels
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
            options={"channels": ["general", "announcements"]},
        )

        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200},
                {"id": "C2", "name": "random", "is_channel": True, "created": 1609459200},
                {
                    "id": "C3",
                    "name": "announcements",
                    "is_channel": True,
                    "created": 1609459200,
                },
            ],
        }

        messages_data = {
            "ok": True,
            "messages": [
                {"type": "message", "user": "U1", "text": "Test", "ts": "1609459200.0"}
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

            # conversations.list + 2 filtered channels (general, announcements)
            mock_async_client.get.side_effect = [
                mock_response_channels,
                mock_response_messages,
                mock_response_messages,
            ]
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            await client.fetch()

        # Assert
        # Should call: 1 conversations.list + 2 conversations.history (not 3)
        assert mock_async_client.get.call_count == 3


class TestSlackClientEdgeCases:
    """Test cases for edge cases and error scenarios."""

    @pytest.mark.asyncio
    async def test_empty_channels_list(self) -> None:
        """
        Test behavior when no channels are returned.

        Expected behavior:
        - Should return empty list
        - Should not crash
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        channels_data = {"ok": True, "channels": []}

        # Act
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = channels_data
            mock_async_client.get.return_value = mock_response
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)
            result = await client.fetch()

        # Assert
        assert result == []

    @pytest.mark.asyncio
    async def test_empty_messages_in_channel(self) -> None:
        """
        Test behavior when channel has no messages.

        Expected behavior:
        - Should not add any items for that channel
        - Should continue processing other channels
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        channels_data = {
            "ok": True,
            "channels": [
                {"id": "C1", "name": "general", "is_channel": True, "created": 1609459200}
            ],
        }

        messages_data = {"ok": True, "messages": []}

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

            client = SlackClient(config)
            result = await client.fetch()

        # Assert
        assert result == []

    @pytest.mark.asyncio
    async def test_api_error_response(self) -> None:
        """
        Test handling of Slack API error responses.

        Expected behavior:
        - Should raise appropriate exception for API errors
        - Should include error message from Slack
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-invalid-token"},
        )

        error_data = {"ok": False, "error": "invalid_auth"}

        # Act & Assert
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = error_data
            mock_async_client.get.return_value = mock_response
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)

            with pytest.raises(Exception, match="invalid_auth|error"):
                await client.fetch()

    @pytest.mark.asyncio
    async def test_malformed_json_response(self) -> None:
        """
        Test handling of malformed JSON responses.

        Expected behavior:
        - Should handle JSON decode errors gracefully
        - Should retry or raise appropriate exception
        """
        # Arrange
        config = PluginConfig(
            name="slack",
            enabled=True,
            interval_minutes=60,
            credentials={"token": "xoxb-test-token"},
        )

        # Act & Assert
        with patch("httpx.AsyncClient") as mock_client:
            mock_async_client = AsyncMock()
            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.side_effect = ValueError("Invalid JSON")
            mock_async_client.get.return_value = mock_response
            mock_client.return_value.__aenter__.return_value = mock_async_client

            client = SlackClient(config)

            with pytest.raises((ValueError, Exception)):
                await client.fetch()
