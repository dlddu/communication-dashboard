import { useState, useEffect, useCallback, useRef } from 'react';
import { useLayoutStore } from '@/store/layoutStore';
import { layoutService } from '@/services/api';
import type { ResponsiveLayouts, LayoutItem } from '@/types/layout';
import {
  addWidgetToLayout,
  removeWidgetFromLayout,
  deduplicateLayout,
} from '@/utils/layoutMerger';

interface UseLayoutPersistenceOptions {
  userId?: string;
  autoSave?: boolean;
  debounceMs?: number;
}

interface UseLayoutPersistenceReturn {
  layouts: ResponsiveLayouts;
  isLoading: boolean;
  error: string | null;
  saveLayout: (layouts: ResponsiveLayouts) => Promise<void>;
  loadLayout: () => Promise<void>;
  addWidget: (widgetId: string, defaultSize?: { w: number; h: number }) => void;
  removeWidget: (widgetId: string) => void;
}

const getStorageKey = (userId?: string): string => {
  return `dashboard-layouts-${userId || 'default'}`;
};

const saveToLocalStorage = (userId: string | undefined, layouts: ResponsiveLayouts): void => {
  try {
    localStorage.setItem(getStorageKey(userId), JSON.stringify(layouts));
  } catch (error) {
    if (error instanceof Error && error.message.includes('Quota')) {
      throw new Error('QuotaExceededError');
    }
    throw error;
  }
};

const loadFromLocalStorage = (userId: string | undefined): ResponsiveLayouts | null => {
  try {
    const stored = localStorage.getItem(getStorageKey(userId));
    if (!stored) return null;
    return JSON.parse(stored);
  } catch {
    return null;
  }
};

export function useLayoutPersistence(
  options: UseLayoutPersistenceOptions = {}
): UseLayoutPersistenceReturn {
  const { userId, autoSave = false, debounceMs = 300 } = options;
  const { layouts, setLayouts } = useLayoutStore();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

  const loadLayout = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      if (userId) {
        // Try loading from backend
        try {
          const backendLayouts = await layoutService.loadLayout(userId);
          setLayouts(backendLayouts);
        } catch {
          // Fallback to localStorage
          const localLayouts = loadFromLocalStorage(userId);
          if (localLayouts) {
            setLayouts(localLayouts);
          } else {
            setError('Failed to load layout from backend and localStorage');
            setLayouts({ lg: [], md: [], sm: [] });
          }
        }
      } else {
        // Load from localStorage only
        const localLayouts = loadFromLocalStorage(userId);
        if (localLayouts) {
          setLayouts(localLayouts);
        } else {
          setLayouts({ lg: [], md: [], sm: [] });
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load layout');
      setLayouts({ lg: [], md: [], sm: [] });
    } finally {
      setIsLoading(false);
    }
  }, [userId, setLayouts]);

  const saveLayout = useCallback(
    async (layoutsToSave: ResponsiveLayouts) => {
      setIsLoading(true);

      // Debounce the save operation
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }

      return new Promise<void>((resolve) => {
        debounceTimerRef.current = setTimeout(async () => {
          try {
            if (userId) {
              try {
                // Try saving to backend with timestamp
                await layoutService.saveLayout(userId, {
                  layouts: layoutsToSave,
                  timestamp: Date.now(),
                });
                setError(null);
                setLayouts(layoutsToSave);
              } catch {
                // Fallback to localStorage
                try {
                  saveToLocalStorage(userId, layoutsToSave);
                  setError('Failed to save to backend, saved locally');
                  setLayouts(layoutsToSave);
                } catch (storageError) {
                  if (
                    storageError instanceof Error &&
                    storageError.message === 'QuotaExceededError'
                  ) {
                    setError('Failed to save: storage quota exceeded');
                  } else {
                    setError('Failed to save layout');
                  }
                }
              }
            } else {
              // Save to localStorage only
              try {
                saveToLocalStorage(userId, layoutsToSave);
                setError(null);
                setLayouts(layoutsToSave);
              } catch (storageError) {
                if (
                  storageError instanceof Error &&
                  storageError.message === 'QuotaExceededError'
                ) {
                  setError('Failed to save: storage quota exceeded');
                } else {
                  setError('Failed to save layout');
                }
              }
            }
          } finally {
            setIsLoading(false);
            resolve();
          }
        }, debounceMs);
      });
    },
    [userId, debounceMs, setLayouts]
  );

  const addWidget = useCallback(
    (widgetId: string, defaultSize?: { w: number; h: number }) => {
      const currentLayouts = useLayoutStore.getState().layouts;
      const newWidget: Partial<LayoutItem> = {
        i: widgetId,
        w: defaultSize?.w || 6,
        h: defaultSize?.h || 2,
      };

      const updatedLayouts: ResponsiveLayouts = {
        lg: deduplicateLayout(
          addWidgetToLayout(currentLayouts.lg, newWidget as Omit<LayoutItem, 'x' | 'y'>)
        ),
        md: deduplicateLayout(
          addWidgetToLayout(currentLayouts.md, newWidget as Omit<LayoutItem, 'x' | 'y'>)
        ),
        sm: deduplicateLayout(
          addWidgetToLayout(currentLayouts.sm, newWidget as Omit<LayoutItem, 'x' | 'y'>)
        ),
      };

      setLayouts(updatedLayouts);

      if (autoSave) {
        saveLayout(updatedLayouts);
      }
    },
    [setLayouts, autoSave, saveLayout]
  );

  const removeWidget = useCallback(
    (widgetId: string) => {
      const currentLayouts = useLayoutStore.getState().layouts;
      const updatedLayouts: ResponsiveLayouts = {
        lg: removeWidgetFromLayout(currentLayouts.lg, widgetId),
        md: removeWidgetFromLayout(currentLayouts.md, widgetId),
        sm: removeWidgetFromLayout(currentLayouts.sm, widgetId),
      };

      setLayouts(updatedLayouts);

      if (autoSave) {
        saveLayout(updatedLayouts);
      }
    },
    [setLayouts, autoSave, saveLayout]
  );

  // Load layout on mount
  useEffect(() => {
    loadLayout();
  }, [loadLayout]);

  // Cleanup debounce timer on unmount
  useEffect(() => {
    return () => {
      if (debounceTimerRef.current) {
        clearTimeout(debounceTimerRef.current);
      }
    };
  }, []);

  return {
    layouts,
    isLoading,
    error,
    saveLayout,
    loadLayout,
    addWidget,
    removeWidget,
  };
}
