import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebCrawlParticipant {
  userId: string;
  name: string;
  avatarInitials: string;
  currentPlaceId: string | null;
  visitedStopIds: string[];
  isHost: boolean;
}

export interface WebGroupCrawlSession {
  sessionCode: string;
  routeId: string;
  routeTitle: string;
  participants: WebCrawlParticipant[];
  squadBonusXp: number;
}

export interface WebCrawlStop {
  placeId: string;
  name: string;
  nearestSubway: string;
}

export interface WebSquadProgress {
  totalStops: number;
  groupCoveredStops: number;
  percentage: number;
  isSquadComplete: boolean;
  stopVisitorsMap: Record<string, string[]>;
}

export function calculateWebSquadProgress(
  session: WebGroupCrawlSession,
  stops: WebCrawlStop[]
): WebSquadProgress {
  if (stops.length === 0 || session.participants.length === 0) {
    return {
      totalStops: 0,
      groupCoveredStops: 0,
      percentage: 0,
      isSquadComplete: false,
      stopVisitorsMap: {},
    };
  }

  const groupVisitedSet = new Set<string>();
  const visitorsMap: Record<string, string[]> = {};

  for (const p of session.participants) {
    for (const stopId of p.visitedStopIds) {
      groupVisitedSet.add(stopId);
    }
    if (p.currentPlaceId) {
      if (!visitorsMap[p.currentPlaceId]) {
        visitorsMap[p.currentPlaceId] = [];
      }
      visitorsMap[p.currentPlaceId].push(p.name);
    }
  }

  const coveredCount = stops.filter((s) => groupVisitedSet.has(s.placeId)).length;
  const percentage = Math.round((coveredCount / stops.length) * 100);

  const allFinished = stops.every((s) =>
    session.participants.every((p) => p.visitedStopIds.includes(s.placeId))
  );

  return {
    totalStops: stops.length,
    groupCoveredStops: coveredCount,
    percentage,
    isSquadComplete: allFinished,
    stopVisitorsMap: visitorsMap,
  };
}

export interface GroupCrawlRoomViewerProps {
  session: WebGroupCrawlSession;
  stops: WebCrawlStop[];
  currentUserId?: string;
  onCheckIn?: (placeId: string) => void;
  onShareCode?: (sessionCode: string) => void;
  language?: 'en' | 'uz' | 'ru';
}

