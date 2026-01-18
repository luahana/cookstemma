import {
  addToViewHistory,
  getViewHistory,
  clearViewHistory,
  type ViewHistoryItem,
} from './viewHistory';

describe('viewHistory localStorage helpers', () => {
  const mockLocalStorage = (() => {
    let store: Record<string, string> = {};
    return {
      getItem: (key: string) => store[key] || null,
      setItem: (key: string, value: string) => {
        store[key] = value;
      },
      removeItem: (key: string) => {
        delete store[key];
      },
      clear: () => {
        store = {};
      },
    };
  })();

  beforeEach(() => {
    mockLocalStorage.clear();
    Object.defineProperty(window, 'localStorage', {
      value: mockLocalStorage,
      writable: true,
    });
  });

  describe('addToViewHistory', () => {
    it('should add a recipe to view history', () => {
      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-123',
        title: 'Kimchi Recipe',
        thumbnail: '/images/kimchi.jpg',
        foodName: 'Kimchi',
      });

      const history = getViewHistory();
      expect(history).toHaveLength(1);
      expect(history[0].type).toBe('recipe');
      expect(history[0].publicId).toBe('recipe-123');
      expect(history[0].title).toBe('Kimchi Recipe');
      expect(history[0].viewedAt).toBeDefined();
    });

    it('should add a log to view history', () => {
      addToViewHistory({
        type: 'log',
        publicId: 'log-456',
        title: 'My Cooking Log',
        thumbnail: '/images/log.jpg',
        foodName: 'Ramen',
        rating: 5,
      });

      const history = getViewHistory();
      expect(history).toHaveLength(1);
      expect(history[0].type).toBe('log');
      expect(history[0].rating).toBe(5);
    });

    it('should add new items to the front', () => {
      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-1',
        title: 'First Recipe',
        thumbnail: null,
        foodName: 'Food 1',
      });

      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-2',
        title: 'Second Recipe',
        thumbnail: null,
        foodName: 'Food 2',
      });

      const history = getViewHistory();
      expect(history).toHaveLength(2);
      expect(history[0].publicId).toBe('recipe-2');
      expect(history[1].publicId).toBe('recipe-1');
    });

    it('should move existing item to front on re-view', () => {
      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-1',
        title: 'First Recipe',
        thumbnail: null,
        foodName: 'Food 1',
      });

      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-2',
        title: 'Second Recipe',
        thumbnail: null,
        foodName: 'Food 2',
      });

      // Re-view first recipe
      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-1',
        title: 'First Recipe Updated',
        thumbnail: null,
        foodName: 'Food 1',
      });

      const history = getViewHistory();
      expect(history).toHaveLength(2);
      expect(history[0].publicId).toBe('recipe-1');
      expect(history[0].title).toBe('First Recipe Updated');
      expect(history[1].publicId).toBe('recipe-2');
    });

    it('should limit to 8 items', () => {
      for (let i = 1; i <= 15; i++) {
        addToViewHistory({
          type: 'recipe',
          publicId: `recipe-${i}`,
          title: `Recipe ${i}`,
          thumbnail: null,
          foodName: `Food ${i}`,
        });
      }

      const history = getViewHistory();
      expect(history).toHaveLength(8);
      // Most recent should be first
      expect(history[0].publicId).toBe('recipe-15');
      // Oldest in the list should be recipe-8 (1-7 were pushed out)
      expect(history[7].publicId).toBe('recipe-8');
    });

    it('should differentiate between recipe and log with same publicId', () => {
      addToViewHistory({
        type: 'recipe',
        publicId: 'same-id',
        title: 'Recipe Title',
        thumbnail: null,
        foodName: 'Food',
      });

      addToViewHistory({
        type: 'log',
        publicId: 'same-id',
        title: 'Log Title',
        thumbnail: null,
        foodName: 'Food',
      });

      const history = getViewHistory();
      expect(history).toHaveLength(2);
    });

    it('should handle null thumbnail and foodName', () => {
      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-123',
        title: 'Recipe',
        thumbnail: null,
        foodName: null,
      });

      const history = getViewHistory();
      expect(history[0].thumbnail).toBeNull();
      expect(history[0].foodName).toBeNull();
    });
  });

  describe('getViewHistory', () => {
    it('should return empty array when no history', () => {
      const history = getViewHistory();
      expect(history).toEqual([]);
    });

    it('should return stored history', () => {
      const item: ViewHistoryItem = {
        type: 'recipe',
        publicId: 'recipe-123',
        title: 'Test Recipe',
        thumbnail: '/img.jpg',
        foodName: 'Food',
        viewedAt: Date.now(),
      };

      mockLocalStorage.setItem('viewHistory', JSON.stringify([item]));

      const history = getViewHistory();
      expect(history).toHaveLength(1);
      expect(history[0]).toEqual(item);
    });

    it('should handle corrupted data gracefully', () => {
      mockLocalStorage.setItem('viewHistory', 'not valid json');

      const history = getViewHistory();
      expect(history).toEqual([]);
    });

    it('should handle non-array data gracefully', () => {
      mockLocalStorage.setItem('viewHistory', JSON.stringify({ invalid: 'data' }));

      const history = getViewHistory();
      expect(history).toEqual([]);
    });
  });

  describe('clearViewHistory', () => {
    it('should clear all history', () => {
      addToViewHistory({
        type: 'recipe',
        publicId: 'recipe-1',
        title: 'Recipe 1',
        thumbnail: null,
        foodName: 'Food 1',
      });

      addToViewHistory({
        type: 'log',
        publicId: 'log-1',
        title: 'Log 1',
        thumbnail: null,
        foodName: 'Food 1',
      });

      expect(getViewHistory()).toHaveLength(2);

      clearViewHistory();

      expect(getViewHistory()).toEqual([]);
    });

    it('should handle clearing empty history', () => {
      clearViewHistory();
      expect(getViewHistory()).toEqual([]);
    });
  });
});
