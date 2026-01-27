import { useState, useEffect, useCallback } from 'react';
import { pluginService } from '@/services/api';
import type { PluginDataItem } from '@/types/plugin';

interface UseSlackMessagesResult {
  messages: PluginDataItem[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
}

export function useSlackMessages(limit?: number): UseSlackMessagesResult {
  const [messages, setMessages] = useState<PluginDataItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Handle negative limit by using default value
  const effectiveLimit = limit !== undefined && limit < 0 ? 50 : limit ?? 50;

  const fetchMessages = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await pluginService.getPluginData('slack', effectiveLimit);
      setMessages(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch Slack messages';
      setError(errorMessage);
      setMessages([]);
    } finally {
      setLoading(false);
    }
  }, [effectiveLimit]);

  useEffect(() => {
    fetchMessages();
  }, [fetchMessages]);

  return {
    messages,
    loading,
    error,
    refresh: fetchMessages,
  };
}
