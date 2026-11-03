import React, { useState } from 'react';

export type PuppetFormat = 'chodir_jamol' | 'chodir_xayol' | 'soya_qogirchoq';
export type CarvingWoodType = 'chinor' | 'walnut' | 'apricot';

export interface PuppetShow {
  id: string;
  title: string;
  durationMinutes: number;
  ticketPriceUzs: number;
  minimumAge: number;
  scheduleTime: string;
  format: PuppetFormat;
  synopsis: string;
}

export interface MarionetteSpec {
  id: string;
  name: string;
  wood: CarvingWoodType;
  stringsCount: number;
  role: string;
  costume: string;
}

export interface PuppetStageItem {
  id: string;
  name: string;
  district: string;
  chiefMaster: string;
  foundedYear: number;
  availableSeats: number;
  repertoire: PuppetShow[];
  signatureFigures: MarionetteSpec[];
}

export const TASHKENT_PUPPET_STAGES: PuppetStageItem[] = [
  {
    id: 'theater-state-puppet-kosmonavtlar',
    name: 'Uzbekistan State Puppet Theater',
    district: 'Yakkasaray Kosmonavtlar',
    chiefMaster: 'Usto Mansur Qo\'g\'irchoqsoz',
    foundedYear: 1939,
    availableSeats: 48,
    repertoire: [
      {
        id: 'show-polvon-kachal-wedding',
        title: 'The Hilarious Wedding of Polvon Kachal',
        durationMinutes: 50,
        ticketPriceUzs: 35000,
        minimumAge: 4,
        scheduleTime: '11:00 AM & 3:00 PM',
        format: 'chodir_jamol',
        synopsis: 'Classic Uzbek folk comedy starring the irreverent glove puppet hero Polvon Kachal.',
      },
      {
        id: 'show-simurgh-legend',
        title: 'The Flight of the Sacred Simurgh',
        durationMinutes: 65,
        ticketPriceUzs: 50000,
        minimumAge: 6,
        scheduleTime: '6:30 PM',
        format: 'chodir_xayol',
        synopsis: 'Spectacular multi-string marionette epic following young Farhod across mythological peaks.',
      },
    ],
    signatureFigures: [
      {
        id: 'figure-polvon-kachal',
        name: 'Polvon Kachal (The Folk Wrestler)',
        wood: 'chinor',
        stringsCount: 0,
        role: 'Protagonist Trickster',
        costume: 'Striped Bekasab Silk Chapan',
      },
      {
        id: 'figure-farhod-hero',
        name: 'Farhod the Stonecutter',
        wood: 'walnut',
        stringsCount: 10,
        role: 'Epic Hero',
        costume: 'Adras Ikat Tunic with Silver Belt',
      },
    ],
  },
  {
    id: 'atelier-old-city-chodir',
    name: 'Old City Chodir Jamol Master Atelier',
    district: 'Shaykhontohur Chorsu',
    chiefMaster: 'Usto Ikrom Usta-Qo\'g\'irchoq',
    foundedYear: 1978,
    availableSeats: 16,
    repertoire: [
      {
        id: 'show-nasriddin-donkey',
        title: 'Afandi and the Wise Donkey',
        durationMinutes: 45,
        ticketPriceUzs: 40000,
        minimumAge: 5,
        scheduleTime: '2:00 PM',
        format: 'chodir_jamol',
        synopsis: 'Humorous philosophical miniature with Nasriddin Afandi negotiating the Chorsu bazaar crowd.',
      },
    ],
    signatureFigures: [
      {
        id: 'figure-afandi',
        name: 'Nasriddin Afandi',
        wood: 'apricot',
        stringsCount: 0,
        role: 'Philosopher Sage',
        costume: 'White Cotton Turban and Blue Velvet Robe',
      },
    ],
  },
  {
    id: 'studio-chilonzor-marionette',
    name: 'Chilonzor Silk String Marionette Studio',
    district: 'Chilonzor Quarter 7',
    chiefMaster: 'Usto Dilshod Marionetkasoz',
    foundedYear: 1995,
    availableSeats: 24,
    repertoire: [
      {
        id: 'show-tahir-zuhra',
        title: 'Tahir and Zuhra: A Musical Tapestry',
        durationMinutes: 60,
        ticketPriceUzs: 45000,
        minimumAge: 7,
        scheduleTime: '5:00 PM',
        format: 'chodir_xayol',
        synopsis: 'Tender romance told with 12-string articulated marionettes dancing to live acoustic music.',
      },
    ],
    signatureFigures: [
      {
        id: 'figure-zuhra-princess',
        name: 'Princess Zuhra',
        wood: 'chinor',
        stringsCount: 12,
        role: 'Heroine',
        costume: 'Gold Zardozi Embroidered Silk Satin',
      },
    ],
  },
];

