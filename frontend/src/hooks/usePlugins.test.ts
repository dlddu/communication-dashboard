import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { usePlugins } from './usePlugins';
import { pluginService } from '@/services/api';
import type { PluginInfo } from '@/types/plugin';

// Mock the API service
vi.mock('@/services/api', () => ({
  pluginService: {
    getPlugins: vi.fn(),
  },
}));

describe('usePlugins', () => {
  const mockPlugins: PluginInfo[] = [
    { name: 'slack', count: 10, last_updated: '2026-01-27T10:00:00Z' },
    { name: 'email', count: 5, last_updated: '2026-01-27T11:00:00Z' },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('initial state', () => {
    it('should start with loading true and empty plugins', () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      expect(result.current.loading).toBe(true);
      expect(result.current.plugins).toEqual([]);
      expect(result.current.error).toBe(null);
    });
  });

  describe('successful fetch', () => {
    it('should fetch and set plugins on mount', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockResolvedValue(mockPlugins);

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert - Initial state
      expect(result.current.loading).toBe(true);
      expect(result.current.plugins).toEqual([]);

      // Wait for the fetch to complete
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Assert - Final state
      expect(result.current.plugins).toEqual(mockPlugins);
      expect(result.current.error).toBe(null);
      expect(pluginService.getPlugins).toHaveBeenCalledTimes(1);
    });

    it('should set loading to false after successful fetch', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockResolvedValue(mockPlugins);

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
      expect(result.current.plugins).toHaveLength(2);
    });

    it('should handle empty plugins array', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockResolvedValue([]);

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
      expect(result.current.plugins).toEqual([]);
      expect(result.current.error).toBe(null);
    });
  });

  describe('error handling', () => {
    it('should set error when fetch fails with Error', async () => {
      // Arrange
      const errorMessage = 'Failed to fetch plugins';
      vi.mocked(pluginService.getPlugins).mockRejectedValue(new Error(errorMessage));

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
      expect(result.current.error).toBe(errorMessage);
      expect(result.current.plugins).toEqual([]);
    });

    it('should set generic error when fetch fails with non-Error', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockRejectedValue('Unknown error');

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
      expect(result.current.error).toBe('Failed to fetch plugins');
      expect(result.current.plugins).toEqual([]);
    });

    it('should handle network errors', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockRejectedValue(new Error('Network Error'));

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
      expect(result.current.error).toBe('Network Error');
    });

    it('should handle timeout errors', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockRejectedValue(new Error('timeout of 30000ms exceeded'));

      // Act
      const { result } = renderHook(() => usePlugins());

      // Assert
      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
      expect(result.current.error).toContain('timeout');
    });
  });

  describe('refetch functionality', () => {
    it('should refetch plugins when refetch is called', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockResolvedValue(mockPlugins);

      // Act
      const { result } = renderHook(() => usePlugins());

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Call refetch
      await result.current.refetch();

      // Assert
      expect(pluginService.getPlugins).toHaveBeenCalledTimes(2);
    });

    it('should reset error state on refetch', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins)
        .mockRejectedValueOnce(new Error('Initial error'))
        .mockResolvedValueOnce(mockPlugins);

      // Act
      const { result } = renderHook(() => usePlugins());

      await waitFor(() => {
        expect(result.current.error).toBe('Initial error');
      });

      // Refetch
      await result.current.refetch();

      // Assert
      await waitFor(() => {
        expect(result.current.error).toBe(null);
      });
      expect(result.current.plugins).toEqual(mockPlugins);
    });

    it('should set loading to true during refetch', async () => {
      // Arrange
      let resolveGetPlugins: (value: PluginInfo[]) => void;
      const pluginsPromise = new Promise<PluginInfo[]>((resolve) => {
        resolveGetPlugins = resolve;
      });
      vi.mocked(pluginService.getPlugins)
        .mockResolvedValueOnce(mockPlugins) // Initial fetch
        .mockReturnValueOnce(pluginsPromise); // Refetch - controlled resolution

      // Act
      const { result } = renderHook(() => usePlugins());

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Start refetch
      const refetchPromise = result.current.refetch();

      // Assert - Should be loading during refetch
      await waitFor(() => {
        expect(result.current.loading).toBe(true);
      });

      // Resolve the refetch
      resolveGetPlugins!(mockPlugins);
      await refetchPromise;

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });
    });

    it('should update plugins with new data on refetch', async () => {
      // Arrange
      const newPlugins: PluginInfo[] = [
        { name: 'slack', count: 20, last_updated: '2026-01-27T12:00:00Z' },
      ];
      vi.mocked(pluginService.getPlugins)
        .mockResolvedValueOnce(mockPlugins)
        .mockResolvedValueOnce(newPlugins);

      // Act
      const { result } = renderHook(() => usePlugins());

      await waitFor(() => {
        expect(result.current.plugins).toEqual(mockPlugins);
      });

      await result.current.refetch();

      // Assert
      await waitFor(() => {
        expect(result.current.plugins).toEqual(newPlugins);
      });
    });
  });

  describe('edge cases', () => {
    it('should handle multiple rapid refetch calls', async () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockResolvedValue(mockPlugins);

      // Act
      const { result } = renderHook(() => usePlugins());

      await waitFor(() => {
        expect(result.current.loading).toBe(false);
      });

      // Call refetch multiple times rapidly
      await Promise.all([
        result.current.refetch(),
        result.current.refetch(),
        result.current.refetch(),
      ]);

      // Assert - Should have called the API for initial + 3 refetches
      expect(pluginService.getPlugins).toHaveBeenCalledTimes(4);
    });

    it('should maintain stable refetch function reference', () => {
      // Arrange
      vi.mocked(pluginService.getPlugins).mockResolvedValue(mockPlugins);

      // Act
      const { result, rerender } = renderHook(() => usePlugins());
      const firstRefetch = result.current.refetch;

      rerender();
      const secondRefetch = result.current.refetch;

      // Assert
      expect(firstRefetch).toBe(secondRefetch);
    });
  });
});
