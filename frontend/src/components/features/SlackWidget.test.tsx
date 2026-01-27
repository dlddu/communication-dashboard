import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SlackWidget } from './SlackWidget';
import { useSlackMessages } from '@/hooks/useSlackMessages';
import type { PluginDataItem } from '@/types/plugin';

// Mock the useSlackMessages hook
vi.mock('@/hooks/useSlackMessages');

describe('SlackWidget', () => {
  const mockMessages: PluginDataItem[] = [
    {
      id: '1',
      source: 'slack',
      title: '#general',
      content: 'Hello team! This is a test message.',
      timestamp: '2026-01-27T10:00:00Z',
      metadata: {
        channel: 'general',
        sender: 'John Doe',
      },
      read: false,
    },
    {
      id: '2',
      source: 'slack',
      title: '#dev',
      content: 'Code review needed for PR #123',
      timestamp: '2026-01-27T09:30:00Z',
      metadata: {
        channel: 'dev',
        sender: 'Jane Smith',
      },
      read: true,
    },
    {
      id: '3',
      source: 'slack',
      title: '#random',
      content: 'Anyone up for lunch?',
      timestamp: '2026-01-27T08:15:00Z',
      metadata: {
        channel: 'random',
        sender: 'Bob Wilson',
      },
      read: false,
    },
  ];

  const mockRefresh = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('rendering', () => {
    it('should render SlackWidget with title', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText('Slack Messages')).toBeInTheDocument();
    });

    it('should render refresh button', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByRole('button', { name: /refresh/i })).toBeInTheDocument();
    });
  });

  describe('message list rendering', () => {
    it('should display all messages when loaded', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText('#general')).toBeInTheDocument();
      expect(screen.getByText('#dev')).toBeInTheDocument();
      expect(screen.getByText('#random')).toBeInTheDocument();
    });

    it('should display message sender for each message', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText('John Doe')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('Bob Wilson')).toBeInTheDocument();
    });

    it('should display message preview for each message', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText(/Hello team! This is a test message./)).toBeInTheDocument();
      expect(screen.getByText(/Code review needed for PR #123/)).toBeInTheDocument();
      expect(screen.getByText(/Anyone up for lunch?/)).toBeInTheDocument();
    });

    it('should display formatted timestamp for each message', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      // Timestamps should be formatted as locale strings
      const timestamps = screen.getAllByTestId('message-timestamp');
      expect(timestamps).toHaveLength(3);
      timestamps.forEach((timestamp) => {
        expect(timestamp).toBeInTheDocument();
        expect(timestamp.textContent).not.toBe('');
      });
    });

    it('should display messages in reverse chronological order', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      const channels = screen.getAllByTestId('message-channel');
      expect(channels[0]).toHaveTextContent('#general'); // Most recent
      expect(channels[1]).toHaveTextContent('#dev');
      expect(channels[2]).toHaveTextContent('#random'); // Oldest
    });

    it('should truncate long message content', () => {
      // Arrange
      const longMessage: PluginDataItem = {
        id: '4',
        source: 'slack',
        title: '#long',
        content: 'A'.repeat(200), // 200 characters
        timestamp: '2026-01-27T10:00:00Z',
        metadata: {
          channel: 'long',
          sender: 'Test User',
        },
        read: false,
      };

      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [longMessage],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      const content = screen.getByTestId('message-content');
      expect(content.textContent?.length).toBeLessThanOrEqual(150); // Truncated at 150 chars
      expect(content.textContent).toMatch(/\.\.\.$/); // Ends with ellipsis
    });

    it('should display empty state when no messages', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText(/no slack messages/i)).toBeInTheDocument();
    });
  });

  describe('loading state', () => {
    it('should display loading indicator when loading', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: true,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText(/loading/i)).toBeInTheDocument();
      expect(screen.queryByText(/no slack messages/i)).not.toBeInTheDocument();
    });

    it('should not display messages while loading', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: true,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText(/loading/i)).toBeInTheDocument();
      expect(screen.queryByText('#general')).not.toBeInTheDocument();
    });

    it('should disable refresh button while loading', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: true,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      expect(refreshButton).toBeDisabled();
    });
  });

  describe('error state', () => {
    it('should display error message when error occurs', () => {
      // Arrange
      const errorMessage = 'Failed to fetch Slack messages';
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: false,
        error: errorMessage,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText(errorMessage)).toBeInTheDocument();
      expect(screen.queryByText(/no slack messages/i)).not.toBeInTheDocument();
    });

    it('should not display messages when error occurs', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: 'API Error',
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText('API Error')).toBeInTheDocument();
      expect(screen.queryByText('#general')).not.toBeInTheDocument();
    });

    it('should enable refresh button when error occurs', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: false,
        error: 'API Error',
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      expect(refreshButton).not.toBeDisabled();
    });
  });

  describe('refresh functionality', () => {
    it('should call refresh when refresh button is clicked', async () => {
      // Arrange
      const user = userEvent.setup();
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      render(<SlackWidget />);

      // Act
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      await user.click(refreshButton);

      // Assert
      expect(mockRefresh).toHaveBeenCalledTimes(1);
    });

    it('should not call refresh when button is disabled', async () => {
      // Arrange
      const user = userEvent.setup();
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [],
        loading: true,
        error: null,
        refresh: mockRefresh,
      });

      render(<SlackWidget />);

      // Act
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      await user.click(refreshButton);

      // Assert
      expect(mockRefresh).not.toHaveBeenCalled();
    });

    it('should show loading state immediately after refresh click', async () => {
      // Arrange
      const user = userEvent.setup();
      let loading = false;

      vi.mocked(useSlackMessages).mockImplementation(() => ({
        messages: mockMessages,
        loading,
        error: null,
        refresh: async () => {
          loading = true;
        },
      }));

      const { rerender } = render(<SlackWidget />);

      // Act
      const refreshButton = screen.getByRole('button', { name: /refresh/i });
      await user.click(refreshButton);

      // Simulate hook re-render with loading state
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: true,
        error: null,
        refresh: mockRefresh,
      });
      rerender(<SlackWidget />);

      // Assert
      expect(screen.getByText(/loading/i)).toBeInTheDocument();
    });
  });

  describe('accessibility', () => {
    it('should have proper ARIA labels', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByRole('button', { name: /refresh/i })).toHaveAttribute('aria-label');
    });

    it('should have proper semantic structure', () => {
      // Arrange
      vi.mocked(useSlackMessages).mockReturnValue({
        messages: mockMessages,
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByRole('list')).toBeInTheDocument();
      const listItems = screen.getAllByRole('listitem');
      expect(listItems).toHaveLength(mockMessages.length);
    });
  });

  describe('edge cases', () => {
    it('should handle missing metadata gracefully', () => {
      // Arrange
      const messageWithoutMetadata: PluginDataItem = {
        id: '5',
        source: 'slack',
        title: '#unknown',
        content: 'Message without metadata',
        timestamp: '2026-01-27T10:00:00Z',
        metadata: {},
        read: false,
      };

      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [messageWithoutMetadata],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText('Unknown')).toBeInTheDocument(); // Default sender
      expect(screen.getByText('#unknown')).toBeInTheDocument(); // Uses title as fallback
    });

    it('should handle invalid timestamp gracefully', () => {
      // Arrange
      const messageWithInvalidTimestamp: PluginDataItem = {
        id: '6',
        source: 'slack',
        title: '#test',
        content: 'Test message',
        timestamp: 'invalid-date',
        metadata: {
          channel: 'test',
          sender: 'Test User',
        },
        read: false,
      };

      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [messageWithInvalidTimestamp],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      const timestamp = screen.getByTestId('message-timestamp');
      expect(timestamp).toHaveTextContent('invalid-date'); // Fallback to original string
    });

    it('should handle empty content gracefully', () => {
      // Arrange
      const messageWithEmptyContent: PluginDataItem = {
        id: '7',
        source: 'slack',
        title: '#empty',
        content: '',
        timestamp: '2026-01-27T10:00:00Z',
        metadata: {
          channel: 'empty',
          sender: 'Test User',
        },
        read: false,
      };

      vi.mocked(useSlackMessages).mockReturnValue({
        messages: [messageWithEmptyContent],
        loading: false,
        error: null,
        refresh: mockRefresh,
      });

      // Act
      render(<SlackWidget />);

      // Assert
      expect(screen.getByText('No content')).toBeInTheDocument(); // Default message
    });
  });
});
