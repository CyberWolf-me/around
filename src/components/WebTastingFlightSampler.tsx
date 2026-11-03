import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebTastingStop {
  id: string;
  venueName: string;
  district: string;
  itemTitle: string;
  flavorNotes: string[];
  originStory: string;
  servingTemp?: string;
}

export interface WebTastingLog {
  stopId: string;
  rating: number; // 1 to 10
  flavorNotes: string[];
  notes?: string;
}

export interface WebTastingFlight {
  id: string;
  title: string;
  curatorTitle: string;
  category: string;
  accentColor: string;
  requiredStops: number;
  stops: WebTastingStop[];
}

export function calculateFlightMetrics(
  flight: WebTastingFlight,
  userLogs: Record<string, WebTastingLog> = {}
): { completedCount: number; percentage: number; averageScore: number; isCompleted: boolean } {
  let completedCount = 0;
  let totalScore = 0;

  for (const stop of flight.stops) {
    const log = userLogs[stop.id];
    if (log && log.rating > 0) {
      completedCount++;
      totalScore += log.rating;
    }
  }

  const isCompleted = completedCount >= flight.requiredStops;
  const percentage = flight.requiredStops > 0
    ? Math.min(100, Math.round((completedCount / flight.requiredStops) * 100))
    : 100;
  const averageScore = completedCount > 0
    ? Number((totalScore / completedCount).toFixed(1))
    : 0;

  return { completedCount, percentage, averageScore, isCompleted };
}

export function getAllFlavorNotes(flight: WebTastingFlight): string[] {
  const set = new Set<string>();
  for (const stop of flight.stops) {
    for (const note of stop.flavorNotes) {
      set.add(note);
    }
  }
  return Array.from(set);
}

export function getFlightCertificateLabel(isCompleted: boolean, locale = 'en'): string {
  const lang = locale.toLowerCase();
  if (isCompleted) {
    if (lang.startsWith('uz')) return 'Sertifikat ochildi! (+50 XP)';
    if (lang.startsWith('ru')) return 'Сертификат открыт! (+50 XP)';
    return 'Cupping Certificate Unlocked! (+50 XP)';
  }

  if (lang.startsWith('uz')) return 'Tasting davom etmoqda';
  if (lang.startsWith('ru')) return 'Дегустация в процессе';
  return 'Cupping In Progress';
}

export interface WebTastingFlightSamplerProps {
  flight: WebTastingFlight;
  userLogs?: Record<string, WebTastingLog>;
  locale?: string;
  onSelectStop?: (stop: WebTastingStop) => void;
  onLogRating?: (stopId: string, rating: number, notes: string[]) => void;
}

