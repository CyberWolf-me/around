import React, { useState } from 'react';
import { buildPassportUrl } from '../router';
import { triggerTelegramHaptic, getTelegramWebApp } from '../services/telegramWebApp';

export interface PassportShareOptions {
  username: string;
  fullName: string;
  archetype?: string;
  totalDrops?: number;
  favoriteDistrict?: string;
  streakWeeks?: number;
  baseUrl?: string;
}

export function buildPassportShareCopy(options: PassportShareOptions): string {
  const { fullName, archetype = 'Urban Explorer', totalDrops = 0, favoriteDistrict = 'Tashkent', streakWeeks } = options;
  const lines: string[] = [
    `🗺️ Check out ${fullName}'s Taste Passport on Around!`,
    `📍 Top Neighborhood: ${favoriteDistrict}`,
    `☕ Archetype: ${archetype}`,
    `✨ Verified Drops: ${totalDrops}`,
  ];

  if (streakWeeks && streakWeeks > 0) {
    lines.push(`🔥 Discovery Streak: ${streakWeeks} weeks`);
  }

  lines.push('', 'Explore trusted local places discovered by friends in Tashkent:');
  return lines.join('\n');
}

export function generateTelegramShareUrl(options: PassportShareOptions): string {
  const passportUrl = buildPassportUrl(options.username, options.baseUrl);
  const text = buildPassportShareCopy(options);
  return `https://t.me/share/url?url=${encodeURIComponent(passportUrl)}&text=${encodeURIComponent(text)}`;
}

export function generateTelegramDirectMsgUrl(options: PassportShareOptions): string {
  const passportUrl = buildPassportUrl(options.username, options.baseUrl);
  const text = buildPassportShareCopy(options);
  return `tg://msg_url?url=${encodeURIComponent(passportUrl)}&text=${encodeURIComponent(text)}`;
}

export interface PassportShareModalProps extends PassportShareOptions {
  isOpen: boolean;
  onClose: () => void;
  onShareSuccess?: () => void;
}

export const PassportShareModal: React.FC<PassportShareModalProps> = ({
  isOpen,
  onClose,
  username,
  fullName,
  archetype = 'Urban Explorer',
  totalDrops = 0,
  favoriteDistrict = 'Mirabad',
  streakWeeks,
  baseUrl,
  onShareSuccess,
}) => {
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const passportUrl = buildPassportUrl(username, baseUrl);
  const shareUrl = generateTelegramShareUrl({
    username,
    fullName,
    archetype,
    totalDrops,
    favoriteDistrict,
    streakWeeks,
    baseUrl,
  });

  const handleCopyLink = async () => {
    triggerTelegramHaptic('selection');
    try {
      if (typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(passportUrl);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      // Fallback
    }
  };

  const handleShareTelegram = () => {
    triggerTelegramHaptic('medium');
    const webApp = getTelegramWebApp();

    if (webApp && typeof (webApp as any).openTelegramLink === 'function') {
      try {
        (webApp as any).openTelegramLink(shareUrl);
        onShareSuccess?.call(null);
        return;
      } catch {
        // Fallback to window.open
      }
    }

    if (typeof window !== 'undefined') {
      window.open(shareUrl, '_blank');
      onShareSuccess?.call(null);
    }
  };

  const initials = fullName
    .split(' ')
    .map((n) => n[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in"
      data-testid="passport-share-modal-backdrop"
      onClick={onClose}
    >
      <div
        className="w-full max-w-sm rounded-3xl bg-[#FAF7F2] p-6 shadow-2xl border border-[#161412]/10"
        data-testid="passport-share-modal"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-[#161412]/8">
          <div className="flex items-center gap-3">
            <div className="flex items-center justify-center w-11 h-11 rounded-full bg-[#FF4800]/10 text-[#FF4800] font-bold text-base border border-[#FF4800]/25">
              {initials}
            </div>
            <div>
              <h3 className="font-bold text-[#161412] text-base leading-tight">{fullName}</h3>
              <p className="text-xs text-[#8F887F] font-mono">@{username}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-[#F3ECE0] flex items-center justify-center text-[#5A544C] hover:text-[#161412]"
            aria-label="Close modal"
          >
            ✕
          </button>
        </div>

        {/* Passport Preview Stats */}
        <div className="grid grid-cols-2 gap-2 my-4">
          <div className="p-3 rounded-2xl bg-[#F3ECE0] border border-[#161412]/6">
            <span className="block text-[10px] font-mono font-semibold uppercase text-[#8F887F]">
              Archetype
            </span>
            <span className="font-bold text-xs text-[#161412] truncate block mt-0.5">
              {archetype}
            </span>
          </div>

          <div className="p-3 rounded-2xl bg-[#F3ECE0] border border-[#161412]/6">
            <span className="block text-[10px] font-mono font-semibold uppercase text-[#8F887F]">
              Top District
            </span>
            <span className="font-bold text-xs text-[#161412] truncate block mt-0.5">
              {favoriteDistrict}
            </span>
          </div>

          <div className="p-3 rounded-2xl bg-[#F3ECE0] border border-[#161412]/6">
            <span className="block text-[10px] font-mono font-semibold uppercase text-[#8F887F]">
              Drops
            </span>
            <span className="font-bold text-xs text-[#161412] block mt-0.5">
              {totalDrops} verified
            </span>
          </div>

          <div className="p-3 rounded-2xl bg-[#F3ECE0] border border-[#161412]/6">
            <span className="block text-[10px] font-mono font-semibold uppercase text-[#8F887F]">
              Streak
            </span>
            <span className="font-bold text-xs text-[#FF4800] block mt-0.5">
              {streakWeeks && streakWeeks > 0 ? `🔥 ${streakWeeks} wks` : 'New Curator'}
            </span>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="space-y-2 mt-4">
          <button
            onClick={handleShareTelegram}
            className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-2xl bg-[#FF4800] text-white font-bold text-sm shadow-md hover:bg-[#e03f00] transition-colors"
            data-testid="share-telegram-btn"
          >
            <span>✈️ Share via Telegram</span>
          </button>

          <button
            onClick={handleCopyLink}
            className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-2xl bg-[#F3ECE0] text-[#161412] font-semibold text-xs border border-[#161412]/10 hover:bg-[#E8DECF] transition-colors"
            data-testid="copy-link-btn"
          >
            <span>{copied ? '✓ Copied to Clipboard!' : '📋 Copy Passport Link'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
