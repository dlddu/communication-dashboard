import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useSlackMessages } from './useSlackMessages';
import { pluginService } from '@/services/api';
import type { PluginDataItem } from '@/types/plugin';

// Mock the pluginService
vi.mock('@/services/api', () => ({
  pluginService: {
    getPluginData: vi.fn(),
  },
}));

describe('useSlackMessages', () => {
  const mockMessages: PluginDataItem[] = [
    {
      id: '1',
      source: 'slack',
      title: '#general',
      content: 'Hello team!',
      timestamp: '2026-01-27T10:00:00Z',
      metadata: {
        channel: 'general',
        sender: 'John Doe',
      },
      read: false,
    },
    {
      id: '2',
      source: 'slack',
      title: '#dev',
      content: 'Code review needed',
      timestamp: '2026-01-27T09:30:00Z',
      metadata: {
        channel: 'dev',
        sender: 'Jane Smith',
      },
      read: true,
    },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('initial load', () => {
    it('should start with loading state', () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      // Act
      const { result } = renderHook(() => useSlackMessages());

      // Assert
      expect(result.current.loading).toBe(true);
      expect(result.current.messages).toEqual([]);
      expect(result.current.error).toBeNull();
    });

    it('should load messages successfully with default limit', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockResolvedValue(mockMessages);

      // Act
      const { result } = renderHook(() => useSlackMessages());

      // Assert - initial state
      expect(result.current.loading).toBe(true);

      // Assert - after loading
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.messages).toEqual(mockMessages);
      expect(result.current.error).toBeNull();
      expect(pluginService.getPluginData).toHaveBeenCalledWith('slack', 50);
      expect(pluginService.getPluginData).toHaveBeenCalledTimes(1);
    });

    it('should load messages with custom limit', async () => {
      // Arrange
      const customLimit = 20;
      vi.mocked(pluginService.getPluginData).mockResolvedValue(mockMessages);

      // Act
      const { result } = renderHook(() => useSlackMessages(customLimit));

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(pluginService.getPluginData).toHaveBeenCalledWith('slack', customLimit);
    });

    it('should handle API error gracefully', async () => {
      // Arrange
      const errorMessage = 'Failed to fetch Slack messages';
      vi.mocked(pluginService.getPluginData).mockRejectedValue(new Error(errorMessage));

      // Act
      const { result } = renderHook(() => useSlackMessages());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.messages).toEqual([]);
      expect(result.current.error).toBe(errorMessage);
    });

    it('should handle non-Error exceptions', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockRejectedValue('Network error');

      // Act
      const { result } = renderHook(() => useSlackMessages());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.error).toBe('Failed to fetch Slack messages');
    });
  });

  describe('refresh functionality', () => {
    it('should refresh messages when refresh is called', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData)
        .mockResolvedValueOnce(mockMessages)
        .mockResolvedValueOnce([mockMessages[0]]);

      const { result } = renderHook(() => useSlackMessages());

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Act - call refresh
      await result.current.refresh();

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.messages).toEqual([mockMessages[0]]);
      expect(pluginService.getPluginData).toHaveBeenCalledTimes(2);
    });

    it('should set loading state during refresh', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockResolvedValue(mockMessages);

      const { result } = renderHook(() => useSlackMessages());

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Act
      const refreshPromise = result.current.refresh();

      // Assert - loading should be true during refresh
      expect(result.current.loading).toBe(true);

      await refreshPromise;

      // Assert - loading should be false after refresh
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
    });

    it('should clear previous error on successful refresh', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData)
        .mockRejectedValueOnce(new Error('Initial error'))
        .mockResolvedValueOnce(mockMessages);

      const { result } = renderHook(() => useSlackMessages());

      await waitFor(() => {
        expect(result.current.error).toBe('Initial error');
      });

      // Act - refresh should succeed
      await result.current.refresh();

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.error).toBeNull();
      expect(result.current.messages).toEqual(mockMessages);
    });

    it('should handle error during refresh', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData)
        .mockResolvedValueOnce(mockMessages)
        .mockRejectedValueOnce(new Error('Refresh failed'));

      const { result } = renderHook(() => useSlackMessages());

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Act
      await result.current.refresh();

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.error).toBe('Refresh failed');
      expect(result.current.messages).toEqual([]);
    });
  });

  describe('edge cases', () => {
    it('should handle empty message list', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockResolvedValue([]);

      // Act
      const { result } = renderHook(() => useSlackMessages());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(result.current.messages).toEqual([]);
      expect(result.current.error).toBeNull();
    });

    it('should handle limit of 0', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockResolvedValue([]);

      // Act
      const { result } = renderHook(() => useSlackMessages(0));

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(pluginService.getPluginData).toHaveBeenCalledWith('slack', 0);
    });

    it('should handle negative limit by using default', async () => {
      // Arrange
      vi.mocked(pluginService.getPluginData).mockResolvedValue(mockMessages);

      // Act
      const { result } = renderHook(() => useSlackMessages(-10));

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      expect(pluginService.getPluginData).toHaveBeenCalledWith('slack', 50);
    });
  });
});
