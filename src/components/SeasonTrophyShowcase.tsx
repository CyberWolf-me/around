import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebTrophyTier = 'bronze' | 'silver' | 'gold';

export interface WebSeasonalChallenge {
  id: string;
  titleEn: string;
  titleUz: string;
  titleRu: string;
  descriptionEn: string;
  descriptionUz: string;
  descriptionRu: string;
  icon: string;
  targetCount: number;
  currentCount: number;
  xpReward: number;
  isCompleted?: boolean;
}

export interface WebCuratorSeason {
  seasonId: string;
  titleEn: string;
  titleUz: string;
  titleRu: string;
  startDate: string;
  endDate: string;
  challenges: WebSeasonalChallenge[];
  daysRemaining: number;
}

export function calculateWebSeasonMetrics(season: WebCuratorSeason) {
  const challenges = season.challenges.map((c) => ({
    ...c,
    isCompleted: c.currentCount >= c.targetCount,
    progressPercentage: Math.min(100, Math.round((c.currentCount / Math.max(1, c.targetCount)) * 100)),
  }));

  const completedCount = challenges.filter((c) => c.isCompleted).length;
  const totalCount = challenges.length;
  const overallPercentage = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

  const totalXpAvailable = challenges.reduce((sum, c) => sum + c.xpReward, 0);
  const totalXpEarned = challenges.filter((c) => c.isCompleted).reduce((sum, c) => sum + c.xpReward, 0);

  let earnedTier: WebTrophyTier | null = null;
  if (completedCount >= 3) {
    earnedTier = 'gold';
  } else if (completedCount === 2) {
    earnedTier = 'silver';
  } else if (completedCount === 1) {
    earnedTier = 'bronze';
  }

  return {
    challenges,
    completedCount,
    totalCount,
    overallPercentage,
    totalXpAvailable,
    totalXpEarned,
    earnedTier,
  };
}

export interface SeasonTrophyShowcaseProps {
  season: WebCuratorSeason;
  language?: 'en' | 'uz' | 'ru';
  onClaimTrophy?: (tier: WebTrophyTier) => void;
}