export function calculateCrossBraceStringTension(stringIndex: number, tiltAngleDegrees: number): number {
  const clampedAngle = Math.max(-45, Math.min(45, tiltAngleDegrees));
  const bias = (stringIndex % 2 === 0 ? 1 : -1) * (clampedAngle / 90.0);
  const rawTension = 0.5 + bias;
  return Math.max(0.0, Math.min(1.0, parseFloat(rawTension.toFixed(2))));
}

export function formatPuppetPriceUzs(price: number): string {
  return price.toLocaleString('en-US') + ' UZS';
}

export function calculateTotalBookingPrice(ticketPrice: number, seatsCount: number): number {
  return Math.max(0, ticketPrice * Math.max(1, seatsCount));
}

export function getWoodHardnessDescription(wood: CarvingWoodType): { name: string; hardnessMohs: number; description: string } {
  switch (wood) {
    case 'chinor':
      return {
        name: 'Chinor (Oriental Plane Tree)',
        hardnessMohs: 3.5,
        description: 'Fine-grained, non-splintering plane tree wood favored for expressive facial carvings.',
      };
    case 'walnut':
      return {
        name: 'Yong\'oq (Mountain Walnut)',
        hardnessMohs: 4.0,
        description: 'Dense dark timber providing lustrous polish for royal regalia and headdresses.',
      };
    case 'apricot':
      return {
        name: 'O\'rik (Wild Apricot)',
        hardnessMohs: 4.5,
        description: 'Extremely tough, resonant timber carved for miniature joint pins and string pulleys.',
      };
  }
}

export function filterStagesByPuppetFormat(stages: PuppetStageItem[], format: PuppetFormat): PuppetStageItem[] {
  return stages.filter((stage) => {
    return (
      stage.repertoire.some((p) => p.format === format) ||
      stage.signatureFigures.some((f) => (format === 'chodir_jamol' ? f.stringsCount === 0 : f.stringsCount > 0))
    );
  });
}

