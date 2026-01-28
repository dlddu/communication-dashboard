import axios, { AxiosError } from 'axios';
import { API_BASE_URL } from '@/config/api';
import type { PluginInfo, PluginDataItem, RefreshResult, ApiError } from '@/types/plugin';
import type { ResponsiveLayouts } from '@/types/layout';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiError>) => {
    if (error.response?.data?.detail) {
      return Promise.reject(new Error(error.response.data.detail));
    }
    return Promise.reject(error);
  }
);

export const pluginService = {
  async getPlugins(): Promise<PluginInfo[]> {
    const response = await apiClient.get<PluginInfo[]>('/plugins');
    return response.data;
  },

  async getPluginData(name: string, limit = 50): Promise<PluginDataItem[]> {
    const response = await apiClient.get<PluginDataItem[]>(`/plugins/${name}/data`, {
      params: { limit },
    });
    return response.data;
  },

  async refreshPlugin(name: string): Promise<RefreshResult> {
    const response = await apiClient.post<RefreshResult>(`/plugins/${name}/refresh`);
    return response.data;
  },
};

export const layoutService = {
  async loadLayout(userId: string): Promise<ResponsiveLayouts> {
    const response = await apiClient.get<ResponsiveLayouts>(`/api/layouts`, {
      params: { user_id: userId },
    });
    return response.data;
  },

  async saveLayout(
    userId: string,
    layouts: ResponsiveLayouts | { layouts: ResponsiveLayouts; timestamp: number }
  ): Promise<{ success: boolean }> {
    const response = await apiClient.post<{ success: boolean }>(`/api/layouts`, {
      user_id: userId,
      ...(('layouts' in layouts) ? layouts : { layouts, timestamp: Date.now() }),
    });
    return response.data;
  },
};

export default apiClient;
