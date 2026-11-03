import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebBreadVariety {
  id: 'obi_non' | 'patir' | 'shirmoy' | 'jizzali';
  name: string;
  priceUzs: number;
  tempCelsius: number;
  garnishes: string[];
  flavorDescription: string;
}

export interface WebChekichStamp {
  id: 'sunburst' | 'rosette' | 'octagon';
  name: string;
  pinCount: number;
  symbolism: string;
}

export interface WebTandoorBakery {
  id: string;
  name: string;
  district: string;
  headBaker: string;
  clayType: string;
  hotLoavesCount: number;
  nextBatchMinutes: number;
  varieties: WebBreadVariety[];
  favoriteChekich: WebChekichStamp;
}

export const CHEKICH_PATTERNS: WebChekichStamp[] = [
  {
    id: 'sunburst',
    name: 'Solar Sunburst (Quyosh Chekich)',
    pinCount: 36,
    symbolism: 'Radiant solar pin spokes reflecting ancient Central Asian sun motifs.',
  },
  {
    id: 'rosette',
    name: 'Eight-Petal Rosette (Gul Chekich)',
    pinCount: 48,
    symbolism: 'Botanical rosette geometry preventing uneven center ballooning in tandoor.',
  },
  {
    id: 'octagon',
    name: 'Timurid Octagram (Yulduz Chekich)',
    pinCount: 64,
    symbolism: 'Sacred architectural star constellation pressed into festive holiday patirs.',
  },
];

export const DEFAULT_BREAD_VARIETIES: WebBreadVariety[] = [
  {
    id: 'obi_non',
    name: 'Obi Non (Daily Sourdough)',
    priceUzs: 4000,
    tempCelsius: 280,
    garnishes: ['Black Nigella (Sedana)', 'Water Wash Glaze'],
    flavorDescription: 'Golden crust with crisp airy blistered rim and moist sour crumb.',
  },
  {
    id: 'patir',
    name: 'Qatlama Patir (Flaky Butter Crust)',
    priceUzs: 8000,
    tempCelsius: 300,
    garnishes: ['Cream & Lamb Tallow', 'Toasted Sesame', 'Nigella Seeds'],
    flavorDescription: 'Decadent flaky ceremonial bread with rich savory buttery crumb.',
  },
  {
    id: 'shirmoy',
    name: 'Shirmoy Non (Aniseed & Chickpea)',
    priceUzs: 12000,
    tempCelsius: 260,
    garnishes: ['Chickpea Yeast Broth', 'Wild Anise Infusion'],
    flavorDescription: 'Fragrant medicinal sweet bread with light digestive texture.',
  },
  {
    id: 'jizzali',
    name: 'Jizzali Non (Mutton Cracklings)',
    priceUzs: 10000,
    tempCelsius: 290,
    garnishes: ['Crispy Mutton Cracklings (Jizza)', 'Braised White Onion'],
    flavorDescription: 'Savory winter bread bursting with caramelized mutton richness.',
  },
];

export const DEFAULT_TANDOOR_BAKERIES: WebTandoorBakery[] = [
  {
    id: 'bakery-chorsu-kattabog',
    name: 'Chorsu Kattabog Tandoor Bakery',
    district: 'Old City Shaykhontohur',
    headBaker: 'Novvoyboshi Usto Shuhrat',
    clayType: 'Rishtan Ochre Refractory Clay',
    hotLoavesCount: 32,
    nextBatchMinutes: 6,
    varieties: [DEFAULT_BREAD_VARIETIES[0], DEFAULT_BREAD_VARIETIES[1]],
    favoriteChekich: CHEKICH_PATTERNS[0],
  },
  {
    id: 'bakery-chigatoy-shirmoy',
    name: 'Chigatoy Mahalla Shirmoy Guild',
    district: 'Almazar',
    headBaker: 'Usto Otabek Novvoy',
    clayType: 'Bukhara Silt & Straw Adobe Clay',
    hotLoavesCount: 18,
    nextBatchMinutes: 12,
    varieties: [DEFAULT_BREAD_VARIETIES[2], DEFAULT_BREAD_VARIETIES[0]],
    favoriteChekich: CHEKICH_PATTERNS[1],
  },
  {
    id: 'bakery-keles-jizzali',
    name: 'Keles Traditional Winter Tandoor',
    district: 'Olmazor North',
    headBaker: 'Usto Bahrom Novvoy',
    clayType: 'Gazgan Red Fireclay Tandoor',
    hotLoavesCount: 28,
    nextBatchMinutes: 4,
    varieties: [DEFAULT_BREAD_VARIETIES[3], DEFAULT_BREAD_VARIETIES[1]],
    favoriteChekich: CHEKICH_PATTERNS[2],
  },
];

