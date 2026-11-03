import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebQuestStop {
  id: string;
  name: string;
  district: string;
  architecturalStyle: string;
  yearBuilt?: number;
  fact: string;
}

export interface WebArchitecturalQuest {
  id: string;
  title: string;
  badgeName: string;
  description: string;
  category: 'Modernism' | 'Heritage' | 'Contemporary' | string;
  accentColor: string;
  requiredStops: number;
  xpReward: number;
  stops: WebQuestStop[];
}

export type QuestFilterTab = 'all' | 'in_progress' | 'completed';

export function calculateQuestProgress(
  quest: WebArchitecturalQuest,
  visitedStopIds: string[] = []
): { visitedCount: number; percentage: number; isUnlocked: boolean } {
  const visited = quest.stops.filter((s) => visitedStopIds.includes(s.id));
  const visitedCount = visited.length;
  const isUnlocked = visitedCount >= quest.requiredStops;
  const percentage = quest.requiredStops > 0
    ? Math.min(100, Math.round((visitedCount / quest.requiredStops) * 100))
    : 100;

  return { visitedCount, percentage, isUnlocked };
}

export function filterQuests(
  quests: WebArchitecturalQuest[],
  filter: QuestFilterTab,
  visitedStopIds: string[] = []
): WebArchitecturalQuest[] {
  if (filter === 'all') return quests;

  return quests.filter((q) => {
    const { isUnlocked } = calculateQuestProgress(q, visitedStopIds);
    if (filter === 'completed') return isUnlocked;
    return !isUnlocked;
  });
}

export function getBadgeStatusLabel(
  isUnlocked: boolean,
  percentage: number,
  locale = 'en'
): string {
  const lang = locale.toLowerCase();
  if (isUnlocked) {
    if (lang.startsWith('uz')) return 'Nishon ochildi!';
    if (lang.startsWith('ru')) return 'Бейдж открыт!';
    return 'Badge Unlocked!';
  }

  if (lang.startsWith('uz')) return `${percentage}% bajarildi`;
  if (lang.startsWith('ru')) return `${percentage}% пройдено`;
  return `${percentage}% Completed`;
}

export interface WebArchitecturalBadgeShowcaseProps {
  quests: WebArchitecturalQuest[];
  visitedStopIds?: string[];
  locale?: string;
  onSelectQuest?: (quest: WebArchitecturalQuest) => void;
  onSelectStop?: (stop: WebQuestStop) => void;
}

