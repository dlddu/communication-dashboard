import { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { pluginService } from '@/services/api';
import type { PluginInfo } from '@/types/plugin';

interface PluginCardProps {
  plugin: PluginInfo;
  onRefresh?: () => void;
}

export function PluginCard({ plugin, onRefresh }: PluginCardProps) {
  const [refreshing, setRefreshing] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const handleRefresh = async () => {
    try {
      setRefreshing(true);
      setMessage(null);
      const result = await pluginService.refreshPlugin(plugin.name);
      setMessage(result.message);
      if (onRefresh) {
        onRefresh();
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Refresh failed';
      setMessage(errorMessage);
    } finally {
      setRefreshing(false);
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'Never';
    try {
      return new Date(dateString).toLocaleString();
    } catch {
      return dateString;
    }
  };

  return (
    <Card className="plugin-card">
      <div className="plugin-card-header">
        <h3 className="plugin-name">{plugin.name}</h3>
        <span className="plugin-count">{plugin.count} items</span>
      </div>

      <div className="plugin-card-body">
        <p className="plugin-updated">
          Last updated: {formatDate(plugin.last_updated)}
        </p>

        {message && (
          <p className={`plugin-message ${message.includes('fail') ? 'error' : 'success'}`}>
            {message}
          </p>
        )}
      </div>

      <div className="plugin-card-footer">
        <Button
          variant="primary"
          onClick={handleRefresh}
          loading={refreshing}
          disabled={refreshing}
        >
          Refresh
        </Button>
      </div>
    </Card>
  );
}
