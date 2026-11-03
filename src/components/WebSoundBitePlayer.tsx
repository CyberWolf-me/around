import React, { useState, useEffect, useRef } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebPlaceSoundBite {
  id: string;
  placeId: string;
  placeName: string;
  district: string;
  authorName: string;
  durationSeconds: number;
  waveformAmplitudes: number[];
  transcriptionSnippet?: string;
  categoryTag: 'barista_tip' | 'history' | 'whisper' | 'ambient';
  likesCount: number;
}

export interface WebSoundBitePlayerProps {
  soundBite: WebPlaceSoundBite;
  locale?: string;
  onPlayToggle?: (playing: boolean) => void;
  onLikeToggle?: (liked: boolean) => void;
}

export function formatSoundDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

export function formatSoundProgress(currentSeconds: number, totalSeconds: number): string {
  return `${formatSoundDuration(currentSeconds)} / ${formatSoundDuration(totalSeconds)}`;
}

export function getSoundBiteCategoryLabel(category: string, locale = 'en'): string {
  const lang = locale.toLowerCase();
  switch (category) {
    case 'barista_tip':
      return lang.startsWith('uz')
        ? 'Barista Tavsiyasi'
        : lang.startsWith('ru')
        ? 'Совет бариста'
        : 'Barista Tip';
    case 'history':
      return lang.startsWith('uz')
        ? 'Tarixiy Xotira'
        : lang.startsWith('ru')
        ? 'История места'
        : 'Local History';
    case 'whisper':
      return lang.startsWith('uz')
        ? 'Hovli Shiviri'
        : lang.startsWith('ru')
        ? 'Шепот дворика'
        : 'Courtyard Whisper';
    case 'ambient':
    default:
      return lang.startsWith('uz')
        ? 'Muhit Ovozi'
        : lang.startsWith('ru')
        ? 'Атмосфера'
        : 'Atmosphere Note';
  }
}

