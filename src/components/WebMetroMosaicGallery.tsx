import React, { useState } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebMetroLine {
  id: 'chilanzar' | 'uzbekistan' | 'yunusabad' | 'circle';
  name: string;
  color: string;
  year: number;
}

export interface WebMetroStation {
  id: string;
  name: string;
  lineId: 'chilanzar' | 'uzbekistan' | 'yunusabad' | 'circle';
  openingYear: number;
  architect: string;
  mosaicArtist: string;
  architecturalStyle: string;
  mosaicDescription: string;
  marblePillars: string;
  lightingStyle: string;
  audioGuideSnippet: string;
  stampPoints: number;
  highlightColor: string;
}

export const METRO_LINES: WebMetroLine[] = [
  { id: 'chilanzar', name: 'Chilanzar (Red)', color: '#E53935', year: 1977 },
  { id: 'uzbekistan', name: 'Uzbekistan (Blue)', color: '#1E88E5', year: 1984 },
  { id: 'yunusabad', name: 'Yunusabad (Green)', color: '#43A047', year: 2001 },
  { id: 'circle', name: 'Circle (Gold)', color: '#FBC02D', year: 2020 },
];

export const DEFAULT_METRO_STATIONS: WebMetroStation[] = [
  {
    id: 'kosmonavtlar',
    name: 'Kosmonavtlar (Cosmonauts)',
    lineId: 'uzbekistan',
    openingYear: 1984,
    architect: 'S. Sultonov',
    mosaicArtist: 'Arnold Gan',
    architecturalStyle: 'Cosmic Soviet Futurism & Ceramic Medallions',
    mosaicDescription:
      'Deep midnight-blue to black ceramic gradient walls echoing atmospheric entry, with ceramic medallions honoring Yuri Gagarin, Valentina Tereshkova, and astronomer Mirzo Ulugbek.',
    marblePillars: 'Deep blue-grey granite and ribbed cylindrical columns',
    lightingStyle: 'Illuminated floating glass orb chandeliers resembling the Milky Way galaxy',
    audioGuideSnippet:
      'Cosmonauts Station evokes a descent into deep cosmos with gradient cerulean tiles and astronomical medallions.',
    stampPoints: 30,
    highlightColor: '#1E88E5',
  },
  {
    id: 'alisher_navoiy',
    name: 'Alisher Navoiy',
    lineId: 'uzbekistan',
    openingYear: 1984,
    architect: 'R. Fayzullayev',
    mosaicArtist: 'Chinghiz Akhmarov',
    architecturalStyle: 'Timurid Vaulted Blue Cupolas & Epic Poem Frescoes',
    mosaicDescription:
      'Intricate vaulted cupolas inspired by Samarkand madrasahs, featuring majolica blue medallions illustrating scenes from Navoi\'s legendary Khamsa epic.',
    marblePillars: 'White Kyzylkum marble arches and octagonal stalactite capitals',
    lightingStyle: 'Chiseled brass hanging mosque-style chandeliers casting lace shadows',
    audioGuideSnippet:
      'Alisher Navoi Station presents vaulted turquoise cupolas depicting five legendary tales from the Khamsa epic.',
    stampPoints: 30,
    highlightColor: '#00BCD4',
  },
  {
    id: 'pakhtakor',
    name: 'Paxtakor (Pakhtakor)',
    lineId: 'chilanzar',
    openingYear: 1977,
    architect: 'A. Tabibov',
    mosaicArtist: 'V. Burmakin',
    architecturalStyle: 'Ceramic Cotton Blossom Majolica & Smalt Arabesques',
    mosaicDescription:
      'Dynamic flowing mosaics made of Tashkent smalt and glazed ceramics portraying blooming cotton bolls and solar swirls in jade, cobalt, and golden ochre.',
    marblePillars: 'Gazgan pink and white marble fluted columns',
    lightingStyle: 'Recessed geometric luminaire coffers embedded in the ceiling',
    audioGuideSnippet:
      'Pakhtakor Station is celebrated for its radiant smalt mosaics weaving cotton blossoms and solar arabesques.',
    stampPoints: 30,
    highlightColor: '#E53935',
  },
  {
    id: 'mustaqillik_maydoni',
    name: 'Mustaqillik Maydoni (Independence Square)',
    lineId: 'chilanzar',
    openingYear: 1977,
    architect: 'L. Adamov',
    mosaicArtist: 'Uzbekistan National Studio',
    architecturalStyle: 'Neoclassical Ceremonial Marble & Crystal Chandeliers',
    mosaicDescription:
      'Polished Gazgan marble halls with geometric star marquetry floors and luminous alabaster cornices symbolizing celebration.',
    marblePillars: 'Fluted white Gazgan marble pillars topped with gilded capital leaves',
    lightingStyle: 'Massive tiered crystal chandeliers evoking ceremonial palace halls',
    audioGuideSnippet:
      'Independence Square Station features ceremonial white marble colonnades and tiered crystal chandeliers.',
    stampPoints: 30,
    highlightColor: '#FF7043',
  },
  {
    id: 'bodomzor',
    name: 'Bodomzor',
    lineId: 'yunusabad',
    openingYear: 2001,
    architect: 'A. Adylov',
    mosaicArtist: 'Usto R. Tokhtayev',
    architecturalStyle: 'Modernist Ceramic Filigree & Almond Blossom Lanterns',
    mosaicDescription:
      'Geometric ceramic relief friezes reflecting almond trees (bodom), paired with undulating ceiling plasterwork and stylized branch motifs.',
    marblePillars: 'Curved light Nurata marble benches and circular central pedestals',
    lightingStyle: 'Pod-like sculptural almond-shaped frosted acrylic luminaires',
    audioGuideSnippet:
      'Bodomzor Station features sculptural almond-shaped light pods and delicate ceramic relief patterns.',
    stampPoints: 30,
    highlightColor: '#43A047',
  },
  {
    id: 'beruniy',
    name: 'Beruniy',
    lineId: 'uzbekistan',
    openingYear: 1991,
    architect: 'S. Sultonov',
    mosaicArtist: 'A. Rakhmatullaev',
    architecturalStyle: 'High Geometric Domes & Astrolabe Reliefs',
    mosaicDescription:
      'Massive spherical tiled cupolas echoing Abu Rayhan al-Biruni\'s spherical trigonometry, adorned with bronze astrolabe emblems.',
    marblePillars: 'Polished grey marble arches with interlocking Islamic geometric friezes',
    lightingStyle: 'Concentric ring luminaires representing planetary orbits',
    audioGuideSnippet:
      'Beruniy Station honors the polymath Al-Biruni with astronomical domes and planetary orbit chandeliers.',
    stampPoints: 30,
    highlightColor: '#5C6BC0',
  },
];

