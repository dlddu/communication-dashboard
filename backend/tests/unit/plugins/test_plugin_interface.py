"""Test cases for plugin interface following TDD approach.

These tests are written before implementation (Red Phase of TDD).
They will fail until the actual implementation is created.
"""

from datetime import datetime
from typing import Any

import pytest

from plugins import BasePlugin, PluginConfig, PluginData


class TestPluginInterface:
    """Test suite for plugin interface requirements."""

    def test_plugin_must_implement_fetch(self):
        """fetch 메서드 미구현 시 에러.

        BasePlugin을 상속받은 클래스가 fetch 메서드를 구현하지 않으면
        인스턴스 생성 시 TypeError가 발생해야 합니다.
        """
        # Arrange: fetch 메서드를 구현하지 않은 플러그인 클래스 정의
        with pytest.raises(TypeError) as exc_info:
            # Act & Assert: 추상 메서드 미구현 시 에러
            class IncompletePlugin(BasePlugin):
                def validate_config(self, config: PluginConfig) -> dict[str, Any]:
                    return {"valid": True}

            IncompletePlugin()

        assert "fetch" in str(exc_info.value).lower()

    def test_plugin_fetch_returns_plugin_data_list(self):
        """fetch는 PluginData 리스트 반환.

        fetch 메서드는 비동기로 동작하며 PluginData 객체의 리스트를 반환해야 합니다.
        반환된 각 항목은 필수 필드를 모두 포함해야 합니다.
        """

        # Arrange: fetch를 구현한 테스트 플러그인
        class TestPlugin(BasePlugin):
            async def fetch(self) -> list[PluginData]:
                return [
                    PluginData(
                        id="test-1",
                        source="test-source",
                        title="Test Message",
                        content="This is a test message",
                        timestamp=datetime.now(),
                        metadata={"priority": "high"},
                        read=False,
                    )
                ]

            def validate_config(self, config: PluginConfig) -> dict[str, Any]:
                return {"valid": True}

        plugin = TestPlugin()

        # Act: fetch 메서드 호출 (비동기)
        import asyncio

        result = asyncio.run(plugin.fetch())

        # Assert: 결과가 리스트이고 PluginData 타입을 포함
        assert isinstance(result, list)
        assert len(result) > 0
        assert isinstance(result[0], PluginData)
        assert result[0].id == "test-1"
        assert result[0].source == "test-source"
        assert result[0].title == "Test Message"
        assert result[0].read is False

    def test_plugin_config_validation(self):
        """잘못된 config는 ValidationError 발생.

        PluginConfig는 Pydantic 모델로 타입 검증을 수행해야 합니다.
        필수 필드 누락이나 잘못된 타입은 ValidationError를 발생시켜야 합니다.
        """
        # Arrange & Act & Assert: 필수 필드 누락
        from pydantic import ValidationError

        with pytest.raises(ValidationError) as exc_info:
            PluginConfig()

        error_dict = exc_info.value.errors()
        field_names = [error["loc"][0] for error in error_dict]
        assert "name" in field_names

        # Arrange & Act & Assert: 잘못된 타입
        with pytest.raises(ValidationError):
            PluginConfig(
                name="test-plugin",
                enabled="not-a-boolean",  # should be bool
                interval_minutes="not-an-int",  # should be int
            )

    def test_interval_minutes_boundary(self):
        """interval은 1-1440 범위만 허용.

        interval_minutes 필드는 1분에서 1440분(24시간) 사이의 값만 허용해야 합니다.
        범위를 벗어난 값은 ValidationError를 발생시켜야 합니다.
        """
        from pydantic import ValidationError

        # Arrange & Act & Assert: 유효한 경계값 (1분)
        config_min = PluginConfig(name="test-plugin", interval_minutes=1)
        assert config_min.interval_minutes == 1

        # Arrange & Act & Assert: 유효한 경계값 (1440분)
        config_max = PluginConfig(name="test-plugin", interval_minutes=1440)
        assert config_max.interval_minutes == 1440

        # Arrange & Act & Assert: 유효한 중간값
        config_mid = PluginConfig(name="test-plugin", interval_minutes=60)
        assert config_mid.interval_minutes == 60

        # Arrange & Act & Assert: 최소값 미만 (0분)
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test-plugin", interval_minutes=0)

        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(error["loc"]) for error in errors)

        # Arrange & Act & Assert: 최소값 미만 (음수)
        with pytest.raises(ValidationError):
            PluginConfig(name="test-plugin", interval_minutes=-1)

        # Arrange & Act & Assert: 최대값 초과 (1441분)
        with pytest.raises(ValidationError):
            PluginConfig(name="test-plugin", interval_minutes=1441)

        # Arrange & Act & Assert: 최대값 초과 (매우 큰 값)
        with pytest.raises(ValidationError):
            PluginConfig(name="test-plugin", interval_minutes=10000)


class TestPluginData:
    """Test suite for PluginData dataclass."""

    def test_plugin_data_creation(self):
        """PluginData 객체가 모든 필수 필드와 함께 생성되어야 합니다."""
        # Arrange
        now = datetime.now()

        # Act
        data = PluginData(
            id="msg-123",
            source="slack",
            title="Team Update",
            content="Meeting at 3pm",
            timestamp=now,
            metadata={"channel": "general", "author": "john"},
            read=True,
        )

        # Assert
        assert data.id == "msg-123"
        assert data.source == "slack"
        assert data.title == "Team Update"
        assert data.content == "Meeting at 3pm"
        assert data.timestamp == now
        assert data.metadata["channel"] == "general"
        assert data.read is True

    def test_plugin_data_default_read_false(self):
        """PluginData의 read 필드 기본값은 False여야 합니다."""
        # Arrange & Act
        data = PluginData(
            id="msg-456",
            source="email",
            title="Important Email",
            content="Please review",
            timestamp=datetime.now(),
            metadata={},
        )

        # Assert
        assert data.read is False


class TestPluginConfig:
    """Test suite for PluginConfig Pydantic model."""

    def test_plugin_config_with_all_fields(self):
        """모든 필드가 포함된 PluginConfig 생성."""
        # Arrange & Act
        config = PluginConfig(
            name="slack-plugin",
            enabled=True,
            interval_minutes=30,
            credentials={"api_key": "secret-key", "workspace": "my-workspace"},
            options={"channels": ["general", "random"], "max_messages": 100},
        )

        # Assert
        assert config.name == "slack-plugin"
        assert config.enabled is True
        assert config.interval_minutes == 30
        assert config.credentials["api_key"] == "secret-key"
        assert config.options["channels"] == ["general", "random"]

    def test_plugin_config_default_values(self):
        """PluginConfig의 기본값 검증."""
        # Arrange & Act
        config = PluginConfig(name="test-plugin", interval_minutes=60)

        # Assert
        assert config.enabled is True  # 기본값
        assert config.credentials is None  # 기본값
        assert config.options == {}  # 기본값

    def test_plugin_config_disabled_plugin(self):
        """비활성화된 플러그인 설정."""
        # Arrange & Act
        config = PluginConfig(
            name="disabled-plugin",
            enabled=False,
            interval_minutes=120,
        )

        # Assert
        assert config.enabled is False
