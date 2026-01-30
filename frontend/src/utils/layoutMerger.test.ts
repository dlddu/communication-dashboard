import { describe, it, expect } from 'vitest';
import type { LayoutItem, ResponsiveLayouts } from '@/types/layout';

import {
  mergeLayoutItem,
  mergeLayouts,
  addWidgetToLayout,
  removeWidgetFromLayout,
  deduplicateLayout,
  findNextAvailablePosition,
} from './layoutMerger';

describe('Layout Merger Utilities', () => {
  const mockLayoutItem: LayoutItem = {
    i: 'widget-1',
    x: 0,
    y: 0,
    w: 6,
    h: 2,
    minW: 4,
    maxW: 8,
    minH: 2,
    maxH: 4,
  };

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

  describe('mergeLayoutItem', () => {
    it('should merge updated properties into existing layout item', () => {
      const updates: Partial<LayoutItem> = { x: 2, y: 1, w: 8 };
      const merged = mergeLayoutItem(mockLayoutItem, updates);

      expect(merged.i).toBe('widget-1'); // Preserved
      expect(merged.x).toBe(2); // Updated
      expect(merged.y).toBe(1); // Updated
      expect(merged.w).toBe(8); // Updated
      expect(merged.h).toBe(2); // Preserved
      expect(merged.minW).toBe(4); // Preserved
    });

    it('should preserve constraints when merging', () => {
      const updates: Partial<LayoutItem> = { w: 10 }; // Exceeds maxW
      const merged = mergeLayoutItem(mockLayoutItem, updates);

      expect(merged.w).toBe(8); // Clamped to maxW
    });

    it('should not allow width below minimum', () => {
      const updates: Partial<LayoutItem> = { w: 2 }; // Below minW
      const merged = mergeLayoutItem(mockLayoutItem, updates);

      expect(merged.w).toBe(4); // Clamped to minW
    });

    it('should not allow height below minimum', () => {
      const updates: Partial<LayoutItem> = { h: 1 }; // Below minH
      const merged = mergeLayoutItem(mockLayoutItem, updates);

      expect(merged.h).toBe(2); // Clamped to minH
    });

    it('should not allow height above maximum', () => {
      const updates: Partial<LayoutItem> = { h: 6 }; // Exceeds maxH
      const merged = mergeLayoutItem(mockLayoutItem, updates);

      expect(merged.h).toBe(4); // Clamped to maxH
    });

    it('should preserve static and other boolean properties', () => {
      const staticItem: LayoutItem = { ...mockLayoutItem, static: true, isDraggable: false };
      const updates: Partial<LayoutItem> = { x: 5 };
      const merged = mergeLayoutItem(staticItem, updates);

      expect(merged.static).toBe(true);
      expect(merged.isDraggable).toBe(false);
    });

    it('should not allow changing widget ID', () => {
      const updates: Partial<LayoutItem> = { i: 'widget-999' };
      const merged = mergeLayoutItem(mockLayoutItem, updates);

      expect(merged.i).toBe('widget-1'); // ID should be immutable
    });
  });

  describe('mergeLayouts', () => {
    it('should merge updates into existing layouts for all breakpoints', () => {
      const updates: Partial<ResponsiveLayouts> = {
        lg: [{ i: 'widget-1', x: 2, y: 0, w: 8, h: 2 }],
      };

      const merged = mergeLayouts(mockLayouts, updates);

      expect(merged.lg[0].x).toBe(2); // Updated
      expect(merged.lg[1]).toEqual(mockLayouts.lg[1]); // Unchanged widget
      expect(merged.md).toEqual(mockLayouts.md); // Unchanged breakpoint
      expect(merged.sm).toEqual(mockLayouts.sm); // Unchanged breakpoint
    });

    it('should add new widget to specific breakpoint', () => {
      const newWidget: LayoutItem = { i: 'widget-3', x: 0, y: 2, w: 6, h: 2 };
      const updates: Partial<ResponsiveLayouts> = {
        lg: [...mockLayouts.lg, newWidget],
      };

      const merged = mergeLayouts(mockLayouts, updates);

      expect(merged.lg).toHaveLength(3);
      expect(merged.lg[2]).toEqual(newWidget);
    });

    it('should preserve existing widgets when updating breakpoint', () => {
      const updates: Partial<ResponsiveLayouts> = {
        sm: [{ i: 'widget-1', x: 0, y: 0, w: 12, h: 3 }], // Only update widget-1
      };

      const merged = mergeLayouts(mockLayouts, updates);

      expect(merged.sm).toHaveLength(2); // Should still have both widgets
      expect(merged.sm[0].h).toBe(3); // Updated
      expect(merged.sm[1]).toEqual(mockLayouts.sm[1]); // Preserved
    });

    it('should handle adding new breakpoint', () => {
      const updates = {
        xl: [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }] as LayoutItem[],
      };

      const merged = mergeLayouts(mockLayouts, updates);

      expect(merged.xl).toBeDefined();
      expect(merged.xl).toHaveLength(1);
    });

    it('should maintain immutability of original layouts', () => {
      const originalCopy = JSON.parse(JSON.stringify(mockLayouts));
      const updates: Partial<ResponsiveLayouts> = {
        lg: [{ i: 'widget-1', x: 5, y: 5, w: 10, h: 10 }],
      };

      mergeLayouts(mockLayouts, updates);

      expect(mockLayouts).toEqual(originalCopy); // Original unchanged
    });
  });

  describe('addWidgetToLayout', () => {
    it('should add new widget with auto-calculated position', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
      ];
      const newWidget = { i: 'widget-3', w: 6, h: 2 };

      const updated = addWidgetToLayout(layout, newWidget);

      expect(updated).toHaveLength(3);
      expect(updated[2].i).toBe('widget-3');
      expect(updated[2].x).toBeDefined();
      expect(updated[2].y).toBeDefined();
    });

    it('should place new widget in next available row when current row is full', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 }, // Row 0 full (12 columns)
      ];
      const newWidget = { i: 'widget-3', w: 6, h: 2 };

      const updated = addWidgetToLayout(layout, newWidget);

      expect(updated[2].x).toBe(0);
      expect(updated[2].y).toBe(2); // Next row (y = previous max y + previous height)
    });

    it('should handle adding to empty layout', () => {
      const emptyLayout: LayoutItem[] = [];
      const newWidget = { i: 'widget-1', w: 6, h: 2 };

      const updated = addWidgetToLayout(emptyLayout, newWidget);

      expect(updated).toHaveLength(1);
      expect(updated[0].x).toBe(0);
      expect(updated[0].y).toBe(0);
    });

    it('should respect widget constraints when adding', () => {
      const layout: LayoutItem[] = [{ i: 'widget-1', x: 0, y: 0, w: 6, h: 2 }];
      const newWidget = { i: 'widget-2', w: 6, h: 2, minW: 4, maxW: 8 };

      const updated = addWidgetToLayout(layout, newWidget);

      expect(updated[1].minW).toBe(4);
      expect(updated[1].maxW).toBe(8);
    });

    it('should not add widget with duplicate ID', () => {
      const layout: LayoutItem[] = [{ i: 'widget-1', x: 0, y: 0, w: 6, h: 2 }];
      const duplicateWidget = { i: 'widget-1', w: 6, h: 2 }; // Same ID

      const updated = addWidgetToLayout(layout, duplicateWidget);

      expect(updated).toHaveLength(1); // Should not add duplicate
    });
  });

  describe('removeWidgetFromLayout', () => {
    it('should remove widget by ID', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
        { i: 'widget-3', x: 0, y: 2, w: 6, h: 2 },
      ];

      const updated = removeWidgetFromLayout(layout, 'widget-2');

      expect(updated).toHaveLength(2);
      expect(updated.find((item) => item.i === 'widget-2')).toBeUndefined();
      expect(updated[0].i).toBe('widget-1');
      expect(updated[1].i).toBe('widget-3');
    });

    it('should maintain positions of remaining widgets', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
      ];

      const updated = removeWidgetFromLayout(layout, 'widget-2');

      expect(updated[0]).toEqual(layout[0]); // Position unchanged
    });

    it('should handle removing non-existent widget gracefully', () => {
      const layout: LayoutItem[] = [{ i: 'widget-1', x: 0, y: 0, w: 6, h: 2 }];

      const updated = removeWidgetFromLayout(layout, 'widget-999');

      expect(updated).toEqual(layout); // No change
    });

    it('should handle removing from empty layout', () => {
      const emptyLayout: LayoutItem[] = [];

      const updated = removeWidgetFromLayout(emptyLayout, 'widget-1');

      expect(updated).toEqual([]);
    });

    it('should maintain immutability', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
      ];
      const originalCopy = JSON.parse(JSON.stringify(layout));

      removeWidgetFromLayout(layout, 'widget-2');

      expect(layout).toEqual(originalCopy); // Original unchanged
    });
  });

  describe('deduplicateLayout', () => {
    it('should remove duplicate widget IDs keeping the last occurrence', () => {
      const layoutWithDuplicates: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
        { i: 'widget-1', x: 0, y: 2, w: 8, h: 3 }, // Duplicate with different position
      ];

      const deduplicated = deduplicateLayout(layoutWithDuplicates);

      expect(deduplicated).toHaveLength(2);
      const widget1 = deduplicated.find((item) => item.i === 'widget-1');
      expect(widget1?.w).toBe(8); // Should keep last occurrence
    });

    it('should handle layout without duplicates', () => {
      const uniqueLayout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 },
      ];

      const deduplicated = deduplicateLayout(uniqueLayout);

      expect(deduplicated).toEqual(uniqueLayout);
    });

    it('should handle empty layout', () => {
      const emptyLayout: LayoutItem[] = [];

      const deduplicated = deduplicateLayout(emptyLayout);

      expect(deduplicated).toEqual([]);
    });

    it('should handle layout with all duplicates', () => {
      const allDuplicates: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-1', x: 2, y: 0, w: 7, h: 2 },
        { i: 'widget-1', x: 4, y: 0, w: 8, h: 2 },
      ];

      const deduplicated = deduplicateLayout(allDuplicates);

      expect(deduplicated).toHaveLength(1);
      expect(deduplicated[0].w).toBe(8); // Last occurrence
    });
  });

  describe('findNextAvailablePosition', () => {
    it('should find position in same row if space available', () => {
      const layout: LayoutItem[] = [{ i: 'widget-1', x: 0, y: 0, w: 4, h: 2 }];
      const widget = { w: 4, h: 2 };

      const position = findNextAvailablePosition(layout, widget);

      expect(position.x).toBe(4); // After widget-1
      expect(position.y).toBe(0); // Same row
    });

    it('should move to next row when current row is full', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 6, h: 2 },
        { i: 'widget-2', x: 6, y: 0, w: 6, h: 2 }, // Row full (12 columns)
      ];
      const widget = { w: 6, h: 2 };

      const position = findNextAvailablePosition(layout, widget);

      expect(position.x).toBe(0);
      expect(position.y).toBe(2); // Next row
    });

    it('should handle empty layout', () => {
      const emptyLayout: LayoutItem[] = [];
      const widget = { w: 6, h: 2 };

      const position = findNextAvailablePosition(emptyLayout, widget);

      expect(position.x).toBe(0);
      expect(position.y).toBe(0);
    });

    it('should account for widget height when calculating next row', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 12, h: 3 }, // Tall widget
      ];
      const widget = { w: 6, h: 2 };

      const position = findNextAvailablePosition(layout, widget);

      expect(position.x).toBe(0);
      expect(position.y).toBe(3); // After tall widget
    });

    it('should find gap in layout for smaller widgets', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 0, y: 0, w: 4, h: 2 },
        { i: 'widget-2', x: 8, y: 0, w: 4, h: 2 }, // Gap at x: 4-7
      ];
      const widget = { w: 3, h: 2 };

      const position = findNextAvailablePosition(layout, widget);

      expect(position.x).toBe(4); // Fill the gap
      expect(position.y).toBe(0);
    });

    it('should handle layouts with irregular positions', () => {
      const layout: LayoutItem[] = [
        { i: 'widget-1', x: 2, y: 1, w: 6, h: 2 },
        { i: 'widget-2', x: 5, y: 3, w: 4, h: 2 },
      ];
      const widget = { w: 6, h: 2 };

      const position = findNextAvailablePosition(layout, widget);

      // Should find first available position
      expect(position.x).toBeGreaterThanOrEqual(0);
      expect(position.y).toBeGreaterThanOrEqual(0);
    });

    it('should not exceed grid column limit (12 columns)', () => {
      const layout: LayoutItem[] = [{ i: 'widget-1', x: 0, y: 0, w: 8, h: 2 }];
      const widget = { w: 6, h: 2 }; // Would exceed 12 if placed at x: 8

      const position = findNextAvailablePosition(layout, widget);

      expect(position.x + widget.w).toBeLessThanOrEqual(12);
    });
  });

  describe('Edge cases and error handling', () => {
    it('should handle widget with zero width gracefully', () => {
      const layout: LayoutItem[] = [];
      const zeroWidthWidget = { i: 'widget-1', w: 0, h: 2 };

      // Should handle without crashing
      const position = findNextAvailablePosition(layout, zeroWidthWidget);
      expect(position).toBeDefined();
    });

    it('should handle widget with negative position', () => {
      const invalidWidget: LayoutItem = { i: 'widget-1', x: -1, y: -1, w: 6, h: 2 };
      const updates: Partial<LayoutItem> = { x: 0 };

      const merged = mergeLayoutItem(invalidWidget, updates);
      expect(merged.x).toBe(0);
    });

    it('should handle layout exceeding grid bounds', () => {
      const outOfBoundsWidget: LayoutItem = { i: 'widget-1', x: 15, y: 0, w: 6, h: 2 };

      // Should not crash when processing
      const layout = [outOfBoundsWidget];
      const position = findNextAvailablePosition(layout, { w: 6, h: 2 });
      expect(position).toBeDefined();
    });
  });
});