/** Evaluates freshness tier based on minutes elapsed */
export function calculateFreshnessTier(minutes: number): { tier: string; isHot: boolean } {
  if (minutes <= 15) {
    return { tier: 'Piping Hot (Tandirdan uzilgan)', isHot: true };
  } else if (minutes <= 45) {
    return { tier: 'Warm & Fragrant (Iliq)', isHot: true };
  } else {
    return { tier: 'Ambient Fresh (Yangi)', isHot: false };
  }
}

/** Formats price in Uzbek Som with spaced thousands */
export function formatWebBreadPrice(price: number): string {
  const parts = price.toString().split('');
  const buffer: string[] = [];
  let count = 0;
  for (let i = parts.length - 1; i >= 0; i--) {
    buffer.unshift(parts[i]);
    count++;
    if (count % 3 === 0 && i !== 0) {
      buffer.unshift(' ');
    }
  }
  return `${buffer.join('')} UZS`;
}

/** Computes batch total cost */
export function calculateBatchTotalUzs(pricePerLoaf: number, count: number): number {
  return pricePerLoaf * Math.max(1, count);
}

/** Checks whether hot loaves are available now */
export function isHotBatchAvailable(bakery: WebTandoorBakery): boolean {
  return bakery.hotLoavesCount > 0;
}

/** Returns pattern pin count label */
export function getWebChekichPinLabel(patternId: string): string {
  const pattern = CHEKICH_PATTERNS.find((p) => p.id === patternId) || CHEKICH_PATTERNS[0];
  return `${pattern.pinCount} steel pins (${pattern.name.split(' ')[0]})`;
}

export interface WebTandoorBakeryViewerProps {
  bakeries?: WebTandoorBakery[];
  initialBakeryId?: string;
  onReserveBatch?: (bakeryId: string, varietyId: string, count: number) => void;
}

