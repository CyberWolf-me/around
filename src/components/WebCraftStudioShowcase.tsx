import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebGlazePalette {
  id: string;
  name: string;
  hexColor: string;
  mineralSource: string;
  symbolicMeaning: string;
}

export interface WebCraftMasterclass {
  id: string;
  title: string;
  durationMinutes: number;
  skillLevel: string;
  maxSeats: number;
  reservedSeats: number;
  priceUzs: number;
  timeSlot: string;
}

export interface WebCraftStudio {
  id: string;
  title: string;
  district: string;
  discipline: string;
  masterName: string;
  masterTitle: string;
  accentColor: string;
  glazes: WebGlazePalette[];
  masterclasses: WebCraftMasterclass[];
}

export const DEFAULT_CRAFT_STUDIOS: WebCraftStudio[] = [
  {
    id: 'studio-rishtan-ceramics',
    title: 'Rishtan Blue Glaze Pottery House',
    district: 'Shaykhontohur',
    discipline: 'Ceramics',
    masterName: 'Usto Alisher Nazirov',
    masterTitle: '7th Generation Rishtan Ceramicist',
    accentColor: '#2563EB',
    glazes: [
      {
        id: 'glaze-ishkor-turquoise',
        name: 'Turquoise Ishkor',
        hexColor: '#00D2FC',
        mineralSource: 'Ishkor Herbal Ash & Desert Silica',
        symbolicMeaning: 'Purity, fertility & flowing oasis springs',
      },
      {
        id: 'glaze-cobalt-ultramarine',
        name: 'Cobalt Ultramarine',
        hexColor: '#2563EB',
        mineralSource: 'Natural Cobalt Oxide Mineral',
        symbolicMeaning: 'Celestial vault, eternal sky & protection',
      },
      {
        id: 'glaze-ochre-saffron',
        name: 'Saffron Ochre',
        hexColor: '#FFD666',
        mineralSource: 'Chatkal River Clay Sediment',
        symbolicMeaning: 'Harvest warmth, hospitality & sunlight',
      },
    ],
    masterclasses: [
      {
        id: 'class-kickwheel-pottery',
        title: 'Foot-Powered Kickwheel Pitcher Throwing',
        durationMinutes: 90,
        skillLevel: 'Beginner',
        maxSeats: 6,
        reservedSeats: 4,
        priceUzs: 180000,
        timeSlot: '11:00 - 12:30',
      },
      {
        id: 'class-ishkor-glaze',
        title: 'Rishtan Turquoise Ishkor Glaze Painting',
        durationMinutes: 120,
        skillLevel: 'Intermediate',
        maxSeats: 5,
        reservedSeats: 5, // Full
        priceUzs: 220000,
        timeSlot: '15:00 - 17:00',
      },
    ],
  },
  {
    id: 'studio-chorsu-woodcarving',
    title: 'Chorsu Walnut Woodcarving Atelier',
    district: 'Old City Chorsu',
    discipline: 'Woodcarving',
    masterName: 'Usto Nematullo Khaydarov',
    masterTitle: 'Master of Central Asian Floral Islimi',
    accentColor: '#FF4800',
    glazes: [
      {
        id: 'glaze-walnut-natural',
        name: 'Aura of Mountain Walnut',
        hexColor: '#8C532B',
        mineralSource: 'Centennial Fergana Walnut Core',
        symbolicMeaning: 'Longevity, wisdom & ancestral roots',
      },
      {
        id: 'glaze-beeswax-golden',
        name: 'Wild Beeswax Lustre',
        hexColor: '#E6A147',
        mineralSource: 'Tian Shan Wild Blossom Honey Wax',
        symbolicMeaning: 'Natural breath & preservation against arid desert winds',
      },
    ],
    masterclasses: [
      {
        id: 'class-laukh-folding-stand',
        title: 'Carving a Seamless Single-Piece Laukh Bookstand',
        durationMinutes: 120,
        skillLevel: 'Intermediate',
        maxSeats: 4,
        reservedSeats: 2,
        priceUzs: 250000,
        timeSlot: '14:00 - 16:00',
      },
    ],
  },
];

export function calculateAvailableSeats(mc: WebCraftMasterclass): number {
  return Math.max(0, mc.maxSeats - mc.reservedSeats);
}

export function isMasterclassFull(mc: WebCraftMasterclass): boolean {
  return mc.reservedSeats >= mc.maxSeats;
}

