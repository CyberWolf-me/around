import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebTeaBlend {
  id: string;
  name: string;
  type: string;
  tempCelsius: number;
  steepSeconds: number;
  botanicals: string[];
  flavor: string;
}

export interface WebChaykhanaVenue {
  id: string;
  name: string;
  district: string;
  masterName: string;
  accentColor: string;
  availableTapchans: number;
  totalTapchans: number;
  samovarYear: string;
  blends: WebTeaBlend[];
}

export const DEFAULT_CHAYKHANA_VENUES: WebChaykhanaVenue[] = [
  {
    id: 'chaykhana-chorsu-chinor',
    name: 'Chorsu Chinor Chaykhana',
    district: 'Old City Shaykhontohur',
    masterName: 'Usto Bobomurod Choychi',
    accentColor: '#059669',
    availableTapchans: 4,
    totalTapchans: 12,
    samovarYear: 'Charcoal Brass Samovar (1924)',
    blends: [
      {
        id: 'blend-kok-choy',
        name: 'Old City Kok-Choy No. 95',
        type: 'Green',
        tempCelsius: 85,
        steepSeconds: 180,
        botanicals: ['Spring Green Leaf', 'Dried Mountain Thyme', 'Wild Mint'],
        flavor: 'Crisp & Grassy',
      },
      {
        id: 'blend-zafaron',
        name: 'Poytaxt Royal Saffron Amber',
        type: 'Saffron',
        tempCelsius: 92,
        steepSeconds: 240,
        botanicals: ['Red Saffron Stigmas', 'Dried Quince Blossoms', 'Ceylon Black Tip'],
        flavor: 'Honeyed Saffron & Spice',
      },
    ],
  },
  {
    id: 'chaykhana-ankhor-terrace',
    name: 'Ankhor Embankment Riverbed Chaykhana',
    district: 'Yakkasaray',
    masterName: 'Otabek Mirzo',
    accentColor: '#00D2FC',
    availableTapchans: 2,
    totalTapchans: 8,
    samovarYear: 'Tsarist Imperial Brass Samovar (1898)',
    blends: [
      {
        id: 'blend-pomegranate-hibiscus',
        name: 'Canal Willow Pomegranate Infusion',
        type: 'Herbal',
        tempCelsius: 95,
        steepSeconds: 300,
        botanicals: ['Pomegranate Peel', 'Hibiscus Calyces', 'Cardamom Pods'],
        flavor: 'Tart Ruby Fruit & Spice',
      },
    ],
  },
];

export function calculateKaytarishAeration(step: number): {
  percent: number;
  stageName: string;
  description: string;
} {
  switch (step) {
    case 1:
      return {
        percent: 33,
        stageName: 'Loy (Mud)',
        description: 'First pour wakes dry botanicals and draws initial dust; returned to pot.',
      };
    case 2:
      return {
        percent: 66,
        stageName: 'Moy (Oil)',
        description: 'Second pour dissolves shimmering essential oils and sweet wildflower aromatics.',
      };
    case 3:
    default:
      return {
        percent: 100,
        stageName: 'Choy (Tea)',
        description: 'Third pour yields crystal liquid amber. Serve to guests with right hand on heart.',
      };
  }
}

export function formatBrewDuration(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs < 10 ? '0' : ''}${secs} min`;
}

export function getWebTapchanLabel(available: number, total: number, locale = 'en'): string {
  const lang = locale.toLowerCase();
  if (available <= 0) {
    if (lang.startsWith('uz')) return 'Barcha tapchanlar band';
    if (lang.startsWith('ru')) return 'Все тапчаны заняты';
    return 'All Tapchans Full';
  }
  if (lang.startsWith('uz')) return `${available} ta tapchan bo'sh (jami ${total})`;
  if (lang.startsWith('ru')) return `${available} тапчанов свободно (из ${total})`;
  return `${available} tapchans free (of ${total})`;
}

export function getWebKaytarishProverb(locale = 'en'): string {
  const lang = locale.toLowerCase();
  if (lang.startsWith('uz')) return 'Birinchi loy, ikkinchi moy, uchinchi choy';
  if (lang.startsWith('ru')) return 'Первая — глина, вторая — масло, третья — чай';
  return 'First is mud, second is oil, third is tea';
}

export function isTapchanAvailable(venue: WebChaykhanaVenue): boolean {
  return venue.availableTapchans > 0;
}

export interface WebChaykhanaBrewBarProps {
  initialVenueId?: string;
  locale?: string;
  onGatheringReserved?: (venueId: string, blendId: string) => void;
}

