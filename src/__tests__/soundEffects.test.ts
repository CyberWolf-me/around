import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  isSoundEnabled,
  setSoundEnabled,
  getSoundVolume,
  setSoundVolume,
  playPop,
  playClick,
  playSuccess,
  playSoundWithHaptic,
  resetAudioContext,
} from '../services/soundEffects';

describe('P18-03: Web Companion Audio-Tactile Sound Effects Synthesizer', () => {
  let mockAudioContext: any;
  const originalWindow = (globalThis as any).window;

  beforeEach(() => {
    resetAudioContext();
    setSoundEnabled(true);
    setSoundVolume(0.35);

    const mockOscillator = {
      type: 'sine',
      frequency: {
        setValueAtTime: vi.fn(),
        exponentialRampToValueAtTime: vi.fn(),
      },
      connect: vi.fn(),
      start: vi.fn(),
      stop: vi.fn(),
    };

    const mockGain = {
      gain: {
        setValueAtTime: vi.fn(),
        exponentialRampToValueAtTime: vi.fn(),
      },
      connect: vi.fn(),
    };

    mockAudioContext = {
      state: 'running',
      currentTime: 10.0,
      createOscillator: vi.fn(() => ({ ...mockOscillator })),
      createGain: vi.fn(() => ({ ...mockGain })),
      destination: {},
      resume: vi.fn(async () => {}),
    };

    (globalThis as any).window = {
      AudioContext: vi.fn(() => mockAudioContext),
      Telegram: {
        WebApp: {
          HapticFeedback: {
            impactOccurred: vi.fn(),
            selectionChanged: vi.fn(),
          },
        },
      },
    };
  });

  afterEach(() => {
    (globalThis as any).window = originalWindow;
    vi.restoreAllMocks();
  });

  it('controls volume and sound toggle accurately', () => {
    expect(isSoundEnabled()).toBe(true);
    setSoundEnabled(false);
    expect(isSoundEnabled()).toBe(false);

    expect(playPop()).toBe(false);
    expect(playClick()).toBe(false);
    expect(playSuccess()).toBe(false);

    setSoundEnabled(true);
    expect(isSoundEnabled()).toBe(true);

    setSoundVolume(0.8);
    expect(getSoundVolume()).toBe(0.8);

    // Clamps within [0, 1]
    setSoundVolume(1.5);
    expect(getSoundVolume()).toBe(1.0);

    setSoundVolume(-0.2);
    expect(getSoundVolume()).toBe(0.0);
  });

  it('synthesizes pop sound via oscillator and gain ramping', () => {
    setSoundEnabled(true);
    setSoundVolume(0.5);

    const ok = playPop();
    expect(ok).toBe(true);
    expect(mockAudioContext.createOscillator).toHaveBeenCalled();
    expect(mockAudioContext.createGain).toHaveBeenCalled();
  });

  it('synthesizes tactile click sound', () => {
    const ok = playClick();
    expect(ok).toBe(true);
    expect(mockAudioContext.createOscillator).toHaveBeenCalled();
  });

  it('synthesizes success chime with multi-note chord', () => {
    const ok = playSuccess();
    expect(ok).toBe(true);
    // 2 harmonic notes played
    expect(mockAudioContext.createOscillator).toHaveBeenCalledTimes(2);
    expect(mockAudioContext.createGain).toHaveBeenCalledTimes(2);
  });

  it('triggers paired haptic impulse alongside sound effect', () => {
    const hapticMock = (globalThis as any).window.Telegram.WebApp.HapticFeedback;

    playSoundWithHaptic('pop', 'light');
    expect(hapticMock.impactOccurred).toHaveBeenCalledWith('light');

    playSoundWithHaptic('select', 'selection');
    expect(hapticMock.selectionChanged).toHaveBeenCalled();
  });
});
