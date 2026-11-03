import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebMetroLine = 'chilanzar' | 'uzbekistan' | 'yunusabad';

export interface WebMetroStationInfo {
  id: string;
  name: string;
  line: WebMetroLine;
  district: string;
  motif: string;
  colorHex: string;
}

export const CANONICAL_WEB_METRO_STATIONS: WebMetroStationInfo[] = [
  // Chilanzar
  {
    id: 'mustaqillik_maydoni',
    name: 'Mustaqillik Maydoni',
    line: 'chilanzar',
    district: 'Yunusabad',
    motif: 'White Marble Sunburst',
    colorHex: '#E53935',
  },
  {
    id: 'amir_temur_xiyoboni',
    name: 'Amir Temur Xiyoboni',
    line: 'chilanzar',
    district: 'Mirabad',
    motif: 'Bronze Dome Ornament',
    colorHex: '#E53935',
  },
  {
    id: 'paxtakor',
    name: 'Paxtakor',
    line: 'chilanzar',
    district: 'Shaykhontohur',
    motif: 'Cotton Flower Ceramic',
    colorHex: '#E53935',
  },
  {
    id: 'novza',
    name: 'Novza',
    line: 'chilanzar',
    district: 'Chilanzar',
    motif: 'Terracotta Geometric Star',
    colorHex: '#E53935',
  },

  // Uzbekistan
  {
    id: 'kosmonavtlar',
    name: 'Kosmonavtlar',
    line: 'uzbekistan',
    district: 'Yakkasaray',
    motif: 'Cosmos Blue Medallion',
    colorHex: '#1E88E5',
  },
  {
    id: 'alisher_navoiy',
    name: 'Alisher Navoiy',
    line: 'uzbekistan',
    district: 'Shaykhontohur',
    motif: 'Turquoise Majolica Cupola',
    colorHex: '#1E88E5',
  },
  {
    id: 'chorsu',
    name: 'Chorsu',
    line: 'uzbekistan',
    district: 'Shaykhontohur',
    motif: 'Turquoise Bazaar Dome',
    colorHex: '#1E88E5',
  },
  {
    id: 'oybek',
    name: 'Oybek',
    line: 'uzbekistan',
    district: 'Mirabad',
    motif: 'Ceramic Poetry Seal',
    colorHex: '#1E88E5',
  },

  // Yunusabad
  {
    id: 'ming_urik',
    name: "Ming O'rik",
    line: 'yunusabad',
    district: 'Mirabad',
    motif: 'Ancient Citadel Apricot',
    colorHex: '#43A047',
  },
  {
    id: 'bodomzor',
    name: 'Bodomzor',
    line: 'yunusabad',
    district: 'Yunusabad',
    motif: 'Almond Blossom Glaze',
    colorHex: '#43A047',
  },
  {
    id: 'shahriston',
    name: 'Shahriston',
    line: 'yunusabad',
    district: 'Yunusabad',
    motif: 'Northern Citadel Wall',
    colorHex: '#43A047',
  },
  {
    id: 'yunus_rajabiy',
    name: 'Yunus Rajabiy',
    line: 'yunusabad',
    district: 'Mirabad',
    motif: 'Carved Sitora Columns',
    colorHex: '#43A047',
  },
];

export function calculateWebLineCompletion(
  line: WebMetroLine,
  claimedIds: string[],
): { count: number; total: number; pct: number } {
  const lineStations = CANONICAL_WEB_METRO_STATIONS.filter((s) => s.line === line);
  if (lineStations.length === 0) return { count: 0, total: 0, pct: 0 };

  const claimedSet = new Set(claimedIds);
  const count = lineStations.filter((s) => claimedSet.has(s.id)).length;
  const pct = Math.round((count / lineStations.length) * 100);

  return { count, total: lineStations.length, pct };
}

export function getWebLineColor(line: WebMetroLine): string {
  switch (line) {
    case 'chilanzar':
      return '#E53935';
    case 'uzbekistan':
      return '#1E88E5';
    case 'yunusabad':
      return '#43A047';
  }
}

export function getWebLineTitle(line: WebMetroLine, locale = 'en'): string {
  const lang = locale.toLowerCase();
  switch (line) {
    case 'chilanzar':
      return lang.startsWith('uz')
        ? 'Chilonzor yo‘li'
        : lang.startsWith('ru')
        ? 'Чиланзарская линия'
        : 'Chilanzar Line';
    case 'uzbekistan':
      return lang.startsWith('uz')
        ? 'O‘zbekiston yo‘li'
        : lang.startsWith('ru')
        ? 'Узбекистанская линия'
        : 'Uzbekistan Line';
    case 'yunusabad':
      return lang.startsWith('uz')
        ? 'Yunusobod yo‘li'
        : lang.startsWith('ru')
        ? 'Юнусабадская линия'
        : 'Yunusabad Line';
  }
}

export interface WebMetroStampShelfProps {
  claimedStationIds?: string[];
  locale?: string;
  onSelectStation?: (stationId: string) => void;
}

