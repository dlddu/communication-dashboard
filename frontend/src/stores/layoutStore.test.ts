import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { act } from '@testing-library/react';
import type { LayoutItem } from '../types/layout';

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

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
});

// Mock axios
vi.mock('axios', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}));

describe('layoutStore', () => {
  beforeEach(() => {
    localStorageMock.clear();
    vi.clearAllMocks();
    vi.resetModules();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('initialization', () => {
    it('should initialize with empty layout', async () => {
      // Arrange & Act
      const { useLayoutStore } = await import('./layoutStore');
      const store = useLayoutStore.getState();

      // Assert
      expect(store.layout).toBeDefined();
      expect(store.layout.lg).toEqual([]);
      expect(store.layout.md).toEqual([]);
      expect(store.layout.sm).toEqual([]);
    });

    it('should initialize with default breakpoints', async () => {
      // Arrange & Act
      const { useLayoutStore } = await import('./layoutStore');
      const store = useLayoutStore.getState();

      // Assert
      expect(store.layout).toHaveProperty('lg');
      expect(store.layout).toHaveProperty('md');
      expect(store.layout).toHaveProperty('sm');
    });
  });

  describe('setLayout', () => {
    it('should update layout state when setLayout is called', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const newLayout = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
      };

      // Act
      act(() => {
        useLayoutStore.getState().setLayout(newLayout);
      });

      // Assert
      const state = useLayoutStore.getState();
      expect(state.layout).toEqual(newLayout);
      expect(state.layout.lg).toHaveLength(1);
      expect(state.layout.lg[0].i).toBe('widget-1');
    });

    it('should update multiple widgets in layout', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const newLayout = {
        lg: [
          { i: 'widget-1', x: 0, y: 0, w: 4, h: 2 },
          { i: 'widget-2', x: 4, y: 0, w: 4, h: 2 },
          { i: 'widget-3', x: 8, y: 0, w: 4, h: 2 },
        ],
        md: [
          { i: 'widget-1', x: 0, y: 0, w: 3, h: 2 },
          { i: 'widget-2', x: 3, y: 0, w: 3, h: 2 },
          { i: 'widget-3', x: 6, y: 0, w: 3, h: 2 },
        ],
        sm: [
          { i: 'widget-1', x: 0, y: 0, w: 2, h: 2 },
          { i: 'widget-2', x: 0, y: 2, w: 2, h: 2 },
          { i: 'widget-3', x: 0, y: 4, w: 2, h: 2 },
        ],
      };

      // Act
      act(() => {
        useLayoutStore.getState().setLayout(newLayout);
      });

      // Assert
      const state = useLayoutStore.getState();
      expect(state.layout.lg).toHaveLength(3);
      expect(state.layout.md).toHaveLength(3);
      expect(state.layout.sm).toHaveLength(3);
    });

    it('should replace existing layout completely', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const initialLayout = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
      };
      const newLayout = {
        lg: [{ i: 'widget-2', x: 4, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-2', x: 3, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-2', x: 0, y: 2, w: 2, h: 2 }],
      };

      // Act
      act(() => {
        useLayoutStore.getState().setLayout(initialLayout);
      });
      act(() => {
        useLayoutStore.getState().setLayout(newLayout);
      });

      // Assert
      const state = useLayoutStore.getState();
      expect(state.layout).toEqual(newLayout);
      expect(state.layout.lg[0].i).toBe('widget-2');
      expect(state.layout.lg).toHaveLength(1);
    });
  });

  describe('localStorage persistence', () => {
    it('should save layout to localStorage automatically when updated', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const newLayout = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
      };

      // Act
      act(() => {
        useLayoutStore.getState().setLayout(newLayout);
      });

      // Assert
      const stored = localStorage.getItem('layout-storage');
      expect(stored).not.toBeNull();
      const parsed = JSON.parse(stored!);
      expect(parsed.state.layout).toBeDefined();
    });

    it('should load layout from localStorage on initialization', async () => {
      // Arrange
      const savedLayout = {
        lg: [{ i: 'widget-saved', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-saved', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-saved', x: 0, y: 0, w: 2, h: 2 }],
      };
      localStorage.setItem(
        'layout-storage',
        JSON.stringify({
          state: { layout: savedLayout },
          version: 0,
        })
      );

      // Act
      // Need to clear module cache and re-import to test initialization
      vi.resetModules();
      const { useLayoutStore } = await import('./layoutStore');

      // Assert
      const state = useLayoutStore.getState();
      expect(state.layout.lg[0]?.i).toBe('widget-saved');
    });

    it('should persist layout updates across multiple changes', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const layout1 = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
      };
      const layout2 = {
        lg: [
          { i: 'widget-1', x: 0, y: 0, w: 4, h: 2 },
          { i: 'widget-2', x: 4, y: 0, w: 4, h: 2 },
        ],
        md: [
          { i: 'widget-1', x: 0, y: 0, w: 3, h: 2 },
          { i: 'widget-2', x: 3, y: 0, w: 3, h: 2 },
        ],
        sm: [
          { i: 'widget-1', x: 0, y: 0, w: 2, h: 2 },
          { i: 'widget-2', x: 0, y: 2, w: 2, h: 2 },
        ],
      };

      // Act
      act(() => {
        useLayoutStore.getState().setLayout(layout1);
      });
      act(() => {
        useLayoutStore.getState().setLayout(layout2);
      });

      // Assert
      const stored = localStorage.getItem('layout-storage');
      const parsed = JSON.parse(stored!);
      expect(parsed.state.layout.lg).toHaveLength(2);
    });
  });

  describe('syncToBackend', () => {
    it('should call backend API to sync layout', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      const mockResponse = { data: { success: true } };
      vi.mocked(axios.post).mockResolvedValue(mockResponse);

      const layout = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
      };

      // Act
      act(() => {
        useLayoutStore.getState().setLayout(layout);
      });
      await useLayoutStore.getState().syncToBackend();

      // Assert
      expect(axios.post).toHaveBeenCalledWith('/api/layouts', { layout });
    });

    it('should return success true when backend sync succeeds', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      const mockResponse = { data: { success: true } };
      vi.mocked(axios.post).mockResolvedValue(mockResponse);

      // Act
      const result = await useLayoutStore.getState().syncToBackend();

      // Assert
      expect(result.success).toBe(true);
    });

    it('should return success false when backend sync fails', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      vi.mocked(axios.post).mockRejectedValue(new Error('Network error'));

      // Act
      const result = await useLayoutStore.getState().syncToBackend();

      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });

    it('should handle network timeout errors gracefully', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      const timeoutError = new Error('timeout of 5000ms exceeded');
      timeoutError.name = 'TimeoutError';
      vi.mocked(axios.post).mockRejectedValue(timeoutError);

      // Act
      const result = await useLayoutStore.getState().syncToBackend();

      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toContain('timeout');
    });
  });

  describe('loadFromBackend', () => {
    it('should load layout from backend API', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      const backendLayout = {
        lg: [{ i: 'backend-widget', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'backend-widget', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'backend-widget', x: 0, y: 0, w: 2, h: 2 }],
      };
      vi.mocked(axios.get).mockResolvedValue({ data: { layout: backendLayout } });

      // Act
      await useLayoutStore.getState().loadFromBackend();

      // Assert
      const state = useLayoutStore.getState();
      expect(state.layout.lg[0]?.i).toBe('backend-widget');
    });

    it('should call GET /api/layouts endpoint', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      vi.mocked(axios.get).mockResolvedValue({ data: { layout: { lg: [], md: [], sm: [] } } });

      // Act
      await useLayoutStore.getState().loadFromBackend();

      // Assert
      expect(axios.get).toHaveBeenCalledWith('/api/layouts');
    });

    it('should update store state with backend layout', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      const backendLayout = {
        lg: [
          { i: 'widget-1', x: 0, y: 0, w: 4, h: 2 },
          { i: 'widget-2', x: 4, y: 0, w: 4, h: 2 },
        ],
        md: [
          { i: 'widget-1', x: 0, y: 0, w: 3, h: 2 },
          { i: 'widget-2', x: 3, y: 0, w: 3, h: 2 },
        ],
        sm: [
          { i: 'widget-1', x: 0, y: 0, w: 2, h: 2 },
          { i: 'widget-2', x: 0, y: 2, w: 2, h: 2 },
        ],
      };
      vi.mocked(axios.get).mockResolvedValue({ data: { layout: backendLayout } });

      // Act
      await useLayoutStore.getState().loadFromBackend();

      // Assert
      const state = useLayoutStore.getState();
      expect(state.layout.lg).toHaveLength(2);
      expect(state.layout.md).toHaveLength(2);
    });

    it('should return success true when backend load succeeds', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      vi.mocked(axios.get).mockResolvedValue({ data: { layout: { lg: [], md: [], sm: [] } } });

      // Act
      const result = await useLayoutStore.getState().loadFromBackend();

      // Assert
      expect(result.success).toBe(true);
    });

    it('should return success false when backend load fails', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      vi.mocked(axios.get).mockRejectedValue(new Error('Backend unavailable'));

      // Act
      const result = await useLayoutStore.getState().loadFromBackend();

      // Assert
      expect(result.success).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('Layout Persistence - DLD-122 Test Cases', () => {
    describe('syncs layout to backend', () => {
      it('should sync layout to backend', async () => {
        // Arrange
        const axios = (await import('axios')).default;
        const { useLayoutStore } = await import('./layoutStore');
        vi.mocked(axios.post).mockResolvedValue({ data: { success: true } });

        const layout = {
          lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
          md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
          sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
        };

        // Act
        act(() => {
          useLayoutStore.getState().setLayout(layout);
        });
        const result = await useLayoutStore.getState().syncToBackend();

        // Assert
        expect(result.success).toBe(true);
        expect(axios.post).toHaveBeenCalledWith('/api/layouts', { layout });
      });
    });

    describe('falls back to localStorage if backend fails', () => {
      it('should use localStorage when backend sync fails', async () => {
        // Arrange
        const axios = (await import('axios')).default;
        const { useLayoutStore } = await import('./layoutStore');
        vi.mocked(axios.post).mockRejectedValue(new Error('Backend error'));
        vi.mocked(axios.get).mockRejectedValue(new Error('Backend error'));

        const layout = {
          lg: [{ i: 'fallback-widget', x: 0, y: 0, w: 4, h: 2 }],
          md: [{ i: 'fallback-widget', x: 0, y: 0, w: 3, h: 2 }],
          sm: [{ i: 'fallback-widget', x: 0, y: 0, w: 2, h: 2 }],
        };

        // Act
        act(() => {
          useLayoutStore.getState().setLayout(layout);
        });
        await useLayoutStore.getState().syncToBackend(); // This will fail

        // Assert - Layout should still be in localStorage
        const stored = localStorage.getItem('layout-storage');
        expect(stored).not.toBeNull();
        const parsed = JSON.parse(stored!);
        expect(parsed.state.layout.lg[0]?.i).toBe('fallback-widget');
      });

      it('should load from localStorage when backend is unavailable', async () => {
        // Arrange - Set up localStorage BEFORE importing store
        const localLayout = {
          lg: [{ i: 'local-widget', x: 0, y: 0, w: 4, h: 2 }],
          md: [{ i: 'local-widget', x: 0, y: 0, w: 3, h: 2 }],
          sm: [{ i: 'local-widget', x: 0, y: 0, w: 2, h: 2 }],
        };

        // Set up localStorage with fallback data BEFORE import
        localStorage.setItem(
          'layout-storage',
          JSON.stringify({
            state: { layout: localLayout },
            version: 0,
          })
        );

        // Now import modules - store will rehydrate from localStorage
        const axios = (await import('axios')).default;
        const { useLayoutStore } = await import('./layoutStore');

        vi.mocked(axios.get).mockRejectedValue(new Error('Backend unavailable'));

        // Act
        const result = await useLayoutStore.getState().loadFromBackend();

        // Assert - Should fail to load from backend
        expect(result.success).toBe(false);

        // But localStorage should still have the data
        const stored = localStorage.getItem('layout-storage');
        const parsed = JSON.parse(stored!);
        expect(parsed.state.layout.lg[0]?.i).toBe('local-widget');
      });
    });

    describe('merges new widgets into existing layout', () => {
      it('should merge new widgets into existing layout', async () => {
        // Arrange
        const { useLayoutStore } = await import('./layoutStore');
        const existingLayout = {
          lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
          md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
          sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
        };

        act(() => {
          useLayoutStore.getState().setLayout(existingLayout);
        });

        const newWidget: LayoutItem = { i: 'widget-2', x: 4, y: 0, w: 4, h: 2 };

        // Act
        act(() => {
          useLayoutStore.getState().mergeWidget(newWidget);
        });

        // Assert
        const state = useLayoutStore.getState();
        expect(state.layout.lg).toHaveLength(2);
        expect(state.layout.lg.find((w) => w.i === 'widget-1')).toBeDefined();
        expect(state.layout.lg.find((w) => w.i === 'widget-2')).toBeDefined();
      });

      it('should preserve existing widget positions when merging', async () => {
        // Arrange
        const { useLayoutStore } = await import('./layoutStore');
        const existingLayout = {
          lg: [
            { i: 'widget-1', x: 0, y: 0, w: 4, h: 2 },
            { i: 'widget-2', x: 4, y: 0, w: 4, h: 2 },
          ],
          md: [
            { i: 'widget-1', x: 0, y: 0, w: 3, h: 2 },
            { i: 'widget-2', x: 3, y: 0, w: 3, h: 2 },
          ],
          sm: [
            { i: 'widget-1', x: 0, y: 0, w: 2, h: 2 },
            { i: 'widget-2', x: 0, y: 2, w: 2, h: 2 },
          ],
        };

        act(() => {
          useLayoutStore.getState().setLayout(existingLayout);
        });

        const widget1Original = existingLayout.lg[0];
        const newWidget: LayoutItem = { i: 'widget-3', x: 8, y: 0, w: 4, h: 2 };

        // Act
        act(() => {
          useLayoutStore.getState().mergeWidget(newWidget);
        });

        // Assert
        const state = useLayoutStore.getState();
        const widget1New = state.layout.lg.find((w) => w.i === 'widget-1');
        expect(widget1New).toEqual(widget1Original);
      });

      it('should place new widget in empty space or at bottom', async () => {
        // Arrange
        const { useLayoutStore } = await import('./layoutStore');
        const existingLayout = {
          lg: [{ i: 'widget-1', x: 0, y: 0, w: 6, h: 2 }],
          md: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
          sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
        };

        act(() => {
          useLayoutStore.getState().setLayout(existingLayout);
        });

        const newWidget: LayoutItem = { i: 'widget-2', x: 0, y: 0, w: 4, h: 2 };

        // Act
        act(() => {
          useLayoutStore.getState().mergeWidget(newWidget);
        });

        // Assert
        const state = useLayoutStore.getState();
        const widget2 = state.layout.lg.find((w) => w.i === 'widget-2');
        expect(widget2).toBeDefined();
        // Widget should be placed without overlapping
        expect(widget2!.x + widget2!.w <= 12).toBe(true); // Grid has 12 columns
      });

      it('should not duplicate widget if it already exists', async () => {
        // Arrange
        const { useLayoutStore } = await import('./layoutStore');
        const existingLayout = {
          lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
          md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
          sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
        };

        act(() => {
          useLayoutStore.getState().setLayout(existingLayout);
        });

        const duplicateWidget: LayoutItem = { i: 'widget-1', x: 4, y: 0, w: 4, h: 2 };

        // Act
        act(() => {
          useLayoutStore.getState().mergeWidget(duplicateWidget);
        });

        // Assert
        const state = useLayoutStore.getState();
        expect(state.layout.lg).toHaveLength(1);
      });

      it('should merge multiple new widgets sequentially', async () => {
        // Arrange
        const { useLayoutStore } = await import('./layoutStore');
        const existingLayout = {
          lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
          md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
          sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
        };

        act(() => {
          useLayoutStore.getState().setLayout(existingLayout);
        });

        const widget2: LayoutItem = { i: 'widget-2', x: 4, y: 0, w: 4, h: 2 };
        const widget3: LayoutItem = { i: 'widget-3', x: 8, y: 0, w: 4, h: 2 };

        // Act
        act(() => {
          useLayoutStore.getState().mergeWidget(widget2);
        });
        act(() => {
          useLayoutStore.getState().mergeWidget(widget3);
        });

        // Assert
        const state = useLayoutStore.getState();
        expect(state.layout.lg).toHaveLength(3);
        expect(state.layout.lg.map((w) => w.i).sort()).toEqual(['widget-1', 'widget-2', 'widget-3']);
      });
    });
  });

  describe('edge cases', () => {
    it('should handle empty backend response gracefully', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      vi.mocked(axios.get).mockResolvedValue({ data: {} });

      // Act
      const result = await useLayoutStore.getState().loadFromBackend();

      // Assert
      expect(result.success).toBe(false);
    });

    it('should handle malformed backend response', async () => {
      // Arrange
      const axios = (await import('axios')).default;
      const { useLayoutStore } = await import('./layoutStore');
      vi.mocked(axios.get).mockResolvedValue({ data: { layout: null } });

      // Act
      const result = await useLayoutStore.getState().loadFromBackend();

      // Assert
      expect(result.success).toBe(false);
    });

    it('should handle localStorage quota exceeded', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const originalSetItem = localStorage.setItem;
      localStorage.setItem = vi.fn(() => {
        throw new Error('QuotaExceededError');
      });

      const largeLayout = {
        lg: Array.from({ length: 100 }, (_, i) => ({
          i: `widget-${i}`,
          x: 0,
          y: i * 2,
          w: 4,
          h: 2,
        })),
        md: Array.from({ length: 100 }, (_, i) => ({
          i: `widget-${i}`,
          x: 0,
          y: i * 2,
          w: 3,
          h: 2,
        })),
        sm: Array.from({ length: 100 }, (_, i) => ({
          i: `widget-${i}`,
          x: 0,
          y: i * 2,
          w: 2,
          h: 2,
        })),
      };

      // Act & Assert - Should not throw
      expect(() => {
        act(() => {
          useLayoutStore.getState().setLayout(largeLayout);
        });
      }).not.toThrow();

      // Cleanup
      localStorage.setItem = originalSetItem;
    });

    it('should handle concurrent layout updates', async () => {
      // Arrange
      const { useLayoutStore } = await import('./layoutStore');
      const layout1 = {
        lg: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-1', x: 0, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 2, h: 2 }],
      };
      const layout2 = {
        lg: [{ i: 'widget-2', x: 4, y: 0, w: 4, h: 2 }],
        md: [{ i: 'widget-2', x: 3, y: 0, w: 3, h: 2 }],
        sm: [{ i: 'widget-2', x: 0, y: 2, w: 2, h: 2 }],
      };

      // Act - Simulate concurrent updates
      act(() => {
        useLayoutStore.getState().setLayout(layout1);
        useLayoutStore.getState().setLayout(layout2);
      });

      // Assert - Last update should win
      const state = useLayoutStore.getState();
      expect(state.layout.lg[0]?.i).toBe('widget-2');
    });
  });
});
