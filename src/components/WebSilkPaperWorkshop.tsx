import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebPaperStage {
  step: number;
  name: string;
  durationHours: number;
  technique: string;
  icon: string;
  description: string;
}

export interface WebCalligraphyScript {
  id: 'nastaliq' | 'thuluth' | 'kufic' | 'diwani';
  name: string;
  origin: string;
  verseSnippet: string;
  proverbEn: string;
  proverbUz: string;
}

export interface WebSilkAtelier {
  id: string;
  name: string;
  district: string;
  master: string;
  priceUzs: number;
  availableSeats: number;
  maxSeats: number;
  mulberrySpecies: string;
  burnishStone: string;
}

export const PAPER_CRAFT_STAGES: WebPaperStage[] = [
  {
    step: 1,
    name: 'Bark Soaking & Peeling',
    durationHours: 12,
    technique: 'Running mountain stream phloem extraction',
    icon: '🌿',
    description: 'Fresh mulberry branches stripped of outer brown rind to expose the tender white inner cambium fibers.',
  },
  {
    step: 2,
    name: 'Watermill Wooden Mashing',
    durationHours: 8,
    technique: 'Hydraulic stone and wooden objuvoz pestles',
    icon: '🪵',
    description: 'Fibers rhythmically crushed for eight continuous hours until transformed into fine, pliable cellulose pulp.',
  },
  {
    step: 3,
    name: 'Silk Sieve Framing & Sun Dewatering',
    durationHours: 24,
    technique: 'Woven horsehair and silk mesh deckle scooping',
    icon: '☀️',
    description: 'Pulp scooped into water vats, pressed between wooden platen screws, and adhered to sunlit mud-brick drying walls.',
  },
  {
    step: 4,
    name: 'Agate Stone Mirror Burnishing',
    durationHours: 1,
    technique: 'Natural Kyzylkum red agate and bull horn polishing',
    icon: '💎',
    description: 'Dry parchment hand-burnished against polished marble tables until an impenetrable glass-like sheen is achieved.',
  },
];

export const CALLIGRAPHY_SCRIPTS: WebCalligraphyScript[] = [
  {
    id: 'nastaliq',
    name: "Nasta'liq (Bride's Script)",
    origin: 'Timurid Herat & Tashkent Chanceries',
    verseSnippet: 'Qalbingni qalam qil, siyohni mehr (Alisher Navoiy)',
    proverbEn: 'Make thy heart the reed pen, and thy ink sheer kindness',
    proverbUz: 'Qalbingni qalam qil, siyohni mehr',
  },
  {
    id: 'thuluth',
    name: 'Thuluth (Monumental Cursive)',
    origin: 'Samarkand Madrasahs & Registan Portals',
    verseSnippet: 'Ilm izla beshikdan qabrgacha',
    proverbEn: 'Seek knowledge from the cradle to the grave',
    proverbUz: 'Ilm izla beshikdan qabrgacha',
  },
  {
    id: 'kufic',
    name: 'Kufic (Geometric Archaic)',
    origin: '9th-Century Samanid Vellum Epistles',
    verseSnippet: 'Baraka halollikdadir',
    proverbEn: 'Abundance abides only within honesty',
    proverbUz: 'Baraka halollikdadir',
  },
  {
    id: 'diwani',
    name: 'Diwani (Imperial Chancery)',
    origin: 'Royal Tashkent & Bukhara Emirs Court',
    verseSnippet: 'Adolat davlatning poydevoridir',
    proverbEn: 'Justice is the eternal foundation of sovereign governance',
    proverbUz: 'Adolat davlatning poydevoridir',
  },
];

