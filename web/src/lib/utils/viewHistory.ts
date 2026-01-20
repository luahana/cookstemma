const VIEW_HISTORY_KEY = 'viewHistory';
const MAX_ITEMS = 8;

export interface ViewHistoryItem {
  type: 'recipe' | 'log';
  publicId: string;
  title: string;
  titleTranslations?: Record<string, string> | null;
  thumbnail: string | null;
  foodName: string | null;
  rating?: number | null;
  viewedAt: number;
}

/**
 * Add an item to view history in localStorage.
 * Deduplicates and limits to MAX_ITEMS.
 */
export function addToViewHistory(
  item: Omit<ViewHistoryItem, 'viewedAt'>
): void {
  if (typeof window === 'undefined') return;

  const stored = localStorage.getItem(VIEW_HISTORY_KEY);
  let history: ViewHistoryItem[] = [];

  if (stored) {
    try {
      const parsed = JSON.parse(stored);
      if (Array.isArray(parsed)) {
        history = parsed;
      }
    } catch {
      // Invalid data, reset
    }
  }

  // Remove if already exists (to move to front)
  history = history.filter(
    (h) => !(h.type === item.type && h.publicId === item.publicId)
  );

  // Add to front with current timestamp
  history.unshift({
    ...item,
    viewedAt: Date.now(),
  });

  // Limit to max items
  history = history.slice(0, MAX_ITEMS);

  localStorage.setItem(VIEW_HISTORY_KEY, JSON.stringify(history));
}

/**
 * Get view history from localStorage.
 */
export function getViewHistory(): ViewHistoryItem[] {
  if (typeof window === 'undefined') return [];

  const stored = localStorage.getItem(VIEW_HISTORY_KEY);
  if (!stored) return [];

  try {
    const parsed = JSON.parse(stored);
    if (Array.isArray(parsed)) {
      return parsed;
    }
  } catch {
    // Invalid data
  }

  return [];
}

/**
 * Clear view history from localStorage.
 */
export function clearViewHistory(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(VIEW_HISTORY_KEY);
}
