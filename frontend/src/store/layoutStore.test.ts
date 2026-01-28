import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import type { ResponsiveLayouts, LayoutItem } from '@/types/layout';

import { useLayoutStore } from './layoutStore';

describe('Layout Store (Zustand)', () => {
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

  const updatedLgLayout: LayoutItem[] = [
    { i: 'widget-1', x: 2, y: 0, w: 6, h: 3 },
    { i: 'widget-2', x: 8, y: 0, w: 4, h: 2 },
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('initial state', () => {
    it('should initialize with empty layouts', () => {
      // Arrange & Act
      const { result } = renderHook(() => useLayoutStore());

      // Assert
      expect(result.current.layouts).toEqual({
        lg: [],
        md: [],
        sm: [],
      });
    });

    it('should provide default getter for layouts', () => {
      // Arrange & Act
      const { result } = renderHook(() => useLayoutStore());

      // Assert
      expect(result.current.layouts).toBeDefined();
      expect(typeof result.current.layouts).toBe('object');
    });
  });

  describe('setLayouts', () => {
    it('should replace entire layouts state', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());

      // Act
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Assert
      expect(result.current.layouts).toEqual(mockLayouts);
      expect(result.current.layouts.lg).toHaveLength(2);
      expect(result.current.layouts.md).toHaveLength(2);
      expect(result.current.layouts.sm).toHaveLength(2);
    });

    it('should overwrite previous layouts completely', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const newLayouts: ResponsiveLayouts = {
        lg: [{ i: 'widget-3', x: 0, y: 0, w: 12, h: 4 }],
        md: [{ i: 'widget-3', x: 0, y: 0, w: 12, h: 4 }],
        sm: [{ i: 'widget-3', x: 0, y: 0, w: 12, h: 4 }],
      };

      // Act
      act(() => {
        result.current.setLayouts(mockLayouts);
      });
      act(() => {
        result.current.setLayouts(newLayouts);
      });

      // Assert
      expect(result.current.layouts).toEqual(newLayouts);
      expect(result.current.layouts.lg).toHaveLength(1);
      expect(result.current.layouts.lg[0].i).toBe('widget-3');
    });

    it('should handle empty layouts object', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const emptyLayouts: ResponsiveLayouts = {
        lg: [],
        md: [],
        sm: [],
      };

      // Act
      act(() => {
        result.current.setLayouts(emptyLayouts);
      });

      // Assert
      expect(result.current.layouts).toEqual(emptyLayouts);
    });
  });

  describe('updateLayout', () => {
    it('should update specific breakpoint layout without affecting others', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.updateLayout('lg', updatedLgLayout);
      });

      // Assert
      expect(result.current.layouts.lg).toEqual(updatedLgLayout);
      expect(result.current.layouts.md).toEqual(mockLayouts.md); // Unchanged
      expect(result.current.layouts.sm).toEqual(mockLayouts.sm); // Unchanged
    });

    it('should update md breakpoint independently', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const updatedMdLayout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 12, h: 2 },
      ];
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.updateLayout('md', updatedMdLayout);
      });

      // Assert
      expect(result.current.layouts.md).toEqual(updatedMdLayout);
      expect(result.current.layouts.lg).toEqual(mockLayouts.lg); // Unchanged
    });

    it('should update sm breakpoint independently', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const updatedSmLayout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 12, h: 3 },
      ];
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.updateLayout('sm', updatedSmLayout);
      });

      // Assert
      expect(result.current.layouts.sm).toEqual(updatedSmLayout);
    });

    it('should handle adding new widget to existing layout', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const layoutWithNewWidget: LayoutItem[] = [
        ...mockLayouts.lg,
        { i: 'widget-3', x: 0, y: 2, w: 6, h: 2 },
      ];
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.updateLayout('lg', layoutWithNewWidget);
      });

      // Assert
      expect(result.current.layouts.lg).toHaveLength(3);
      expect(result.current.layouts.lg[2].i).toBe('widget-3');
    });

    it('should handle removing widget from layout', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const layoutWithRemovedWidget: LayoutItem[] = [mockLayouts.lg[0]];
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.updateLayout('lg', layoutWithRemovedWidget);
      });

      // Assert
      expect(result.current.layouts.lg).toHaveLength(1);
      expect(result.current.layouts.lg[0].i).toBe('widget-1');
    });
  });

  describe('resetLayouts', () => {
    it('should reset layouts to empty state', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.resetLayouts();
      });

      // Assert
      expect(result.current.layouts).toEqual({
        lg: [],
        md: [],
        sm: [],
      });
    });

    it('should be idempotent when called multiple times', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      act(() => {
        result.current.setLayouts(mockLayouts);
      });

      // Act
      act(() => {
        result.current.resetLayouts();
        result.current.resetLayouts();
        result.current.resetLayouts();
      });

      // Assert
      expect(result.current.layouts).toEqual({
        lg: [],
        md: [],
        sm: [],
      });
    });
  });

  describe('edge cases', () => {
    it('should handle updating non-existent breakpoint gracefully', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const customLayout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
      ];

      // Act & Assert
      act(() => {
        result.current.updateLayout('xl', customLayout);
      });
      // Should add the new breakpoint
      expect(result.current.layouts.xl).toEqual(customLayout);
    });

    it('should handle layouts with duplicate widget IDs', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      const duplicateLayouts: ResponsiveLayouts = {
        lg: [
          { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
          { i: 'widget-1', x: 6, y: 0, w: 6, h: 2 }, // Duplicate ID
        ],
        md: [],
        sm: [],
      };

      // Act
      act(() => {
        result.current.setLayouts(duplicateLayouts);
      });

      // Assert
      // Should handle gracefully (store accepts duplicates, deduplication happens at utility level)
      expect(result.current.layouts.lg).toHaveLength(2);
    });

    it('should maintain immutability of state', () => {
      // Arrange
      const { result } = renderHook(() => useLayoutStore());
      act(() => {
        result.current.setLayouts(mockLayouts);
      });
      const previousLayouts = result.current.layouts;

      // Act
      act(() => {
        result.current.updateLayout('lg', updatedLgLayout);
      });

      // Assert
      expect(result.current.layouts).not.toBe(previousLayouts);
      expect(previousLayouts.lg).toEqual(mockLayouts.lg); // Original unchanged
    });
  });

  describe('multiple store instances', () => {
    it('should share state across multiple hook calls', () => {
      // Arrange
      const { result: result1 } = renderHook(() => useLayoutStore());
      const { result: result2 } = renderHook(() => useLayoutStore());

      // Act
      act(() => {
        result1.current.setLayouts(mockLayouts);
      });

      // Assert
      expect(result2.current.layouts).toEqual(mockLayouts);
      // Both hooks should see the same state
    });

    it('should synchronize updates across instances', () => {
      // Arrange
      const { result: result1 } = renderHook(() => useLayoutStore());
      const { result: result2 } = renderHook(() => useLayoutStore());

      // Act
      act(() => {
        result1.current.setLayouts(mockLayouts);
      });
      act(() => {
        result2.current.updateLayout('lg', updatedLgLayout);
      });

      // Assert
      expect(result1.current.layouts.lg).toEqual(updatedLgLayout);
      expect(result2.current.layouts.lg).toEqual(updatedLgLayout);
    });
  });
});