export const DEFAULT_SILK_ATELIERS: WebSilkAtelier[] = [
  {
    id: 'atelier-chorsu-mulberry',
    name: 'Chorsu Silk Paper & Manuscript Guild',
    district: 'Old City Shaykhontohur',
    master: "Usto Mirzo Bobo Qog'ozchi",
    priceUzs: 150000,
    availableSeats: 4,
    maxSeats: 8,
    mulberrySpecies: 'White Mulberry (Morus Alba)',
    burnishStone: 'Kyzylkum Red Agate Stone (Aqiq)',
  },
  {
    id: 'atelier-hast-imam-calligraphy',
    name: 'Hast Imam Holy Scripture & Vellum Atelier',
    district: 'Almazar',
    master: 'Usto Abdulaziz Mansur Calligrapher',
    priceUzs: 180000,
    availableSeats: 2,
    maxSeats: 6,
    mulberrySpecies: 'Black Mulberry (Morus Nigra)',
    burnishStone: 'Mountain Chalcedony & Horn Burnisher',
  },
  {
    id: 'atelier-navoiy-literature',
    name: 'Navoiy Literary Manuscript & Diwani Atelier',
    district: 'Mirabad',
    master: 'Usto Dilshodbek Khattot',
    priceUzs: 140000,
    availableSeats: 5,
    maxSeats: 10,
    mulberrySpecies: 'Wild Pskem River Mulberry',
    burnishStone: 'Polished Riverbed Jasper',
  },
];

/** Evaluates agate stone burnishing smoothness and luster grade */
export function calculatePaperSmoothness(passes: number): { percent: number; grade: string } {
  if (passes <= 0) return { percent: 0, grade: 'Raw Matte Parchment' };
  if (passes >= 30) return { percent: 100, grade: 'Mirror Glass Sheen (Imperial Grade)' };

  const percent = Math.min(100, Math.round((passes / 30) * 100));
  let grade = 'Slightly Textured';
  if (percent >= 75) {
    grade = 'Lustrous Silk Vellum';
  } else if (percent >= 45) {
    grade = 'Semi-Smooth Calligraphy Surface';
  }
  return { percent, grade };
}

