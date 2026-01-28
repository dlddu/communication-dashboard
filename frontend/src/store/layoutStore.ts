import { create } from 'zustand';
import type { LayoutItem, ResponsiveLayouts } from '@/types/layout';

interface LayoutStore {
  layouts: ResponsiveLayouts;
  setLayouts: (layouts: ResponsiveLayouts) => void;
  updateLayout: (breakpoint: string, layout: LayoutItem[]) => void;
  resetLayouts: () => void;
}

const defaultLayouts: ResponsiveLayouts = {
  lg: [],
  md: [],
  sm: [],
};

export const useLayoutStore = create<LayoutStore>((set) => ({
  layouts: defaultLayouts,

  setLayouts: (layouts) =>
    set(() => ({
      layouts,
    })),

  updateLayout: (breakpoint, layout) =>
    set((state) => ({
      layouts: {
        ...state.layouts,
        [breakpoint]: layout,
      },
    })),

  resetLayouts: () =>
    set(() => ({
      layouts: defaultLayouts,
    })),
}));
