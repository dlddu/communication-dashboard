import { useState, useEffect, useCallback } from 'react';
import { pluginService } from '@/services/api';
import type { PluginInfo } from '@/types/plugin';

interface UsePluginsResult {
  plugins: PluginInfo[];
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function usePlugins(): UsePluginsResult {
  const [plugins, setPlugins] = useState<PluginInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPlugins = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await pluginService.getPlugins();
      setPlugins(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch plugins';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPlugins();
  }, [fetchPlugins]);

  return {
    plugins,
    loading,
    error,
    refetch: fetchPlugins,
  };
}
