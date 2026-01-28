import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import type { ResponsiveLayouts } from '@/types/layout';

// Mock the layout service
vi.mock('@/services/api', () => ({
  layoutService: {
    loadLayout: vi.fn(),
    saveLayout: vi.fn(),
  },
}));

import { useLayoutPersistence } from './useLayoutPersistence';
import { layoutService } from '@/services/api';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};

  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      store[key] = value.toString();
    },
    removeItem: (key: string) => {
      delete store[key];
    },
    clear: () => {
      store = {};
    },
  };
})();

describe('useLayoutPersistence Hook', () => {
  const mockLayouts: ResponsiveLayouts = {
    lg: [
      { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
      { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
    ],
    md: [
      { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
      { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
    ],
    sm: [
      { i: 'widget-1', x: 0, y: 0, w: 12, h: 2 },
      { i: 'widget-2', x: 0, y: 2, w: 12, h: 2 },
    ],
  };

  beforeEach(() => {
    vi.clearAllMocks();
    localStorageMock.clear();
    global.localStorage = localStorageMock as Storage;
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe('Backend Synchronization', () => {
    describe('DLD-122: syncs layout to backend', () => {
      it('should save layout to backend API when saveLayout is called', async () => {
        // Arrange
        vi.mocked(layoutService.saveLayout).mockResolvedValue({ success: true });
        vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        // Wait for initial load
        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });

        // Act
        await result.current.saveLayout(mockLayouts);

        // Assert
        expect(layoutService.saveLayout).toHaveBeenCalledWith(
          'user-123',
          expect.objectContaining({
            layouts: mockLayouts,
            timestamp: expect.any(Number),
          })
        );
      });

      it('should load layout from backend API on initial mount', async () => {
        // Arrange
        vi.mocked(layoutService.loadLayout).mockResolvedValue(mockLayouts);

        // Act
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        // Assert
        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });
        expect(layoutService.loadLayout).toHaveBeenCalledWith('user-123');
        expect(result.current.layouts).toEqual(mockLayouts);
      });

      it('should include timestamp in backend save request', async () => {
        // Arrange
        vi.mocked(layoutService.saveLayout).mockResolvedValue({ success: true });
        vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });

        // Act
        await result.current.saveLayout(mockLayouts);

        // Assert
        expect(layoutService.saveLayout).toHaveBeenCalledWith(
          'user-123',
          expect.objectContaining({
            layouts: mockLayouts,
            timestamp: expect.any(Number),
          })
        );
      });

      it('should debounce multiple rapid save calls', async () => {
        // Arrange
        vi.mocked(layoutService.saveLayout).mockResolvedValue({ success: true });
        vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
        const { result } = renderHook(() =>
          useLayoutPersistence({ userId: 'user-123', debounceMs: 300 })
        );

        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });

        // Act - rapid saves
        result.current.saveLayout(mockLayouts);
        result.current.saveLayout(mockLayouts);
        result.current.saveLayout(mockLayouts);

        // Wait for debounce
        await new Promise((resolve) => setTimeout(resolve, 400));

        // Assert - should only call API once
        expect(layoutService.saveLayout).toHaveBeenCalledTimes(1);
      });
    });

    describe('DLD-122: falls back to localStorage if backend fails', () => {
      it('should save to localStorage when backend API fails', async () => {
        // Arrange
        vi.mocked(layoutService.saveLayout).mockRejectedValue(new Error('Network error'));
        vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });

        // Act
        await result.current.saveLayout(mockLayouts);

        // Assert
        const stored = localStorage.getItem('dashboard-layouts-user-123');
        expect(stored).toBeTruthy();
        expect(JSON.parse(stored!)).toEqual(mockLayouts);
      });

      it('should load from localStorage when backend API fails', async () => {
        // Arrange
        localStorage.setItem('dashboard-layouts-user-123', JSON.stringify(mockLayouts));
        vi.mocked(layoutService.loadLayout).mockRejectedValue(new Error('Network error'));

        // Act
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        // Assert
        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });
        expect(result.current.layouts).toEqual(mockLayouts);
        expect(result.current.error).toBeNull();
      });

      it('should set error message when backend save fails', async () => {
        // Arrange
        vi.mocked(layoutService.saveLayout).mockRejectedValue(new Error('Server error'));
        vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });

        // Act
        await result.current.saveLayout(mockLayouts);

        // Assert
        expect(result.current.error).toBe('Failed to save to backend, saved locally');
      });

      it('should prioritize backend data over localStorage when both exist', async () => {
        // Arrange
        const localLayouts: ResponsiveLayouts = {
          lg: [{ i: 'widget-local', x: 0, y: 0, w: 12, h: 2 }],
          md: [],
          sm: [],
        };
        localStorage.setItem('dashboard-layouts-user-123', JSON.stringify(localLayouts));
        vi.mocked(layoutService.loadLayout).mockResolvedValue(mockLayouts);

        // Act
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        // Assert
        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });
        expect(result.current.layouts).toEqual(mockLayouts); // Backend data wins
      });

      it('should sync localStorage to backend on next successful save', async () => {
        // Arrange
        vi.mocked(layoutService.saveLayout)
          .mockRejectedValueOnce(new Error('Network error')) // First save fails
          .mockResolvedValueOnce({ success: true }); // Second save succeeds
        vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
        const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

        await waitFor(() => {
          expect(result.current.isLoading).toBe(false);
        });

        // Act
        await result.current.saveLayout(mockLayouts);
        const stored = localStorage.getItem('dashboard-layouts-user-123');
        expect(stored).toBeTruthy();

        // Second save should sync to backend
        await result.current.saveLayout(mockLayouts);

        // Assert
        expect(layoutService.saveLayout).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('localStorage Operations', () => {
    it('should save layouts to localStorage with correct key', async () => {
      // Arrange
      vi.mocked(layoutService.saveLayout).mockRejectedValue(new Error('Offline'));
      vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Act
      await result.current.saveLayout(mockLayouts);

      // Assert
      const stored = localStorage.getItem('dashboard-layouts-user-123');
      expect(stored).toBeTruthy();
      expect(JSON.parse(stored!)).toEqual(mockLayouts);
    });

    it('should load layouts from localStorage when no userId provided', async () => {
      // Arrange
      localStorage.setItem('dashboard-layouts-default', JSON.stringify(mockLayouts));

      // Act
      const { result } = renderHook(() => useLayoutPersistence());

      // Assert
      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });
      expect(result.current.layouts).toEqual(mockLayouts);
    });

    it('should handle corrupted localStorage data gracefully', async () => {
      // Arrange
      localStorage.setItem('dashboard-layouts-user-123', 'invalid-json{{{');
      vi.mocked(layoutService.loadLayout).mockRejectedValue(new Error('Network error'));

      // Act
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      // Assert
      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });
      expect(result.current.layouts).toEqual({ lg: [], md: [], sm: [] }); // Fallback to empty
      expect(result.current.error).toBeTruthy();
    });

    it('should handle localStorage quota exceeded error', async () => {
      // Arrange
      vi.mocked(layoutService.saveLayout).mockRejectedValue(new Error('Offline'));
      vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
      const setItemSpy = vi.spyOn(localStorage, 'setItem').mockImplementation(() => {
        throw new Error('QuotaExceededError');
      });
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Act
      await result.current.saveLayout(mockLayouts);

      // Assert
      expect(result.current.error).toBe('Failed to save: storage quota exceeded');
      setItemSpy.mockRestore();
    });
  });

  describe('DLD-122: merges new widgets into existing layout', () => {
    it('should add new widget using addWidget method', async () => {
      // Arrange
      const existingLayouts: ResponsiveLayouts = {
        lg: [
          { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
          { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
        ],
        md: [
          { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
          { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
        ],
        sm: [
          { i: 'widget-1', x: 0, y: 0, w: 12, h: 2 },
          { i: 'widget-2', x: 0, y: 2, w: 12, h: 2 },
        ],
      };
      vi.mocked(layoutService.loadLayout).mockResolvedValue(existingLayouts);
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      // Act
      await waitFor(() => expect(result.current.isLoading).toBe(false));
      result.current.addWidget('widget-3', { w: 6, h: 2 });

      // Assert
      expect(result.current.layouts.lg).toHaveLength(3);
      expect(result.current.layouts.md).toHaveLength(3);
      expect(result.current.layouts.sm).toHaveLength(3);
      expect(result.current.layouts.lg.find((item) => item.i === 'widget-3')).toBeDefined();
    });

    it('should remove widget using removeWidget method', async () => {
      // Arrange
      const layoutsWithThreeWidgets: ResponsiveLayouts = {
        lg: [
          { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
          { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
          { i: 'widget-3', x: 0, y: 2, w: 6, h: 2 },
        ],
        md: [],
        sm: [],
      };
      vi.mocked(layoutService.loadLayout).mockResolvedValue(layoutsWithThreeWidgets);
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      // Act
      await waitFor(() => expect(result.current.isLoading).toBe(false));
      result.current.removeWidget('widget-2');

      // Assert
      expect(result.current.layouts.lg).toHaveLength(2);
      expect(result.current.layouts.lg.find((item) => item.i === 'widget-2')).toBeUndefined();
    });

    it('should not duplicate widgets when adding existing widget ID', async () => {
      // Arrange
      const existingLayouts: ResponsiveLayouts = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 6, h: 2 }],
        md: [],
        sm: [],
      };
      vi.mocked(layoutService.loadLayout).mockResolvedValue(existingLayouts);
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      // Act
      await waitFor(() => expect(result.current.isLoading).toBe(false));
      result.current.addWidget('widget-1', { w: 6, h: 2 });

      // Assert
      const widget1Items = result.current.layouts.lg.filter((item) => item.i === 'widget-1');
      expect(widget1Items).toHaveLength(1); // Should not duplicate
    });
  });

  describe('Error handling', () => {
    it('should handle both backend and localStorage failures', async () => {
      // Arrange
      vi.mocked(layoutService.saveLayout).mockRejectedValue(new Error('Network error'));
      vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
      vi.spyOn(localStorage, 'setItem').mockImplementation(() => {
        throw new Error('Storage error');
      });
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Act
      await result.current.saveLayout(mockLayouts);

      // Assert
      expect(result.current.error).toBe('Failed to save layout');
    });

    it('should clear error on successful save', async () => {
      // Arrange
      vi.mocked(layoutService.saveLayout)
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValueOnce({ success: true });
      vi.mocked(layoutService.loadLayout).mockResolvedValue({ lg: [], md: [], sm: [] });
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false);
      });

      // Act
      await result.current.saveLayout(mockLayouts);
      expect(result.current.error).toBeTruthy();

      // Second save succeeds
      await result.current.saveLayout(mockLayouts);

      // Assert
      expect(result.current.error).toBeNull();
    });
  });

  describe('Edge cases', () => {
    it('should handle empty layouts', async () => {
      // Arrange
      const emptyLayouts: ResponsiveLayouts = { lg: [], md: [], sm: [] };
      vi.mocked(layoutService.loadLayout).mockResolvedValue(emptyLayouts);

      // Act
      const { result } = renderHook(() => useLayoutPersistence({ userId: 'user-123' }));

      // Assert
      await waitFor(() => expect(result.current.isLoading).toBe(false));
      expect(result.current.layouts).toEqual(emptyLayouts);
    });

    it('should handle null userId gracefully', async () => {
      // Arrange & Act
      const { result } = renderHook(() => useLayoutPersistence({ userId: undefined }));

      // Assert
      await waitFor(() => expect(result.current.isLoading).toBe(false));
      // Should use default key for localStorage
      expect(result.current).toBeDefined();
    });
  });
});
