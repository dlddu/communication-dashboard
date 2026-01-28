/**
 * Layout types for react-grid-layout integration
 */

/**
 * Represents a single grid item's layout configuration
 */
export interface LayoutItem {
  /** Unique identifier for the grid item (must match the key prop of the child component) */
  i: string;
  /** X position in grid units (column index) */
  x: number;
  /** Y position in grid units (row index) */
  y: number;
  /** Width in grid units */
  w: number;
  /** Height in grid units */
  h: number;
  /** Minimum width in grid units */
  minW?: number;
  /** Minimum height in grid units */
  minH?: number;
  /** Maximum width in grid units */
  maxW?: number;
  /** Maximum height in grid units */
  maxH?: number;
  /** Whether the item is static (cannot be dragged or resized) */
  static?: boolean;
  /** Whether the item can be dragged */
  isDraggable?: boolean;
  /** Whether the item can be resized */
  isResizable?: boolean;
}

/**
 * Responsive layouts for different breakpoints
 */
export interface ResponsiveLayouts {
  /** Layout for large screens (≥1200px) */
  lg: LayoutItem[];
  /** Layout for medium screens (≥996px) */
  md: LayoutItem[];
  /** Layout for small screens (≥768px) */
  sm: LayoutItem[];
  /** Index signature for react-grid-layout compatibility */
  [key: string]: LayoutItem[];
}

/**
 * Breakpoint configuration for responsive grid
 */
export interface Breakpoints {
  lg: number;
  md: number;
  sm: number;
  /** Index signature for react-grid-layout compatibility */
  [key: string]: number;
}

/**
 * Column configuration for each breakpoint
 */
export interface Cols {
  lg: number;
  md: number;
  sm: number;
  /** Index signature for react-grid-layout compatibility */
  [key: string]: number;
}

/**
 * Props for ResponsiveGridLayout component
 */
export interface ResponsiveGridLayoutProps {
  /** Layout configurations for all breakpoints */
  layouts: ResponsiveLayouts;
  /** Grid items as React children */
  children?: React.ReactNode;
  /** Callback fired when layout changes */
  onLayoutChange?: (currentLayout: LayoutItem[], allLayouts: ResponsiveLayouts) => void;
  /** Callback fired when breakpoint changes */
  onBreakpointChange?: (newBreakpoint: string, newCols: number) => void;
  /** Whether items can be dragged */
  isDraggable?: boolean;
  /** Whether items can be resized */
  isResizable?: boolean;
  /** CSS selector for drag handle */
  draggableHandle?: string;
  /** CSS selector for elements that should not trigger drag */
  draggableCancel?: string;
  /** Height of a single row in pixels */
  rowHeight?: number;
  /** Padding inside the container [horizontal, vertical] */
  containerPadding?: [number, number];
  /** Margin between grid items [horizontal, vertical] */
  margin?: [number, number];
  /** Compact type for layout algorithm */
  compactType?: 'vertical' | 'horizontal' | null;
  /** Whether to prevent item collision */
  preventCollision?: boolean;
  /** Breakpoint configuration (default: { lg: 1200, md: 996, sm: 768 }) */
  breakpoints?: Breakpoints;
  /** Column configuration (default: { lg: 12, md: 12, sm: 12 }) */
  cols?: Cols;
  /** CSS class name for the grid container */
  className?: string;
}
