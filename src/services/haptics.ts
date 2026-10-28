export const buzz = (duration: number | number[] = 8): void => {
  try {
    if (typeof window !== 'undefined' && 'navigator' in window && 'vibrate' in navigator) {
      navigator.vibrate(duration as VibratePattern);
    }
  } catch (err) {
    // Graceful fallback
  }
};

export const hapticPatterns = {
  light: () => buzz(6),
  medium: () => buzz(14),
  success: () => buzz([8, 40, 12]),
  warning: () => buzz([15, 60, 20]),
};
