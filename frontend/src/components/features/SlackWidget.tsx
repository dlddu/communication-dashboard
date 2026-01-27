import { useSlackMessages } from '@/hooks/useSlackMessages';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import type { PluginDataItem } from '@/types/plugin';

export function SlackWidget() {
  const { messages, loading, error, refresh } = useSlackMessages();

  const formatTimestamp = (timestamp: string): string => {
    try {
      const date = new Date(timestamp);
      if (isNaN(date.getTime())) {
        return timestamp;
      }
      return date.toLocaleString();
    } catch {
      return timestamp;
    }
  };

  const truncateContent = (content: string): string => {
    if (content.length <= 150) {
      return content;
    }
    return content.substring(0, 150) + '...';
  };

  const getSender = (message: PluginDataItem): string => {
    return (message.metadata?.sender as string) || 'Unknown';
  };

  const getChannel = (message: PluginDataItem): string => {
    return message.title;
  };

  const getContent = (message: PluginDataItem): string => {
    if (!message.content || message.content.trim() === '') {
      return 'No content';
    }
    return truncateContent(message.content);
  };

  return (
    <Card>
      <div style={{ padding: '1rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <h2>Slack Messages</h2>
          <Button
            onClick={refresh}
            disabled={loading}
            aria-label="Refresh Slack messages"
          >
            Refresh
          </Button>
        </div>

        {loading && <div>Loading...</div>}

        {!loading && error && <div>{error}</div>}

        {!loading && !error && messages.length === 0 && (
          <div>No Slack messages</div>
        )}

        {!loading && !error && messages.length > 0 && (
          <ul role="list" style={{ listStyle: 'none', padding: 0, margin: 0 }}>
            {messages.map((message) => (
              <li key={message.id} role="listitem" style={{ marginBottom: '1rem', paddingBottom: '1rem', borderBottom: '1px solid #eee' }}>
                <div data-testid="message-channel" style={{ fontWeight: 'bold' }}>
                  {getChannel(message)}
                </div>
                <div style={{ fontSize: '0.9rem', color: '#666', marginTop: '0.25rem' }}>
                  {getSender(message)}
                </div>
                <div data-testid="message-content" style={{ marginTop: '0.5rem' }}>
                  {getContent(message)}
                </div>
                <div data-testid="message-timestamp" style={{ fontSize: '0.8rem', color: '#999', marginTop: '0.25rem' }}>
                  {formatTimestamp(message.timestamp)}
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </Card>
  );
}
