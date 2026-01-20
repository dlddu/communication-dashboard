"""
Tests for MockPlugin functionality.

This test suite verifies the MockPlugin implementation including:
- BasePlugin inheritance
- Dummy data generation
- Enabled flag handling
- Error simulation
- Integration with scheduler and database

Tests follow TDD style with AAA (Arrange-Act-Assert) pattern.
"""

from datetime import datetime

import pytest

from backend.plugins.base import BasePlugin
from backend.plugins.mock_plugin import MockPlugin
from backend.plugins.schemas import PluginConfig, PluginData


class TestMockPluginBasics:
    """Test cases for basic MockPlugin functionality."""

    def test_mock_plugin_inherits_base_plugin(self) -> None:
        """
        Test that MockPlugin properly inherits from BasePlugin.

        Expected behavior:
        - MockPlugin should be a subclass of BasePlugin
        - isinstance check should return True
        """
        # Arrange
        config = PluginConfig(name="mock", enabled=True, interval_minutes=60)

        # Act
        plugin = MockPlugin(config)

        # Assert
        assert isinstance(plugin, BasePlugin)
        assert issubclass(MockPlugin, BasePlugin)

    def test_mock_plugin_fetch_returns_plugin_data_list(self) -> None:
        """
        Test that fetch() returns a list of PluginData.

        Expected behavior:
        - Return type should be a list
        - All items should be PluginData instances
        """
        # Arrange
        config = PluginConfig(name="mock", enabled=True, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0
        for item in result:
            assert isinstance(item, PluginData)

    def test_mock_plugin_fetch_generates_valid_data_structure(self) -> None:
        """
        Test that generated PluginData has all required fields.

        Expected behavior:
        - Each PluginData should have valid id, source, title, content, timestamp
        - metadata should be a dict
        - read should be a boolean
        """
        # Arrange
        config = PluginConfig(name="test-mock", enabled=True, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert len(result) > 0
        data = result[0]
        assert isinstance(data.id, str)
        assert len(data.id) > 0
        assert isinstance(data.source, str)
        assert len(data.source) > 0
        assert isinstance(data.title, str)
        assert isinstance(data.content, str)
        assert isinstance(data.timestamp, datetime)
        assert isinstance(data.metadata, dict)
        assert isinstance(data.read, bool)

    def test_mock_plugin_generates_unique_ids(self) -> None:
        """
        Test that generated PluginData items have unique IDs.

        Expected behavior:
        - Each item should have a unique id
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={"item_count": 5},
        )
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        ids = [item.id for item in result]
        assert len(ids) == len(set(ids)), "All IDs should be unique"


class TestMockPluginConfiguration:
    """Test cases for MockPlugin configuration handling."""

    def test_mock_plugin_respects_enabled_flag(self) -> None:
        """
        Test that MockPlugin returns empty list when disabled.

        Expected behavior:
        - enabled=False should return empty list
        """
        # Arrange
        config = PluginConfig(name="mock", enabled=False, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert result == []

    def test_mock_plugin_uses_plugin_name_as_source(self) -> None:
        """
        Test that MockPlugin uses config.name as source field.

        Expected behavior:
        - source field should equal config.name
        """
        # Arrange
        plugin_name = "my-test-plugin"
        config = PluginConfig(name=plugin_name, enabled=True, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert len(result) > 0
        for item in result:
            assert item.source == plugin_name


class TestMockPluginErrorSimulation:
    """Test cases for MockPlugin error simulation feature."""

    def test_mock_plugin_simulates_error(self) -> None:
        """
        Test that MockPlugin raises RuntimeError when simulate_error is True.

        Expected behavior:
        - simulate_error=True should raise RuntimeError
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={"simulate_error": True},
        )
        plugin = MockPlugin(config)

        # Act & Assert
        with pytest.raises(RuntimeError) as exc_info:
            plugin.fetch()

        assert "simulated" in str(exc_info.value).lower()

    def test_mock_plugin_normal_operation_without_error_flag(self) -> None:
        """
        Test that MockPlugin works normally when simulate_error is False.

        Expected behavior:
        - simulate_error=False should not raise exception
        - Normal data should be returned
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={"simulate_error": False},
        )
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0


class TestMockPluginIntegration:
    """Integration test cases for MockPlugin."""

    def test_mock_plugin_with_scheduler_compatible(self) -> None:
        """
        Test that MockPlugin can be used with scheduler.

        Expected behavior:
        - fetch() can be called multiple times
        - Returns consistent data structure
        """
        # Arrange
        config = PluginConfig(name="mock", enabled=True, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act: Simulate multiple scheduler calls
        results = [plugin.fetch() for _ in range(3)]

        # Assert
        for result in results:
            assert isinstance(result, list)
            assert all(isinstance(item, PluginData) for item in result)

    def test_mock_plugin_data_structure_for_persistence(self) -> None:
        """
        Test that MockPlugin data is suitable for database persistence.

        Expected behavior:
        - All required fields for PluginData are present
        - Fields have correct types for SQLite storage
        """
        # Arrange
        config = PluginConfig(name="mock", enabled=True, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert len(result) > 0
        data = result[0]

        # Check fields required for database storage
        assert isinstance(data.id, str)
        assert isinstance(data.source, str)
        assert isinstance(data.title, str)
        assert isinstance(data.content, str)
        assert isinstance(data.timestamp, datetime)
        assert isinstance(data.metadata, dict)
        assert isinstance(data.read, bool)

    def test_mock_plugin_metadata_structure(self) -> None:
        """
        Test that MockPlugin generates proper metadata.

        Expected behavior:
        - metadata should be a dict (possibly empty)
        - Should be JSON serializable
        """
        import json

        # Arrange
        config = PluginConfig(name="mock", enabled=True, interval_minutes=60)
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        for item in result:
            # metadata should be JSON serializable
            json_str = json.dumps(item.metadata)
            assert isinstance(json_str, str)

    def test_mock_plugin_consistent_data_count(self) -> None:
        """
        Test that MockPlugin generates consistent number of items.

        Expected behavior:
        - Default should generate 1-5 items
        - item_count option controls exact count
        """
        # Arrange: Default count
        config_default = PluginConfig(name="mock", enabled=True, interval_minutes=60)
        plugin_default = MockPlugin(config_default)

        # Arrange: Custom count
        config_custom = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={"item_count": 3},
        )
        plugin_custom = MockPlugin(config_custom)

        # Act
        result_default = plugin_default.fetch()
        result_custom = plugin_custom.fetch()

        # Assert
        assert 1 <= len(result_default) <= 5
        assert len(result_custom) == 3


class TestMockPluginEdgeCases:
    """Test cases for MockPlugin edge cases."""

    def test_mock_plugin_with_null_options(self) -> None:
        """
        Test that MockPlugin handles None options gracefully.

        Expected behavior:
        - options=None should not cause error
        - Should use default behavior
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options=None,
        )
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0

    def test_mock_plugin_with_empty_options(self) -> None:
        """
        Test that MockPlugin handles empty options dict.

        Expected behavior:
        - options={} should not cause error
        - Should use default behavior
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={},
        )
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0

    def test_mock_plugin_with_extra_options(self) -> None:
        """
        Test that MockPlugin ignores unknown options.

        Expected behavior:
        - Unknown options should be ignored
        - Should not cause error
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={"unknown_option": "value", "another_unknown": 123},
        )
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        assert isinstance(result, list)
        assert len(result) > 0

    def test_mock_plugin_read_flag_defaults_to_false(self) -> None:
        """
        Test that MockPlugin sets read flag to False by default.

        Expected behavior:
        - All generated items should have read=False
        """
        # Arrange
        config = PluginConfig(
            name="mock",
            enabled=True,
            interval_minutes=60,
            options={"item_count": 5},
        )
        plugin = MockPlugin(config)

        # Act
        result = plugin.fetch()

        # Assert
        for item in result:
            assert item.read is False