/** Formats Uzbek Som with spaced thousands separators */
export function formatWebAtelierPrice(price: number): string {
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

/** Checks whether seats remain in the atelier */
export function isAtelierSeatAvailable(atelier: WebSilkAtelier): boolean {
  return atelier.availableSeats > 0;
}

/** Returns localized script proverb */
export function getWebScriptProverb(scriptId: string, langCode: string): string {
  const script = CALLIGRAPHY_SCRIPTS.find((s) => s.id === scriptId) || CALLIGRAPHY_SCRIPTS[0];
  return langCode.toLowerCase() === 'uz' ? script.proverbUz : script.proverbEn;
}

/** Sums hours across all papercraft stages */
export function calculateCumulativeHours(stages: WebPaperStage[]): number {
  return stages.reduce((sum, stage) => sum + stage.durationHours, 0);
}

export interface WebSilkPaperWorkshopProps {
  ateliers?: WebSilkAtelier[];
  initialAtelierId?: string;
  onReserveWorkshop?: (atelierId: string, scriptId: string) => void;
}

export const WebSilkPaperWorkshop: React.FC<WebSilkPaperWorkshopProps> = ({
  ateliers = DEFAULT_SILK_ATELIERS,
  initialAtelierId,
  onReserveWorkshop,
}) => {
  const [selectedAtelierId, setSelectedAtelierId] = useState<string>(
    initialAtelierId || (ateliers.length > 0 ? ateliers[0].id : '')
  );
  const [activeStageStep, setActiveStageStep] = useState<number>(4);
  const [selectedScriptId, setSelectedScriptId] = useState<'nastaliq' | 'thuluth' | 'kufic' | 'diwani'>('nastaliq');
  const [burnishPasses, setBurnishPasses] = useState<number>(18);
  const [reservedAtelierIds, setReservedAtelierIds] = useState<string[]>([]);

  const selectedAtelier =
    ateliers.find((a) => a.id === selectedAtelierId) || ateliers[0];

  const activeStage =
    PAPER_CRAFT_STAGES.find((s) => s.step === activeStageStep) || PAPER_CRAFT_STAGES[3];

  const selectedScript =
    CALLIGRAPHY_SCRIPTS.find((s) => s.id === selectedScriptId) || CALLIGRAPHY_SCRIPTS[0];

  const smoothness = calculatePaperSmoothness(burnishPasses);
  const totalHours = calculateCumulativeHours(PAPER_CRAFT_STAGES);
  const isReserved = reservedAtelierIds.includes(selectedAtelier?.id || '');

  const handleSelectAtelier = (id: string) => {
    setSelectedAtelierId(id);
    playSoundWithHaptic('click');
  };

  const handleSelectScript = (id: 'nastaliq' | 'thuluth' | 'kufic' | 'diwani') => {
    setSelectedScriptId(id);
    playSoundWithHaptic('select');
  };

  const handleBurnishClick = () => {
    setBurnishPasses((prev) => Math.min(35, prev + 5));
    playSoundWithHaptic('pop');
  };

  const handleResetBurnish = () => {
    setBurnishPasses(5);
    playSoundWithHaptic('click');
  };

  const handleReserve = () => {
    if (!selectedAtelier || isReserved || !isAtelierSeatAvailable(selectedAtelier)) return;
    setReservedAtelierIds([...reservedAtelierIds, selectedAtelier.id]);
    playSoundWithHaptic('trophy');
    if (onReserveWorkshop) {
      onReserveWorkshop(selectedAtelier.id, selectedScript.id);
    }
  };

  return (
    <div
      data-testid="web-silk-paper-workshop"
      className="p-6 max-w-5xl mx-auto bg-stone-900 text-stone-100 rounded-3xl shadow-2xl border border-stone-800"
    >
      {/* Header and Telemetry */}
      <div className="flex flex-col md:flex-row md:items-center justify-between pb-6 border-b border-stone-800 gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 text-xs font-bold uppercase tracking-wider bg-amber-600/20 text-amber-400 border border-amber-500/30 rounded-full">
              Living Manuscript Heritage
            </span>
            <span className="text-xs text-stone-400">Mulberry Silk Paper & Calligraphy Guild</span>
          </div>
          <h2 className="text-2xl md:text-3xl font-black tracking-tight text-white">
            Tashkent Silk Paper & Calligraphy Atelier
          </h2>
        </div>

        {/* Papercraft Stats Pill */}
        <div className="flex items-center gap-4 bg-stone-800/80 px-4 py-2.5 rounded-2xl border border-stone-700/60">
          <div>
            <div className="text-[11px] font-bold tracking-wider uppercase text-stone-400">
              Craft Duration
            </div>
            <div className="text-xl font-black text-amber-400" data-testid="craft-duration-stat">
              {totalHours} Hours
            </div>
          </div>
          <div className="h-8 w-px bg-stone-700" />
          <div>
            <div className="text-[11px] font-bold tracking-wider uppercase text-stone-400">
              Durability
            </div>
            <div className="text-sm font-semibold text-emerald-400">1,000+ Years</div>
          </div>
        </div>
      </div>

      {/* Atelier Tabs */}
      <div className="flex flex-wrap items-center gap-2 pt-6 pb-4">
        {ateliers.map((atelier) => {
          const isSelected = selectedAtelier?.id === atelier.id;
          const isBooked = reservedAtelierIds.includes(atelier.id);

          return (
            <button
              key={atelier.id}
              data-testid={`atelier-tab-${atelier.id}`}
              onClick={() => handleSelectAtelier(atelier.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                isSelected
                  ? 'bg-amber-500 text-stone-950 shadow-md font-black'
                  : 'bg-stone-800 text-stone-300 hover:bg-stone-700'
              }`}
            >
              <span>{atelier.name.split(' ')[0]}</span>
              <span className="text-[10px] opacity-75">({atelier.district.split(' ')[0]})</span>
              {isBooked && <span className="text-emerald-300 text-xs font-bold">✓</span>}
            </button>
          );
        })}
      </div>

      {/* 4-Stage Craft Timeline Scrubber */}
      <div className="bg-stone-950 p-4 rounded-2xl border border-stone-800 mb-6">
        <div className="flex items-center justify-between mb-3 text-xs text-stone-400 font-semibold">
          <span>Traditional 4-Stage Silk Paper Process</span>
          <span className="text-amber-400">Stage {activeStage.step} of 4: {activeStage.durationHours}h</span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
          {PAPER_CRAFT_STAGES.map((stage) => {
            const isCurrent = activeStage.step === stage.step;
            return (
              <button
                key={stage.step}
                data-testid={`stage-step-${stage.step}`}
                onClick={() => {
                  setActiveStageStep(stage.step);
                  playSoundWithHaptic('click');
                }}
                className={`p-3 rounded-xl text-left transition-all border ${
                  isCurrent
                    ? 'bg-stone-800 border-amber-500/80 shadow-md'
                    : 'bg-stone-900/60 border-stone-800 hover:border-stone-700 text-stone-400'
                }`}
              >
                <div className="text-base mb-1">{stage.icon}</div>
                <div className={`text-xs font-bold mb-0.5 ${isCurrent ? 'text-amber-400' : 'text-stone-300'}`}>
                  {stage.step}. {stage.name.split(' ')[0]}
                </div>
                <div className="text-[10px] text-stone-400">{stage.durationHours} Hours</div>
              </button>
            );
          })}
        </div>

        <div className="mt-3 p-3 bg-stone-900/80 rounded-xl text-xs text-stone-300 border border-stone-800/80">
          <span className="font-bold text-amber-300">{activeStage.name}: </span>
          {activeStage.description}
        </div>
      </div>

      {/* Interactive Main Section: Agate Burnishing Simulator + Script Calligraphy Showcase */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Agate Burnishing Touch Simulator */}
        <div className="lg:col-span-6 bg-stone-800/50 p-5 rounded-2xl border border-stone-700/80 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-400">
                💎 Stage 4: Agate Stone Burnishing
              </span>
              <span className="text-xs text-stone-400">{burnishPasses} Stone Strokes</span>
            </div>

            <h3 className="text-lg font-bold text-white mb-1">
              Natural Agate Glass Burnisher
            </h3>
            <p className="text-xs text-stone-300 mb-4">
              Rubbing the dried mulberry sheet with polished stone seals the cellulose pores,
              preventing ink bleeding and ensuring thousand-year archival quality.
            </p>

            {/* Simulated Paper Texture Face */}
            <div
              data-testid="burnish-preview-face"
              className="p-6 rounded-2xl text-center border transition-all duration-300 relative overflow-hidden"
              style={{
                backgroundColor: '#FAF5EA',
                color: '#161412',
                borderColor: smoothness.percent >= 75 ? '#D97706' : '#D1D5DB',
                boxShadow: smoothness.percent >= 75 ? '0 10px 25px -5px rgba(217, 119, 6, 0.2)' : 'none',
              }}
            >
              <div className="text-[11px] font-mono uppercase tracking-widest text-stone-500 mb-1">
                Mulberry Vellum Surface
              </div>
              <div className="text-base font-black text-stone-900 mb-1" data-testid="smoothness-grade">
                {smoothness.grade}
              </div>
              <div className="text-xs text-stone-700 font-semibold">
                Mirror Smoothness: {smoothness.percent}%
              </div>

              {/* Progress bar */}
              <div className="w-full bg-stone-300 h-2 rounded-full mt-3 overflow-hidden">
                <div
                  className="bg-amber-600 h-full transition-all duration-300"
                  style={{ width: `${smoothness.percent}%` }}
                />
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between gap-3 mt-4">
            <button
              data-testid="burnish-stroke-button"
              onClick={handleBurnishClick}
              className="flex-1 py-2.5 px-4 rounded-xl bg-amber-500 hover:bg-amber-400 text-stone-950 font-black text-xs shadow-lg transition-all active:scale-95 flex items-center justify-center gap-2"
            >
              <span>Rub With Agate (+5 Strokes)</span>
            </button>
            <button
              data-testid="burnish-reset-button"
              onClick={handleResetBurnish}
              className="py-2.5 px-3 rounded-xl bg-stone-700 hover:bg-stone-600 text-stone-200 text-xs font-semibold"
            >
              Reset
            </button>
          </div>
        </div>

        {/* Right Column: Calligraphy Script Selector & Atelier Booking */}
        <div className="lg:col-span-6 bg-stone-800/50 p-5 rounded-2xl border border-stone-700/80 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-400">
                ✒️ Script & Masterclass
              </span>
              <span className="text-xs text-emerald-400 font-semibold">
                {selectedAtelier.availableSeats} of {selectedAtelier.maxSeats} Seats Open
              </span>
            </div>

            <h3 className="text-lg font-bold text-white mb-2">
              {selectedAtelier.name}
            </h3>
            <div className="text-xs text-stone-300 mb-3">
              Master: <span className="text-amber-300 font-bold">{selectedAtelier.master}</span> •{' '}
              <span className="text-stone-400">{selectedAtelier.mulberrySpecies}</span>
            </div>

            {/* Script Selector Tabs */}
            <div className="flex flex-wrap gap-1.5 mb-3">
              {CALLIGRAPHY_SCRIPTS.map((script) => {
                const isSelected = selectedScript.id === script.id;
                return (
                  <button
                    key={script.id}
                    data-testid={`script-tab-${script.id}`}
                    onClick={() => handleSelectScript(script.id)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                      isSelected
                        ? 'bg-amber-400 text-stone-950 font-black'
                        : 'bg-stone-700 text-stone-300 hover:bg-stone-600'
                    }`}
                  >
                    {script.name.split(' ')[0]}
                  </button>
                );
              })}
            </div>

            {/* Script Verse Card */}
            <div className="p-3.5 bg-stone-950 rounded-xl border border-stone-800 mb-4">
              <div className="text-[11px] font-bold text-amber-400 uppercase tracking-wider mb-1">
                {selectedScript.name} • {selectedScript.origin}
              </div>
              <div className="text-sm font-serif italic text-stone-100 mb-1">
                "{selectedScript.verseSnippet}"
              </div>
              <div className="text-xs text-stone-400">
                Translation: {selectedScript.proverbEn}
              </div>
            </div>
          </div>

          {/* Pricing & Reservation CTA */}
          <div className="pt-3 border-t border-stone-700/80 flex items-center justify-between gap-4">
            <div>
              <div className="text-[11px] font-bold text-stone-400 uppercase">Masterclass Fee</div>
              <div className="text-lg font-black text-white" data-testid="atelier-price-tag">
                {formatWebAtelierPrice(selectedAtelier.priceUzs)}
              </div>
            </div>

            <button
              data-testid="reserve-workshop-button"
              onClick={handleReserve}
              disabled={isReserved || !isAtelierSeatAvailable(selectedAtelier)}
              className={`px-5 py-2.5 rounded-xl text-xs font-black transition-all flex items-center gap-2 ${
                isReserved
                  ? 'bg-emerald-600/30 text-emerald-300 border border-emerald-500/40 cursor-default'
                  : !isAtelierSeatAvailable(selectedAtelier)
                  ? 'bg-stone-700 text-stone-400 cursor-not-allowed'
                  : 'bg-amber-500 hover:bg-amber-400 text-stone-950 shadow-lg active:scale-95'
              }`}
            >
              {isReserved ? (
                <>
                  <span>✓ Enrolled</span>
                  <span className="text-[10px] opacity-80">(+35 XP)</span>
                </>
              ) : !isAtelierSeatAvailable(selectedAtelier) ? (
                <span>Fully Booked</span>
              ) : (
                <>
                  <span>Reserve Seat</span>
                  <span className="text-[10px] bg-stone-900/40 px-1.5 py-0.5 rounded">
                    +35 XP
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

export default WebSilkPaperWorkshop;
