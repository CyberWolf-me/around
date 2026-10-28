import { describe, it, expect, beforeEach } from 'vitest';
import { storage } from '../services/storage';

describe('Storage Service', () => {
  beforeEach(() => {
    storage.clearAll();
  });

  it('stores and retrieves serialized data accurately', () => {
    const testData = { name: 'Kettle & Loaf', rating: 4.7, tags: ['quiet', 'coffee'] };
    storage.set('test_venue', testData);

    const retrieved = storage.get('test_venue', null);
    expect(retrieved).toEqual(testData);
  });

  it('returns default fallback when key does not exist', () => {
    const fallback = ['fallback_1', 'fallback_2'];
    const result = storage.get('non_existent_key', fallback);
    expect(result).toEqual(fallback);
  });

  it('removes keys properly', () => {
    storage.set('temp_key', 'some_value');
    expect(storage.get('temp_key', null)).toBe('some_value');

    storage.remove('temp_key');
    expect(storage.get('temp_key', null)).toBeNull();
  });
});
