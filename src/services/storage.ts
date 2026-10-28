const STORAGE_PREFIX = 'around_app_v1_';

// In-memory fallback for environments without localStorage (Node.js, SSR, tests)
const memoryStore = new Map<string, string>();

const hasLocalStorage = (): boolean => {
  try {
    return typeof window !== 'undefined' && typeof window.localStorage !== 'undefined';
  } catch {
    return false;
  }
};

export const storage = {
  get<T>(key: string, defaultValue: T): T {
    try {
      const fullKey = STORAGE_PREFIX + key;
      const raw = hasLocalStorage() ? localStorage.getItem(fullKey) : memoryStore.get(fullKey);
      return raw ? JSON.parse(raw) : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  },

  set<T>(key: string, value: T): void {
    try {
      const fullKey = STORAGE_PREFIX + key;
      const serialized = JSON.stringify(value);
      if (hasLocalStorage()) {
        localStorage.setItem(fullKey, serialized);
      } else {
        memoryStore.set(fullKey, serialized);
      }
    } catch (e) {
      // Graceful fallback
    }
  },

  remove(key: string): void {
    try {
      const fullKey = STORAGE_PREFIX + key;
      if (hasLocalStorage()) {
        localStorage.removeItem(fullKey);
      } else {
        memoryStore.delete(fullKey);
      }
    } catch (e) {
      // Graceful fallback
    }
  },

  clearAll(): void {
    try {
      if (hasLocalStorage()) {
        Object.keys(localStorage)
          .filter(k => k.startsWith(STORAGE_PREFIX))
          .forEach(k => localStorage.removeItem(k));
      } else {
        memoryStore.clear();
      }
    } catch (e) {
      // Graceful fallback
    }
  }
};
