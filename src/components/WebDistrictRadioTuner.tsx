import React, { useState, useEffect, useRef } from 'react';
import { playSoundWithHaptic } from '../services/soundEffects';

export interface WebRadioStation {
  id: string;
  frequencyMhz: number;
  callsign: string;
  title: string;
  district: string;
  genreDescription: string;
  accentColor: string;
  baseListeners: number;
  currentTrack: string;
}

export const DEFAULT_RADIO_STATIONS: WebRadioStation[] = [
  {
    id: 'station-chorsu-fm',
    frequencyMhz: 88.4,
    callsign: 'CHRS 88.4',
    title: 'Old City Chorsu Echoes',
    district: 'Shaykhontohur',
    genreDescription: 'Clay ovens, spice merchants & morning adhan reverberation',
    accentColor: '#2563EB',
    baseListeners: 340,
    currentTrack: 'Kaffal Shashi Courtyard Birds & Copper Chimes',
  },
  {
    id: 'station-mirabad-beat',
    frequencyMhz: 94.2,
    callsign: 'MRBD 94.2',
    title: 'Mirabad Modern Beat',
    district: 'Mirabad',
    genreDescription: 'Specialty espresso hiss, vinyl crackle & evening lo-fi beats',
    accentColor: '#FF4800',
    baseListeners: 520,
    currentTrack: 'Shevchenko Rain & Ceramic Portafilter Knocks',
  },
  {
    id: 'station-yunusabad-rain',
    frequencyMhz: 101.6,
    callsign: 'YNSB 101.6',
    title: 'Yunusabad Night Rain',
    district: 'Yunusabad',
    genreDescription: 'TV tower wind chimes, nocturnal tram hum & autumn rain',
    accentColor: '#059669',
    baseListeners: 290,
    currentTrack: 'Amir Timur Avenue Tram Tracks & Deep Drizzle',
  },
  {
    id: 'station-yakkasaray-breeze',
    frequencyMhz: 107.5,
    callsign: 'YKKS 107.5',
    title: 'Yakkasaray Park Breeze',
    district: 'Yakkasaray',
    genreDescription: 'Ankhor canal water ripple, plane trees & acoustic dombra',
    accentColor: '#A259FF',
    baseListeners: 215,
    currentTrack: 'Ankhor Embankment Twilight & Willow Leaves',
  },
];

export function calculateWebLiveListeners(station: WebRadioStation, hourOfDay?: number): number {
  const hour = hourOfDay !== undefined ? hourOfDay : new Date().getHours();
  let timeMultiplier = 1.0;

  if (hour >= 18 && hour <= 23) {
    timeMultiplier = 1.6;
  } else if (hour >= 8 && hour <= 12) {
    timeMultiplier = 1.3;
  } else if (hour >= 1 && hour <= 6) {
    timeMultiplier = 0.5;
  }

  const variance = Math.sin(hour * 0.5) * 20;
  return Math.max(20, Math.round(station.baseListeners * timeMultiplier + variance));
}

export function tuneFrequency(
  frequencyMhz: number,
  stations: WebRadioStation[] = DEFAULT_RADIO_STATIONS,
  hourOfDay?: number
): {
  lockedStation: WebRadioStation | null;
  signalStrength: number;
  isClearReception: boolean;
  staticVolume: number;
  liveListeners: number;
} {
  const maxTolerance = 1.0;
  let closest: WebRadioStation | null = null;
  let minDiff = Infinity;

  for (const s of stations) {
    const diff = Math.abs(s.frequencyMhz - frequencyMhz);
    if (diff < minDiff) {
      minDiff = diff;
      closest = s;
    }
  }

  if (!closest || minDiff > maxTolerance) {
    return {
      lockedStation: null,
      signalStrength: 0,
      isClearReception: false,
      staticVolume: 1.0,
      liveListeners: 14,
    };
  }

  const rawStrength = Math.max(0, Math.min(1, 1.0 - minDiff / maxTolerance));
  const signalStrength = Number(rawStrength.toFixed(2));
  const isClearReception = signalStrength >= 0.75;
  const staticVolume = Number((1.0 - signalStrength).toFixed(2));
  const liveListeners = calculateWebLiveListeners(closest, hourOfDay);

  return {
    lockedStation: closest,
    signalStrength,
    isClearReception,
    staticVolume,
    liveListeners,
  };
}

