"""
Slack API client wrapper plugin.

This module provides SlackClient, a plugin that fetches data from Slack channels.
It supports:
- conversations.list API for fetching channel list
- conversations.history API for fetching messages
- Rate limit handling with exponential backoff
- Network error retry logic (max 3 attempts)
- Cursor-based pagination
"""

import asyncio
import logging
from datetime import datetime, timezone
from typing import Any, Optional

import httpx

from .base import BasePlugin
from .schemas import PluginConfig, PluginData

logger = logging.getLogger(__name__)

SLACK_API_BASE_URL = "https://slack.com/api"
MAX_NETWORK_RETRIES = 3
MAX_RATE_LIMIT_RETRIES = 5


class SlackAPIError(Exception):
    """Exception raised when Slack API returns an error response."""

    def __init__(self, error: str, message: str = "") -> None:
        self.error = error
        self.message = message or f"Slack API error: {error}"
        super().__init__(self.message)


class RateLimitExceededError(Exception):
    """Exception raised when rate limit retries are exhausted."""

    pass


class SlackClient(BasePlugin):
    """
    Slack client plugin that fetches messages from Slack channels.

    This plugin connects to Slack's Web API and retrieves messages from channels.
    It handles rate limiting with exponential backoff and retries network errors.

    Attributes:
        config: Plugin configuration with Slack credentials
        _token: Slack Bot token extracted from credentials

    Example:
        >>> config = PluginConfig(
        ...     name="slack",
        ...     enabled=True,
        ...     credentials={"token": "xoxb-your-token"}
        ... )
        >>> client = SlackClient(config)
        >>> data = await client.fetch()
    """

    def __init__(self, config: PluginConfig) -> None:
        """
        Initialize the Slack client with configuration.

        Args:
            config: Plugin configuration with credentials containing 'token'

        Raises:
            ValueError: If credentials are missing or token is not provided
        """
        super().__init__(config)
        self._validate_credentials()
        self._token = self.config.credentials["token"]  # type: ignore[index]

    def _validate_credentials(self) -> None:
        """
        Validate that required credentials are present.

        Raises:
            ValueError: If credentials or token is missing
        """
        if self.config.credentials is None:
            raise ValueError("Slack credentials required: token is missing")
        if "token" not in self.config.credentials:
            raise ValueError("Slack credentials required: token is missing")

    async def _make_request(
        self,
        client: httpx.AsyncClient,
        url: str,
        params: Optional[dict[str, Any]] = None,
    ) -> dict[str, Any]:
        """
        Make an HTTP request to Slack API with retry logic.

        Handles rate limiting (HTTP 429) with exponential backoff and retries
        network errors up to MAX_NETWORK_RETRIES times.

        Args:
            client: httpx.AsyncClient instance
            url: API endpoint URL
            params: Optional query parameters

        Returns:
            JSON response as dictionary

        Raises:
            SlackAPIError: If Slack API returns an error response
            RateLimitExceededError: If rate limit retries are exhausted
            httpx.ConnectError: If all network retries are exhausted
            httpx.TimeoutException: If all timeout retries are exhausted
        """
        headers = {"Authorization": f"Bearer {self._token}"}
        network_retries = 0
        rate_limit_retries = 0
        backoff_seconds = 1

        while True:
            try:
                response = await client.get(url, headers=headers, params=params)

                if response.status_code == 429:
                    if rate_limit_retries >= MAX_RATE_LIMIT_RETRIES:
                        raise RateLimitExceededError(
                            f"Rate limit exceeded after {rate_limit_retries} retries"
                        )

                    retry_after = response.headers.get("Retry-After")
                    if retry_after:
                        wait_time = int(retry_after)
                    else:
                        wait_time = backoff_seconds
                        backoff_seconds *= 2

                    logger.warning(f"Rate limited, waiting {wait_time}s before retry")
                    await asyncio.sleep(wait_time)
                    rate_limit_retries += 1
                    continue

                data = response.json()

                if not data.get("ok", False):
                    error_code = data.get("error", "unknown_error")
                    raise SlackAPIError(error_code)

                return dict(data)

            except (httpx.ConnectError, httpx.TimeoutException) as e:
                network_retries += 1
                if network_retries > MAX_NETWORK_RETRIES:
                    raise

                error_name = type(e).__name__
                logger.warning(
                    f"Network error ({error_name}), "
                    f"retry {network_retries}/{MAX_NETWORK_RETRIES}"
                )
                await asyncio.sleep(1)

    async def _get_conversations_list(
        self, client: Optional[httpx.AsyncClient] = None
    ) -> list[dict[str, Any]]:
        """
        Fetch list of Slack channels using conversations.list API.

        Handles cursor-based pagination to retrieve all channels.

        Args:
            client: Optional httpx.AsyncClient instance

        Returns:
            List of channel dictionaries from Slack API
        """
        url = f"{SLACK_API_BASE_URL}/conversations.list"
        channels: list[dict[str, Any]] = []
        cursor: Optional[str] = None

        async with httpx.AsyncClient() as http_client:
            active_client = client or http_client
            while True:
                params: dict[str, Any] = {"limit": 100}
                if cursor:
                    params["cursor"] = cursor

                data = await self._make_request(active_client, url, params)
                channels.extend(data.get("channels", []))

                response_metadata = data.get("response_metadata", {})
                cursor = response_metadata.get("next_cursor", "")
                if not cursor:
                    break

        return channels

    async def _get_conversations_history(
        self, channel_id: str, client: Optional[httpx.AsyncClient] = None
    ) -> list[dict[str, Any]]:
        """
        Fetch message history for a specific channel.

        Handles cursor-based pagination to retrieve messages.

        Args:
            channel_id: Slack channel ID
            client: Optional httpx.AsyncClient instance

        Returns:
            List of message dictionaries from Slack API
        """
        url = f"{SLACK_API_BASE_URL}/conversations.history"
        messages: list[dict[str, Any]] = []
        cursor: Optional[str] = None

        async with httpx.AsyncClient() as http_client:
            active_client = client or http_client
            while True:
                params: dict[str, Any] = {"channel": channel_id, "limit": 100}
                if cursor:
                    params["cursor"] = cursor

                data = await self._make_request(active_client, url, params)
                messages.extend(data.get("messages", []))

                response_metadata = data.get("response_metadata", {})
                cursor = response_metadata.get("next_cursor", "")
                if not cursor:
                    break

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
        Fetch messages from Slack channels.

        Returns empty list if plugin is disabled.
        Respects channel filter if specified in options.

        Returns:
            List of PluginData instances containing Slack messages
        """
        if not self.config.enabled:
            return []

        async with httpx.AsyncClient() as client:
            channels = await self._get_conversations_list(client)

            if not channels:
                return []

            options = self.config.options or {}
            channel_filter = options.get("channels")
            if channel_filter:
                channels = [c for c in channels if c.get("name") in channel_filter]

            items: list[PluginData] = []

            for channel in channels:
                channel_id = channel.get("id", "")
                channel_name = channel.get("name", "unknown")

                messages = await self._get_conversations_history(channel_id, client)

                for msg in messages:
                    if msg.get("type") != "message":
                        continue

                    msg_ts = msg.get("ts", "0")
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
                        read=False,
                    )
                    items.append(data)

            return items
