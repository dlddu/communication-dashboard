"""
Slack API client wrapper.

This module provides an asynchronous client for interacting with the Slack Web API.
It handles rate limiting with exponential backoff and network error retries.
"""

import asyncio
from typing import Any, Optional, cast

import httpx


class SlackAPIError(Exception):
    """Exception raised when Slack API returns an error response."""

    def __init__(self, error: str, message: str = "") -> None:
        """
        Initialize SlackAPIError.

        Args:
            error: The error code from Slack API
            message: Optional additional message
        """
        self.error = error
        super().__init__(f"Slack API error: {error}. {message}".strip())


class SlackRateLimitError(Exception):
    """Exception raised when rate limit retries are exhausted."""

    pass


class SlackNetworkError(Exception):
    """Exception raised when network retries are exhausted."""

    pass


class SlackClient:
    """
    Async Slack API client wrapper.

    Provides methods to interact with Slack Web API with built-in
    rate limit handling and network error retries.

    Attributes:
        api_token: Slack API token for authentication
        max_retries: Maximum number of retry attempts for network errors
    """

    BASE_URL = "https://slack.com/api"
    MAX_RATE_LIMIT_RETRIES = 10
    INITIAL_BACKOFF_SECONDS = 1

    def __init__(self, api_token: str, max_retries: int = 3) -> None:
        """
        Initialize the Slack client.

        Args:
            api_token: Slack API token (e.g., xoxb-...)
            max_retries: Maximum number of retry attempts for network errors
        """
        self.api_token = api_token
        self.max_retries = max_retries

    async def conversations_list(self) -> list[dict[str, Any]]:
        """
        Retrieve a list of conversations (channels) from Slack.

        Returns:
            List of channel dictionaries from Slack API

        Raises:
            SlackAPIError: If Slack API returns an error
            SlackRateLimitError: If rate limit retries are exhausted
            httpx.ConnectError: If network retries are exhausted
            httpx.TimeoutException: If request times out after retries
        """
        response_data = await self._make_request(
            endpoint="conversations.list",
            params={},
        )
        return cast(list[dict[str, Any]], response_data.get("channels", []))

    async def conversations_history(
        self,
        channel_id: str,
        limit: int = 100,
        oldest: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """
        Retrieve message history from a Slack channel.

        Args:
            channel_id: The ID of the channel to retrieve messages from
            limit: Maximum number of messages to return
            oldest: Only messages after this Unix timestamp will be returned

        Returns:
            List of message dictionaries from Slack API

        Raises:
            SlackAPIError: If Slack API returns an error
            SlackRateLimitError: If rate limit retries are exhausted
            httpx.ConnectError: If network retries are exhausted
            httpx.TimeoutException: If request times out after retries
        """
        params: dict[str, Any] = {
            "channel": channel_id,
            "limit": limit,
        }
        if oldest is not None:
            params["oldest"] = oldest

        response_data = await self._make_request(
            endpoint="conversations.history",
            params=params,
        )
        return cast(list[dict[str, Any]], response_data.get("messages", []))

    async def _make_request(
        self,
        endpoint: str,
        params: dict[str, Any],
    ) -> dict[str, Any]:
        """
        Make an API request with retry logic for rate limits and network errors.

        Args:
            endpoint: The Slack API endpoint (e.g., "conversations.list")
            params: Query parameters to send with the request

        Returns:
            The JSON response data from Slack API

        Raises:
            SlackAPIError: If Slack API returns an error
            SlackRateLimitError: If rate limit retries are exhausted
            httpx.ConnectError: If network retries are exhausted
            httpx.TimeoutException: If request times out after retries
        """
        url = f"{self.BASE_URL}/{endpoint}"
        headers = {"Authorization": f"Bearer {self.api_token}"}

        rate_limit_attempts = 0
        network_attempts = 0
        backoff = self.INITIAL_BACKOFF_SECONDS

        async with httpx.AsyncClient() as client:
            while True:
                try:
                    response = await client.get(url, headers=headers, params=params)

                    # Handle rate limiting (HTTP 429)
                    if response.status_code == 429:
                        rate_limit_attempts += 1
                        if rate_limit_attempts > self.MAX_RATE_LIMIT_RETRIES:
                            raise SlackRateLimitError(
                                f"Rate limit retries exhausted after {rate_limit_attempts} attempts"
                            )

                        # Use Retry-After header if present, otherwise exponential backoff
                        retry_after = response.headers.get("Retry-After")
                        if retry_after:
                            wait_time = float(retry_after)
                        else:
                            wait_time = backoff
                            backoff *= 2

                        await asyncio.sleep(wait_time)
                        continue

                    # Parse response
                    response.raise_for_status()
                    data = response.json()

                    # Check for Slack API errors
                    if not data.get("ok", False):
                        error = data.get("error", "unknown_error")
                        raise SlackAPIError(error)

                    return cast(dict[str, Any], data)

                except (httpx.ConnectError, httpx.TimeoutException):
                    network_attempts += 1
                    if network_attempts >= self.max_retries:
                        raise

                    # Exponential backoff between retries
                    wait_time = self.INITIAL_BACKOFF_SECONDS * (2 ** (network_attempts - 1))
                    await asyncio.sleep(wait_time)