export const WebArchitecturalBadgeShowcase: React.FC<WebArchitecturalBadgeShowcaseProps> = ({
  quests,
  visitedStopIds = [],
  locale = 'en',
  onSelectQuest,
  onSelectStop,
}) => {
  const [activeFilter, setActiveFilter] = useState<QuestFilterTab>('all');
  const [selectedQuestId, setSelectedQuestId] = useState<string | null>(
    quests.length > 0 ? quests[0].id : null
  );

  const filteredQuests = filterQuests(quests, activeFilter, visitedStopIds);
  const selectedQuest = quests.find((q) => q.id === selectedQuestId) || quests[0];

  const handleFilterChange = (filter: QuestFilterTab) => {
    setActiveFilter(filter);
    playSoundWithHaptic('select');
  };

  const handleCardClick = (quest: WebArchitecturalQuest) => {
    setSelectedQuestId(quest.id);
    const { isUnlocked } = calculateQuestProgress(quest, visitedStopIds);
    if (isUnlocked) {
      playSoundWithHaptic('trophy');
    } else {
      playSoundWithHaptic('click');
    }
    onSelectQuest?.(quest);
  };

  return (
    <div
      data-testid="architectural-badge-showcase"
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '20px',
        fontFamily: 'Plus Jakarta Sans, sans-serif',
      }}
    >
      {/* Header and Filter Tabs */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h2 style={{ margin: 0, fontSize: '20px', fontWeight: 700, color: '#161412' }}>
            Tashkent Architectural Quests
          </h2>
          <p style={{ margin: '4px 0 0', fontSize: '13px', color: '#8F887F' }}>
            Discover modernist brise-soleil, Silk Road majolica, and contemporary cafe design.
          </p>
        </div>

        {/* Filter Pills */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {(['all', 'in_progress', 'completed'] as QuestFilterTab[]).map((tab) => {
            const isActive = activeFilter === tab;
            const label =
              tab === 'all'
                ? 'All Quests'
                : tab === 'in_progress'
                ? 'In Progress'
                : 'Completed';

            return (
              <button
                key={tab}
                data-testid={`filter-${tab}`}
                onClick={() => handleFilterChange(tab)}
                style={{
                  padding: '6px 14px',
                  borderRadius: '16px',
                  border: isActive ? '1px solid #161412' : '1px solid #E8DECF',
                  backgroundColor: isActive ? '#161412' : '#FFFDF9',
                  color: isActive ? '#FFFDF9' : '#5A544C',
                  fontSize: '12px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Grid of Quest Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
          gap: '16px',
        }}
      >
        {filteredQuests.map((quest) => {
          const { visitedCount, percentage, isUnlocked } = calculateQuestProgress(
            quest,
            visitedStopIds
          );
          const isSelected = selectedQuest?.id === quest.id;

          return (
            <div
              key={quest.id}
              data-testid={`quest-card-${quest.id}`}
              onClick={() => handleCardClick(quest)}
              style={{
                backgroundColor: '#FFFDF9',
                borderRadius: '16px',
                border: isSelected
                  ? `2px solid ${quest.accentColor}`
                  : '1px solid #E8DECF',
                padding: '16px',
                cursor: 'pointer',
                display: 'flex',
                flexDirection: 'column',
                gap: '12px',
                transition: 'transform 0.15s ease, box-shadow 0.15s ease',
                boxShadow: isUnlocked
                  ? '0 4px 12px rgba(217, 119, 6, 0.12)'
                  : '0 2px 8px rgba(0,0,0,0.03)',
              }}
            >
              {/* Card Header: Icon, Badge Title, Status Pill */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <div
                    style={{
                      width: '40px',
                      height: '40px',
                      borderRadius: '50%',
                      backgroundColor: `${quest.accentColor}22`,
                      border: `1.5px solid ${quest.accentColor}`,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '18px',
                      color: quest.accentColor,
                    }}
                  >
                    🏛️
                  </div>
                  <div>
                    <h4 style={{ margin: 0, fontSize: '15px', fontWeight: 700, color: '#161412' }}>
                      {quest.badgeName}
                    </h4>
                    <span style={{ fontSize: '12px', color: '#8F887F' }}>
                      {quest.category}
                    </span>
                  </div>
                </div>

                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 700,
                    padding: '3px 8px',
                    borderRadius: '10px',
                    backgroundColor: isUnlocked ? `${quest.accentColor}22` : '#F7F2EA',
                    color: isUnlocked ? quest.accentColor : '#5A544C',
                  }}
                >
                  {isUnlocked ? `+${quest.xpReward} XP` : `${percentage}%`}
                </span>
              </div>

              {/* Description */}
              <p style={{ margin: 0, fontSize: '12px', color: '#5A544C', lineHeight: 1.4 }}>
                {quest.description}
              </p>

              {/* Progress Bar */}
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
                      width: `${percentage}%`,
                      backgroundColor: quest.accentColor,
                      transition: 'width 0.3s ease',
                    }}
                  />
                </div>
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    marginTop: '4px',
                    fontSize: '11px',
                    color: '#8F887F',
                  }}
                >
                  <span>{getBadgeStatusLabel(isUnlocked, percentage, locale)}</span>
                  <span>
                    {visitedCount}/{quest.requiredStops} stops
                  </span>
                </div>
              </div>

              {/* Stop Chips */}
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                {quest.stops.map((stop) => {
                  const isVisited = visitedStopIds.includes(stop.id);
                  return (
                    <span
                      key={stop.id}
                      onClick={(e) => {
                        e.stopPropagation();
                        playSoundWithHaptic('select');
                        onSelectStop?.(stop);
                      }}
                      style={{
                        fontSize: '11px',
                        padding: '3px 8px',
                        borderRadius: '8px',
                        backgroundColor: isVisited ? `${quest.accentColor}18` : '#F7F2EA',
                        border: isVisited
                          ? `1px solid ${quest.accentColor}`
                          : '1px solid #E8DECF',
                        color: isVisited ? quest.accentColor : '#8F887F',
                        cursor: 'pointer',
                      }}
                    >
                      {isVisited ? '✓ ' : '○ '}
                      {stop.name}
                    </span>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