export const SeasonTrophyShowcase: React.FC<SeasonTrophyShowcaseProps> = ({
  season,
  language = 'en',
  onClaimTrophy,
}) => {
  const metrics = React.useMemo(() => calculateWebSeasonMetrics(season), [season]);

  const t = {
    seasonTag: language === 'uz' ? 'OYLIK MAVSUM' : language === 'ru' ? 'СЕЗОН МЕСЯЦА' : 'MONTHLY SEASON',
    daysLeft:
      language === 'uz'
        ? `${season.daysRemaining} kun qoldi`
        : language === 'ru'
        ? `Осталось ${season.daysRemaining} дн.`
        : `${season.daysRemaining} days left`,
    trophyShelf:
      language === 'uz' ? 'Mavsumiy Kuboklar' : language === 'ru' ? 'Сезонные Трофеи' : 'Seasonal Trophy Shelf',
    claim: language === 'uz' ? 'Qabul Qilish' : language === 'ru' ? 'Получить' : 'Claim Trophy',
    unlocked: language === 'uz' ? 'Qulfdan Chiqdi' : language === 'ru' ? 'Разблокирован' : 'Unlocked',
    locked: language === 'uz' ? 'Qulflangan' : language === 'ru' ? 'Заблокирован' : 'Locked',
  };

  const seasonTitle =
    language === 'uz' ? season.titleUz : language === 'ru' ? season.titleRu : season.titleEn;

  const handleTrophyClick = (_tier: WebTrophyTier, isUnlocked: boolean) => {
    if (isUnlocked) {
      playSoundWithHaptic('trophy');
    } else {
      playSoundWithHaptic('select');
    }
  };

  const handleClaim = () => {
    if (metrics.earnedTier) {
      playSoundWithHaptic('success');
      onClaimTrophy?.(metrics.earnedTier);
    }
  };

  return (
    <div
      data-testid="season-trophy-showcase"
      style={{
        background: '#161412',
        borderRadius: 20,
        padding: 24,
        color: '#FAF7F2',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
        border: '1px solid #2B2621',
      }}
    >
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <div
            style={{
              fontSize: 10,
              fontWeight: 800,
              letterSpacing: '0.08em',
              color: '#FF4800',
              textTransform: 'uppercase',
            }}
          >
            {t.seasonTag} · {season.seasonId}
          </div>
          <h2 style={{ margin: '4px 0 0 0', fontSize: 20, fontWeight: 800, color: '#FAF7F2' }}>
            {seasonTitle}
          </h2>
        </div>
        <div
          style={{
            background: '#24201C',
            border: '1px solid #38322B',
            borderRadius: 12,
            padding: '6px 12px',
            fontSize: 12,
            fontWeight: 700,
            color: '#B8B0A5',
          }}
        >
          ⏳ {t.daysLeft}
        </div>
      </div>

      {/* Trophy Shelf Row */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ fontSize: 12, fontWeight: 700, color: '#8F887F', marginBottom: 10 }}>
          {t.trophyShelf}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {(['bronze', 'silver', 'gold'] as WebTrophyTier[]).map((tier) => {
            const isUnlocked =
              (tier === 'bronze' && (metrics.earnedTier === 'bronze' || metrics.earnedTier === 'silver' || metrics.earnedTier === 'gold')) ||
              (tier === 'silver' && (metrics.earnedTier === 'silver' || metrics.earnedTier === 'gold')) ||
              (tier === 'gold' && metrics.earnedTier === 'gold');

            const emoji = tier === 'gold' ? '🥇' : tier === 'silver' ? '🥈' : '🥉';
            const name = tier.toUpperCase();

            return (
              <div
                key={tier}
                data-testid={`trophy-badge-${tier}`}
                onClick={() => handleTrophyClick(tier, isUnlocked)}
                style={{
                  background: isUnlocked ? '#26211B' : '#1C1916',
                  border: `1.5px solid ${isUnlocked ? '#FFD666' : '#2F2923'}`,
                  borderRadius: 14,
                  padding: 12,
                  textAlign: 'center',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                  opacity: isUnlocked ? 1.0 : 0.45,
                }}
              >
                <div style={{ fontSize: 26, marginBottom: 4 }}>{emoji}</div>
                <div style={{ fontSize: 11, fontWeight: 800, color: isUnlocked ? '#FFD666' : '#8F887F' }}>
                  {name}
                </div>
                <div style={{ fontSize: 9, fontWeight: 700, color: isUnlocked ? '#66E5B4' : '#5A544C', marginTop: 2 }}>
                  {isUnlocked ? t.unlocked : t.locked}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Challenge List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginBottom: 20 }}>
        {metrics.challenges.map((challenge) => {
          const isDone = challenge.isCompleted;
          const title =
            language === 'uz'
              ? challenge.titleUz
              : language === 'ru'
              ? challenge.titleRu
              : challenge.titleEn;

          return (
            <div
              key={challenge.id}
              data-testid={`challenge-row-${challenge.id}`}
              style={{
                background: isDone ? 'rgba(102, 229, 180, 0.08)' : '#211D19',
                border: `1px solid ${isDone ? '#66E5B4' : '#332D26'}`,
                borderRadius: 14,
                padding: 12,
                display: 'flex',
                alignItems: 'center',
                gap: 12,
              }}
            >
              <div
                style={{
                  width: 38,
                  height: 38,
                  borderRadius: 10,
                  background: '#2C2620',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 18,
                }}
              >
                {challenge.icon}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ fontSize: 13, fontWeight: 700, color: '#FAF7F2' }}>{title}</span>
                  <span style={{ fontSize: 12, fontWeight: 800, color: isDone ? '#66E5B4' : '#8F887F' }}>
                    {challenge.currentCount}/{challenge.targetCount}
                  </span>
                </div>
                {/* Progress bar */}
                <div style={{ height: 4, background: '#2D2721', borderRadius: 2, overflow: 'hidden' }}>
                  <div
                    style={{
                      height: '100%',
                      width: `${challenge.progressPercentage}%`,
                      background: isDone ? '#66E5B4' : '#FF4800',
                      borderRadius: 2,
                    }}
                  />
                </div>
              </div>
              <div
                style={{
                  padding: '4px 8px',
                  borderRadius: 6,
                  background: 'rgba(255, 72, 0, 0.15)',
                  color: '#FF4800',
                  fontSize: 11,
                  fontWeight: 800,
                }}
              >
                +{challenge.xpReward} XP
              </div>
            </div>
          );
        })}
      </div>

      {/* Claim Banner */}
      {metrics.earnedTier && (
        <div
          data-testid="claim-banner"
          style={{
            background: 'rgba(255, 214, 102, 0.1)',
            border: '1.5px solid #FFD666',
            borderRadius: 14,
            padding: 14,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div>
            <div style={{ fontSize: 13, fontWeight: 800, color: '#FFD666' }}>
              🎉 {metrics.earnedTier.toUpperCase()} TROPHY EARNED
            </div>
            <div style={{ fontSize: 11, color: '#B8B0A5', marginTop: 2 }}>
              {metrics.totalXpEarned} / {metrics.totalXpAvailable} XP Awarded
            </div>
          </div>
          <button
            data-testid="claim-trophy-web-btn"
            onClick={handleClaim}
            style={{
              background: '#FF4800',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: 10,
              padding: '8px 16px',
              fontSize: 12,
              fontWeight: 800,
              cursor: 'pointer',
            }}
          >
            {t.claim}
          </button>
        </div>
      )}
    </div>
  );
};
