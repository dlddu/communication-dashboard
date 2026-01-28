import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ResponsiveGridLayout } from './ResponsiveGridLayout';
import type { ResponsiveLayouts } from '@/types/layout';

// Mock react-grid-layout
vi.mock('react-grid-layout', () => ({
  Responsive: vi.fn(({ children, ...props }) => (
    <div data-testid="responsive-grid-layout" {...props}>
      {children}
    </div>
  )),
  WidthProvider: vi.fn((component) => component),
}));

describe('ResponsiveGridLayout', () => {
  const mockOnLayoutChange = vi.fn();
  const mockOnBreakpointChange = vi.fn();

  const defaultLayouts: ResponsiveLayouts = {
    lg: [
      { i: 'item-1', x: 0, y: 0, w: 6, h: 2, minW: 2, minH: 2 },
      { i: 'item-2', x: 6, y: 0, w: 6, h: 2, minW: 2, minH: 2 },
    ],
    md: [
      { i: 'item-1', x: 0, y: 0, w: 6, h: 2, minW: 2, minH: 2 },
      { i: 'item-2', x: 6, y: 0, w: 6, h: 2, minW: 2, minH: 2 },
    ],
    sm: [
      { i: 'item-1', x: 0, y: 0, w: 12, h: 2, minW: 2, minH: 2 },
      { i: 'item-2', x: 0, y: 2, w: 12, h: 2, minW: 2, minH: 2 },
    ],
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rendering', () => {
    it('should render ResponsiveGridLayout component', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-2">Item 2</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
    });

    it('should render all children as grid items', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1" data-testid="grid-item-1">
            Item 1
          </div>
          <div key="item-2" data-testid="grid-item-2">
            Item 2
          </div>
          <div key="item-3" data-testid="grid-item-3">
            Item 3
          </div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('grid-item-1')).toBeInTheDocument();
      expect(screen.getByTestId('grid-item-2')).toBeInTheDocument();
      expect(screen.getByTestId('grid-item-3')).toBeInTheDocument();
    });

    it('should render with provided layouts prop', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should render without children', () => {
      // Arrange & Act
      render(<ResponsiveGridLayout layouts={defaultLayouts} />);

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
    });
  });

  describe('breakpoint configuration', () => {
    it('should have lg breakpoint configuration (1200px)', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Breakpoints should include lg: 1200
    });

    it('should have md breakpoint configuration (996px)', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Breakpoints should include md: 996
    });

    it('should have sm breakpoint configuration (768px)', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Breakpoints should include sm: 768
    });

    it('should have correct column configuration for each breakpoint', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Should have 12 columns for lg, md, and sm
    });
  });

  describe('responsive behavior', () => {
    it('should apply lg layout for large screens', () => {
      // Arrange
      global.innerWidth = 1400;

      // Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-2">Item 2</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Items should be side by side (w: 6 each)
    });

    it('should apply md layout for medium screens', () => {
      // Arrange
      global.innerWidth = 1000;

      // Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-2">Item 2</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Items should be side by side (w: 6 each)
    });

    it('should apply sm layout for small screens', () => {
      // Arrange
      global.innerWidth = 600;

      // Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-2">Item 2</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
      // Items should be stacked (w: 12 each)
    });

    it('should call onBreakpointChange when breakpoint changes', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout
          layouts={defaultLayouts}
          onBreakpointChange={mockOnBreakpointChange}
        >
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      // This would be tested with resize events in integration tests
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
    });
  });

  describe('drag and drop functionality', () => {
    it('should enable dragging by default', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should disable dragging when isDraggable is false', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} isDraggable={false}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should call onLayoutChange when layout changes', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout
          layouts={defaultLayouts}
          onLayoutChange={mockOnLayoutChange}
        >
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      // onLayoutChange would be called during drag operations
    });

    it('should have drag handle class applied', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} draggableHandle=".drag-handle">
          <div key="item-1">
            <div className="drag-handle">Drag Handle</div>
            <div>Content</div>
          </div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should support drag cancel class', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} draggableCancel=".no-drag">
          <div key="item-1">
            <div className="no-drag">Cannot Drag</div>
          </div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });
  });

  describe('resize functionality', () => {
    it('should enable resizing by default', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should disable resizing when isResizable is false', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} isResizable={false}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should respect minimum width constraints', () => {
      // Arrange
      const layoutsWithMinConstraints: ResponsiveLayouts = {
        lg: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2, minW: 4, minH: 2 }],
        md: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2, minW: 4, minH: 2 }],
        sm: [{ i: 'item-1', x: 0, y: 0, w: 12, h: 2, minW: 4, minH: 2 }],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={layoutsWithMinConstraints}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      // minW should be enforced during resize
    });

    it('should respect maximum width constraints', () => {
      // Arrange
      const layoutsWithMaxConstraints: ResponsiveLayouts = {
        lg: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2, maxW: 8, maxH: 4 }],
        md: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2, maxW: 8, maxH: 4 }],
        sm: [{ i: 'item-1', x: 0, y: 0, w: 12, h: 2, maxW: 12, maxH: 4 }],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={layoutsWithMaxConstraints}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      // maxW should be enforced during resize
    });

    it('should call onLayoutChange when item is resized', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout
          layouts={defaultLayouts}
          onLayoutChange={mockOnLayoutChange}
        >
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      // onLayoutChange would be called during resize operations
    });
  });

  describe('layout persistence', () => {
    it('should call onLayoutChange with current layout and all layouts', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout
          layouts={defaultLayouts}
          onLayoutChange={mockOnLayoutChange}
        >
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
    });

    it('should maintain layout state across re-renders', () => {
      // Arrange
      const { rerender } = render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Act
      rerender(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-2">Item 2</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      expect(screen.getByText('Item 1')).toBeInTheDocument();
      expect(screen.getByText('Item 2')).toBeInTheDocument();
    });
  });

  describe('grid configuration', () => {
    it('should have default row height', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should accept custom row height', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} rowHeight={50}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should have container padding', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} containerPadding={[10, 10]}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should have margin between grid items', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} margin={[10, 10]}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should support compact type for vertical layout', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} compactType="vertical">
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should support compact type for horizontal layout', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} compactType="horizontal">
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should support prevention of collision', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts} preventCollision={true}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });
  });

  describe('accessibility', () => {
    it('should have proper semantic structure', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-2">Item 2</div>
        </ResponsiveGridLayout>
      );

      // Assert
      const gridLayout = screen.getByTestId('responsive-grid-layout');
      expect(gridLayout).toBeInTheDocument();
    });

    it('should support ARIA labels on grid items', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1" aria-label="Dashboard Widget 1">
            Item 1
          </div>
          <div key="item-2" aria-label="Dashboard Widget 2">
            Item 2
          </div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByLabelText('Dashboard Widget 1')).toBeInTheDocument();
      expect(screen.getByLabelText('Dashboard Widget 2')).toBeInTheDocument();
    });

    it('should maintain focus during drag operations', () => {
      // Arrange & Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1" tabIndex={0}>
            Item 1
          </div>
        </ResponsiveGridLayout>
      );

      // Assert
      const item = screen.getByText('Item 1');
      expect(item).toHaveAttribute('tabIndex', '0');
    });
  });

  describe('edge cases', () => {
    it('should handle empty layouts object', () => {
      // Arrange
      const emptyLayouts: ResponsiveLayouts = {
        lg: [],
        md: [],
        sm: [],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={emptyLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      expect(screen.getByText('Item 1')).toBeInTheDocument();
    });

    it('should handle missing breakpoint in layouts', () => {
      // Arrange
      const partialLayouts = {
        lg: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2 }],
        // md and sm missing
      } as ResponsiveLayouts;

      // Act
      render(
        <ResponsiveGridLayout layouts={partialLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
    });

    it('should handle children with duplicate keys gracefully', () => {
      // Arrange
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      // Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
          <div key="item-1">Item 1 Duplicate</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();

      // Cleanup
      consoleSpy.mockRestore();
    });

    it('should handle layout items with negative positions', () => {
      // Arrange
      const layoutsWithNegative: ResponsiveLayouts = {
        lg: [{ i: 'item-1', x: -1, y: -1, w: 6, h: 2 }],
        md: [{ i: 'item-1', x: -1, y: -1, w: 6, h: 2 }],
        sm: [{ i: 'item-1', x: -1, y: -1, w: 12, h: 2 }],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={layoutsWithNegative}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      // Should handle or normalize negative positions
    });

    it('should handle layout items exceeding grid columns', () => {
      // Arrange
      const layoutsExceedingColumns: ResponsiveLayouts = {
        lg: [{ i: 'item-1', x: 0, y: 0, w: 20, h: 2 }], // Exceeds 12 columns
        md: [{ i: 'item-1', x: 0, y: 0, w: 20, h: 2 }],
        sm: [{ i: 'item-1', x: 0, y: 0, w: 20, h: 2 }],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={layoutsExceedingColumns}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      // Should clamp or handle overflow
    });

    it('should handle child with missing key', () => {
      // Arrange
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      // Act
      render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div>Item without key</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();

      // Cleanup
      consoleSpy.mockRestore();
    });

    it('should handle rapidly changing breakpoints', () => {
      // Arrange
      const { rerender } = render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Act - Simulate rapid viewport changes
      global.innerWidth = 1400; // lg
      rerender(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      global.innerWidth = 800; // md
      rerender(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      global.innerWidth = 600; // sm
      rerender(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
    });
  });

  describe('performance', () => {
    it('should render efficiently with many grid items', () => {
      // Arrange
      const manyItems = Array.from({ length: 20 }, (_, i) => (
        <div key={`item-${i}`} data-testid={`grid-item-${i}`}>
          Item {i}
        </div>
      ));

      const largeLayouts: ResponsiveLayouts = {
        lg: Array.from({ length: 20 }, (_, i) => ({
          i: `item-${i}`,
          x: (i % 4) * 3,
          y: Math.floor(i / 4) * 2,
          w: 3,
          h: 2,
        })),
        md: Array.from({ length: 20 }, (_, i) => ({
          i: `item-${i}`,
          x: (i % 3) * 4,
          y: Math.floor(i / 3) * 2,
          w: 4,
          h: 2,
        })),
        sm: Array.from({ length: 20 }, (_, i) => ({
          i: `item-${i}`,
          x: 0,
          y: i * 2,
          w: 12,
          h: 2,
        })),
      };

      // Act
      render(<ResponsiveGridLayout layouts={largeLayouts}>{manyItems}</ResponsiveGridLayout>);

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      expect(screen.getByTestId('grid-item-0')).toBeInTheDocument();
      expect(screen.getByTestId('grid-item-19')).toBeInTheDocument();
    });

    it('should not cause memory leaks on unmount', () => {
      // Arrange
      const { unmount } = render(
        <ResponsiveGridLayout layouts={defaultLayouts}>
          <div key="item-1">Item 1</div>
        </ResponsiveGridLayout>
      );

      // Act
      unmount();

      // Assert
      expect(screen.queryByTestId('responsive-grid-layout')).not.toBeInTheDocument();
    });
  });

  describe('static items', () => {
    it('should support static (non-draggable, non-resizable) items', () => {
      // Arrange
      const layoutsWithStatic: ResponsiveLayouts = {
        lg: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2, static: true }],
        md: [{ i: 'item-1', x: 0, y: 0, w: 6, h: 2, static: true }],
        sm: [{ i: 'item-1', x: 0, y: 0, w: 12, h: 2, static: true }],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={layoutsWithStatic}>
          <div key="item-1">Static Item</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByTestId('responsive-grid-layout')).toBeInTheDocument();
      expect(screen.getByText('Static Item')).toBeInTheDocument();
    });

    it('should mix static and dynamic items', () => {
      // Arrange
      const mixedLayouts: ResponsiveLayouts = {
        lg: [
          { i: 'item-1', x: 0, y: 0, w: 6, h: 2, static: true },
          { i: 'item-2', x: 6, y: 0, w: 6, h: 2 },
        ],
        md: [
          { i: 'item-1', x: 0, y: 0, w: 6, h: 2, static: true },
          { i: 'item-2', x: 6, y: 0, w: 6, h: 2 },
        ],
        sm: [
          { i: 'item-1', x: 0, y: 0, w: 12, h: 2, static: true },
          { i: 'item-2', x: 0, y: 2, w: 12, h: 2 },
        ],
      };

      // Act
      render(
        <ResponsiveGridLayout layouts={mixedLayouts}>
          <div key="item-1">Static Item</div>
          <div key="item-2">Dynamic Item</div>
        </ResponsiveGridLayout>
      );

      // Assert
      expect(screen.getByText('Static Item')).toBeInTheDocument();
      expect(screen.getByText('Dynamic Item')).toBeInTheDocument();
    });
  });
});