export const WebMetroStampShelf: React.FC<WebMetroStampShelfProps> = ({
  claimedStationIds = [],
  locale = 'en',
  onSelectStation,
}) => {
  const [activeLine, setActiveLine] = useState<WebMetroLine>('uzbekistan');
  const [inspectedId, setInspectedId] = useState<string | null>(null);

  const claimedSet = new Set(claimedStationIds);
  const stations = CANONICAL_WEB_METRO_STATIONS.filter((s) => s.line === activeLine);
  const completion = calculateWebLineCompletion(activeLine, claimedStationIds);
  const lineColor = getWebLineColor(activeLine);
  const lineTitle = getWebLineTitle(activeLine, locale);

  const handleLineChange = (line: WebMetroLine) => {
    playSoundWithHaptic('select');
    setActiveLine(line);
    setInspectedId(null);
  };

  const handleStationClick = (station: WebMetroStationInfo) => {
    const isClaimed = claimedSet.has(station.id);
    playSoundWithHaptic(isClaimed ? 'trophy' : 'click');
    setInspectedId(station.id);
    if (onSelectStation) onSelectStation(station.id);
  };

  return (
    <div
      data-testid="web-metro-stamp-shelf"
      style={{
        background: '#FFFDF9',
        borderRadius: 20,
        padding: 20,
        border: '1.5px solid rgba(22, 20, 18, 0.12)',
        boxShadow: '0 4px 18px rgba(22, 20, 18, 0.05)',
        fontFamily: 'Plus Jakarta Sans, sans-serif',
        maxWidth: 480,
        margin: '0 auto',
      }}
    >
      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: 16,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ fontSize: 20 }}>🚇</span>
          <span
            data-testid="shelf-title"
            style={{ fontWeight: 800, fontSize: 16, color: '#161412' }}
          >
            {locale.startsWith('uz')
              ? 'Metro Pasport Muhrlari'
              : locale.startsWith('ru')
              ? 'Печати Метро Ташкента'
              : 'Tashkent Metro Stamps'}
          </span>
        </div>
        <div
          data-testid="overall-stamps-badge"
          style={{
            background: '#F3ECE0',
            padding: '4px 10px',
            borderRadius: 12,
            fontSize: 12,
            fontWeight: 700,
            color: '#5A544C',
          }}
        >
          {claimedStationIds.length} / {CANONICAL_WEB_METRO_STATIONS.length}
        </div>
      </div>

      {/* Line Filter Tabs */}
      <div
        style={{
          display: 'flex',
          gap: 6,
          marginBottom: 14,
        }}
      >
        {(['chilanzar', 'uzbekistan', 'yunusabad'] as WebMetroLine[]).map((line) => {
          const isSelected = line === activeLine;
          const color = getWebLineColor(line);
          const title = getWebLineTitle(line, locale);

          return (
            <button
              key={line}
              type="button"
              data-testid={`metro-tab-${line}`}
              onClick={() => handleLineChange(line)}
              style={{
                flex: 1,
                padding: '8px 4px',
                borderRadius: 10,
                border: 'none',
                background: isSelected ? color : '#F3ECE0',
                color: isSelected ? '#FFFFFF' : '#5A544C',
                fontSize: 11.5,
                fontWeight: 700,
                cursor: 'pointer',
                textAlign: 'center',
                transition: 'all 0.15s ease',
              }}
            >
              {title.split(' ')[0]}
            </button>
          );
        })}
      </div>

      {/* Line Progress Bar */}
      <div
        data-testid="line-progress-banner"
        style={{
          background: `${lineColor}12`,
          border: `1px solid ${lineColor}33`,
          borderRadius: 12,
          padding: 10,
          marginBottom: 16,
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            marginBottom: 6,
            fontSize: 12,
            fontWeight: 700,
            color: lineColor,
          }}
        >
          <span data-testid="active-line-title">{lineTitle}</span>
          <span data-testid="line-completion-text">
            {completion.count}/{completion.total} ({completion.pct}%)
          </span>
        </div>
        <div
          style={{
            height: 6,
            borderRadius: 3,
            background: `${lineColor}26`,
            overflow: 'hidden',
          }}
        >
          <div
            style={{
              height: '100%',
              width: `${completion.pct}%`,
              background: lineColor,
              borderRadius: 3,
              transition: 'width 0.3s ease',
            }}
          />
        </div>
      </div>

      {/* Ceramic Seal Grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(2, 1fr)',
          gap: 10,
        }}
      >
        {stations.map((station) => {
          const isClaimed = claimedSet.has(station.id);
          const isInspected = inspectedId === station.id;

          return (
            <div
              key={station.id}
              data-testid={`stamp-card-${station.id}`}
              onClick={() => handleStationClick(station)}
              style={{
                background: isClaimed ? `${lineColor}0A` : '#F3ECE0',
                border: `1.5px solid ${
                  isInspected ? lineColor : isClaimed ? `${lineColor}55` : 'rgba(22, 20, 18, 0.12)'
                }`,
                borderRadius: 14,
                padding: 12,
                cursor: 'pointer',
                textAlign: 'center',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                transition: 'all 0.15s ease',
              }}
            >
              <div
                style={{
                  width: 38,
                  height: 38,
                  borderRadius: '50%',
                  background: isClaimed ? lineColor : 'rgba(22, 20, 18, 0.08)',
                  color: isClaimed ? '#FFFFFF' : '#8F887F',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 18,
                  marginBottom: 6,
                  border: isClaimed ? '2px dashed #FFFFFF' : 'none',
                }}
              >
                {isClaimed ? '🎖️' : '🔒'}
              </div>
              <div
                data-testid={`station-name-${station.id}`}
                style={{
                  fontSize: 12,
                  fontWeight: 700,
                  color: isClaimed ? '#161412' : '#8F887F',
                  marginBottom: 2,
                }}
              >
                {station.name}
              </div>
              <div
                style={{
                  fontSize: 10,
                  fontWeight: 500,
                  color: isClaimed ? lineColor : '#8F887F',
                }}
              >
                {isClaimed ? station.motif : '+25 XP Check-In'}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
