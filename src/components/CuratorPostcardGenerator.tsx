import React from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export type WebPostcardTheme = 'paper' | 'carbon' | 'mint';
export type WebPostcardAspectRatio = '1:1' | '9:16';

export interface WebCuratorPostcard {
  placeId: string;
  placeName: string;
  district: string;
  atmosphereTag: string;
  verifiedSeal: string;
  nearestSubway: string;
  curatorName: string;
  curatorHandle: string;
  curatorTier: string;
  curatorXp: number;
  receiptNumber: string;
  theme?: WebPostcardTheme;
  aspectRatio?: WebPostcardAspectRatio;
}

export function generateWebReceiptNumber(district: string = 'Mirabad'): string {
  const clean = district.toUpperCase().replace(/[^A-Z]/g, '');
  const prefix = clean.length >= 3 ? clean.substring(0, 3) : 'TAS';
  return `REC-${prefix}-2026-774`;
}

export function getWebPostcardThemeStyles(theme: WebPostcardTheme) {
  switch (theme) {
    case 'carbon':
      return {
        bg: '#1C1A18',
        text: '#FFFFFF',
        muted: '#99948D',
        border: '#332E29',
        pillBg: '#2A2622',
        sealColor: '#FF5A1F',
      };
    case 'mint':
      return {
        bg: '#EAF7F2',
        text: '#0D3326',
        muted: '#3C6B5B',
        border: '#C1E6D8',
        pillBg: '#D5F0E5',
        sealColor: '#0E7A53',
      };
    case 'paper':
    default:
      return {
        bg: '#FFFDF9',
        text: '#161412',
        muted: '#7A7369',
        border: '#E8DECF',
        pillBg: '#F3ECE0',
        sealColor: '#FF5A1F',
      };
  }
}

export interface CuratorPostcardGeneratorProps {
  postcard: WebCuratorPostcard;
  onShare?: (postcard: WebCuratorPostcard) => void;
  language?: 'en' | 'uz' | 'ru';
}

