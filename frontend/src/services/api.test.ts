import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { pluginService } from './api';
import type { PluginInfo, PluginDataItem, RefreshResult } from '@/types/plugin';

describe('pluginService', () => {
  let mock: MockAdapter;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('getPlugins', () => {
    it('should return plugins list when API call succeeds', async () => {
      // Arrange
      const mockPlugins: PluginInfo[] = [
        { name: 'slack', count: 10, last_updated: '2026-01-27T10:00:00Z' },
        { name: 'email', count: 5, last_updated: '2026-01-27T11:00:00Z' },
      ];
      mock.onGet('/plugins').reply(200, mockPlugins);

      // Act
      const result = await pluginService.getPlugins();

      // Assert
      expect(result).toEqual(mockPlugins);
      expect(result).toHaveLength(2);
      expect(result[0].name).toBe('slack');
    });

    it('should throw error when API call fails', async () => {
      // Arrange
      mock.onGet('/plugins').reply(500, { detail: 'Internal Server Error' });

      // Act & Assert
      await expect(pluginService.getPlugins()).rejects.toThrow('Internal Server Error');
    });

    it('should handle network error', async () => {
      // Arrange
      mock.onGet('/plugins').networkError();

      // Act & Assert
      await expect(pluginService.getPlugins()).rejects.toThrow();
    });

    it('should handle timeout', async () => {
      // Arrange
      mock.onGet('/plugins').timeout();

      // Act & Assert
      await expect(pluginService.getPlugins()).rejects.toThrow();
    });

    it('should return empty array when no plugins available', async () => {
      // Arrange
      mock.onGet('/plugins').reply(200, []);

      // Act
      const result = await pluginService.getPlugins();

      // Assert
      expect(result).toEqual([]);
      expect(result).toHaveLength(0);
    });
  });

  describe('getPluginData', () => {
    it('should return plugin data with default limit', async () => {
      // Arrange
      const pluginName = 'slack';
      const mockData: PluginDataItem[] = [
        {
          id: '1',
          source: 'slack',
          title: 'Test Message',
          content: 'Test content',
          timestamp: '2026-01-27T10:00:00Z',
          metadata: {},
          read: false,
        },
      ];
      mock.onGet(`/plugins/${pluginName}/data`, { params: { limit: 50 } }).reply(200, mockData);

      // Act
      const result = await pluginService.getPluginData(pluginName);

      // Assert
      expect(result).toEqual(mockData);
      expect(result).toHaveLength(1);
      expect(result[0].source).toBe('slack');
    });

    it('should return plugin data with custom limit', async () => {
      // Arrange
      const pluginName = 'email';
      const customLimit = 100;
      const mockData: PluginDataItem[] = [];
      mock.onGet(`/plugins/${pluginName}/data`, { params: { limit: customLimit } }).reply(200, mockData);

      // Act
      const result = await pluginService.getPluginData(pluginName, customLimit);

      // Assert
      expect(result).toEqual(mockData);
    });

    it('should throw error when plugin not found', async () => {
      // Arrange
      const pluginName = 'nonexistent';
      mock.onGet(`/plugins/${pluginName}/data`).reply(404, { detail: 'Plugin not found' });

      // Act & Assert
      await expect(pluginService.getPluginData(pluginName)).rejects.toThrow('Plugin not found');
    });

    it('should handle malformed plugin name', async () => {
      // Arrange
      const pluginName = '';
      mock.onGet(`/plugins/${pluginName}/data`).reply(400, { detail: 'Invalid plugin name' });

      // Act & Assert
      await expect(pluginService.getPluginData(pluginName)).rejects.toThrow('Invalid plugin name');
    });
  });

  describe('refreshPlugin', () => {
    it('should return success result when refresh succeeds', async () => {
      // Arrange
      const pluginName = 'slack';
      const mockResult: RefreshResult = {
        success: true,
        message: 'Refresh successful',
        data_count: 10,
      };
      mock.onPost(`/plugins/${pluginName}/refresh`).reply(200, mockResult);

      // Act
      const result = await pluginService.refreshPlugin(pluginName);

      // Assert
      expect(result).toEqual(mockResult);
      expect(result.success).toBe(true);
      expect(result.data_count).toBe(10);
    });

    it('should return failure result when refresh fails', async () => {
      // Arrange
      const pluginName = 'email';
      const mockResult: RefreshResult = {
        success: false,
        message: 'Refresh failed',
        data_count: null,
      };
      mock.onPost(`/plugins/${pluginName}/refresh`).reply(200, mockResult);

      // Act
      const result = await pluginService.refreshPlugin(pluginName);

      // Assert
      expect(result.success).toBe(false);
      expect(result.data_count).toBe(null);
    });

    it('should throw error when plugin not configured', async () => {
      // Arrange
      const pluginName = 'unconfigured';
      mock.onPost(`/plugins/${pluginName}/refresh`).reply(400, { detail: 'Plugin not configured' });

      // Act & Assert
      await expect(pluginService.refreshPlugin(pluginName)).rejects.toThrow('Plugin not configured');
    });

    it('should handle server error during refresh', async () => {
      // Arrange
      const pluginName = 'slack';
      mock.onPost(`/plugins/${pluginName}/refresh`).reply(500, { detail: 'Internal error' });

      // Act & Assert
      await expect(pluginService.refreshPlugin(pluginName)).rejects.toThrow('Internal error');
    });
  });

  describe('API client configuration', () => {
    it('should have correct base URL', async () => {
      // Arrange
      const mockPlugins: PluginInfo[] = [];
      mock.onGet('/plugins').reply(200, mockPlugins);

      // Act
      await pluginService.getPlugins();

      // Assert
      expect(mock.history.get[0].baseURL).toBe('http://localhost:8000');
    });

    it('should include Content-Type header', async () => {
      // Arrange
      const mockPlugins: PluginInfo[] = [];
      mock.onGet('/plugins').reply(200, mockPlugins);

      // Act
      await pluginService.getPlugins();

      // Assert
      expect(mock.history.get[0].headers?.['Content-Type']).toBe('application/json');
    });
  });
});
