/**
 * Web Companion Audio-Tactile Sound Effects Synthesizer (P18-03)
 * Uses standard Web Audio API to synthesize zero-asset micro-interaction sounds
 * synchronized with Telegram WebApp haptic impulses.
 */

import { triggerTelegramHaptic } from './telegramWebApp';

export type SoundEffectType = 'pop' | 'click' | 'success' | 'trophy' | 'select';

let audioCtx: AudioContext | null = null;
let soundEnabled = true;
let masterVolume = 0.35; // Soft ambient volume

function getAudioContext(): AudioContext | null {
  if (typeof window === 'undefined') return null;

  try {
    if (!audioCtx) {
      const AudioCtxClass =
        window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtxClass) {
        audioCtx = new AudioCtxClass();
      }
    }

    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume().catch(() => {});
    }

    return audioCtx;
  } catch {
    return null;
  }
}

export function isSoundEnabled(): boolean {
  return soundEnabled;
}

export function setSoundEnabled(enabled: boolean): void {
  soundEnabled = enabled;
}

export function getSoundVolume(): number {
  return masterVolume;
}

export function setSoundVolume(volume: number): void {
  masterVolume = Math.max(0, Math.min(1, volume));
}

export function resetAudioContext(): void {
  audioCtx = null;
}

/**
 * Synthesizes a soft organic pop sound on button taps.
 */
export function playPop(): boolean {
  if (!soundEnabled) return false;
  const ctx = getAudioContext();
  if (!ctx) return false;

  try {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'sine';
    const now = ctx.currentTime;

    osc.frequency.setValueAtTime(540, now);
    osc.frequency.exponentialRampToValueAtTime(180, now + 0.06);

    gain.gain.setValueAtTime(masterVolume * 0.5, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.06);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.06);
    return true;
  } catch {
    return false;
  }
}

/**
 * Synthesizes a subtle tactile click.
 */
export function playClick(): boolean {
  if (!soundEnabled) return false;
  const ctx = getAudioContext();
  if (!ctx) return false;

  try {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();

    osc.type = 'triangle';
    const now = ctx.currentTime;

    osc.frequency.setValueAtTime(900, now);
    osc.frequency.exponentialRampToValueAtTime(300, now + 0.03);

    gain.gain.setValueAtTime(masterVolume * 0.4, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);

    osc.connect(gain);
    gain.connect(ctx.destination);

    osc.start(now);
    osc.stop(now + 0.03);
    return true;
  } catch {
    return false;
  }
}

/**
 * Synthesizes a warm ascending chime on goal/streak achievement.
 */
export function playSuccess(): boolean {
  if (!soundEnabled) return false;
  const ctx = getAudioContext();
  if (!ctx) return false;

  try {
    const now = ctx.currentTime;
    // Harmonic notes: C6 (1046Hz) and E6 (1318Hz)
    const notes = [
      { freq: 1046.5, delay: 0, duration: 0.12 },
      { freq: 1318.5, delay: 0.08, duration: 0.18 },
    ];

    for (const n of notes) {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      const start = now + n.delay;
      osc.frequency.setValueAtTime(n.freq, start);

      gain.gain.setValueAtTime(masterVolume * 0.35, start);
      gain.gain.exponentialRampToValueAtTime(0.001, start + n.duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(start);
      osc.stop(start + n.duration);
    }
    return true;
  } catch {
    return false;
  }
}

/**
 * Plays sound effect paired with synchronized Telegram haptic impulse.
 */
export function playSoundWithHaptic(
  effect: SoundEffectType,
  hapticStyle: 'light' | 'medium' | 'heavy' | 'selection' = 'light'
): void {
  if (hapticStyle === 'selection') {
    triggerTelegramHaptic('selection');
  } else {
    triggerTelegramHaptic(hapticStyle);
  }

  switch (effect) {
    case 'pop':
      playPop();
      break;
    case 'click':
    case 'select':
      playClick();
      break;
    case 'success':
    case 'trophy':
      playSuccess();
      break;
  }
}