export function formatWebPriceUzs(priceUzs: number): string {
  const str = priceUzs.toString();
  const parts: string[] = [];
  let count = 0;
  for (let i = str.length - 1; i >= 0; i--) {
    parts.unshift(str[i]);
    count++;
    if (count % 3 === 0 && i !== 0) {
      parts.unshift(' ');
    }
  }
  return `${parts.join('')} UZS`;
}

export function getWebReservationStatus(
  isReserved: boolean,
  isFull: boolean,
  locale = 'en'
): string {
  const lang = locale.toLowerCase();
  if (isReserved) {
    if (lang.startsWith('uz')) return 'Band qilingan (+40 XP)';
    if (lang.startsWith('ru')) return 'Забронировано (+40 XP)';
    return 'Reserved (+40 XP)';
  }
  if (isFull) {
    if (lang.startsWith('uz')) return 'Barcha joylar band';
    if (lang.startsWith('ru')) return 'Все места заняты';
    return 'Fully Booked';
  }
  if (lang.startsWith('uz')) return 'Joyni band qilish';
  if (lang.startsWith('ru')) return 'Забронировать место';
  return 'Reserve Seat';
}

export function filterStudiosByDiscipline(
  studios: WebCraftStudio[],
  discipline: string
): WebCraftStudio[] {
  if (!discipline || discipline.toLowerCase() === 'all') {
    return studios;
  }
  return studios.filter((s) => s.discipline.toLowerCase() === discipline.toLowerCase());
}

export interface WebCraftStudioShowcaseProps {
  initialStudioId?: string;
  locale?: string;
  onReservationComplete?: (studioId: string, masterclassId: string) => void;
}