export const WebPuppetTheaterStage: React.FC = () => {
  const [selectedStage, setSelectedStage] = useState<PuppetStageItem>(TASHKENT_PUPPET_STAGES[0]);
  const [selectedShow, setSelectedShow] = useState<PuppetShow>(TASHKENT_PUPPET_STAGES[0].repertoire[0]);
  const [tiltAngle, setTiltAngle] = useState<number>(0);
  const [seatsCount, setSeatsCount] = useState<number>(2);
  const [isReserved, setIsReserved] = useState<boolean>(false);

  const handleStageSelect = (stage: PuppetStageItem) => {
    setSelectedStage(stage);
    setSelectedShow(stage.repertoire[0] || null);
    setIsReserved(false);
  };

  const handleReserve = () => {
    setIsReserved(true);
  };

  const strings = [
    { label: 'Head Balance String', index: 0 },
    { label: 'Left Arm Gesture String', index: 1 },
    { label: 'Right Arm Gesture String', index: 2 },
    { label: 'Left Leg Step String', index: 3 },
    { label: 'Right Leg Step String', index: 4 },
  ];

  return (
    <div className="bg-rose-950/20 border border-rose-800/40 rounded-2xl p-6 text-stone-100 max-w-2xl mx-auto shadow-2xl backdrop-blur-md">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-rose-800/30 pb-4 mb-6">
        <div>
          <h2 className="text-xl font-bold tracking-tight text-amber-200">
            Tashkent Puppet Theater & Marionette Stage
          </h2>
          <p className="text-xs text-rose-300/80 mt-1">
            Chodir Jamol Glove Puppetry & 12-String Chinor Wood Marionettes
          </p>
        </div>
        <span className="bg-amber-500/20 text-amber-300 text-xs font-semibold px-3 py-1 rounded-full border border-amber-500/30">
          +35 XP
        </span>
      </div>

      {/* Stage Venue Tabs */}
      <div className="grid grid-cols-3 gap-2 mb-6">
        {TASHKENT_PUPPET_STAGES.map((stage) => {
          const isCurrent = stage.id === selectedStage.id;
          return (
            <button
              key={stage.id}
              onClick={() => handleStageSelect(stage)}
              className={`text-left p-3 rounded-xl text-xs transition-all ${
                isCurrent
                  ? 'bg-rose-900/60 border border-amber-400/50 shadow-md text-amber-100 font-semibold'
                  : 'bg-stone-900/40 border border-stone-800 hover:border-rose-700/50 text-stone-300'
              }`}
            >
              <div className="truncate font-medium">{stage.name}</div>
              <div className="text-[10px] text-stone-400 mt-1">{stage.district}</div>
            </button>
          );
        })}
      </div>

      {/* Repertoire Selector */}
      <div className="mb-6">
        <label className="text-xs font-semibold text-rose-200 uppercase tracking-wider block mb-2">
          Current Repertoire Performance
        </label>
        <div className="space-y-2">
          {selectedStage.repertoire.map((show) => {
            const isShowSelected = selectedShow && selectedShow.id === show.id;
            return (
              <div
                key={show.id}
                onClick={() => setSelectedShow(show)}
                className={`p-3 rounded-xl border cursor-pointer transition-all ${
                  isShowSelected
                    ? 'bg-rose-900/40 border-amber-400/60 text-white'
                    : 'bg-stone-900/30 border-stone-800/80 text-stone-300 hover:border-rose-800/40'
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-sm text-amber-100">{show.title}</span>
                  <span className="text-xs text-amber-400 font-medium">
                    {formatPuppetPriceUzs(show.ticketPriceUzs)}
                  </span>
                </div>
                <div className="flex items-center gap-3 text-xs text-stone-400 mt-1">
                  <span>{show.scheduleTime}</span>
                  <span>•</span>
                  <span>{show.durationMinutes} min</span>
                  <span>•</span>
                  <span className="text-rose-300 font-medium">Age {show.minimumAge}+</span>
                </div>
                <p className="text-xs text-stone-300 mt-2 line-clamp-2">{show.synopsis}</p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Interactive Marionette Cross-Brace Controller Simulator */}
      <div className="bg-stone-900/60 border border-rose-800/30 rounded-xl p-4 mb-6">
        <div className="flex items-center justify-between mb-3">
          <span className="text-xs font-semibold text-amber-200">
            Marionette Cross-Brace String Tension Simulator
          </span>
          <span className="text-xs text-rose-300 font-mono">Tilt: {tiltAngle}°</span>
        </div>

        <input
          type="range"
          min="-45"
          max="45"
          value={tiltAngle}
          onChange={(e) => setTiltAngle(parseInt(e.target.value, 10))}
          className="w-full accent-amber-500 mb-4 cursor-pointer"
        />

        {/* String Tension Gauges */}
        <div className="space-y-2">
          {strings.map((str) => {
            const tension = calculateCrossBraceStringTension(str.index, tiltAngle);
            const percentage = Math.round(tension * 100);
            return (
              <div key={str.index} className="flex items-center justify-between text-xs">
                <span className="text-stone-300 text-[11px] w-44 truncate">{str.label}</span>
                <div className="flex-1 mx-3 h-2 bg-stone-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-amber-500 to-rose-500 transition-all duration-150"
                    style={{ width: `${percentage}%` }}
                  />
                </div>
                <span className="text-[11px] font-mono text-amber-300 w-10 text-right">
                  {percentage}%
                </span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Seat Booking & XP CTA */}
      <div className="flex items-center justify-between border-t border-rose-800/30 pt-4">
        <div>
          <div className="text-xs text-stone-400">Total Booking Price</div>
          <div className="text-lg font-bold text-amber-200">
            {selectedShow
              ? formatPuppetPriceUzs(calculateTotalBookingPrice(selectedShow.ticketPriceUzs, seatsCount))
              : '0 UZS'}
          </div>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-stone-900/50 border border-stone-800 rounded-lg px-2 py-1">
            <button
              onClick={() => setSeatsCount(Math.max(1, seatsCount - 1))}
              className="text-stone-300 hover:text-white px-1 font-bold text-sm"
              disabled={seatsCount <= 1}
            >
              -
            </button>
            <span className="text-sm font-semibold w-4 text-center">{seatsCount}</span>
            <button
              onClick={() => setSeatsCount(Math.min(6, seatsCount + 1))}
              className="text-stone-300 hover:text-white px-1 font-bold text-sm"
              disabled={seatsCount >= 6}
            >
              +
            </button>
          </div>

          <button
            onClick={handleReserve}
            disabled={isReserved}
            className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
              isReserved
                ? 'bg-emerald-800/60 text-emerald-200 border border-emerald-500/40 cursor-default'
                : 'bg-gradient-to-r from-rose-700 to-amber-600 hover:from-rose-600 hover:to-amber-500 text-white shadow-lg'
            }`}
          >
            {isReserved ? 'Reserved! (+35 XP)' : 'Reserve Seats (+35 XP)'}
          </button>
        </div>
      </div>
    </div>
  );
};
