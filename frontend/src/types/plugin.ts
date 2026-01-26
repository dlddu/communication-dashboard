export interface PluginInfo {
  name: string;
  count: number;
  last_updated: string | null;
}

export interface PluginDataItem {
  id: string;
  source: string;
  title: string;
  content: string;
  timestamp: string;
  metadata: Record<string, unknown>;
  read: boolean;
}

export interface RefreshResult {
  success: boolean;
  message: string;
  data_count: number | null;
}

export interface ApiError {
  detail: string;
}
