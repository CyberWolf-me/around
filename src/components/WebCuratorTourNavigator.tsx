import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebTourChapter {
  id: string;
  chapterIndex: number;
  title: string;
  venueName: string;
  durationSeconds: number;
  transcriptSnippet: string;
}

export interface WebCuratorTour {
  id: string;
  title: string;
  curatorName: string;
  district: string;
  chapters: WebTourChapter[];
}

export function formatTourDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
}

export function calculateTourProgressPct(totalChapters: number, completedCount: number): number {
  if (totalChapters === 0) return 0;
  return Math.round((completedCount / totalChapters) * 100);
}

export function getChapterHeader(index: number, total: number, locale = 'en'): string {
  const lang = locale.toLowerCase();
  if (lang.startsWith('uz')) {
    return `${total} tadan ${index}-bob`;
  } else if (lang.startsWith('ru')) {
    return `Глава ${index} из ${total}`;
  }
  return `Chapter ${index} of ${total}`;
}

export interface WebCuratorTourNavigatorProps {
  tour: WebCuratorTour;
  completedChapterIds?: string[];
  locale?: string;
  onChapterChange?: (chapterIndex: number) => void;
  onPlayToggle?: (isPlaying: boolean) => void;
}

export const WebCuratorTourNavigator: React.FC<WebCuratorTourNavigatorProps> = ({
  tour,
  completedChapterIds = [],
  locale = 'en',
  onChapterChange,
  onPlayToggle,
}) => {
  const [activeChapterIndex, setActiveChapterIndex] = useState<number>(1);
  const [isPlaying, setIsPlaying] = useState<boolean>(false);

  const chapters = tour.chapters;
  const currentChapter = chapters.find((c) => c.chapterIndex === activeChapterIndex) || chapters[0];
  const completedSet = new Set(completedChapterIds);
  const progressPct = calculateTourProgressPct(chapters.length, completedSet.size);

  const handlePlayToggle = () => {
    playSoundWithHaptic(isPlaying ? 'click' : 'select');
    const next = !isPlaying;
    setIsPlaying(next);
    if (onPlayToggle) onPlayToggle(next);
  };

  const handleSelectChapter = (chapterIndex: number) => {
    playSoundWithHaptic('click');
    setActiveChapterIndex(chapterIndex);
    if (onChapterChange) onChapterChange(chapterIndex);
  };

  return (
    <div
      data-testid="web-curator-tour-navigator"
      style={{
        background: '#FFFDF9',
        borderRadius: 20,
        padding: 20,
        border: `1.5px solid ${isPlaying ? '#FF4800' : 'rgba(22, 20, 18, 0.12)'}`,
        boxShadow: '0 4px 18px rgba(22, 20, 18, 0.05)',
        fontFamily: 'Plus Jakarta Sans, sans-serif',
        maxWidth: 480,
        margin: '0 auto',
      }}
    >
      {/* Tour Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          marginBottom: 14,
        }}
      >
        <div>
          <div
            data-testid="tour-title"
            style={{ fontWeight: 800, fontSize: 16, color: '#161412', marginBottom: 2 }}
          >
            {tour.title}
          </div>
          <div
            data-testid="tour-curator"
            style={{ fontSize: 12, color: '#8F887F', fontWeight: 500 }}
          >
            by {tour.curatorName} • {tour.district}
          </div>
        </div>
        <div
          data-testid="tour-progress-badge"
          style={{
            background: 'rgba(255, 72, 0, 0.08)',
            color: '#FF4800',
            fontSize: 11,
            fontWeight: 700,
            borderRadius: 12,
            padding: '4px 10px',
          }}
        >
          {progressPct}% Complete
        </div>
      </div>

      {/* Active Chapter Card */}
      {currentChapter && (
        <div
          data-testid="active-chapter-card"
          style={{
            background: '#F7F2EA',
            borderRadius: 14,
            padding: 14,
            marginBottom: 16,
            border: '1px solid rgba(22, 20, 18, 0.06)',
          }}
        >
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              marginBottom: 6,
            }}
          >
            <span
              data-testid="chapter-heading"
              style={{ fontSize: 11, fontWeight: 700, color: '#FF4800' }}
            >
              {getChapterHeader(currentChapter.chapterIndex, chapters.length, locale)}
            </span>
            <span
              data-testid="chapter-venue"
              style={{
                fontSize: 11,
                fontWeight: 600,
                color: '#161412',
                background: '#FAF7F2',
                padding: '2px 8px',
                borderRadius: 6,
              }}
            >
              📍 {currentChapter.venueName}
            </span>
          </div>

          <div
            data-testid="chapter-title"
            style={{ fontSize: 14, fontWeight: 700, color: '#161412', marginBottom: 6 }}
          >
            {currentChapter.title}
          </div>

          <div
            data-testid="chapter-snippet"
            style={{
              fontSize: 12,
              fontStyle: 'italic',
              color: '#5A544C',
              lineHeight: 1.35,
              marginBottom: 10,
            }}
          >
            “{currentChapter.transcriptSnippet}”
          </div>

          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <button
              type="button"
              data-testid="play-toggle-btn"
              onClick={handlePlayToggle}
              style={{
                background: '#FF4800',
                color: '#FFFFFF',
                border: 'none',
                borderRadius: 20,
                padding: '6px 14px',
                fontSize: 12,
                fontWeight: 700,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 6,
              }}
            >
              <span>{isPlaying ? '⏸' : '▶'}</span>
              <span>{isPlaying ? 'Pause' : 'Play Chapter'}</span>
            </button>
            <span
              data-testid="chapter-duration"
              style={{ fontSize: 11, fontWeight: 600, color: '#8F887F' }}
            >
              {formatTourDuration(currentChapter.durationSeconds)}
            </span>
          </div>
        </div>
      )}

      {/* Chapters Stepper List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {chapters.map((ch) => {
          const isActive = ch.chapterIndex === activeChapterIndex;
          const isDone = completedSet.has(ch.id);

          return (
            <div
              key={ch.id}
              data-testid={`chapter-row-${ch.chapterIndex}`}
              onClick={() => handleSelectChapter(ch.chapterIndex)}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '8px 12px',
                borderRadius: 10,
                background: isActive ? '#F3ECE0' : 'transparent',
                cursor: 'pointer',
                border: `1px solid ${isActive ? 'rgba(255, 72, 0, 0.3)' : 'transparent'}`,
                transition: 'all 0.15s ease',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontSize: 14 }}>{isDone ? '✅' : '🎧'}</span>
                <div>
                  <div
                    style={{
                      fontSize: 12.5,
                      fontWeight: isActive ? 700 : 600,
                      color: isActive ? '#FF4800' : '#161412',
                    }}
                  >
                    {ch.chapterIndex}. {ch.title}
                  </div>
                  <div style={{ fontSize: 11, color: '#8F887F' }}>{ch.venueName}</div>
                </div>
              </div>
              <span style={{ fontSize: 11, fontWeight: 600, color: '#8F887F' }}>
                {formatTourDuration(ch.durationSeconds)}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
