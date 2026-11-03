import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebRouteWaypoint {
  id: string;
  routeId: string;
  placeId: string;
  placeName: string;
  orderIndex: number;
  category: string;
  hint: string;
  xpAwarded: number;
}

export interface WebWaypointStatusItem {
  waypoint: WebRouteWaypoint;
  isVisited: boolean;
}

export interface WebRouteProgressSummary {
  routeId: string;
  routeName: string;
  district: string;
  totalWaypointsCount: number;
  visitedWaypointsCount: number;
  completionPercentage: number;
  isCompleted: boolean;
  nextTargetWaypoint?: WebRouteWaypoint;
  totalXpEarned: number;
  completionBonusXp: number;
  waypointsWithStatus: WebWaypointStatusItem[];
}

export function computeWebTrailProgress(
  routeId: string,
  routeName: string,
  district: string,
  waypoints: WebRouteWaypoint[],
  visitedPlaceIds: Set<string>,
  completionBonusXp = 50,
): WebRouteProgressSummary {
  if (!waypoints || waypoints.length === 0) {
    return {
      routeId,
      routeName,
      district,
      totalWaypointsCount: 0,
      visitedWaypointsCount: 0,
      completionPercentage: 0,
      isCompleted: false,
      totalXpEarned: 0,
      completionBonusXp,
      waypointsWithStatus: [],
    };
  }

  const sorted = [...waypoints].sort((a, b) => a.orderIndex - b.orderIndex);
  let visitedCount = 0;
  let totalXp = 0;
  let nextTarget: WebRouteWaypoint | undefined;

  const waypointsWithStatus: WebWaypointStatusItem[] = sorted.map((wp) => {
    const isVisited = visitedPlaceIds.has(wp.placeId);
    if (isVisited) {
      visitedCount++;
      totalXp += wp.xpAwarded;
    } else if (!nextTarget) {
      nextTarget = wp;
    }
    return { waypoint: wp, isVisited };
  });

  const isCompleted = visitedCount === sorted.length && sorted.length > 0;
  if (isCompleted) {
    totalXp += completionBonusXp;
  }

  const completionPercentage = sorted.length > 0 ? visitedCount / sorted.length : 0;

  return {
    routeId,
    routeName,
    district,
    totalWaypointsCount: sorted.length,
    visitedWaypointsCount: visitedCount,
    completionPercentage,
    isCompleted,
    nextTargetWaypoint: nextTarget,
    totalXpEarned: totalXp,
    completionBonusXp,
    waypointsWithStatus,
  };
}

export function formatWebTrailProgressTitle(
  summary: WebRouteProgressSummary,
  locale = 'en',
): string {
  const lang = locale.toLowerCase();

  if (summary.isCompleted) {
    if (lang.startsWith('uz')) return 'Marshrut yakunlandi! 🏆';
    if (lang.startsWith('ru')) return 'Маршрут пройден! 🏆';
    return 'Route completed! 🏆';
  }

  if (lang.startsWith('uz')) {
    return `${summary.totalWaypointsCount} tadan ${summary.visitedWaypointsCount} ta bekat bajarildi`;
  } else if (lang.startsWith('ru')) {
    return `Пройдено ${summary.visitedWaypointsCount} из ${summary.totalWaypointsCount} остановок`;
  }
  return `${summary.visitedWaypointsCount} of ${summary.totalWaypointsCount} stops completed`;
}

export interface WebTrailProgressStepperProps {
  summary: WebRouteProgressSummary;
  locale?: string;
  onWaypointClick?: (waypoint: WebRouteWaypoint) => void;
}