/** Filters stations by line ID or returns all */
export function filterStationsByLine(
  stations: WebMetroStation[],
  lineId: string
): WebMetroStation[] {
  if (lineId === 'all') return stations;
  return stations.filter((s) => s.lineId === lineId);
}

/** Calculates total exploration progress, stamps, and XP */
export function calculateMetroExplorationProgress(
  stations: WebMetroStation[],
  stampedIds: string[]
): { visitedCount: number; totalCount: number; percentage: number; totalXp: number } {
  const totalCount = stations.length;
  const visitedCount = stations.filter((s) => stampedIds.includes(s.id)).length;
  const percentage = totalCount > 0 ? Math.round((visitedCount / totalCount) * 100) : 0;
  const totalXp = stations
    .filter((s) => stampedIds.includes(s.id))
    .reduce((sum, s) => sum + s.stampPoints, 0);

  return { visitedCount, totalCount, percentage, totalXp };
}

/** Trilingual stamp status copy */
export function getWebMetroStampStatus(isStamped: boolean, langCode: string): string {
  if (isStamped) {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return "Shtamp yig'ilgan (+30 XP)";
      case 'ru':
        return 'Штамп получен (+30 XP)';
      case 'en':
      default:
        return 'Stamp Collected (+30 XP)';
    }
  } else {
    switch (langCode.toLowerCase()) {
      case 'uz':
        return 'Shtampni olish (+30 XP)';
      case 'ru':
        return 'Собрать штамп (+30 XP)';
      case 'en':
      default:
        return 'Collect Stamp (+30 XP)';
    }
  }
}