export function formatRadioFrequency(freq: number): string {
  return `${freq.toFixed(1)} MHz`;
}

export function getRadioReceptionLabel(strength: number, locale = 'en'): string {
  const lang = locale.toLowerCase();
  if (strength >= 0.75) {
    if (lang.startsWith('uz')) return 'Aniq signal';
    if (lang.startsWith('ru')) return 'Четкий сигнал';
    return 'Clear Signal';
  } else if (strength >= 0.35) {
    if (lang.startsWith('uz')) return 'Zaif signal';
    if (lang.startsWith('ru')) return 'Слабый сигнал';
    return 'Weak Signal';
  } else {
    if (lang.startsWith('uz')) return 'Statik shovqin';
    if (lang.startsWith('ru')) return 'Статический шум';
    return 'Static Noise';
  }
}

export function formatRadioSessionProgress(minutes: number, locale = 'en'): string {
  const lang = locale.toLowerCase();
  const remaining = Math.max(0, 10 - minutes);

  if (minutes >= 10) {
    if (lang.startsWith('uz')) return '10 daqiqa tinglandi! +25 XP berildi';
    if (lang.startsWith('ru')) return '10 минут прослушано! +25 XP получено';
    return '10 minutes tuned in! Earned +25 XP';
  }

  if (lang.startsWith('uz')) return `+25 XP olish uchun yana ${remaining} daqiqa tinglang`;
  if (lang.startsWith('ru')) return `Слушайте еще ${remaining} мин до +25 XP`;
  return `Listen ${remaining} more mins for +25 XP`;
}

export interface WebDistrictRadioTunerProps {
  initialFrequency?: number;
  initialPlaying?: boolean;
  locale?: string;
  onTuningChanged?: (freq: number, station: WebRadioStation | null, isPlaying: boolean) => void;
}