export const WebChaykhanaBrewBar: React.FC<WebChaykhanaBrewBarProps> = ({
  initialVenueId = 'chaykhana-chorsu-chinor',
  locale = 'en',
  onGatheringReserved,
}) => {
  const [selectedVenueId, setSelectedVenueId] = useState<string>(initialVenueId);
  const [activeStep, setActiveStep] = useState<number>(1);
  const [isReserved, setIsReserved] = useState<boolean>(false);

  const currentVenue =
    DEFAULT_CHAYKHANA_VENUES.find((v) => v.id === selectedVenueId) || DEFAULT_CHAYKHANA_VENUES[0];
  const [selectedBlendId, setSelectedBlendId] = useState<string>(
    currentVenue.blends[0]?.id || 'blend-kok-choy'
  );

  const selectedBlend =
    currentVenue.blends.find((b) => b.id === selectedBlendId) || currentVenue.blends[0];
  const aeration = calculateKaytarishAeration(activeStep);
  const proverb = getWebKaytarishProverb(locale);
  const tapchanLabel = getWebTapchanLabel(currentVenue.availableTapchans, currentVenue.totalTapchans, locale);

  const handleStepClick = (step: number) => {
    setActiveStep(step);
    playSoundWithHaptic('select');
  };

  const handleBlendClick = (blend: WebTeaBlend) => {
    setSelectedBlendId(blend.id);
    playSoundWithHaptic('select');
  };

  const handleReserve = () => {
    if (!isTapchanAvailable(currentVenue) && !isReserved) return;
    setIsReserved(true);
    playSoundWithHaptic('success');
    onGatheringReserved?.(currentVenue.id, selectedBlend.id);
  };

  return (
    <div
      data-testid="chaykhana-brew-bar"
      className="p-5 rounded-3xl bg-[#FFFDF9] border border-[#28161412] shadow-xl text-[#161412] max-w-lg w-full"
    >
      {/* Venue Switcher Tabs */}
      <div className="flex items-center gap-2 mb-4 overflow-x-auto pb-1">
        {DEFAULT_CHAYKHANA_VENUES.map((venue) => {
          const isSelected = venue.id === currentVenue.id;
          return (
            <button
              key={venue.id}
              data-testid={`venue-tab-${venue.id}`}
              onClick={() => {
                setSelectedVenueId(venue.id);
                setSelectedBlendId(venue.blends[0]?.id || '');
                setIsReserved(false);
                playSoundWithHaptic('select');
              }}
              className="px-3 py-1 rounded-xl text-xs font-bold border transition-all"
              style={{
                backgroundColor: isSelected ? `${venue.accentColor}1A` : '#FAF7F2',
                borderColor: isSelected ? venue.accentColor : '#18161412',
                color: isSelected ? venue.accentColor : '#5A544C',
              }}
            >
              {venue.district}
            </button>
          );
        })}
      </div>

      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span
              className="px-2 py-0.5 rounded-md text-[10px] font-black uppercase tracking-wider"
              style={{
                backgroundColor: `${currentVenue.accentColor}1A`,
                color: currentVenue.accentColor,
              }}
            >
              CHAYKHANA
            </span>
            <span className="px-2 py-0.5 rounded-md bg-[#F3ECE0] text-[10px] font-bold text-[#5A544C]">
              {currentVenue.district}
            </span>
          </div>
          <h3 className="font-extrabold text-lg tracking-tight text-[#161412]">
            {currentVenue.name}
          </h3>
          <p className="text-xs text-[#8F887F] font-medium">
            {currentVenue.masterName} • {currentVenue.samovarYear}
          </p>
        </div>

        {/* Samovar Kettle Icon */}
        <div
          className="w-12 h-12 rounded-2xl flex items-center justify-center border border-[#18161412]"
          style={{
            backgroundColor: `${currentVenue.accentColor}15`,
            color: currentVenue.accentColor,
          }}
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 100-6 3 3 0 000 6z"
            />
          </svg>
        </div>
      </div>

      {/* Tapchan Availability Bar */}
      <div className="p-3 rounded-2xl bg-[#FAF7F2] border border-[#18161412] mb-4 flex items-center justify-between text-xs">
        <div className="flex items-center gap-2">
          <span
            className="w-2 h-2 rounded-full"
            style={{
              backgroundColor: isTapchanAvailable(currentVenue) ? '#059669' : '#8F887F',
            }}
          />
          <span className="font-bold text-[#161412]">{tapchanLabel}</span>
        </div>
        <span className="text-[11px] text-[#5A544C] font-mono">Traditional Rishtan Pialahs</span>
      </div>

      {/* 3-Step Kaytarish Aerator */}
      <div className="p-4 rounded-2xl bg-[#FAF7F2] border border-[#18161412] mb-4">
        <div className="flex items-center justify-between mb-2">
          <span className="text-[11px] font-black uppercase tracking-wider text-[#161412]">
            3-Step Kaytarish Aeration
          </span>
          <span
            data-testid="aeration-percent-badge"
            className="text-xs font-mono font-bold"
            style={{ color: currentVenue.accentColor }}
          >
            {aeration.percent}% Oxygenated
          </span>
        </div>

        {/* Step Buttons */}
        <div className="grid grid-cols-3 gap-2 mb-3">
          {[1, 2, 3].map((step) => {
            const isSelected = activeStep === step;
            const stepData = calculateKaytarishAeration(step);
            return (
              <button
                key={step}
                data-testid={`kaytarish-step-btn-${step}`}
                onClick={() => handleStepClick(step)}
                className="py-1.5 px-2 rounded-xl text-xs font-bold border transition-all text-center"
                style={{
                  backgroundColor: isSelected ? currentVenue.accentColor : '#FFFDF9',
                  borderColor: isSelected ? currentVenue.accentColor : '#18161412',
                  color: isSelected ? '#FFFFFF' : '#161412',
                }}
              >
                {step}. {stepData.stageName}
              </button>
            );
          })}
        </div>

        {/* Active Stage Description */}
        <p className="text-xs text-[#5A544C] mb-2 leading-relaxed">
          {aeration.description}
        </p>

        {/* Folk Proverb Banner */}
        <div className="p-2 rounded-xl bg-[#FFFDF9] border border-[#1816140D] flex items-center gap-2">
          <span className="text-sm">🍵</span>
          <span className="text-[11px] italic text-[#8F887F] font-medium">{proverb}</span>
        </div>
      </div>

      {/* Signature Tea Blends */}
      <div className="mb-4">
        <span className="text-[11px] font-black uppercase tracking-wider text-[#8F887F] block mb-2">
          Signature Teas
        </span>
        <div className="space-y-2">
          {currentVenue.blends.map((blend) => {
            const isSelected = selectedBlend.id === blend.id;
            return (
              <div
                key={blend.id}
                data-testid={`blend-card-${blend.id}`}
                onClick={() => handleBlendClick(blend)}
                className="p-3 rounded-2xl border transition-all cursor-pointer"
                style={{
                  backgroundColor: isSelected ? `${currentVenue.accentColor}0C` : '#FAF7F2',
                  borderColor: isSelected ? currentVenue.accentColor : '#18161412',
                }}
              >
                <div className="flex items-center justify-between mb-1">
                  <span className="font-extrabold text-xs text-[#161412]">{blend.name}</span>
                  <span className="font-mono text-[10px] text-[#5A544C] bg-[#F3ECE0] px-2 py-0.5 rounded-md">
                    {blend.tempCelsius}°C • {formatBrewDuration(blend.steepSeconds)}
                  </span>
                </div>
                <p className="text-[11px] text-[#8F887F]">{blend.flavor}</p>
                <div className="flex flex-wrap gap-1 mt-1.5">
                  {blend.botanicals.map((bot, i) => (
                    <span
                      key={i}
                      className="px-1.5 py-0.5 rounded bg-[#FFFDF9] border border-[#1816140A] text-[9px] font-medium text-[#5A544C]"
                    >
                      {bot}
                    </span>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Reservation CTA Button */}
      <button
        data-testid="reserve-tapchan-btn"
        onClick={handleReserve}
        disabled={!isTapchanAvailable(currentVenue) && !isReserved}
        className="w-full py-3 rounded-2xl text-xs font-bold transition-all active:scale-95 shadow-md flex items-center justify-center gap-2"
        style={{
          backgroundColor: isReserved
            ? currentVenue.accentColor
            : isTapchanAvailable(currentVenue)
            ? '#161412'
            : '#F3ECE0',
          color: isTapchanAvailable(currentVenue) || isReserved ? '#FFFFFF' : '#8F887F',
          cursor: isTapchanAvailable(currentVenue) || isReserved ? 'pointer' : 'not-allowed',
        }}
      >
        <span>
          {isReserved
            ? 'Tapchan Reserved (+35 XP)'
            : isTapchanAvailable(currentVenue)
            ? 'Host Tapchan Gathering (+35 XP)'
            : 'All Tapchans Full'}
        </span>
      </button>
    </div>
  );
};
