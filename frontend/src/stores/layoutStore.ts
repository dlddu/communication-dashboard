import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import axios from 'axios';
import type { ResponsiveLayouts, LayoutItem } from '../types/layout';

interface LayoutStore {
  layout: ResponsiveLayouts;
  isLoading: boolean;
  isSyncing: boolean;
  error: string | null;
  setLayout: (layout: ResponsiveLayouts) => void;
  syncToBackend: () => Promise<{ success: boolean; error?: string }>;
  loadFromBackend: () => Promise<{ success: boolean; error?: string }>;
  mergeWidget: (widget: LayoutItem) => void;
}

const defaultLayout: ResponsiveLayouts = {
  lg: [],
  md: [],
  sm: [],
};

export const useLayoutStore = create<LayoutStore>()(
  persist(
    (set, get) => ({
      layout: defaultLayout,
      isLoading: false,
      isSyncing: false,
      error: null,

      setLayout: (layout: ResponsiveLayouts) => {
        set({ layout });
      },

      syncToBackend: async () => {
        set({ isSyncing: true, error: null });
        try {
          const { layout } = get();
          await axios.post('/api/layouts', { layout });
          set({ isSyncing: false });
          return { success: true };
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          set({ isSyncing: false, error: errorMessage });
          return { success: false, error: errorMessage };
        }
      },

      loadFromBackend: async () => {
        set({ isLoading: true, error: null });
        try {
          const response = await axios.get('/api/layouts');
          const data = response.data;

          // Validate response has layout
          if (!data.layout || typeof data.layout !== 'object') {
            throw new Error('Invalid response from backend');
          }

          // Validate layout has required breakpoints
          if (!data.layout.lg || !data.layout.md || !data.layout.sm) {
            throw new Error('Invalid layout structure');
          }

          set({ layout: data.layout, isLoading: false });
          return { success: true };
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          // Don't overwrite the current layout on backend failure
          // This preserves localStorage data when backend is unavailable
          set({ isLoading: false, error: errorMessage });
          return { success: false, error: errorMessage };
        }
      },

      mergeWidget: (widget: LayoutItem) => {
        const { layout } = get();

        // Check if widget already exists in lg layout
        const existsInLg = layout.lg.some((item) => item.i === widget.i);
        if (existsInLg) {
          return; // Don't duplicate
        }

        // Add widget to lg layout
        const newLgLayout = [...layout.lg, widget];

        // Create proportional versions for md and sm
        const mdWidget: LayoutItem = {
          ...widget,
          w: Math.ceil(widget.w * 0.75), // Scale width for md
          x: Math.floor(widget.x * 0.75),
        };

        const smWidget: LayoutItem = {
          ...widget,
          w: Math.min(widget.w, 2), // Limit width for sm
          x: 0, // Stack vertically on small screens
          y: layout.sm.length > 0
            ? Math.max(...layout.sm.map((item) => item.y + item.h))
            : 0,
        };

        const newLayout: ResponsiveLayouts = {
          lg: newLgLayout,
          md: [...layout.md, mdWidget],
          sm: [...layout.sm, smWidget],
        };

        set({ layout: newLayout });
      },
    }),
    {
      name: 'layout-storage',
      storage: {
        getItem: (name) => {
          const str = localStorage.getItem(name);
          return str ? JSON.parse(str) : null;
        },
        setItem: (name, value) => {
          try {
            localStorage.setItem(name, JSON.stringify(value));
          } catch (error) {
            // Gracefully handle quota exceeded errors
            console.warn('Failed to save to localStorage:', error);
          }
        },
        removeItem: (name) => localStorage.removeItem(name),
      },
    }
  )
);
