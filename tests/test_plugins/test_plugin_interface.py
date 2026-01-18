"""Tests for plugin interface (TDD Red Phase).

These tests define the expected behavior of the plugin system.
They will fail until the implementation is complete.
"""

from datetime import datetime
from typing import Any

import pytest
from pydantic import ValidationError

from communication_dashboard.plugins.config import PluginConfig, ValidationResult
from communication_dashboard.plugins.models import PluginData
from tests.conftest import MockInvalidPlugin, MockValidPlugin


class TestPluginInterface:
    """Test suite for BasePlugin abstract interface."""

    def test_plugin_must_implement_fetch(self) -> None:
        """fetch 메서드 미구현 시 TypeError 발생.

        Abstract method인 fetch()를 구현하지 않은 클래스는
        인스턴스화할 수 없어야 합니다.
        """
        with pytest.raises(TypeError, match="Can't instantiate abstract class"):
            MockInvalidPlugin()

    def test_plugin_fetch_returns_plugin_data_list(self) -> None:
        """fetch는 PluginData 리스트를 반환해야 함.

        정상적으로 구현된 플러그인의 fetch() 메서드는
        PluginData 객체들의 리스트를 반환해야 합니다.
        """
        plugin = MockValidPlugin()
        result = plugin.fetch()

        assert isinstance(result, list)
        assert len(result) > 0
        assert all(isinstance(item, PluginData) for item in result)

    def test_plugin_must_implement_validate_config(self) -> None:
        """validate_config 메서드 미구현 시 TypeError 발생.

        Abstract method인 validate_config()를 구현하지 않은 클래스는
        인스턴스화할 수 없어야 합니다.
        """
        # MockInvalidPlugin은 두 메서드 모두 구현하지 않음
        with pytest.raises(TypeError, match="Can't instantiate abstract class"):
            MockInvalidPlugin()

    def test_plugin_validate_config_returns_validation_result(self) -> None:
        """validate_config는 ValidationResult를 반환해야 함.

        정상적으로 구현된 플러그인의 validate_config() 메서드는
        ValidationResult 객체를 반환해야 합니다.
        """
        plugin = MockValidPlugin()
        result = plugin.validate_config()

        assert isinstance(result, ValidationResult)
        assert hasattr(result, 'success')
        assert isinstance(result.success, bool)


class TestPluginData:
    """Test suite for PluginData dataclass."""

    def test_plugin_data_creation_with_all_fields(
        self, valid_plugin_data: PluginData
    ) -> None:
        """모든 필드가 포함된 PluginData 생성.

        PluginData는 모든 필수 필드를 가지고 생성할 수 있어야 합니다.
        """
        assert valid_plugin_data.id == "test-id-123"
        assert valid_plugin_data.source == "test-source"
        assert valid_plugin_data.title == "Test Title"
        assert valid_plugin_data.content == "Test content for plugin data"
        assert valid_plugin_data.timestamp == datetime(2026, 1, 18, 10, 30, 0)
        assert valid_plugin_data.metadata == {"author": "test", "tags": ["test", "example"]}
        assert valid_plugin_data.read is False

    def test_plugin_data_read_defaults_to_false(self) -> None:
        """read 필드는 기본값이 False여야 함.

        read 필드를 지정하지 않으면 자동으로 False가 되어야 합니다.
        """
        data = PluginData(
            id="test-id",
            source="test-source",
            title="Test",
            content="Content",
            timestamp=datetime.now(),
            metadata={},
        )
        assert data.read is False

    def test_plugin_data_requires_all_mandatory_fields(self) -> None:
        """필수 필드 누락 시 에러 발생.

        id, source, title, content, timestamp, metadata는 필수 필드입니다.
        """
        with pytest.raises(TypeError):
            PluginData()  # type: ignore

        with pytest.raises(TypeError):
            PluginData(id="test")  # type: ignore

    def test_plugin_data_metadata_is_dict(self) -> None:
        """metadata 필드는 Dict[str, Any] 타입이어야 함."""
        data = PluginData(
            id="test",
            source="test",
            title="Test",
            content="Content",
            timestamp=datetime.now(),
            metadata={"key": "value", "nested": {"data": [1, 2, 3]}},
        )
        assert isinstance(data.metadata, dict)
        assert data.metadata["key"] == "value"
        assert data.metadata["nested"]["data"] == [1, 2, 3]