export const WebCraftStudioShowcase: React.FC<WebCraftStudioShowcaseProps> = ({
  initialStudioId = 'studio-rishtan-ceramics',
  locale = 'en',
  onReservationComplete,
}) => {
  const [selectedStudioId, setSelectedStudioId] = useState<string>(initialStudioId);
  const [selectedGlazeId, setSelectedGlazeId] = useState<string | null>(null);
  const [reservedClassId, setReservedClassId] = useState<string | null>(null);

  const currentStudio =
    DEFAULT_CRAFT_STUDIOS.find((s) => s.id === selectedStudioId) || DEFAULT_CRAFT_STUDIOS[0];
  const activeGlaze =
    currentStudio.glazes.find((g) => g.id === selectedGlazeId) || currentStudio.glazes[0];

  const handleGlazeClick = (glaze: WebGlazePalette) => {
    setSelectedGlazeId(glaze.id);
    playSoundWithHaptic('select');
  };

  const handleReserve = (masterclass: WebCraftMasterclass) => {
    if (isMasterclassFull(masterclass) && reservedClassId !== masterclass.id) {
      return;
    }
    setReservedClassId(masterclass.id);
    playSoundWithHaptic('success');
    onReservationComplete?.(currentStudio.id, masterclass.id);
  };

  return (
    <div
      data-testid="craft-studio-showcase"
      className="p-5 rounded-3xl bg-[#FFFDF9] border border-[#28161412] shadow-xl text-[#161412] max-w-lg w-full"
    >
      {/* Studio Selector Tabs */}
      <div className="flex items-center gap-2 mb-4 overflow-x-auto pb-1">
        {DEFAULT_CRAFT_STUDIOS.map((studio) => {
          const isSelected = studio.id === currentStudio.id;
          return (
            <button
              key={studio.id}
              data-testid={`studio-tab-${studio.id}`}
              onClick={() => {
                setSelectedStudioId(studio.id);
                setSelectedGlazeId(null);
                playSoundWithHaptic('select');
              }}
              className="px-3 py-1 rounded-xl text-xs font-bold border transition-all"
              style={{
                backgroundColor: isSelected ? `${studio.accentColor}1A` : '#FAF7F2',
                borderColor: isSelected ? studio.accentColor : '#18161412',
                color: isSelected ? studio.accentColor : '#5A544C',
              }}
            >
              {studio.discipline}
            </button>
          );
        })}
      </div>

      {/* Studio Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span
              className="px-2 py-0.5 rounded-md text-[10px] font-black uppercase tracking-wider"
              style={{
                backgroundColor: `${currentStudio.accentColor}1A`,
                color: currentStudio.accentColor,
              }}
            >
              {currentStudio.discipline}
            </span>
            <span className="px-2 py-0.5 rounded-md bg-[#F3ECE0] text-[10px] font-bold text-[#5A544C]">
              {currentStudio.district}
            </span>
          </div>
          <h3 className="font-extrabold text-lg tracking-tight text-[#161412]">
            {currentStudio.title}
          </h3>
          <p className="text-xs text-[#8F887F] font-medium">
            {currentStudio.masterName} • {currentStudio.masterTitle}
          </p>
        </div>

        {/* Pottery Wheel Badge Icon */}
        <div
          className="w-12 h-12 rounded-2xl flex items-center justify-center border border-[#18161412]"
          style={{
            backgroundColor: `${currentStudio.accentColor}15`,
            color: currentStudio.accentColor,
          }}
        >
          <svg className="w-6 h-6 animate-spin-slow" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <circle cx="12" cy="12" r="9" strokeWidth="2" strokeDasharray="4 2" />
            <circle cx="12" cy="12" r="3" strokeWidth="2" />
          </svg>
        </div>
      </div>

      {/* Mineral Glaze Palette Inspector */}
      <div className="p-3.5 rounded-2xl bg-[#FAF7F2] border border-[#18161412] mb-4">
        <span className="text-[10px] uppercase font-bold tracking-wider text-[#8F887F] block mb-2">
          Mineral Glaze Palette & Natural Media
        </span>

        <div className="flex items-center gap-2 mb-3">
          {currentStudio.glazes.map((glaze) => {
            const isSelected = activeGlaze?.id === glaze.id;
            return (
              <button
                key={glaze.id}
                data-testid={`glaze-swatch-${glaze.id}`}
                onClick={() => handleGlazeClick(glaze)}
                className="w-8 h-8 rounded-full border-2 transition-transform active:scale-95 shadow-sm"
                style={{
                  backgroundColor: glaze.hexColor,
                  borderColor: isSelected ? '#161412' : '#FFFFFF',
                  transform: isSelected ? 'scale(1.15)' : 'scale(1)',
                }}
                aria-label={glaze.name}
              />
            );
          })}
        </div>

        {activeGlaze && (
          <div className="text-xs">
            <div className="flex items-center gap-2 mb-0.5">
              <span className="font-extrabold text-[#161412]">{activeGlaze.name}</span>
              <span className="font-mono text-[10px] text-[#8F887F]">{activeGlaze.mineralSource}</span>
            </div>
            <p className="text-[#5A544C] italic text-[11px]">"{activeGlaze.symbolicMeaning}"</p>
          </div>
        )}
      </div>

      {/* Masterclass Schedule & RSVP List */}
      <div className="space-y-3">
        {currentStudio.masterclasses.map((mc) => {
          const isReserved = reservedClassId === mc.id;
          const isFull = isMasterclassFull(mc) && !isReserved;
          const statusText = getWebReservationStatus(isReserved, isFull, locale);
          const available = calculateAvailableSeats(mc);

          return (
            <div
              key={mc.id}
              data-testid={`masterclass-card-${mc.id}`}
              className="p-3 rounded-2xl border transition-all"
              style={{
                backgroundColor: isReserved ? `${currentStudio.accentColor}0C` : '#FAF7F2',
                borderColor: isReserved ? currentStudio.accentColor : '#18161412',
              }}
            >
              <div className="flex items-start justify-between mb-1.5">
                <div>
                  <h4 className="font-bold text-xs text-[#161412]">{mc.title}</h4>
                  <p className="text-[11px] text-[#8F887F] font-mono">
                    {mc.timeSlot} • {mc.durationMinutes} min
                  </p>
                </div>
                <span className="px-1.5 py-0.5 rounded bg-[#FF48001F] text-[#FF4800] text-[10px] font-black font-mono">
                  +40 XP
                </span>
              </div>

              <div className="flex items-center justify-between mt-2 pt-2 border-t border-[#1816140D]">
                <div>
                  <span className="font-mono font-extrabold text-xs text-[#161412]">
                    {formatWebPriceUzs(mc.priceUzs)}
                  </span>
                  <span className="text-[10px] text-[#8F887F] ml-2">
                    {isFull ? 'Sold Out' : `${available} seats left`}
                  </span>
                </div>

                <button
                  data-testid={`reserve-btn-${mc.id}`}
                  onClick={() => handleReserve(mc)}
                  disabled={isFull}
                  className="px-3 py-1.5 rounded-xl text-xs font-bold transition-all active:scale-95 shadow-sm"
                  style={{
                    backgroundColor: isReserved
                      ? currentStudio.accentColor
                      : isFull
                      ? '#F3ECE0'
                      : '#161412',
                    color: isFull ? '#8F887F' : '#FFFFFF',
                    cursor: isFull ? 'not-allowed' : 'pointer',
                  }}
                >
                  {statusText}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