export const WebDistrictRadioTuner: React.FC<WebDistrictRadioTunerProps> = ({
  initialFrequency = 88.4,
  initialPlaying = false,
  locale = 'en',
  onTuningChanged,
}) => {
  const [frequency, setFrequency] = useState<number>(initialFrequency);
  const [isPlaying, setIsPlaying] = useState<boolean>(initialPlaying);
  const [minutesListened] = useState<number>(3);
  const audioContextRef = useRef<AudioContext | null>(null);
  const noiseNodeRef = useRef<AudioBufferSourceNode | null>(null);
  const gainNodeRef = useRef<GainNode | null>(null);

  const tuning = tuneFrequency(frequency, DEFAULT_RADIO_STATIONS);
  const lockedStation = tuning.lockedStation;
  const accentColor = lockedStation ? lockedStation.accentColor : '#8F887F';
  const receptionLabel = getRadioReceptionLabel(tuning.signalStrength, locale);
  const sessionProgress = formatRadioSessionProgress(minutesListened, locale);

  const handleFrequencyChange = (newFreq: number) => {
    const rounded = Math.round(newFreq * 10) / 10;
    setFrequency(rounded);
    const result = tuneFrequency(rounded);
    playSoundWithHaptic(result.isClearReception ? 'select' : 'click');
    onTuningChanged?.(rounded, result.lockedStation, isPlaying);
  };

  const handleStationSelect = (station: WebRadioStation) => {
    setFrequency(station.frequencyMhz);
    playSoundWithHaptic('select');
    onTuningChanged?.(station.frequencyMhz, station, isPlaying);
  };

  const togglePlayPause = () => {
    const nextPlaying = !isPlaying;
    setIsPlaying(nextPlaying);
    playSoundWithHaptic(nextPlaying ? 'pop' : 'click');
    onTuningChanged?.(frequency, lockedStation, nextPlaying);
  };

  // Web Audio noise generator for authentic analog radio tuning static
  useEffect(() => {
    if (typeof window === 'undefined' || !isPlaying) {
      if (noiseNodeRef.current) {
        try {
          noiseNodeRef.current.stop();
          noiseNodeRef.current.disconnect();
        } catch {
          // ignore
        }
        noiseNodeRef.current = null;
      }
      return;
    }

    try {
      const AudioCtxClass =
        window.AudioContext ||
        (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!AudioCtxClass) return;

      if (!audioContextRef.current) {
        audioContextRef.current = new AudioCtxClass();
      }
      const ctx = audioContextRef.current;
      if (ctx.state === 'suspended') {
        ctx.resume().catch(() => {});
      }

      // Generate 2 seconds of white noise buffer
      const bufferSize = ctx.sampleRate * 2;
      const noiseBuffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
      const output = noiseBuffer.getChannelData(0);
      for (let i = 0; i < bufferSize; i++) {
        output[i] = (Math.random() * 2 - 1) * 0.15; // Soft static
      }

      const whiteNoise = ctx.createBufferSource();
      whiteNoise.buffer = noiseBuffer;
      whiteNoise.loop = true;

      const gainNode = ctx.createGain();
      gainNode.gain.value = tuning.staticVolume * 0.2; // Modulated by static volume

      whiteNoise.connect(gainNode);
      gainNode.connect(ctx.destination);
      whiteNoise.start(0);

      noiseNodeRef.current = whiteNoise;
      gainNodeRef.current = gainNode;
    } catch {
      // Audio not supported in headless environments
    }

    return () => {
      if (noiseNodeRef.current) {
        try {
          noiseNodeRef.current.stop();
          noiseNodeRef.current.disconnect();
        } catch {
          // ignore
        }
        noiseNodeRef.current = null;
      }
    };
  }, [isPlaying, frequency, tuning.staticVolume]);

  return (
    <div
      data-testid="district-radio-tuner"
      className="p-5 rounded-3xl bg-[#FFFDF9] border border-[#28161412] shadow-xl text-[#161412] max-w-md w-full transition-all duration-200"
      style={{ borderColor: tuning.isClearReception ? `${accentColor}55` : undefined }}
    >
      {/* Top Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div
            className="w-11 h-11 rounded-2xl flex items-center justify-center border border-[#18161412]"
            style={{
              backgroundColor: tuning.isClearReception ? `${accentColor}1A` : '#F3ECE0',
              color: tuning.isClearReception ? accentColor : '#8F887F',
            }}
          >
            <svg
              className="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 18h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2zM9 9h6m-6 4h6"
              />
            </svg>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base tracking-tight">
                {lockedStation ? lockedStation.callsign : formatRadioFrequency(frequency)}
              </span>
              {tuning.isClearReception && (
                <span
                  className="px-1.5 py-0.5 rounded text-[10px] font-black uppercase tracking-wider"
                  style={{ backgroundColor: `${accentColor}20`, color: accentColor }}
                >
                  LOCK
                </span>
              )}
            </div>
            <p className="text-xs text-[#8F887F] truncate max-w-[200px]">
              {lockedStation
                ? `${lockedStation.title} • ${lockedStation.district}`
                : 'Static Noise • Open Frequency'}
            </p>
          </div>
        </div>

        {/* Play/Pause Button */}
        <button
          data-testid="radio-play-btn"
          onClick={togglePlayPause}
          className="w-11 h-11 rounded-full flex items-center justify-center shadow-md active:scale-95 transition-transform"
          style={{
            backgroundColor: isPlaying ? '#FF4800' : '#F3ECE0',
            color: isPlaying ? '#FFFFFF' : '#161412',
          }}
          aria-label={isPlaying ? 'Pause' : 'Play'}
        >
          {isPlaying ? (
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z" />
            </svg>
          ) : (
            <svg className="w-5 h-5 ml-0.5" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z" />
            </svg>
          )}
        </button>
      </div>

      {/* Digital LCD Panel */}
      <div className="p-3.5 rounded-2xl bg-[#FAF7F2] border border-[#28161412] mb-4 flex items-center justify-between">
        <div className="flex items-baseline gap-1.5">
          <span
            data-testid="radio-frequency-readout"
            className="font-mono text-2xl font-black tracking-tight"
            style={{ color: tuning.isClearReception ? accentColor : '#161412' }}
          >
            {frequency.toFixed(1)}
          </span>
          <span className="font-mono text-xs font-semibold text-[#8F887F]">MHz</span>
        </div>

        <div className="flex items-center gap-2">
          {/* Signal Badge */}
          <span
            data-testid="radio-signal-badge"
            className="px-2 py-1 rounded-lg text-xs font-bold flex items-center gap-1.5"
            style={{
              backgroundColor: tuning.isClearReception ? '#66E5B422' : '#FF48001F',
              color: tuning.isClearReception ? '#059669' : '#FF4800',
            }}
          >
            <span
              className="w-1.5 h-1.5 rounded-full"
              style={{ backgroundColor: tuning.isClearReception ? '#059669' : '#FF4800' }}
            />
            {receptionLabel}
          </span>

          {/* Listeners Badge */}
          <span
            data-testid="radio-listeners-badge"
            className="px-2 py-1 rounded-lg bg-[#F3ECE0] text-xs font-mono font-medium text-[#5A544C] flex items-center gap-1.5"
          >
            <span
              className="w-1.5 h-1.5 rounded-full"
              style={{ backgroundColor: isPlaying ? '#059669' : '#8F887F' }}
            />
            {tuning.liveListeners} live
          </span>
        </div>
      </div>

      {/* Animated Equalizer Wave Bars */}
      <div className="h-6 flex items-end justify-center gap-1 mb-4" data-testid="radio-equalizer">
        {[8, 14, 20, 10, 16, 22, 12, 18, 9, 15, 11].map((h, i) => {
          const height = isPlaying
            ? tuning.isClearReception
              ? Math.max(4, h * tuning.signalStrength)
              : 5
            : 3;
          return (
            <div
              key={i}
              className="w-1 rounded-full transition-all duration-300"
              style={{
                height: `${height}px`,
                backgroundColor: isPlaying
                  ? tuning.isClearReception
                    ? accentColor
                    : '#8F887F'
                  : '#B8B0A5',
              }}
            />
          );
        })}
      </div>

      {/* Analog Frequency Slider */}
      <div className="mb-4">
        <input
          data-testid="radio-frequency-slider"
          type="range"
          min="88.0"
          max="108.0"
          step="0.1"
          value={frequency}
          onChange={(e) => handleFrequencyChange(parseFloat(e.target.value))}
          className="w-full h-2 bg-[#F3ECE0] rounded-lg appearance-none cursor-pointer accent-[#FF4800]"
        />
        <div className="flex justify-between text-[10px] font-mono font-semibold text-[#8F887F] mt-1 px-1">
          <span>88.0</span>
          <span>93.0</span>
          <span>98.0</span>
          <span>103.0</span>
          <span>108.0</span>
        </div>
      </div>

      {/* Station Preset Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 mb-4">
        {DEFAULT_RADIO_STATIONS.map((station) => {
          const isSelected = lockedStation?.id === station.id;
          return (
            <button
              key={station.id}
              data-testid={`radio-station-btn-${station.id}`}
              onClick={() => handleStationSelect(station)}
              className="px-2.5 py-1.5 rounded-xl border text-xs font-semibold whitespace-nowrap transition-all flex items-center gap-1.5"
              style={{
                backgroundColor: isSelected ? `${station.accentColor}1A` : '#FAF7F2',
                borderColor: isSelected ? station.accentColor : '#18161412',
                color: isSelected ? station.accentColor : '#5A544C',
              }}
            >
              <span className="font-mono font-bold">{station.frequencyMhz.toFixed(1)}</span>
              <span className="text-[10px] uppercase font-bold tracking-tight opacity-80">
                {station.district}
              </span>
            </button>
          );
        })}
      </div>

      {/* Session Progress Footer */}
      <div className="p-2.5 rounded-xl bg-[#FAF7F2] border border-[#18161412] flex items-center justify-between text-xs">
        <span className="text-[#5A544C] font-medium">{sessionProgress}</span>
        <span className="font-bold text-[#FF4800]">+25 XP</span>
      </div>
    </div>
  );
};