class TestPluginConfig:
    """Test suite for PluginConfig Pydantic model."""

    def test_plugin_config_validation(
        self, valid_plugin_config_data: dict[str, Any]
    ) -> None:
        """유효한 config는 PluginConfig 생성 성공.

        모든 필드가 올바른 형식이면 검증을 통과해야 합니다.
        """
        config = PluginConfig(**valid_plugin_config_data)

        assert config.name == "test-plugin"
        assert config.enabled is True
        assert config.interval_minutes == 60
        assert config.credentials == {"api_key": "test-key"}
        assert config.options == {"timeout": 30}

    def test_plugin_config_enabled_defaults_to_true(
        self, minimal_plugin_config_data: dict[str, Any]
    ) -> None:
        """enabled 필드는 기본값이 True여야 함."""
        config = PluginConfig(**minimal_plugin_config_data)
        assert config.enabled is True

    def test_plugin_config_credentials_optional(
        self, minimal_plugin_config_data: dict[str, Any]
    ) -> None:
        """credentials 필드는 선택사항이어야 함."""
        config = PluginConfig(**minimal_plugin_config_data)
        assert config.credentials is None or isinstance(config.credentials, dict)

    def test_plugin_config_options_optional(
        self, minimal_plugin_config_data: dict[str, Any]
    ) -> None:
        """options 필드는 선택사항이어야 함."""
        config = PluginConfig(**minimal_plugin_config_data)
        assert config.options is None or isinstance(config.options, dict)

    def test_interval_minutes_boundary_minimum(self) -> None:
        """interval은 최소 1분이어야 함.

        1보다 작은 값은 ValidationError를 발생시켜야 합니다.
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=0)

        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(error) for error in errors)

        with pytest.raises(ValidationError):
            PluginConfig(name="test", interval_minutes=-1)

    def test_interval_minutes_boundary_maximum(self) -> None:
        """interval은 최대 1440분(24시간)이어야 함.

        1440보다 큰 값은 ValidationError를 발생시켜야 합니다.
        """
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig(name="test", interval_minutes=1441)

        errors = exc_info.value.errors()
        assert any("interval_minutes" in str(error) for error in errors)

        with pytest.raises(ValidationError):
            PluginConfig(name="test", interval_minutes=2000)

    def test_interval_minutes_boundary_valid_range(self) -> None:
        """interval은 1-1440 범위 내 값은 허용.

        경계값 1과 1440은 유효해야 합니다.
        """
        # 최소값 테스트
        config_min = PluginConfig(name="test", interval_minutes=1)
        assert config_min.interval_minutes == 1

        # 최대값 테스트
        config_max = PluginConfig(name="test", interval_minutes=1440)
        assert config_max.interval_minutes == 1440

        # 중간값 테스트
        config_mid = PluginConfig(name="test", interval_minutes=60)
        assert config_mid.interval_minutes == 60

    def test_plugin_config_name_required(self) -> None:
        """name 필드는 필수여야 함."""
        with pytest.raises(ValidationError) as exc_info:
            PluginConfig()  # type: ignore

        errors = exc_info.value.errors()
        assert any(error["loc"] == ("name",) for error in errors)

    def test_plugin_config_invalid_types(self) -> None:
        """잘못된 타입은 ValidationError 발생.

        각 필드는 정의된 타입만 허용해야 합니다.
        """
        # enabled가 리스트면 에러 (Pydantic v2는 "yes" 문자열을 bool로 변환하지만, 리스트는 불가)
        with pytest.raises(ValidationError):
            PluginConfig(name="test", enabled=["invalid"])  # type: ignore

        # interval_minutes가 문자열이면 에러 (숫자 형태가 아닌 경우)
        with pytest.raises(ValidationError):
            PluginConfig(name="test", interval_minutes="invalid")  # type: ignore

        # credentials가 리스트면 에러
        with pytest.raises(ValidationError):
            PluginConfig(name="test", credentials=["not", "a", "dict"])  # type: ignore


class TestValidationResult:
    """Test suite for ValidationResult model."""

    def test_validation_result_success(self) -> None:
        """성공 케이스의 ValidationResult 생성."""
        result = ValidationResult(success=True, message="Validation passed")

        assert result.success is True
        assert result.message == "Validation passed"
        assert result.errors is None

    def test_validation_result_failure_with_errors(self) -> None:
        """실패 케이스의 ValidationResult 생성 (에러 목록 포함)."""
        errors = ["Missing required field: api_key", "Invalid format: url"]
        result = ValidationResult(
            success=False,
            message="Validation failed",
            errors=errors,
        )

        assert result.success is False
        assert result.message == "Validation failed"
        assert result.errors == errors
        assert len(result.errors) == 2

    def test_validation_result_message_optional(self) -> None:
        """message 필드는 선택사항이어야 함."""
        result = ValidationResult(success=True)
        assert result.success is True
        assert result.message is None or isinstance(result.message, str)

    def test_validation_result_errors_optional(self) -> None:
        """errors 필드는 선택사항이어야 함."""
        result = ValidationResult(success=True, message="OK")
        assert result.errors is None or isinstance(result.errors, list)

    def test_validation_result_requires_success_field(self) -> None:
        """success 필드는 필수여야 함."""
        with pytest.raises(ValidationError) as exc_info:
            ValidationResult()  # type: ignore

        errors = exc_info.value.errors()
        assert any(error["loc"] == ("success",) for error in errors)


class TestPluginIntegration:
    """Integration tests for plugin system components."""

    def test_complete_plugin_workflow(self) -> None:
        """전체 플러그인 워크플로우 통합 테스트.

        플러그인 생성 -> 설정 검증 -> 데이터 fetch 전체 흐름을 테스트합니다.
        """
        # 1. 플러그인 생성
        plugin = MockValidPlugin()

        # 2. 설정 검증
        validation = plugin.validate_config()
        assert validation.success is True

        # 3. 데이터 fetch
        data_list = plugin.fetch()
        assert len(data_list) > 0

        # 4. 반환된 데이터 검증
        first_item = data_list[0]
        assert isinstance(first_item, PluginData)
        assert first_item.id is not None
        assert first_item.source is not None
        assert isinstance(first_item.timestamp, datetime)
        assert isinstance(first_item.metadata, dict)
        assert first_item.read is False