export const GroupCrawlRoomViewer: React.FC<GroupCrawlRoomViewerProps> = ({
  session,
  stops,
  currentUserId,
  onCheckIn,
  onShareCode,
  language = 'en',
}) => {
  const progress = React.useMemo(() => {
    return calculateWebSquadProgress(session, stops);
  }, [session, stops]);

  const handleCheckInClick = (placeId: string) => {
    playSoundWithHaptic('select');
    onCheckIn?.(placeId);
  };

  const handleShareClick = () => {
    playSoundWithHaptic('click');
    onShareCode?.(session.sessionCode);
  };

  const t = {
    header:
      language === 'uz'
        ? 'GURUH SAYRI JONLI MAYDONI'
        : language === 'ru'
        ? 'ГРУППОВОЙ МАРШРУТ ОНЛАЙН'
        : 'SQUAD CRAWL LIVE RADAR',
    squadProgress:
      language === 'uz' ? 'Guruh Jarayoni' : language === 'ru' ? 'Прогресс группы' : 'Squad Progress',
    checkIn:
      language === 'uz' ? 'Belgilanish' : language === 'ru' ? 'Отметиться' : 'Check In',
    atStop:
      language === 'uz' ? 'Shu yerda' : language === 'ru' ? 'Здесь' : 'Here',
    squadComplete:
      language === 'uz'
        ? 'Guruh Barcha Bekatlarni Yakunladi! 🏆'
        : language === 'ru'
        ? 'Группа завершила маршрут! 🏆'
        : 'Squad Completed the Crawl! 🏆',
    squad: language === 'uz' ? 'Guruh a’zolari' : language === 'ru' ? 'Участники' : 'Squad',
  };

  return (
    <div
      data-testid="group-crawl-room-viewer"
      style={{
        background: '#1A1A1A',
        borderRadius: 16,
        padding: 20,
        color: '#FFFFFF',
        border: progress.isSquadComplete ? '1px solid #66E5B4' : '1px solid #2A2A2A',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
      }}
    >
      {/* Header Tag & Session Code */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 10, fontWeight: 800, color: '#FF5A1F', letterSpacing: '0.12em', textTransform: 'uppercase' }}>
            👥 {t.header}
          </span>
          <button
            data-testid="share-code-button"
            onClick={handleShareClick}
            style={{
              background: '#262626',
              border: '1px solid #3A3A3A',
              color: '#FFFFFF',
              borderRadius: 6,
              padding: '2px 8px',
              fontSize: 11,
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            {session.sessionCode} ⎘
          </button>
        </div>
        <span
          style={{
            fontSize: 11,
            fontWeight: 700,
            padding: '2px 8px',
            borderRadius: 6,
            background: 'rgba(255, 214, 102, 0.15)',
            color: '#FFD666',
          }}
        >
          +{session.squadBonusXp} XP Squad
        </span>
      </div>

      {/* Route Title & Progress */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 8 }}>
        <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700 }}>
          {session.routeTitle}
        </h3>
        <span style={{ fontSize: 16, fontWeight: 800, color: progress.isSquadComplete ? '#66E5B4' : '#FF5A1F' }}>
          {progress.percentage}%
        </span>
      </div>

      {/* Progress Bar */}
      <div style={{ width: '100%', height: 6, background: '#262626', borderRadius: 3, overflow: 'hidden', marginBottom: 16 }}>
        <div
          data-testid="squad-progress-bar"
          style={{
            width: `${progress.percentage}%`,
            height: '100%',
            background: progress.isSquadComplete ? '#66E5B4' : '#FF5A1F',
            transition: 'width 0.3s ease',
          }}
        />
      </div>

      {/* Stop Radar List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginBottom: 16 }}>
        {stops.map((stop, idx) => {
          const visitors = progress.stopVisitorsMap[stop.placeId] || [];
          const currentUserVisited = session.participants
            .find((p) => p.userId === currentUserId)
            ?.visitedStopIds.includes(stop.placeId);

          return (
            <div
              key={stop.placeId}
              data-testid={`stop-radar-${stop.placeId}`}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                padding: '8px 12px',
                background: '#222222',
                border: visitors.length > 0 ? '1px solid rgba(255, 90, 31, 0.4)' : '1px solid #2D2D2D',
                borderRadius: 8,
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{ fontSize: 11, fontWeight: 700, color: '#888888' }}>
                  {idx + 1}.
                </span>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{stop.name}</div>
                  <div style={{ fontSize: 10, color: '#888888' }}>🚇 {stop.nearestSubway}</div>
                </div>
              </div>

              {/* Visitors badges or check in button */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                {visitors.map((name) => (
                  <span
                    key={name}
                    style={{
                      fontSize: 10,
                      fontWeight: 700,
                      padding: '2px 6px',
                      borderRadius: 4,
                      background: 'rgba(255, 90, 31, 0.2)',
                      color: '#FF5A1F',
                    }}
                  >
                    📍 {name}
                  </span>
                ))}
                {!currentUserVisited && (
                  <button
                    data-testid={`checkin-btn-${stop.placeId}`}
                    onClick={() => handleCheckInClick(stop.placeId)}
                    style={{
                      background: '#FF5A1F',
                      color: '#FFFFFF',
                      border: 'none',
                      borderRadius: 6,
                      padding: '4px 8px',
                      fontSize: 10,
                      fontWeight: 700,
                      cursor: 'pointer',
                    }}
                  >
                    {t.checkIn}
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {/* Participants Roster */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, paddingTop: 10, borderTop: '1px solid #262626' }}>
        <span style={{ fontSize: 11, color: '#888888', fontWeight: 600 }}>{t.squad}:</span>
        {session.participants.map((p) => (
          <div
            key={p.userId}
            title={`${p.name} (${p.visitedStopIds.length}/${stops.length})`}
            style={{
              width: 24,
              height: 24,
              borderRadius: 12,
              background: p.isHost ? '#FF5A1F' : '#333333',
              color: '#FFFFFF',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 10,
              fontWeight: 700,
            }}
          >
            {p.avatarInitials}
          </div>
        ))}
      </div>
    </div>
  );
};
