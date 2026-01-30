import type { LayoutItem, ResponsiveLayouts } from '@/types/layout';

const GRID_COLS = 12;

/**
 * Merges updated properties into an existing layout item while preserving constraints
 */
export function mergeLayoutItem(
  existing: LayoutItem,
  updates: Partial<LayoutItem>
): LayoutItem {
  const merged = { ...existing, ...updates };

  // ID is immutable
  merged.i = existing.i;

  // Clamp width to constraints
  if (merged.minW !== undefined && merged.w < merged.minW) {
    merged.w = merged.minW;
  }
  if (merged.maxW !== undefined && merged.w > merged.maxW) {
    merged.w = merged.maxW;
  }

  // Clamp height to constraints
  if (merged.minH !== undefined && merged.h < merged.minH) {
    merged.h = merged.minH;
  }
  if (merged.maxH !== undefined && merged.h > merged.maxH) {
    merged.h = merged.maxH;
  }

  return merged;
}

/**
 * Merges layout updates into existing layouts for all breakpoints
 */
export function mergeLayouts(
  existing: ResponsiveLayouts,
  updates: Partial<ResponsiveLayouts>
): ResponsiveLayouts {
  const merged: ResponsiveLayouts = { ...existing };

  Object.keys(updates).forEach((breakpoint) => {
    const updatedLayout = updates[breakpoint];
    if (!updatedLayout) return;

    const existingLayout = merged[breakpoint] || [];
    const updatedMap = new Map(updatedLayout.map((item) => [item.i, item]));

    // Merge existing items with updates
    const mergedLayout = existingLayout.map((item) => {
      const update = updatedMap.get(item.i);
      if (update) {
        updatedMap.delete(item.i);
        return mergeLayoutItem(item, update);
      }
      return item;
    });

    // Add new items that weren't in existing layout
    updatedMap.forEach((item) => {
      mergedLayout.push(item);
    });

    merged[breakpoint] = mergedLayout;
  });

  return merged;
}

/**
 * Adds a new widget to a layout with auto-calculated position
 */
export function addWidgetToLayout(
  layout: LayoutItem[],
  newWidget: Omit<LayoutItem, 'x' | 'y'> & Partial<Pick<LayoutItem, 'x' | 'y'>>
): LayoutItem[] {
  // Check for duplicate ID
  if (layout.some((item) => item.i === newWidget.i)) {
    return layout;
  }

  const position =
    newWidget.x !== undefined && newWidget.y !== undefined
      ? { x: newWidget.x, y: newWidget.y }
      : findNextAvailablePosition(layout, newWidget);

  const completeWidget: LayoutItem = {
    ...newWidget,
    x: position.x,
    y: position.y,
  } as LayoutItem;

  return [...layout, completeWidget];
}

/**
 * Removes a widget from a layout by ID
 */
export function removeWidgetFromLayout(
  layout: LayoutItem[],
  widgetId: string
): LayoutItem[] {
  return layout.filter((item) => item.i !== widgetId);
}

/**
 * Removes duplicate widgets, keeping the last occurrence
 */
export function deduplicateLayout(layout: LayoutItem[]): LayoutItem[] {
  const seen = new Map<string, LayoutItem>();

  layout.forEach((item) => {
    seen.set(item.i, item);
  });

  return Array.from(seen.values());
}

/**
 * Finds the next available position for a widget in the grid
 */
export function findNextAvailablePosition(
  layout: LayoutItem[],
  widget: Partial<LayoutItem>
): { x: number; y: number } {
  if (layout.length === 0) {
    return { x: 0, y: 0 };
  }

  const width = widget.w || 6;
  const height = widget.h || 2;

  // Build occupancy grid
  const maxY = Math.max(...layout.map((item) => item.y + item.h));
  const occupancy: boolean[][] = [];

  for (let y = 0; y <= maxY + height; y++) {
    occupancy[y] = new Array(GRID_COLS).fill(false);
  }

  // Mark occupied cells
  layout.forEach((item) => {
    for (let y = item.y; y < item.y + item.h; y++) {
      for (let x = item.x; x < item.x + item.w; x++) {
        if (occupancy[y] && x < GRID_COLS) {
          occupancy[y][x] = true;
        }
      }
    }
  });

  // Find first available position
  for (let y = 0; y <= maxY + height; y++) {
    for (let x = 0; x <= GRID_COLS - width; x++) {
      let canPlace = true;

      // Check if widget fits at this position
      for (let dy = 0; dy < height && canPlace; dy++) {
        for (let dx = 0; dx < width && canPlace; dx++) {
          if (occupancy[y + dy]?.[x + dx]) {
            canPlace = false;
          }
        }
      }

      if (canPlace) {
        return { x, y };
      }
    }
  }

  // Fallback: place at bottom
  return { x: 0, y: maxY };
}
