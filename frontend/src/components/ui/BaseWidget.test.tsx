import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BaseWidget } from './BaseWidget';

describe('BaseWidget', () => {
  const mockOnRefresh = vi.fn();
  const mockOnSettings = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rendering', () => {
    it('should render BaseWidget with title', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" />);

      // Assert
      expect(screen.getByText('Test Widget')).toBeInTheDocument();
    });

    it('should render with custom className', () => {
      // Arrange & Act
      const { container } = render(
        <BaseWidget title="Test Widget" className="custom-class" />
      );

      // Assert
      expect(container.firstChild).toHaveClass('custom-class');
    });

    it('should render children content', () => {
      // Arrange & Act
      render(
        <BaseWidget title="Test Widget">
          <div data-testid="child-content">Child Content</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByTestId('child-content')).toBeInTheDocument();
      expect(screen.getByText('Child Content')).toBeInTheDocument();
    });

    it('should render multiple children', () => {
      // Arrange & Act
      render(
        <BaseWidget title="Test Widget">
          <div data-testid="child-1">Child 1</div>
          <div data-testid="child-2">Child 2</div>
          <div data-testid="child-3">Child 3</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByTestId('child-1')).toBeInTheDocument();
      expect(screen.getByTestId('child-2')).toBeInTheDocument();
      expect(screen.getByTestId('child-3')).toBeInTheDocument();
    });
  });

  describe('header section', () => {
    it('should have draggable handle className for drag-and-drop', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" />);

      // Assert
      const header = screen.getByText('Test Widget').closest('[class*="drag-handle"]');
      expect(header).toBeInTheDocument();
    });

    it('should render refresh button in header', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" onRefresh={mockOnRefresh} />);

      // Assert
      expect(screen.getByRole('button', { name: /refresh/i })).toBeInTheDocument();
    });

    it('should render settings button when onSettings is provided', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" onSettings={mockOnSettings} />);

      // Assert
      expect(screen.getByRole('button', { name: /settings/i })).toBeInTheDocument();
    });

    it('should not render settings button when onSettings is not provided', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" />);

      // Assert
      expect(screen.queryByRole('button', { name: /settings/i })).not.toBeInTheDocument();
    });

    it('should render both refresh and settings buttons together', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          onRefresh={mockOnRefresh}
          onSettings={mockOnSettings}
        />
      );

      // Assert
      expect(screen.getByRole('button', { name: /refresh/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /settings/i })).toBeInTheDocument();
    });
  });

  describe('Widget Component - Linear Test Cases', () => {
    describe('displays plugin data correctly', () => {
      it('should display plugin data as children', () => {
        // Arrange & Act
        render(
          <BaseWidget title="Slack Messages">
            <div data-testid="plugin-data">
              <div>Message 1</div>
              <div>Message 2</div>
              <div>Message 3</div>
            </div>
          </BaseWidget>
        );

        // Assert
        expect(screen.getByTestId('plugin-data')).toBeInTheDocument();
        expect(screen.getByText('Message 1')).toBeInTheDocument();
        expect(screen.getByText('Message 2')).toBeInTheDocument();
        expect(screen.getByText('Message 3')).toBeInTheDocument();
      });

      it('should display complex plugin data structures', () => {
        // Arrange & Act
        render(
          <BaseWidget title="Email Widget">
            <ul data-testid="email-list">
              <li>
                <strong>Subject:</strong> Important Email
              </li>
              <li>
                <strong>From:</strong> john@example.com
              </li>
            </ul>
          </BaseWidget>
        );

        // Assert
        expect(screen.getByTestId('email-list')).toBeInTheDocument();
        expect(screen.getByText('Important Email')).toBeInTheDocument();
        expect(screen.getByText('john@example.com')).toBeInTheDocument();
      });
    });

    describe('shows loading state during refresh', () => {
      it('should display loading indicator when isLoading is true', () => {
        // Arrange & Act
        render(
          <BaseWidget title="Test Widget" isLoading={true}>
            <div>Content</div>
          </BaseWidget>
        );

        // Assert
        expect(screen.getByText(/loading/i)).toBeInTheDocument();
      });

      it('should not display children while loading', () => {
        // Arrange & Act
        render(
          <BaseWidget title="Test Widget" isLoading={true}>
            <div data-testid="child-content">Content</div>
          </BaseWidget>
        );

        // Assert
        expect(screen.getByText(/loading/i)).toBeInTheDocument();
        expect(screen.queryByTestId('child-content')).not.toBeInTheDocument();
      });

      it('should disable refresh button while loading', () => {
        // Arrange & Act
        render(
          <BaseWidget
            title="Test Widget"
            isLoading={true}
            onRefresh={mockOnRefresh}
          />
        );

        // Assert
        const refreshButton = screen.getByRole('button', { name: /refresh/i });
        expect(refreshButton).toBeDisabled();
      });

      it('should disable settings button while loading', () => {
        // Arrange & Act
        render(
          <BaseWidget
            title="Test Widget"
            isLoading={true}
            onSettings={mockOnSettings}
          />
        );

        // Assert
        const settingsButton = screen.getByRole('button', { name: /settings/i });
        expect(settingsButton).toBeDisabled();
      });

      it('should show loading state without hiding title', () => {
        // Arrange & Act
        render(<BaseWidget title="Test Widget" isLoading={true} />);

        // Assert
        expect(screen.getByText('Test Widget')).toBeInTheDocument();
        expect(screen.getByText(/loading/i)).toBeInTheDocument();
      });
    });

    describe('calls onRefresh when button clicked', () => {
      it('should call onRefresh when refresh button is clicked', async () => {
        // Arrange
        const user = userEvent.setup();
        render(<BaseWidget title="Test Widget" onRefresh={mockOnRefresh} />);

        // Act
        const refreshButton = screen.getByRole('button', { name: /refresh/i });
        await user.click(refreshButton);

        // Assert
        expect(mockOnRefresh).toHaveBeenCalledTimes(1);
      });

      it('should not call onRefresh when button is disabled', async () => {
        // Arrange
        const user = userEvent.setup();
        render(
          <BaseWidget
            title="Test Widget"
            isLoading={true}
            onRefresh={mockOnRefresh}
          />
        );

        // Act
        const refreshButton = screen.getByRole('button', { name: /refresh/i });
        await user.click(refreshButton);

        // Assert
        expect(mockOnRefresh).not.toHaveBeenCalled();
      });

      it('should handle async onRefresh callback', async () => {
        // Arrange
        const asyncRefresh = vi.fn().mockResolvedValue(undefined);
        const user = userEvent.setup();
        render(<BaseWidget title="Test Widget" onRefresh={asyncRefresh} />);

        // Act
        const refreshButton = screen.getByRole('button', { name: /refresh/i });
        await user.click(refreshButton);

        // Assert
        expect(asyncRefresh).toHaveBeenCalledTimes(1);
      });

      it('should allow multiple refresh clicks when not disabled', async () => {
        // Arrange
        const user = userEvent.setup();
        render(<BaseWidget title="Test Widget" onRefresh={mockOnRefresh} />);

        // Act
        const refreshButton = screen.getByRole('button', { name: /refresh/i });
        await user.click(refreshButton);
        await user.click(refreshButton);
        await user.click(refreshButton);

        // Assert
        expect(mockOnRefresh).toHaveBeenCalledTimes(3);
      });
    });

    describe('handles empty data gracefully', () => {
      it('should display empty message when isEmpty is true', () => {
        // Arrange & Act
        render(<BaseWidget title="Test Widget" isEmpty={true} />);

        // Assert
        expect(screen.getByText(/no data/i)).toBeInTheDocument();
      });

      it('should display custom empty message', () => {
        // Arrange & Act
        render(
          <BaseWidget
            title="Test Widget"
            isEmpty={true}
            emptyMessage="No items available"
          />
        );

        // Assert
        expect(screen.getByText('No items available')).toBeInTheDocument();
      });

      it('should not display children when isEmpty is true', () => {
        // Arrange & Act
        render(
          <BaseWidget title="Test Widget" isEmpty={true}>
            <div data-testid="child-content">Content</div>
          </BaseWidget>
        );

        // Assert
        expect(screen.getByText(/no data/i)).toBeInTheDocument();
        expect(screen.queryByTestId('child-content')).not.toBeInTheDocument();
      });

      it('should prefer empty message over loading state', () => {
        // Arrange & Act
        render(
          <BaseWidget
            title="Test Widget"
            isEmpty={true}
            isLoading={false}
            emptyMessage="No data to show"
          />
        );

        // Assert
        expect(screen.getByText('No data to show')).toBeInTheDocument();
        expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
      });

      it('should enable refresh button in empty state', () => {
        // Arrange & Act
        render(
          <BaseWidget
            title="Test Widget"
            isEmpty={true}
            onRefresh={mockOnRefresh}
          />
        );

        // Assert
        const refreshButton = screen.getByRole('button', { name: /refresh/i });
        expect(refreshButton).not.toBeDisabled();
      });
    });
  });

  describe('error state', () => {
    it('should display error message when error is string', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" error="Failed to load data" />);

      // Assert
      expect(screen.getByText(/failed to load data/i)).toBeInTheDocument();
    });

    it('should display error message when error is Error object', () => {
      // Arrange
      const error = new Error('Network error occurred');

      // Act
      render(<BaseWidget title="Test Widget" error={error} />);

      // Assert
      expect(screen.getByText(/network error occurred/i)).toBeInTheDocument();
    });

    it('should not display children when error exists', () => {
      // Arrange & Act
      render(
        <BaseWidget title="Test Widget" error="Error occurred">
          <div data-testid="child-content">Content</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByText(/error occurred/i)).toBeInTheDocument();
      expect(screen.queryByTestId('child-content')).not.toBeInTheDocument();
    });

    it('should enable refresh button when error exists', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          error="API Error"
          onRefresh={mockOnRefresh}
        />
      );

      // Assert
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      expect(refreshButton).not.toBeDisabled();
    });

    it('should prioritize error over loading state', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          error="Critical error"
          isLoading={true}
        />
      );

      // Assert
      expect(screen.getByText(/critical error/i)).toBeInTheDocument();
      expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
    });

    it('should prioritize error over empty state', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          error="Error occurred"
          isEmpty={true}
          emptyMessage="No data"
        />
      );

      // Assert
      expect(screen.getByText(/error occurred/i)).toBeInTheDocument();
      expect(screen.queryByText('No data')).not.toBeInTheDocument();
    });
  });

  describe('settings functionality', () => {
    it('should call onSettings when settings button is clicked', async () => {
      // Arrange
      const user = userEvent.setup();
      render(<BaseWidget title="Test Widget" onSettings={mockOnSettings} />);

      // Act
      const settingsButton = screen.getByRole('button', { name: /settings/i });
      await user.click(settingsButton);

      // Assert
      expect(mockOnSettings).toHaveBeenCalledTimes(1);
    });

    it('should not call onSettings when button is disabled', async () => {
      // Arrange
      const user = userEvent.setup();
      render(
        <BaseWidget
          title="Test Widget"
          isLoading={true}
          onSettings={mockOnSettings}
        />
      );

      // Act
      const settingsButton = screen.getByRole('button', { name: /settings/i });
      await user.click(settingsButton);

      // Assert
      expect(mockOnSettings).not.toHaveBeenCalled();
    });

    it('should allow multiple settings button clicks', async () => {
      // Arrange
      const user = userEvent.setup();
      render(<BaseWidget title="Test Widget" onSettings={mockOnSettings} />);

      // Act
      const settingsButton = screen.getByRole('button', { name: /settings/i });
      await user.click(settingsButton);
      await user.click(settingsButton);

      // Assert
      expect(mockOnSettings).toHaveBeenCalledTimes(2);
    });

    it('should enable settings button in error state', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          error="Error"
          onSettings={mockOnSettings}
        />
      );

      // Assert
      const settingsButton = screen.getByRole('button', { name: /settings/i });
      expect(settingsButton).not.toBeDisabled();
    });
  });

  describe('accessibility', () => {
    it('should have proper ARIA label for refresh button', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" onRefresh={mockOnRefresh} />);

      // Assert
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      expect(refreshButton).toHaveAttribute('aria-label');
    });

    it('should have proper ARIA label for settings button', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" onSettings={mockOnSettings} />);

      // Assert
      const settingsButton = screen.getByRole('button', { name: /settings/i });
      expect(settingsButton).toHaveAttribute('aria-label');
    });

    it('should indicate loading state to screen readers', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" isLoading={true} />);

      // Assert
      const loadingElement = screen.getByText(/loading/i);
      expect(loadingElement).toHaveAttribute('role', 'status');
      expect(loadingElement).toHaveAttribute('aria-live', 'polite');
    });

    it('should indicate error state to screen readers', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" error="Error occurred" />);

      // Assert
      const errorElement = screen.getByText(/error occurred/i);
      expect(errorElement).toHaveAttribute('role', 'alert');
      expect(errorElement).toHaveAttribute('aria-live', 'assertive');
    });

    it('should have semantic header structure', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" />);

      // Assert
      const title = screen.getByText('Test Widget');
      expect(title.tagName).toBe('H2');
    });

    it('should be keyboard navigable for refresh button', async () => {
      // Arrange
      const user = userEvent.setup();
      render(<BaseWidget title="Test Widget" onRefresh={mockOnRefresh} />);

      // Act
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      refreshButton.focus();
      await user.keyboard('{Enter}');

      // Assert
      expect(mockOnRefresh).toHaveBeenCalledTimes(1);
    });

    it('should be keyboard navigable for settings button', async () => {
      // Arrange
      const user = userEvent.setup();
      render(<BaseWidget title="Test Widget" onSettings={mockOnSettings} />);

      // Act
      const settingsButton = screen.getByRole('button', { name: /settings/i });
      settingsButton.focus();
      await user.keyboard('{Enter}');

      // Assert
      expect(mockOnSettings).toHaveBeenCalledTimes(1);
    });
  });

  describe('state priorities', () => {
    it('should show error state over all other states', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          error="Critical error"
          isLoading={true}
          isEmpty={true}
        >
          <div data-testid="content">Content</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByText(/critical error/i)).toBeInTheDocument();
      expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/no data/i)).not.toBeInTheDocument();
      expect(screen.queryByTestId('content')).not.toBeInTheDocument();
    });

    it('should show loading state over empty and content', () => {
      // Arrange & Act
      render(
        <BaseWidget title="Test Widget" isLoading={true} isEmpty={true}>
          <div data-testid="content">Content</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByText(/loading/i)).toBeInTheDocument();
      expect(screen.queryByText(/no data/i)).not.toBeInTheDocument();
      expect(screen.queryByTestId('content')).not.toBeInTheDocument();
    });

    it('should show empty state over content when both present', () => {
      // Arrange & Act
      render(
        <BaseWidget title="Test Widget" isEmpty={true} emptyMessage="Empty!">
          <div data-testid="content">Content</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByText('Empty!')).toBeInTheDocument();
      expect(screen.queryByTestId('content')).not.toBeInTheDocument();
    });

    it('should show content when no states are active', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Test Widget"
          error={null}
          isLoading={false}
          isEmpty={false}
        >
          <div data-testid="content">Content</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByTestId('content')).toBeInTheDocument();
      expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/error/i)).not.toBeInTheDocument();
      expect(screen.queryByText(/no data/i)).not.toBeInTheDocument();
    });
  });

  describe('edge cases', () => {
    it('should handle empty title string', () => {
      // Arrange & Act
      render(<BaseWidget title="" />);

      // Assert
      const header = screen.getByRole('heading', { level: 2 });
      expect(header).toBeInTheDocument();
      expect(header.textContent).toBe('');
    });

    it('should handle very long title', () => {
      // Arrange
      const longTitle = 'A'.repeat(100);

      // Act
      render(<BaseWidget title={longTitle} />);

      // Assert
      expect(screen.getByText(longTitle)).toBeInTheDocument();
    });

    it('should handle special characters in title', () => {
      // Arrange
      const specialTitle = 'Widget <>&"\' Test';

      // Act
      render(<BaseWidget title={specialTitle} />);

      // Assert
      expect(screen.getByText(specialTitle)).toBeInTheDocument();
    });

    it('should handle null children gracefully', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget">{null}</BaseWidget>);

      // Assert
      expect(screen.getByText('Test Widget')).toBeInTheDocument();
    });

    it('should handle undefined children gracefully', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget">{undefined}</BaseWidget>);

      // Assert
      expect(screen.getByText('Test Widget')).toBeInTheDocument();
    });

    it('should handle empty string error gracefully', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" error="" />);

      // Assert
      expect(screen.queryByRole('alert')).not.toBeInTheDocument();
    });

    it('should handle Error object with empty message', () => {
      // Arrange
      const error = new Error('');

      // Act
      render(<BaseWidget title="Test Widget" error={error} />);

      // Assert
      // Should handle gracefully, potentially showing generic error message
      expect(screen.getByText('Test Widget')).toBeInTheDocument();
    });

    it('should handle both onRefresh and onSettings being undefined', () => {
      // Arrange & Act
      render(<BaseWidget title="Test Widget" />);

      // Assert
      expect(screen.queryByRole('button', { name: /refresh/i })).not.toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /settings/i })).not.toBeInTheDocument();
    });

    it('should handle rapid state changes', () => {
      // Arrange
      const { rerender } = render(
        <BaseWidget title="Test Widget" isLoading={true} />
      );

      // Act - Simulate rapid state changes
      rerender(<BaseWidget title="Test Widget" isLoading={false} isEmpty={true} />);
      rerender(
        <BaseWidget title="Test Widget" isLoading={false} isEmpty={false}>
          <div>Content</div>
        </BaseWidget>
      );
      rerender(<BaseWidget title="Test Widget" error="Error" />);

      // Assert
      expect(screen.getByText(/error/i)).toBeInTheDocument();
    });
  });

  describe('integration scenarios', () => {
    it('should work with SlackWidget use case', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Slack Messages"
          onRefresh={mockOnRefresh}
          isLoading={false}
        >
          <ul>
            <li>#general - New message</li>
            <li>#dev - Code review needed</li>
          </ul>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByText('Slack Messages')).toBeInTheDocument();
      expect(screen.getByText('#general - New message')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /refresh/i })).toBeInTheDocument();
    });

    it('should work with EmailWidget use case', () => {
      // Arrange & Act
      render(
        <BaseWidget
          title="Inbox"
          onRefresh={mockOnRefresh}
          onSettings={mockOnSettings}
          isLoading={false}
        >
          <div>3 unread emails</div>
        </BaseWidget>
      );

      // Assert
      expect(screen.getByText('Inbox')).toBeInTheDocument();
      expect(screen.getByText('3 unread emails')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /refresh/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /settings/i })).toBeInTheDocument();
    });

    it('should support widget in draggable grid layout', () => {
      // Arrange & Act
      render(
        <div className="grid-item">
          <BaseWidget title="Dashboard Widget">
            <div>Widget Content</div>
          </BaseWidget>
        </div>
      );

      // Assert
      const header = screen.getByText('Dashboard Widget').closest('[class*="drag-handle"]');
      expect(header).toBeInTheDocument();
    });
  });
});