export const WebSoundBitePlayer: React.FC<WebSoundBitePlayerProps> = ({
  soundBite,
  locale = 'en',
  onPlayToggle,
  onLikeToggle,
}) => {
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [playbackProgress, setPlaybackProgress] = useState<number>(0);
  const [isLiked, setIsLiked] = useState<boolean>(false);
  const [likesCount, setLikesCount] = useState<number>(soundBite.likesCount);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const amplitudes = soundBite.waveformAmplitudes.length > 0
    ? soundBite.waveformAmplitudes
    : [0.3, 0.5, 0.8, 0.4, 0.9, 0.6, 0.4, 0.7];

  const currentSeconds = playbackProgress * soundBite.durationSeconds;
  const progressText = formatSoundProgress(currentSeconds, soundBite.durationSeconds);
  const categoryTitle = getSoundBiteCategoryLabel(soundBite.categoryTag, locale);

  const handlePlayToggle = () => {
    playSoundWithHaptic(isPlaying ? 'click' : 'select');
    const nextState = !isPlaying;
    setIsPlaying(nextState);
    if (onPlayToggle) onPlayToggle(nextState);
  };

  const handleLikeToggle = () => {
    playSoundWithHaptic('pop');
    const nextLiked = !isLiked;
    setIsLiked(nextLiked);
    setLikesCount((prev) => (nextLiked ? prev + 1 : Math.max(0, prev - 1)));
    if (onLikeToggle) onLikeToggle(nextLiked);
  };

  const handleSeek = (fraction: number) => {
    playSoundWithHaptic('select');
    const clamped = Math.max(0, Math.min(1, fraction));
    setPlaybackProgress(clamped);
  };

  useEffect(() => {
    if (isPlaying) {
      const intervalMs = 200;
      const step = intervalMs / (soundBite.durationSeconds * 1000);
      timerRef.current = setInterval(() => {
        setPlaybackProgress((prev) => {
          if (prev >= 1.0) {
            setIsPlaying(false);
            if (onPlayToggle) onPlayToggle(false);
            return 0;
          }
          return Math.min(1.0, prev + step);
        });
      }, intervalMs);
    } else {
      if (timerRef.current) {
        clearInterval(timerRef.current);
        timerRef.current = null;
      }
    }

    return () => {
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
    };
  }, [isPlaying, soundBite.durationSeconds, onPlayToggle]);

  return (
    <div
      data-testid="web-sound-bite-player"
      style={{
        background: '#FFFDF9',
        borderRadius: 16,
        padding: 18,
        border: `1.5px solid ${isPlaying ? '#FF4800' : 'rgba(22, 20, 18, 0.12)'}`,
        boxShadow: '0 4px 16px rgba(22, 20, 18, 0.05)',
        fontFamily: 'Plus Jakarta Sans, sans-serif',
        maxWidth: 440,
        margin: '0 auto',
      }}
    >
      {/* Author and Category Bar */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 10,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: '50%',
              backgroundColor: 'rgba(255, 72, 0, 0.1)',
              color: '#FF4800',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 700,
              fontSize: 13,
            }}
          >
            {soundBite.authorName.charAt(0).toUpperCase()}
          </div>
          <div>
            <div
              data-testid="author-name"
              style={{ fontWeight: 700, fontSize: 14, color: '#161412' }}
            >
              {soundBite.authorName}
            </div>
            <div
              data-testid="category-badge"
              style={{ fontSize: 11, color: '#8F887F', fontWeight: 500 }}
            >
              {categoryTitle}
            </div>
          </div>
        </div>

        <button
          type="button"
          data-testid="like-button"
          onClick={handleLikeToggle}
          style={{
            background: isLiked ? 'rgba(220, 38, 38, 0.1)' : '#F3ECE0',
            color: isLiked ? '#DC2626' : '#5A544C',
            border: 'none',
            borderRadius: 12,
            padding: '4px 10px',
            fontSize: 12,
            fontWeight: 600,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: 4,
          }}
        >
          <span>{isLiked ? '❤️' : '🤍'}</span>
          <span data-testid="likes-count">{likesCount}</span>
        </button>
      </div>

      {/* Transcription snippet */}
      {soundBite.transcriptionSnippet && (
        <div
          data-testid="transcription-snippet"
          style={{
            fontSize: 12.5,
            fontStyle: 'italic',
            color: '#5A544C',
            marginBottom: 12,
            lineHeight: 1.35,
          }}
        >
          “{soundBite.transcriptionSnippet}”
        </div>
      )}

      {/* SVG Waveform Visualizer */}
      <div
        data-testid="waveform-container"
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 3,
          height: 38,
          marginBottom: 12,
          cursor: 'pointer',
          padding: '2px 0',
        }}
      >
        {amplitudes.map((amp, idx) => {
          const barFraction = (idx + 1) / amplitudes.length;
          const isActive = barFraction <= playbackProgress;
          const heightPct = Math.max(12, Math.min(100, amp * 100));

          return (
            <div
              key={idx}
              data-testid={`waveform-bar-${idx}`}
              onClick={() => handleSeek(barFraction)}
              style={{
                flex: 1,
                height: `${heightPct}%`,
                background: isActive ? '#FF4800' : 'rgba(22, 20, 18, 0.15)',
                borderRadius: 3,
                transition: 'background 0.15s ease',
              }}
            />
          );
        })}
      </div>

      {/* Player Controls & Place Tag */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button
            type="button"
            data-testid="play-toggle-button"
            onClick={handlePlayToggle}
            style={{
              width: 36,
              height: 36,
              borderRadius: '50%',
              backgroundColor: '#FF4800',
              color: '#FFFFFF',
              border: 'none',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 15,
            }}
          >
            {isPlaying ? '⏸' : '▶'}
          </button>
          <span
            data-testid="progress-text"
            style={{ fontSize: 12, fontWeight: 600, color: '#5A544C' }}
          >
            {progressText}
          </span>
        </div>

        <div
          data-testid="place-badge"
          style={{
            background: 'rgba(255, 72, 0, 0.08)',
            color: '#FF4800',
            fontSize: 11,
            fontWeight: 600,
            borderRadius: 8,
            padding: '4px 8px',
            display: 'flex',
            alignItems: 'center',
            gap: 4,
          }}
        >
          <span>📍</span>
          <span>{soundBite.placeName}</span>
        </div>
      </div>
    </div>
  );
};
