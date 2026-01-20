"""
Tests for Slack API client wrapper.

This test suite verifies the Slack API client functionality including:
- SlackClient class with conversations_list() and conversations_history() methods
- Rate limit handling (HTTP 429) with exponential backoff
- Network error retry mechanism (maximum 3 retries)
- Proper error handling and logging

These tests are written in TDD style (Red Phase) and will fail until implementation is complete.
"""

# Removed unused import: typing.Any
from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest


class TestSlackAPIClient:
    """Test cases for SlackClient API wrapper."""

    def test_slack_client_initialization(self) -> None:
        """
        Test that SlackClient can be initialized with an API token.

        Expected behavior:
        - SlackClient should accept api_token parameter
        - Should store token for API authentication
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange & Act
        client = SlackClient(api_token="xoxb-test-token-12345")

        # Assert
        assert client is not None
        assert hasattr(client, "api_token")
        assert client.api_token == "xoxb-test-token-12345"

    @pytest.mark.asyncio
    async def test_conversations_list_success(self) -> None:
        """
        Test conversations_list() method successfully retrieves channel list.

        Expected behavior:
        - Makes GET request to /conversations.list endpoint
        - Returns list of channel dictionaries
        - Includes authorization header with Bearer token
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        mock_response_data = {
            "ok": True,
            "channels": [
                {
                    "id": "C123456",
                    "name": "general",
                    "is_channel": True,
                    "is_member": True,
                },
                {
                    "id": "C789012",
                    "name": "random",
                    "is_channel": True,
                    "is_member": True,
                },
            ],
        }

        # Mock httpx.AsyncClient
        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act
            result = await client.conversations_list()

            # Assert
            assert len(result) == 2
            assert result[0]["id"] == "C123456"
            assert result[0]["name"] == "general"
            assert result[1]["id"] == "C789012"
            assert result[1]["name"] == "random"

            # Verify API call
            mock_client.get.assert_called_once()
            call_args = mock_client.get.call_args
            assert "conversations.list" in call_args[0][0]

    @pytest.mark.asyncio
    async def test_conversations_history_success(self) -> None:
        """
        Test conversations_history() method successfully retrieves messages.

        Expected behavior:
        - Makes GET request to /conversations.history endpoint
        - Accepts channel_id parameter
        - Returns list of message dictionaries
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        channel_id = "C123456"
        mock_response_data = {
            "ok": True,
            "messages": [
                {
                    "type": "message",
                    "user": "U123456",
                    "text": "Hello, world!",
                    "ts": "1234567890.123456",
                },
                {
                    "type": "message",
                    "user": "U789012",
                    "text": "How are you?",
                    "ts": "1234567891.123456",
                },
            ],
        }

        # Mock httpx.AsyncClient
        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act
            result = await client.conversations_history(channel_id=channel_id)

            # Assert
            assert len(result) == 2
            assert result[0]["text"] == "Hello, world!"
            assert result[0]["user"] == "U123456"
            assert result[1]["text"] == "How are you?"

            # Verify API call with channel parameter
            mock_client.get.assert_called_once()
            call_args = mock_client.get.call_args
            assert "conversations.history" in call_args[0][0]

    @pytest.mark.asyncio
    async def test_rate_limit_handling_with_retry_after(self) -> None:
        """
        Test rate limit handling when receiving HTTP 429 response.

        Expected behavior:
        - Detects HTTP 429 status code
        - Reads Retry-After header if present
        - Waits for specified duration
        - Retries the request
        - Eventually succeeds after rate limit clears
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        success_response_data = {
            "ok": True,
            "channels": [{"id": "C123", "name": "general"}],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # First call returns 429, second call succeeds
            mock_rate_limit_response = MagicMock()
            mock_rate_limit_response.status_code = 429
            mock_rate_limit_response.headers = {"Retry-After": "1"}

            mock_success_response = MagicMock()
            mock_success_response.status_code = 200
            mock_success_response.json.return_value = success_response_data
            mock_success_response.raise_for_status = MagicMock()

            mock_client.get.side_effect = [
                mock_rate_limit_response,
                mock_success_response,
            ]

            # Mock asyncio.sleep to avoid actual waiting in tests
            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                # Act
                result = await client.conversations_list()

                # Assert
                assert len(result) == 1
                assert result[0]["name"] == "general"
                assert mock_client.get.call_count == 2
                mock_sleep.assert_called_once()  # Should have waited

    @pytest.mark.asyncio
    async def test_rate_limit_handling_with_exponential_backoff(self) -> None:
        """
        Test exponential backoff when Retry-After header is not present.

        Expected behavior:
        - On 429 without Retry-After, uses exponential backoff
        - Wait time increases: 1s, 2s, 4s, 8s, etc.
        - Retries until success or max attempts reached
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        success_response_data = {
            "ok": True,
            "channels": [{"id": "C123", "name": "general"}],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # Two 429 responses, then success
            mock_rate_limit_response_1 = MagicMock()
            mock_rate_limit_response_1.status_code = 429
            mock_rate_limit_response_1.headers = {}

            mock_rate_limit_response_2 = MagicMock()
            mock_rate_limit_response_2.status_code = 429
            mock_rate_limit_response_2.headers = {}

            mock_success_response = MagicMock()
            mock_success_response.status_code = 200
            mock_success_response.json.return_value = success_response_data
            mock_success_response.raise_for_status = MagicMock()

            mock_client.get.side_effect = [
                mock_rate_limit_response_1,
                mock_rate_limit_response_2,
                mock_success_response,
            ]

            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                # Act
                result = await client.conversations_list()

                # Assert
                assert len(result) == 1
                assert mock_client.get.call_count == 3

                # Verify exponential backoff: first wait ~1s, second wait ~2s
                assert mock_sleep.call_count == 2
                sleep_calls = [call[0][0] for call in mock_sleep.call_args_list]
                assert sleep_calls[0] >= 1  # First backoff
                assert sleep_calls[1] >= 2  # Second backoff (exponential)

    @pytest.mark.asyncio
    async def test_network_error_retry_with_max_attempts(self) -> None:
        """
        Test network error retry mechanism with maximum 3 attempts.

        Expected behavior:
        - Catches network-related exceptions (ConnectError, TimeoutException)
        - Retries up to 3 times
        - Raises exception after 3 failed attempts
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # Simulate network error on all attempts
            mock_client.get.side_effect = httpx.ConnectError("Connection failed")

            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                # Act & Assert
                with pytest.raises(httpx.ConnectError):
                    await client.conversations_list()

                # Should have tried 3 times (initial + 2 retries = 3 total)
                assert mock_client.get.call_count == 3
                assert mock_sleep.call_count == 2  # Sleeps between retries

    @pytest.mark.asyncio
    async def test_network_error_retry_succeeds_on_second_attempt(self) -> None:
        """
        Test that retry succeeds if network recovers before max attempts.

        Expected behavior:
        - First attempt fails with network error
        - Second attempt succeeds
        - Returns successful result
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        success_response_data = {
            "ok": True,
            "channels": [{"id": "C123", "name": "general"}],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # First call fails, second succeeds
            mock_success_response = MagicMock()
            mock_success_response.status_code = 200
            mock_success_response.json.return_value = success_response_data
            mock_success_response.raise_for_status = MagicMock()

            mock_client.get.side_effect = [
                httpx.ConnectError("Connection failed"),
                mock_success_response,
            ]

            with patch("asyncio.sleep", new_callable=AsyncMock) as mock_sleep:
                # Act
                result = await client.conversations_list()

                # Assert
                assert len(result) == 1
                assert result[0]["name"] == "general"
                assert mock_client.get.call_count == 2
                assert mock_sleep.call_count == 1  # One retry sleep

    @pytest.mark.asyncio
    async def test_timeout_error_retry(self) -> None:
        """
        Test that timeout errors are retried.

        Expected behavior:
        - Catches httpx.TimeoutException
        - Retries up to max attempts
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # All attempts timeout
            mock_client.get.side_effect = httpx.TimeoutException("Request timed out")

            with patch("asyncio.sleep", new_callable=AsyncMock):
                # Act & Assert
                with pytest.raises(httpx.TimeoutException):
                    await client.conversations_list()

                # Should have tried 3 times
                assert mock_client.get.call_count == 3

    @pytest.mark.asyncio
    async def test_conversations_history_with_optional_params(self) -> None:
        """
        Test conversations_history() with optional parameters.

        Expected behavior:
        - Accepts limit parameter to limit number of messages
        - Accepts oldest/latest timestamps for filtering
        - Passes parameters to API correctly
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        mock_response_data = {
            "ok": True,
            "messages": [
                {"type": "message", "text": "Test", "ts": "1234567890.123456"}
            ],
        }

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act
            result = await client.conversations_history(
                channel_id="C123456", limit=10, oldest="1234567890.000000"
            )

            # Assert
            assert len(result) == 1
            mock_client.get.assert_called_once()

    @pytest.mark.asyncio
    async def test_api_error_response_handling(self) -> None:
        """
        Test handling of Slack API error responses.

        Expected behavior:
        - Detects when Slack API returns ok=False
        - Raises appropriate exception with error message
        """
        from backend.plugins.slack_client import SlackAPIError, SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        error_response_data = {"ok": False, "error": "invalid_auth"}

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = error_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act & Assert
            with pytest.raises(SlackAPIError) as exc_info:
                await client.conversations_list()

            # Should contain error message from Slack API
            assert "invalid_auth" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_authorization_header_format(self) -> None:
        """
        Test that authorization header is correctly formatted.

        Expected behavior:
        - Uses Bearer token authentication
        - Header format: "Authorization: Bearer xoxb-..."
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token-12345")
        mock_response_data = {"ok": True, "channels": []}

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act
            await client.conversations_list()

            # Assert
            call_kwargs = mock_client.get.call_args[1]
            assert "headers" in call_kwargs
            assert "Authorization" in call_kwargs["headers"]
            assert call_kwargs["headers"]["Authorization"] == "Bearer xoxb-test-token-12345"


class TestSlackClientEdgeCases:
    """Edge case tests for SlackClient."""

    @pytest.mark.asyncio
    async def test_empty_channel_list(self) -> None:
        """
        Test handling of empty channel list response.

        Expected behavior:
        - Returns empty list when no channels exist
        - Does not raise exception
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        mock_response_data = {"ok": True, "channels": []}

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act
            result = await client.conversations_list()

            # Assert
            assert result == []

    @pytest.mark.asyncio
    async def test_empty_message_history(self) -> None:
        """
        Test handling of empty message history.

        Expected behavior:
        - Returns empty list when channel has no messages
        - Does not raise exception
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")
        mock_response_data = {"ok": True, "messages": []}

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            mock_response = MagicMock()
            mock_response.status_code = 200
            mock_response.json.return_value = mock_response_data
            mock_response.raise_for_status = MagicMock()
            mock_client.get.return_value = mock_response

            # Act
            result = await client.conversations_history(channel_id="C123456")

            # Assert
            assert result == []

    @pytest.mark.asyncio
    async def test_max_rate_limit_retries_exceeded(self) -> None:
        """
        Test behavior when rate limit retries are exhausted.

        Expected behavior:
        - Should have a maximum retry limit for rate limits
        - Raises exception when max retries exceeded
        """
        from backend.plugins.slack_client import SlackClient

        # Arrange
        client = SlackClient(api_token="xoxb-test-token")

        with patch("httpx.AsyncClient") as mock_client_class:
            mock_client = AsyncMock()
            mock_client_class.return_value.__aenter__.return_value = mock_client

            # Always return 429
            mock_rate_limit_response = MagicMock()
            mock_rate_limit_response.status_code = 429
            mock_rate_limit_response.headers = {"Retry-After": "1"}

            mock_client.get.return_value = mock_rate_limit_response

            with patch("asyncio.sleep", new_callable=AsyncMock):
                # Act & Assert
                # Should eventually give up and raise exception
                from backend.plugins.slack_client import SlackRateLimitError
                with pytest.raises(SlackRateLimitError):
                    await client.conversations_list()

                # Should have tried multiple times but not infinite
                assert mock_client.get.call_count > 1
                assert mock_client.get.call_count < 20  # Sanity check
