import { Responsive, WidthProvider } from 'react-grid-layout';
import type { ResponsiveGridLayoutProps } from '@/types/layout';
import 'react-grid-layout/css/styles.css';
import 'react-resizable/css/styles.css';

const ResponsiveGridLayoutBase = WidthProvider(Responsive);

/**
 * ResponsiveGridLayout component
 * A responsive, draggable and resizable grid layout component based on react-grid-layout
 */
export function ResponsiveGridLayout({
  layouts,
  children,
  onLayoutChange,
  onBreakpointChange,
  isDraggable = true,
  isResizable = true,
  draggableHandle,
  draggableCancel,
  rowHeight = 100,
  containerPadding,
  margin,
  compactType = 'vertical',
  preventCollision = false,
  breakpoints = { lg: 1200, md: 996, sm: 768 },
  cols = { lg: 12, md: 12, sm: 12 },
  className = '',
}: ResponsiveGridLayoutProps) {
  return (
    <ResponsiveGridLayoutBase
      className={className}
      layouts={layouts}
      breakpoints={breakpoints}
      cols={cols}
      rowHeight={rowHeight}
      isDraggable={isDraggable}
      isResizable={isResizable}
      draggableHandle={draggableHandle}
      draggableCancel={draggableCancel}
      containerPadding={containerPadding}
      margin={margin}
      compactType={compactType}
      preventCollision={preventCollision}
      onLayoutChange={onLayoutChange}
      onBreakpointChange={onBreakpointChange}
    >
      {children}
    </ResponsiveGridLayoutBase>
  );
}