export const CuratorPostcardGenerator: React.FC<CuratorPostcardGeneratorProps> = ({
  postcard: initialPostcard,
  onShare,
  language = 'en',
}) => {
  const [theme, setTheme] = React.useState<WebPostcardTheme>(initialPostcard.theme || 'paper');
  const [aspectRatio, setAspectRatio] = React.useState<WebPostcardAspectRatio>(
    initialPostcard.aspectRatio || '9:16'
  );

  const themeStyles = React.useMemo(() => getWebPostcardThemeStyles(theme), [theme]);

  const handleThemeChange = (newTheme: WebPostcardTheme) => {
    playSoundWithHaptic('select');
    setTheme(newTheme);
  };

  const handleRatioChange = (newRatio: WebPostcardAspectRatio) => {
    playSoundWithHaptic('select');
    setAspectRatio(newRatio);
  };

  const handleShareClick = () => {
    playSoundWithHaptic('success');
    onShare?.({
      ...initialPostcard,
      theme,
      aspectRatio,
    });
  };

  const t = {
    header:
      language === 'uz'
        ? 'TOSHKENT MADANIY CHEKI & KARTA'
        : language === 'ru'
        ? 'ТАШКЕНТСКИЙ КУЛЬТУРНЫЙ ЧЕК'
        : 'TASHKENT CULTURAL RECEIPT',
    share:
      language === 'uz'
        ? 'Telegramga Ulashish'
        : language === 'ru'
        ? 'Поделиться в Telegram'
        : 'Share to Telegram',
    verified:
      language === 'uz' ? 'TASDIQLANGAN' : language === 'ru' ? 'ПРОВЕРЕНО' : 'VERIFIED VISIT',
  };

  return (
    <div
      data-testid="curator-postcard-generator"
      style={{
        background: '#141414',
        borderRadius: 16,
        padding: 20,
        color: '#FFFFFF',
        border: '1px solid #2A2A2A',
        fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, sans-serif',
      }}
    >
      {/* Top Ratio & Theme Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        {/* Theme Pills */}
        <div style={{ display: 'flex', gap: 6 }}>
          {(['paper', 'carbon', 'mint'] as WebPostcardTheme[]).map((thm) => (
            <button
              key={thm}
              data-testid={`theme-btn-${thm}`}
              onClick={() => handleThemeChange(thm)}
              style={{
                background: theme === thm ? '#FF5A1F' : '#222222',
                color: theme === thm ? '#FFFFFF' : '#888888',
                border: '1px solid #333333',
                borderRadius: 6,
                padding: '4px 10px',
                fontSize: 11,
                fontWeight: 700,
                cursor: 'pointer',
                textTransform: 'capitalize',
              }}
            >
              {thm}
            </button>
          ))}
        </div>

        {/* Aspect Ratio Switcher */}
        <div style={{ display: 'flex', gap: 6 }}>
          {(['9:16', '1:1'] as WebPostcardAspectRatio[]).map((r) => (
            <button
              key={r}
              data-testid={`ratio-btn-${r.replace(':', '-')}`}
              onClick={() => handleRatioChange(r)}
              style={{
                background: aspectRatio === r ? '#FF5A1F' : '#222222',
                color: aspectRatio === r ? '#FFFFFF' : '#888888',
                border: '1px solid #333333',
                borderRadius: 6,
                padding: '4px 10px',
                fontSize: 11,
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              {r}
            </button>
          ))}
        </div>
      </div>

      {/* Postcard Body Preview */}
      <div
        data-testid="postcard-preview-card"
        style={{
          background: themeStyles.bg,
          color: themeStyles.text,
          borderRadius: 14,
          padding: 20,
          border: `1.5px solid ${themeStyles.border}`,
          marginBottom: 16,
          transition: 'all 0.2s ease',
        }}
      >
        {/* Receipt Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, fontWeight: 700, color: themeStyles.muted, marginBottom: 14 }}>
          <span>{t.header}</span>
          <span style={{ fontFamily: 'monospace' }}>{initialPostcard.receiptNumber}</span>
        </div>

        {/* Venue Title & Seal Stamp */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
          <div>
            <h3 style={{ margin: 0, fontSize: 18, fontWeight: 800, color: themeStyles.text }}>
              {initialPostcard.placeName}
            </h3>
            <div style={{ fontSize: 11, fontWeight: 700, color: themeStyles.sealColor, marginTop: 4 }}>
              {initialPostcard.district.toUpperCase()} · {initialPostcard.atmosphereTag}
            </div>
          </div>
          {/* Verified Seal */}
          <div
            style={{
              padding: '6px 8px',
              borderRadius: 8,
              border: `1.5px solid ${themeStyles.sealColor}`,
              background: themeStyles.pillBg,
              textAlign: 'center',
            }}
          >
            <div style={{ fontSize: 10, fontWeight: 800, color: themeStyles.sealColor }}>✓ SEAL</div>
            <div style={{ fontSize: 9, fontFamily: 'monospace', fontWeight: 700, color: themeStyles.sealColor }}>
              {initialPostcard.verifiedSeal}
            </div>
          </div>
        </div>

        {/* Transit Beacon */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '6px 10px',
            background: themeStyles.pillBg,
            borderRadius: 8,
            fontSize: 11,
            marginBottom: 14,
          }}
        >
          <span>🚇 {initialPostcard.nearestSubway}</span>
          <span style={{ fontSize: 9, fontWeight: 700, letterSpacing: '0.08em', color: themeStyles.muted }}>
            {t.verified}
          </span>
        </div>

        {/* Curator Signature */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div
              style={{
                width: 28,
                height: 28,
                borderRadius: 14,
                background: '#FF5A1F',
                color: '#FFFFFF',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 12,
                fontWeight: 800,
              }}
            >
              {initialPostcard.curatorName.substring(0, 1).toUpperCase()}
            </div>
            <div>
              <div style={{ fontSize: 12, fontWeight: 700, color: themeStyles.text }}>{initialPostcard.curatorName}</div>
              <div style={{ fontSize: 10, color: themeStyles.muted }}>
                @{initialPostcard.curatorHandle} · {initialPostcard.curatorTier}
              </div>
            </div>
          </div>
          <span
            style={{
              fontSize: 11,
              fontWeight: 800,
              padding: '2px 8px',
              borderRadius: 6,
              background: 'rgba(255, 90, 31, 0.15)',
              color: '#FF5A1F',
            }}
          >
            {initialPostcard.curatorXp} XP
          </span>
        </div>

        {/* Simulated Barcode */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 2, height: 16, opacity: 0.6 }}>
          {Array.from({ length: 36 }).map((_, i) => (
            <div
              key={i}
              style={{
                width: i % 4 === 0 ? 3 : 1.5,
                height: '100%',
                background: themeStyles.text,
              }}
            />
          ))}
        </div>
      </div>

      {/* Share Button */}
      <button
        data-testid="share-postcard-btn"
        onClick={handleShareClick}
        style={{
          width: '100%',
          padding: '12px',
          borderRadius: 10,
          border: 'none',
          background: '#FF5A1F',
          color: '#FFFFFF',
          fontSize: 13,
          fontWeight: 700,
          cursor: 'pointer',
        }}
      >
        ✈️ {t.share}
      </button>
    </div>
  );
};