export const WebTastingFlightSampler: React.FC<WebTastingFlightSamplerProps> = ({
  flight,
  userLogs = {},
  locale = 'en',
  onSelectStop,
  onLogRating,
}) => {
  const [selectedNote, setSelectedNote] = useState<string | null>(null);
  const [selectedStopId, setSelectedStopId] = useState<string | null>(
    flight.stops.length > 0 ? flight.stops[0].id : null
  );

  const metrics = calculateFlightMetrics(flight, userLogs);
  const allNotes = getAllFlavorNotes(flight);

  const handleNoteClick = (note: string) => {
    if (selectedNote === note) {
      setSelectedNote(null);
    } else {
      setSelectedNote(note);
      playSoundWithHaptic('select');
    }
  };

  const handleStopClick = (stop: WebTastingStop) => {
    setSelectedStopId(stop.id);
    playSoundWithHaptic('click');
    onSelectStop?.(stop);
  };

  const handleRateQuick = (stopId: string, rating: number) => {
    playSoundWithHaptic('pop');
    const existing = userLogs[stopId]?.flavorNotes || [];
    onLogRating?.(stopId, rating, existing);
  };

  return (
    <div
      data-testid="tasting-flight-sampler"
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '20px',
        fontFamily: 'Plus Jakarta Sans, sans-serif',
      }}
    >
      {/* Header and Progress Card */}
      <div
        style={{
          backgroundColor: '#FFFDF9',
          borderRadius: '16px',
          border: `1.5px solid ${metrics.isCompleted ? flight.accentColor : '#E8DECF'}`,
          padding: '18px',
          display: 'flex',
          flexDirection: 'column',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <span
              style={{
                fontSize: '11px',
                fontWeight: 700,
                textTransform: 'uppercase',
                color: flight.accentColor,
                letterSpacing: '0.05em',
              }}
            >
              {flight.category} Tasting Flight
            </span>
            <h2 style={{ margin: '4px 0 2px', fontSize: '18px', fontWeight: 700, color: '#161412' }}>
              {flight.title}
            </h2>
            <p style={{ margin: 0, fontSize: '13px', color: '#8F887F' }}>
              {flight.curatorTitle}
            </p>
          </div>

          <span
            style={{
              padding: '4px 10px',
              borderRadius: '12px',
              backgroundColor: metrics.isCompleted ? `${flight.accentColor}22` : '#F7F2EA',
              color: metrics.isCompleted ? flight.accentColor : '#5A544C',
              fontSize: '12px',
              fontWeight: 700,
            }}
          >
            {metrics.isCompleted ? '+50 XP' : `${metrics.percentage}%`}
          </span>
        </div>

        {/* Progress Bar & Rating */}
        <div>
          <div
            style={{
              height: '6px',
              borderRadius: '3px',
              backgroundColor: '#F3ECE0',
              overflow: 'hidden',
            }}
          >
            <div
              style={{
                height: '100%',
                width: `${metrics.percentage}%`,
                backgroundColor: flight.accentColor,
                transition: 'width 0.3s ease',
              }}
            />
          </div>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              marginTop: '6px',
              fontSize: '12px',
              color: '#8F887F',
            }}
          >
            <span>{getFlightCertificateLabel(metrics.isCompleted, locale)}</span>
            <span>
              {metrics.averageScore > 0 ? `Avg Cupping: ${metrics.averageScore} / 10 • ` : ''}
              {metrics.completedCount}/{flight.requiredStops} tastings
            </span>
          </div>
        </div>

        {/* Flavor Notes Cloud */}
        <div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: '#8F887F', marginBottom: '6px' }}>
            Aroma & Flavor Palette (click to filter stops):
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
            {allNotes.map((note) => {
              const isSelected = selectedNote === note;
              return (
                <button
                  key={note}
                  data-testid={`note-pill-${note}`}
                  onClick={() => handleNoteClick(note)}
                  style={{
                    padding: '3px 9px',
                    borderRadius: '10px',
                    border: isSelected
                      ? `1.5px solid ${flight.accentColor}`
                      : '1px solid #E8DECF',
                    backgroundColor: isSelected ? `${flight.accentColor}22` : '#FFFDF9',
                    color: isSelected ? flight.accentColor : '#5A544C',
                    fontSize: '11px',
                    fontWeight: isSelected ? 700 : 500,
                    cursor: 'pointer',
                  }}
                >
                  {note}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Tasting Stops List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
        {flight.stops.map((stop) => {
          const log = userLogs[stop.id];
          const isLogged = log && log.rating > 0;
          const isSelected = selectedStopId === stop.id;
          const containsSelectedNote =
            !selectedNote || stop.flavorNotes.includes(selectedNote);

          return (
            <div
              key={stop.id}
              data-testid={`tasting-stop-${stop.id}`}
              onClick={() => handleStopClick(stop)}
              style={{
                backgroundColor: '#FFFDF9',
                borderRadius: '14px',
                border: isSelected
                  ? `2px solid ${flight.accentColor}`
                  : '1px solid #E8DECF',
                padding: '14px',
                cursor: 'pointer',
                display: 'flex',
                flexDirection: 'column',
                gap: '8px',
                opacity: containsSelectedNote ? 1.0 : 0.45,
                transition: 'all 0.15s ease',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <h4 style={{ margin: 0, fontSize: '14px', fontWeight: 700, color: '#161412' }}>
                    {stop.itemTitle}
                  </h4>
                  <span style={{ fontSize: '12px', color: '#8F887F' }}>
                    {stop.venueName} • {stop.district}
                  </span>
                </div>

                {stop.servingTemp && (
                  <span
                    style={{
                      fontSize: '11px',
                      padding: '2px 8px',
                      borderRadius: '8px',
                      backgroundColor: '#F7F2EA',
                      color: '#5A544C',
                      fontWeight: 600,
                    }}
                  >
                    {stop.servingTemp}
                  </span>
                )}
              </div>

              <p style={{ margin: 0, fontSize: '12px', color: '#5A544C', lineHeight: 1.4 }}>
                {stop.originStory}
              </p>

              {/* Stop Flavor Tags */}
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '5px' }}>
                {stop.flavorNotes.map((note) => (
                  <span
                    key={note}
                    style={{
                      fontSize: '10px',
                      padding: '2px 6px',
                      borderRadius: '6px',
                      backgroundColor:
                        selectedNote === note ? `${flight.accentColor}22` : '#F7F2EA',
                      color: selectedNote === note ? flight.accentColor : '#8F887F',
                      fontWeight: selectedNote === note ? 700 : 500,
                    }}
                  >
                    {note}
                  </span>
                ))}
              </div>

              {/* Quick Cupping Rating Bar */}
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  marginTop: '4px',
                  paddingTop: '6px',
                  borderTop: '1px dashed #E8DECF',
                }}
              >
                <span style={{ fontSize: '11px', color: '#8F887F' }}>
                  {isLogged ? `Logged: ${log.rating}★` : 'Rate this specimen:'}
                </span>

                <div style={{ display: 'flex', gap: '4px' }}>
                  {[7, 8, 9, 10].map((star) => (
                    <button
                      key={star}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleRateQuick(stop.id, star);
                      }}
                      style={{
                        padding: '2px 6px',
                        borderRadius: '6px',
                        border: '1px solid #E8DECF',
                        backgroundColor:
                          log?.rating === star ? flight.accentColor : '#FFFDF9',
                        color: log?.rating === star ? '#FFFDF9' : '#5A544C',
                        fontSize: '11px',
                        fontWeight: 600,
                        cursor: 'pointer',
                      }}
                    >
                      {star}★
                    </button>
                  ))}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
