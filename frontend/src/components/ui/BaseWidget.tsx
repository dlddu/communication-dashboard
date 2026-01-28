import type { ReactNode } from 'react';
import { Card } from './Card';
import { Button } from './Button';

export interface BaseWidgetProps {
  title: string;
  children?: ReactNode;
  onRefresh?: () => void | Promise<void>;
  onSettings?: () => void;
  isLoading?: boolean;
  error?: Error | string | null;
  isEmpty?: boolean;
  emptyMessage?: string;
  className?: string;
}

export function BaseWidget({
  title,
  children,
  onRefresh,
  onSettings,
  isLoading = false,
  error,
  isEmpty = false,
  emptyMessage = 'No data available',
  className = '',
}: BaseWidgetProps) {
  // Determine which content to show based on state priority
  const hasError = error && (typeof error === 'string' ? error.trim() !== '' : error.message.trim() !== '');
  const shouldShowLoading = !hasError && isLoading;
  const shouldShowEmpty = !hasError && !isLoading && isEmpty;
  const shouldShowContent = !hasError && !isLoading && !isEmpty;

  // Extract error message
  const errorMessage = error instanceof Error ? error.message : error;

  // Buttons should be disabled only during loading
  const buttonsDisabled = isLoading;

  return (
    <Card className={className}>
      <div>
        {/* Header with drag handle */}
        <div className="widget-header drag-handle" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '1rem' }}>
          <h2 style={{ margin: 0 }}>{title}</h2>

          <div style={{ display: 'flex', gap: '0.5rem' }}>
            {onRefresh && (
              <Button
                onClick={onRefresh}
                disabled={buttonsDisabled}
                aria-label="Refresh widget"
                className="no-drag"
                variant="secondary"
              >
                Refresh
              </Button>
            )}
            {onSettings && (
              <Button
                onClick={onSettings}
                disabled={buttonsDisabled}
                aria-label="Widget settings"
                className="no-drag"
                variant="secondary"
              >
                Settings
              </Button>
            )}
          </div>
        </div>

        {/* Content area */}
        <div style={{ padding: '0 1rem 1rem 1rem' }}>
          {/* Error state */}
          {hasError && (
            <div
              role="alert"
              aria-live="assertive"
              style={{ color: 'red', padding: '1rem', backgroundColor: '#fee', borderRadius: '4px' }}
            >
              {errorMessage}
            </div>
          )}

          {/* Loading state */}
          {shouldShowLoading && (
            <div
              role="status"
              aria-live="polite"
              style={{ padding: '1rem', textAlign: 'center' }}
            >
              Loading...
            </div>
          )}

          {/* Empty state */}
          {shouldShowEmpty && (
            <div
              role="alert"
              style={{ padding: '1rem', textAlign: 'center', color: '#666' }}
            >
              {emptyMessage}
            </div>
          )}

          {/* Content */}
          {shouldShowContent && children}
        </div>
      </div>
    </Card>
  );
}