export const WebTrailProgressStepper: React.FC<WebTrailProgressStepperProps> = ({
  summary,
  locale = 'en',
  onWaypointClick,
}) => {
  const handleWaypointClick = (wp: WebRouteWaypoint) => {
    playSoundWithHaptic('select');
    if (onWaypointClick) {
      onWaypointClick(wp);
    }
  };

  const progressTitle = formatWebTrailProgressTitle(summary, locale);
  const percentageInt = Math.round(summary.completionPercentage * 100);

  return (
    <div className="w-full max-w-xl mx-auto p-5 rounded-2xl bg-white dark:bg-stone-900 border border-stone-200 dark:border-stone-800 shadow-sm">
      {/* Header */}
      <div className="flex items-start justify-between gap-3 pb-3 border-b border-stone-100 dark:border-stone-800">
        <div>
          <h2 className="text-base font-black text-stone-900 dark:text-stone-100">
            {summary.routeName}
          </h2>
          <p className="text-xs font-semibold text-stone-500 dark:text-stone-400 mt-0.5">
            {summary.district} • {progressTitle}
          </p>
        </div>

        <div className="px-2.5 py-1 rounded-lg bg-orange-50 dark:bg-orange-950/40 border border-orange-200 dark:border-orange-800 text-xs font-black text-orange-600 dark:text-orange-400 shrink-0">
          +{summary.totalXpEarned} XP
        </div>
      </div>

      {/* Progress Bar */}
      <div className="mt-3 w-full bg-stone-100 dark:bg-stone-800 h-2 rounded-full overflow-hidden">
        <div
          className={`h-full transition-all duration-500 ${
            summary.isCompleted ? 'bg-emerald-500' : 'bg-orange-500'
          }`}
          style={{ width: `${percentageInt}%` }}
        />
      </div>

      {/* Checkpoints Stepper */}
      <div className="mt-5 space-y-3">
        {summary.waypointsWithStatus.map((item, idx) => {
          const isLast = idx === summary.waypointsWithStatus.length - 1;
          const isNextTarget = summary.nextTargetWaypoint?.id === item.waypoint.id;

          return (
            <div
              key={item.waypoint.id}
              data-testid={`trail-waypoint-item-${item.waypoint.id}`}
              onClick={() => handleWaypointClick(item.waypoint)}
              className="flex items-start gap-3 cursor-pointer group"
            >
              {/* Node indicator */}
              <div className="flex flex-col items-center">
                <div
                  className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-black transition-transform group-hover:scale-110 ${
                    item.isVisited
                      ? 'bg-emerald-500 text-white'
                      : isNextTarget
                      ? 'bg-orange-500 text-white ring-4 ring-orange-100 dark:ring-orange-900/40'
                      : 'border-2 border-stone-300 dark:border-stone-600 text-stone-400'
                  }`}
                >
                  {item.isVisited ? '✓' : idx + 1}
                </div>
                {!isLast && (
                  <div
                    className={`w-0.5 h-6 mt-1 ${
                      item.isVisited
                        ? 'bg-emerald-500'
                        : 'bg-stone-200 dark:bg-stone-700'
                    }`}
                  />
                )}
              </div>

              {/* Waypoint metadata */}
              <div className="flex-1 pb-1">
                <div className="flex items-center justify-between">
                  <span
                    className={`text-xs font-bold ${
                      item.isVisited
                        ? 'text-stone-900 dark:text-stone-100'
                        : isNextTarget
                        ? 'text-orange-600 dark:text-orange-400 font-black'
                        : 'text-stone-500 dark:text-stone-400'
                    }`}
                  >
                    {item.waypoint.placeName}
                  </span>
                  <span className="text-[10px] font-bold text-stone-400 dark:text-stone-500">
                    +{item.waypoint.xpAwarded} XP
                  </span>
                </div>
                <p className="text-[11px] text-stone-500 dark:text-stone-400 mt-0.5">
                  {item.waypoint.category} • {item.waypoint.hint}
                </p>
              </div>
            </div>
          );
        })}
      </div>

      {/* Completion Banner */}
      {summary.isCompleted && (
        <div className="mt-4 p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 flex items-center gap-2">
          <span className="text-lg">🏆</span>
          <span className="text-xs font-bold text-emerald-800 dark:text-emerald-300">
            {locale.startsWith('uz')
              ? `Tabriklaymiz! Marshrut to'liq bajarildi (+${summary.completionBonusXp} bonus XP)`
              : locale.startsWith('ru')
              ? `Поздравляем! Маршрут завершен (+${summary.completionBonusXp} бонусных XP)`
              : `Route Completed! +${summary.completionBonusXp} Bonus XP Awarded`}
          </span>
        </div>
      )}
    </div>
  );
};