/** Calculates cyclical zoom step */
export function calculateZoomScale(currentZoom: number): number {
  if (currentZoom >= 2) return 1;
  return Number((currentZoom + 0.5).toFixed(1));
}

export interface WebMetroMosaicGalleryProps {
  stations?: WebMetroStation[];
  initialSelectedStationId?: string;
  onStampCollected?: (stationId: string) => void;
}

export const WebMetroMosaicGallery: React.FC<WebMetroMosaicGalleryProps> = ({
  stations = DEFAULT_METRO_STATIONS,
  initialSelectedStationId,
  onStampCollected,
}) => {
  const [activeLine, setActiveLine] = useState<string>('all');
  const [selectedStationId, setSelectedStationId] = useState<string>(
    initialSelectedStationId || (stations.length > 0 ? stations[0].id : '')
  );
  const [stampedIds, setStampedIds] = useState<string[]>([]);
  const [isPlayingAudio, setIsPlayingAudio] = useState<boolean>(false);
  const [zoomLevel, setZoomLevel] = useState<number>(1);

  const filteredStations = filterStationsByLine(stations, activeLine);

  const selectedStation =
    stations.find((s) => s.id === selectedStationId) || filteredStations[0] || stations[0];

  const handleSelectLine = (lineId: string) => {
    setActiveLine(lineId);
    playSoundWithHaptic('select');
  };

  const handleSelectStation = (stationId: string) => {
    setSelectedStationId(stationId);
    setIsPlayingAudio(false);
    setZoomLevel(1);
    playSoundWithHaptic('click');
  };

  const handleToggleAudio = () => {
    setIsPlayingAudio(!isPlayingAudio);
    playSoundWithHaptic('pop');
  };

  const handleCollectStamp = (stationId: string) => {
    if (stampedIds.includes(stationId)) return;
    const next = [...stampedIds, stationId];
    setStampedIds(next);
    playSoundWithHaptic('trophy');
    if (onStampCollected) {
      onStampCollected(stationId);
    }
  };

  const handleZoomToggle = () => {
    setZoomLevel(calculateZoomScale(zoomLevel));
    playSoundWithHaptic('click');
  };

  const progress = calculateMetroExplorationProgress(stations, stampedIds);

  return (
    <div
      data-testid="web-metro-mosaic-gallery"
      className="p-6 max-w-5xl mx-auto bg-stone-900 text-stone-100 rounded-3xl shadow-2xl border border-stone-800"
    >
      {/* Header and Telemetry */}
      <div className="flex flex-col md:flex-row md:items-center justify-between pb-6 border-b border-stone-800 gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="px-2.5 py-0.5 text-xs font-bold uppercase tracking-wider bg-red-600/20 text-red-400 border border-red-500/30 rounded-full">
              Subterranean Art Heritage
            </span>
            <span className="text-xs text-stone-400">Tashkent Subway (1977–Present)</span>
          </div>
          <h2 className="text-2xl md:text-3xl font-black tracking-tight text-white">
            Metro Ceramic Mosaics & Architecture Guide
          </h2>
        </div>

        {/* Passport Explorer Stats */}
        <div className="flex items-center gap-4 bg-stone-800/80 px-4 py-2.5 rounded-2xl border border-stone-700/60">
          <div>
            <div className="text-[11px] font-bold tracking-wider uppercase text-stone-400">
              Explorer XP
            </div>
            <div className="text-xl font-black text-amber-400" data-testid="total-xp-counter">
              +{progress.totalXp} XP
            </div>
          </div>
          <div className="h-8 w-px bg-stone-700" />
          <div>
            <div className="text-[11px] font-bold tracking-wider uppercase text-stone-400">
              Stamps
            </div>
            <div className="text-sm font-semibold text-stone-200">
              {progress.visitedCount} / {progress.totalCount} ({progress.percentage}%)
            </div>
          </div>
        </div>
      </div>

      {/* Line Switcher Navigation */}
      <div className="flex flex-wrap items-center gap-2 pt-6 pb-4">
        <button
          data-testid="line-tab-all"
          onClick={() => handleSelectLine('all')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
            activeLine === 'all'
              ? 'bg-stone-100 text-stone-950 shadow-md'
              : 'bg-stone-800 text-stone-400 hover:text-stone-200'
          }`}
        >
          All Lines ({stations.length})
        </button>
        {METRO_LINES.map((line) => {
          const lineCount = stations.filter((s) => s.lineId === line.id).length;
          const isActive = activeLine === line.id;
          return (
            <button
              key={line.id}
              data-testid={`line-tab-${line.id}`}
              onClick={() => handleSelectLine(line.id)}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                isActive
                  ? 'bg-stone-100 text-stone-950 shadow-md'
                  : 'bg-stone-800 text-stone-400 hover:text-stone-200'
              }`}
            >
              <span
                className="w-2.5 h-2.5 rounded-full"
                style={{ backgroundColor: line.color }}
              />
              {line.name} ({lineCount})
            </button>
          );
        })}
      </div>

      {/* Main Grid: Station List + High-Res Architectural Spotlight */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
        {/* Left Column: Station Cards List */}
        <div className="lg:col-span-5 space-y-3 max-h-[580px] overflow-y-auto pr-1">
          {filteredStations.map((station) => {
            const isSelected = selectedStation?.id === station.id;
            const isStamped = stampedIds.includes(station.id);
            const line = METRO_LINES.find((l) => l.id === station.lineId);

            return (
              <div
                key={station.id}
                data-testid={`station-card-${station.id}`}
                onClick={() => handleSelectStation(station.id)}
                className={`p-4 rounded-2xl cursor-pointer transition-all border ${
                  isSelected
                    ? 'bg-stone-800/90 border-amber-500/80 shadow-lg ring-1 ring-amber-500/50'
                    : 'bg-stone-800/40 border-stone-800 hover:border-stone-700'
                }`}
              >
                <div className="flex items-center justify-between mb-1.5">
                  <span
                    className="px-2 py-0.5 rounded text-[10px] font-extrabold uppercase text-white"
                    style={{ backgroundColor: line?.color || '#1E88E5' }}
                  >
                    {line?.name.split(' ')[0]}
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-[11px] text-stone-400 font-medium">
                      {station.openingYear}
                    </span>
                    {isStamped && (
                      <span className="text-emerald-400 font-bold text-xs">✓ STAMPED</span>
                    )}
                  </div>
                </div>

                <h3 className="text-base font-bold text-white mb-1">{station.name}</h3>
                <div className="text-xs text-stone-400 line-clamp-1 mb-2">
                  {station.architecturalStyle}
                </div>

                <div className="flex items-center justify-between text-[11px] text-stone-400">
                  <span className="truncate max-w-[180px]">🎨 {station.mosaicArtist}</span>
                  <span className="text-amber-400/90 font-semibold">
                    +{station.stampPoints} XP
                  </span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Right Column: Architectural Spotlight & Ceramic Zoom Viewer */}
        {selectedStation && (
          <div
            data-testid="station-spotlight-panel"
            className="lg:col-span-7 bg-stone-800/70 p-6 rounded-3xl border border-stone-700/80 flex flex-col justify-between"
          >
            <div>
              {/* Station Headline */}
              <div className="flex items-start justify-between gap-4 mb-4">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span
                      className="w-3 h-3 rounded-full"
                      style={{ backgroundColor: selectedStation.highlightColor }}
                    />
                    <span className="text-xs font-bold text-stone-300 uppercase tracking-wide">
                      {selectedStation.architecturalStyle}
                    </span>
                  </div>
                  <h3 className="text-2xl font-black text-white">{selectedStation.name}</h3>
                  <div className="text-xs text-stone-400 mt-0.5">
                    Architect: <span className="text-stone-200">{selectedStation.architect}</span>{' '}
                    • Mosaic Master:{' '}
                    <span className="text-amber-400 font-medium">
                      {selectedStation.mosaicArtist}
                    </span>
                  </div>
                </div>

                {/* Stamp Action Button */}
                <button
                  data-testid="stamp-cta-button"
                  onClick={() => handleCollectStamp(selectedStation.id)}
                  disabled={stampedIds.includes(selectedStation.id)}
                  className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
                    stampedIds.includes(selectedStation.id)
                      ? 'bg-emerald-600/30 text-emerald-300 border border-emerald-500/40 cursor-default'
                      : 'bg-amber-500 hover:bg-amber-400 text-stone-950 font-black shadow-lg shadow-amber-500/20 active:scale-95'
                  }`}
                >
                  {stampedIds.includes(selectedStation.id) ? (
                    <>
                      <span>✓ Stamped</span>
                      <span className="text-[10px] opacity-80">(+30 XP)</span>
                    </>
                  ) : (
                    <>
                      <span>Collect Stamp</span>
                      <span className="text-[10px] bg-stone-900/40 px-1.5 py-0.5 rounded">
                        +{selectedStation.stampPoints} XP
                      </span>
                    </>
                  )}
                </button>
              </div>

              {/* Ceramic Mosaic High-Res Simulated Visualizer */}
              <div className="relative overflow-hidden rounded-2xl bg-stone-950 border border-stone-800 p-6 my-4">
                <div
                  className="transition-transform duration-300"
                  style={{ transform: `scale(${zoomLevel})`, transformOrigin: 'center' }}
                >
                  <div
                    className="h-28 rounded-xl flex items-center justify-center p-4 text-center border"
                    style={{
                      background: `linear-gradient(135deg, ${selectedStation.highlightColor}33, #161412 80%)`,
                      borderColor: `${selectedStation.highlightColor}66`,
                    }}
                  >
                    <div className="space-y-1">
                      <div className="text-xs font-mono uppercase tracking-widest text-stone-400">
                        Ceramic Smalt Mosaic Preview
                      </div>
                      <div className="text-sm font-semibold text-stone-100 max-w-md mx-auto line-clamp-2">
                        {selectedStation.mosaicDescription}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between mt-3 pt-3 border-t border-stone-800/80 text-[11px] text-stone-400">
                  <span>Zoom: {zoomLevel}x</span>
                  <button
                    data-testid="zoom-toggle-button"
                    onClick={handleZoomToggle}
                    className="px-2.5 py-1 rounded bg-stone-800 text-stone-300 hover:bg-stone-700 text-xs font-semibold"
                  >
                    {zoomLevel >= 2 ? 'Reset Zoom' : 'Magnify Mosaic (2x)'}
                  </button>
                </div>
              </div>

              {/* Material Details: Marble Columns & Lighting System */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 my-4">
                <div className="bg-stone-900/80 p-3 rounded-xl border border-stone-800">
                  <div className="text-[11px] font-bold text-stone-400 uppercase tracking-wider mb-1">
                    🏛️ Marble & Pillars
                  </div>
                  <div className="text-xs text-stone-200">{selectedStation.marblePillars}</div>
                </div>
                <div className="bg-stone-900/80 p-3 rounded-xl border border-stone-800">
                  <div className="text-[11px] font-bold text-stone-400 uppercase tracking-wider mb-1">
                    💡 Illumination & Ceilings
                  </div>
                  <div className="text-xs text-stone-200">{selectedStation.lightingStyle}</div>
                </div>
              </div>
            </div>

            {/* Audio Guide Player Footer */}
            <div className="bg-stone-900/90 p-4 rounded-2xl border border-stone-800 mt-4 flex items-center justify-between gap-4">
              <div className="space-y-0.5">
                <div className="text-[11px] font-bold text-amber-400 uppercase tracking-wider flex items-center gap-1.5">
                  <span>🎧 Audio Guide Curated Snippet</span>
                  {isPlayingAudio && (
                    <span className="flex gap-0.5 items-end h-3">
                      <span className="w-1 bg-amber-400 animate-pulse h-3" />
                      <span className="w-1 bg-amber-400 animate-pulse h-2" />
                      <span className="w-1 bg-amber-400 animate-pulse h-3.5" />
                    </span>
                  )}
                </div>
                <p className="text-xs text-stone-300 line-clamp-2">
                  {selectedStation.audioGuideSnippet}
                </p>
              </div>

              <button
                data-testid="audio-guide-toggle"
                onClick={handleToggleAudio}
                className={`px-4 py-2.5 rounded-xl text-xs font-extrabold transition-all whitespace-nowrap ${
                  isPlayingAudio
                    ? 'bg-red-600 hover:bg-red-500 text-white'
                    : 'bg-stone-700 hover:bg-stone-600 text-stone-100'
                }`}
              >
                {isPlayingAudio ? 'Pause Guide' : 'Play Guide'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default WebMetroMosaicGallery;