export const WebTandoorBakeryViewer: React.FC<WebTandoorBakeryViewerProps> = ({
  bakeries = DEFAULT_TANDOOR_BAKERIES,
  initialBakeryId,
  onReserveBatch,
}) => {
  const [selectedBakeryId, setSelectedBakeryId] = useState<string>(
    initialBakeryId || (bakeries.length > 0 ? bakeries[0].id : '')
  );
  const [selectedVarietyId, setSelectedVarietyId] = useState<string>('obi_non');
  const [loavesCount, setLoavesCount] = useState<number>(2);
  const [punctureCount, setPunctureCount] = useState<number>(1);
  const [reservedBakeryIds, setReservedBakeryIds] = useState<string[]>([]);

  const selectedBakery =
    bakeries.find((b) => b.id === selectedBakeryId) || bakeries[0];

  const selectedVariety =
    selectedBakery.varieties.find((v) => v.id === selectedVarietyId) ||
    selectedBakery.varieties[0] ||
    DEFAULT_BREAD_VARIETIES[0];

  const isReserved = reservedBakeryIds.includes(selectedBakery.id);
  const hasHotLoaves = isHotBatchAvailable(selectedBakery);
  const freshness = calculateFreshnessTier(5);
  const totalPrice = calculateBatchTotalUzs(selectedVariety.priceUzs, loavesCount);

  const handleSelectBakery = (id: string) => {
    setSelectedBakeryId(id);
    const bakery = bakeries.find((b) => b.id === id);
    if (bakery && bakery.varieties.length > 0) {
      setSelectedVarietyId(bakery.varieties[0].id);
    }
    playSoundWithHaptic('click');
  };

  const handleSelectVariety = (id: string) => {
    setSelectedVarietyId(id);
    playSoundWithHaptic('select');
  };

  const handleStampDough = () => {
    setPunctureCount((prev) => prev + 1);
    playSoundWithHaptic('pop');
  };

  const handleResetStamp = () => {
    setPunctureCount(1);
    playSoundWithHaptic('click');
  };

  const handleReserve = () => {
    if (isReserved || !hasHotLoaves) return;
    setReservedBakeryIds([...reservedBakeryIds, selectedBakery.id]);
    playSoundWithHaptic('trophy');
    if (onReserveBatch) {
      onReserveBatch(selectedBakery.id, selectedVariety.id, loavesCount);
    }
  };

  return (
    <div
      data-testid="web-tandoor-bakery-viewer"
      className="p-6 max-w-5xl mx-auto bg-stone-900 text-stone-100 rounded-3xl shadow-2xl border border-stone-800"
    >
      {/* Header and Telemetry */}
      <div className="flex flex-col md:flex-row md:items-center justify-between pb-6 border-b border-stone-800 gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 text-xs font-bold uppercase tracking-wider bg-orange-600/20 text-orange-400 border border-orange-500/30 rounded-full">
              Living Culinary Heritage
            </span>
            <span className="text-xs text-stone-400">Clay Tandoor Non Guild</span>
          </div>
          <h2 className="text-2xl md:text-3xl font-black tracking-tight text-white">
            Tashkent Tandoor Bakeries & Chekich Stamp Trail
          </h2>
        </div>

        {/* Tandoor Temperature & Status Stats */}
        <div className="flex items-center gap-4 bg-stone-800/80 px-4 py-2.5 rounded-2xl border border-stone-700/60">
          <div>
            <div className="text-[11px] font-bold tracking-wider uppercase text-stone-400">
              Oven Heat
            </div>
            <div className="text-xl font-black text-orange-400" data-testid="tandoor-heat-gauge">
              {selectedVariety.tempCelsius}°C
            </div>
          </div>
          <div className="h-8 w-px bg-stone-700" />
          <div>
            <div className="text-[11px] font-bold tracking-wider uppercase text-stone-400">
              Freshness
            </div>
            <div className="text-sm font-semibold text-emerald-400">
              {freshness.tier.split(' ')[0]} {freshness.tier.split(' ')[1]}
            </div>
          </div>
        </div>
      </div>

      {/* Bakery Tabs */}
      <div className="flex flex-wrap items-center gap-2 pt-6 pb-4">
        {bakeries.map((bakery) => {
          const isSelected = selectedBakery.id === bakery.id;
          const isBooked = reservedBakeryIds.includes(bakery.id);

          return (
            <button
              key={bakery.id}
              data-testid={`bakery-tab-${bakery.id}`}
              onClick={() => handleSelectBakery(bakery.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                isSelected
                  ? 'bg-orange-500 text-stone-950 shadow-md font-black'
                  : 'bg-stone-800 text-stone-300 hover:bg-stone-700'
              }`}
            >
              <span>{bakery.name.split(' ')[0]}</span>
              <span className="text-[10px] opacity-75">({bakery.district.split(' ')[0]})</span>
              {isBooked && <span className="text-emerald-300 text-xs font-bold">✓</span>}
            </button>
          );
        })}
      </div>

      {/* Main Grid: Chekich Stamping Tool + Bread Batch Reservation */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
        {/* Left Column: Chekich Bread Stamp Simulator */}
        <div className="lg:col-span-6 bg-stone-800/50 p-5 rounded-2xl border border-stone-700/80 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase tracking-wider text-orange-400">
                🪵 Sacred Chekich Pin Stamp
              </span>
              <span className="text-xs text-stone-400">{punctureCount} Centers Pierced</span>
            </div>

            <h3 className="text-lg font-bold text-white mb-1">
              {selectedBakery.favoriteChekich.name}
            </h3>
            <p className="text-xs text-stone-300 mb-4">
              {selectedBakery.favoriteChekich.symbolism}
            </p>

            {/* Simulated Raw Dough Disk with Chekich Center Stamp */}
            <div
              data-testid="chekich-dough-disk"
              className="p-8 rounded-full aspect-square max-w-[240px] mx-auto flex flex-col items-center justify-center text-center border-4 border-dashed transition-all duration-300 relative overflow-hidden"
              style={{
                backgroundColor: '#F7E7CE',
                borderColor: '#EA580C',
                color: '#161412',
                boxShadow: '0 10px 30px -10px rgba(234, 88, 12, 0.3)',
              }}
            >
              <div className="text-[10px] font-mono uppercase tracking-widest text-stone-600 mb-1">
                Raw Bread Dough (Toba)
              </div>
              <div className="text-2xl font-black text-orange-950 mb-1">
                {'✦ '.repeat(Math.min(5, punctureCount))}
              </div>
              <div className="text-[11px] text-stone-800 font-bold" data-testid="chekich-pins-label">
                {selectedBakery.favoriteChekich.pinCount} Steel Pins
              </div>
              <div className="text-[10px] text-stone-600 mt-1">
                Geometric Air Vent Pattern
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between gap-3 mt-6">
            <button
              data-testid="chekich-stamp-button"
              onClick={handleStampDough}
              className="flex-1 py-2.5 px-4 rounded-xl bg-orange-500 hover:bg-orange-400 text-stone-950 font-black text-xs shadow-lg transition-all active:scale-95 flex items-center justify-center gap-2"
            >
              <span>Stamp Center With Chekich (+1)</span>
            </button>
            <button
              data-testid="chekich-reset-button"
              onClick={handleResetStamp}
              className="py-2.5 px-3 rounded-xl bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs font-semibold"
            >
              Reset
            </button>
          </div>
        </div>

        {/* Right Column: Bakery Bread Varieties & Hot Loaves Reservation */}
        <div className="lg:col-span-6 bg-stone-800/50 p-5 rounded-2xl border border-stone-700/80 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase tracking-wider text-orange-400">
                🔥 Fresh Hot Tandoor Batch
              </span>
              <span className="text-xs text-emerald-400 font-semibold" data-testid="hot-loaves-stat">
                {selectedBakery.hotLoavesCount} Hot Loaves Ready
              </span>
            </div>

            <h3 className="text-lg font-bold text-white mb-1">
              {selectedBakery.name}
            </h3>
            <div className="text-xs text-stone-300 mb-3">
              Master Baker: <span className="text-orange-300 font-bold">{selectedBakery.headBaker}</span> •{' '}
              <span className="text-stone-400">{selectedBakery.clayType}</span>
            </div>

            {/* Bread Variety Selector Tabs */}
            <div className="flex flex-wrap gap-1.5 mb-3">
              {selectedBakery.varieties.map((variety) => {
                const isSelected = selectedVariety.id === variety.id;
                return (
                  <button
                    key={variety.id}
                    data-testid={`variety-tab-${variety.id}`}
                    onClick={() => handleSelectVariety(variety.id)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                      isSelected
                        ? 'bg-orange-400 text-stone-950 font-black'
                        : 'bg-stone-700 text-stone-300 hover:bg-stone-600'
                    }`}
                  >
                    {variety.name.split(' ')[0]}
                  </button>
                );
              })}
            </div>

            {/* Variety Flavor & Garnishes Card */}
            <div className="p-3.5 bg-stone-950 rounded-xl border border-stone-800 mb-4">
              <div className="flex items-center justify-between text-[11px] font-bold text-orange-400 uppercase tracking-wider mb-1">
                <span>{selectedVariety.name}</span>
                <span>{selectedVariety.tempCelsius}°C Woodfire</span>
              </div>
              <div className="text-xs text-stone-200 mb-2">
                {selectedVariety.flavorDescription}
              </div>
              <div className="flex flex-wrap gap-1">
                {selectedVariety.garnishes.map((garnish, idx) => (
                  <span
                    key={idx}
                    className="px-2 py-0.5 rounded bg-stone-800 text-[10px] text-stone-300 font-medium"
                  >
                    🌿 {garnish}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* Quantity Selector, Price & Reservation CTA */}
          <div className="pt-3 border-t border-stone-700/80 flex items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <button
                  data-testid="decrement-loaves"
                  onClick={() => setLoavesCount(Math.max(1, loavesCount - 1))}
                  className="w-6 h-6 rounded bg-stone-700 hover:bg-stone-600 text-xs font-bold flex items-center justify-center text-stone-200"
                >
                  -
                </button>
                <span className="text-sm font-black text-white" data-testid="loaves-count">
                  {loavesCount} Loaves
                </span>
                <button
                  data-testid="increment-loaves"
                  onClick={() => setLoavesCount(Math.min(10, loavesCount + 1))}
                  className="w-6 h-6 rounded bg-stone-700 hover:bg-stone-600 text-xs font-bold flex items-center justify-center text-stone-200"
                >
                  +
                </button>
              </div>
              <div className="text-base font-black text-orange-400" data-testid="total-price-tag">
                {formatWebBreadPrice(totalPrice)}
              </div>
            </div>

            <button
              data-testid="reserve-bread-batch-button"
              onClick={handleReserve}
              disabled={isReserved || !hasHotLoaves}
              className={`px-5 py-2.5 rounded-xl text-xs font-black transition-all flex items-center gap-2 ${
                isReserved
                  ? 'bg-emerald-600/30 text-emerald-300 border border-emerald-500/40 cursor-default'
                  : !hasHotLoaves
                  ? 'bg-stone-700 text-stone-400 cursor-not-allowed'
                  : 'bg-orange-500 hover:bg-orange-400 text-stone-950 shadow-lg active:scale-95'
              }`}
            >
              {isReserved ? (
                <>
                  <span>✓ Reserved</span>
                  <span className="text-[10px] opacity-80">(+30 XP)</span>
                </>
              ) : !hasHotLoaves ? (
                <span>Baking Next Batch</span>
              ) : (
                <>
                  <span>Reserve Hot Bread</span>
                  <span className="text-[10px] bg-stone-900/40 px-1.5 py-0.5 rounded">
                    +30 XP
                  </span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WebTandoorBakeryViewer;
