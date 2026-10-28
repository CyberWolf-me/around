import React from 'react';

export const ICON_PATHS: Record<string, string> = {
  home: 'M3.5 10.5 12 3.5l8.5 7v9.2a.8.8 0 0 1-.8.8h-5.2v-6h-5v6H4.3a.8.8 0 0 1-.8-.8z',
  compass: 'M12 20.5a8.5 8.5 0 1 0 0-17 8.5 8.5 0 0 0 0 17zm3.4-11.9-2.3 5.4-5.4 2.3 2.3-5.4z',
  bookmark: 'M6 3.5h12v17l-6-4.2-6 4.2z',
  user: 'M4.6 20.5c0-3.7 3.3-6.2 7.4-6.2s7.4 2.5 7.4 6.2M12 12.5a4.2 4.2 0 1 0 0-8.4 4.2 4.2 0 0 0 0 8.4z',
  bell: 'M6.5 10.2a5.5 5.5 0 0 1 11 0c0 3.9 1.4 5.4 1.4 5.4H5.1s1.4-1.5 1.4-5.4zM10 19.2a2.1 2.1 0 0 0 4 0',
  search: 'M10.8 17a6.4 6.4 0 1 0 0-12.8 6.4 6.4 0 0 0 0 12.8zM15.6 15.8 20.5 20.7',
  plus: 'M12 5.2v13.6M5.2 12h13.6',
  camera: 'M3.4 8.6h3.2L8.2 6h7.6l1.6 2.6h3.2v10.8H3.4zM12 17.2a3.4 3.4 0 1 0 0-6.8 3.4 3.4 0 0 0 0 6.8z',
  x: 'M6.2 6.2 17.8 17.8M17.8 6.2 6.2 17.8',
  chevL: 'M14.6 5 8 12l6.6 7',
  chevR: 'M9.4 5 16 12l-6.6 7',
  arrowUR: 'M7 17 17 7M9.2 7H17v7.8',
  map: 'M3.5 6.6 9 4.1l6 2.5 5.5-2.5v13.4L15 20l-6-2.5-5.5 2.5zM9 4.1v13.4M15 6.6V20',
  list: 'M4 7.2h16M4 12h16M4 16.8h11',
  star: 'M12 3.6l2.55 5.5 6 .8-4.4 4.1 1.15 5.9L12 16.9l-5.3 3 1.15-5.9L3.45 9.9l6-.8z',
  clock: 'M12 20.5a8.5 8.5 0 1 0 0-17 8.5 8.5 0 0 0 0 17zM12 7.4V12l3 2',
  nav: 'M12 3.4 19.2 20.6 12 16.6 4.8 20.6z',
  share: 'M12 15.2V3.8M8.4 7.4 12 3.8l3.6 3.6M5.4 12.6v7h13.2v-7',
  check: 'M4.8 12.4 9.4 17 19.2 6.8',
  lock: 'M5.4 10.6h13.2v9.4H5.4zM8.6 10.6V8a3.4 3.4 0 0 1 6.8 0v2.6',
  globe: 'M12 20.5a8.5 8.5 0 1 0 0-17 8.5 8.5 0 0 0 0 17zM3.6 12h16.8M12 3.5c2.4 2.4 3.6 5.3 3.6 8.5s-1.2 6.1-3.6 8.5c-2.4-2.4-3.6-5.3-3.6-8.5S9.6 5.9 12 3.5z',
  image: 'M3.6 4.6h16.8v14.8H3.6zM3.6 15.6l4.8-4.8 4 4 2.6-2.6 5.4 5.4M8.2 9.4a1.1 1.1 0 1 0 0-.1',
  flash: 'M13.4 3 6.6 13.6h4.6L10.6 21l6.8-10.6h-4.6z',
  send: 'M3.8 12 20.4 4.6 13 21l-2.1-7z',
  trash: 'M5 7h14M9.2 7V4.6h5.6V7M7.2 7l.9 13h7.8l.9-13',
  flag: 'M6 3.6v16.8M6 4.6h11.4l-2.1 4 2.1 4H6',
  sliders: 'M4 8.2h9.4M17 8.2h3M4 15.8h3M10.6 15.8H20M15.6 8.2a1.8 1.8 0 1 0 0-.1M8.6 15.8a1.8 1.8 0 1 0 0-.1',
  grid: 'M4 4h6.4v6.4H4zM13.6 4H20v6.4h-6.4zM4 13.6h6.4V20H4zM13.6 13.6H20V20h-6.4z',
  heart: 'M12 20s-7.6-4.6-7.6-9.6a4.3 4.3 0 0 1 7.6-2.6 4.3 4.3 0 0 1 7.6 2.6C19.6 15.4 12 20 12 20z',
  dots: 'M6 12h.1M12 12h.1M18 12h.1',
  coffee: 'M5 5h11v9a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4zM16 7h2.2a2.4 2.4 0 0 1 0 4.8H16M4 21h13',
  users: 'M9 20.4c0-2.9 2.2-4.8 5-4.8s5 1.9 5 4.8M14 12.2a3.6 3.6 0 1 0 0-7.2 3.6 3.6 0 0 0 0 7.2zM4 20.4c0-2.2 1.2-3.7 3-4.3M7.4 12a2.9 2.9 0 1 0 0-5.8',
  fork: 'M7 3.4v7.2a2 2 0 0 0 4 0V3.4M9 12.6v8M16.4 3.4c-1.4 2-2 4-2 6.4 0 1.6.8 2.4 2 2.4s2-.8 2-2.4c0-2.4-.6-4.4-2-6.4zM16.4 12.2v8.4',
  shield: 'M12 3 4 6.5v6c0 5 3.5 9 8 10.5 4.5-1.5 8-5.5 8-10.5v-6L12 3z',
  filter: 'M4 5h16l-6 7.5v6l-4-2v-4z',
  sparkler: 'M12 2.5v4M12 17.5v4M4.5 12h4M15.5 12h4M6.7 6.7l2.8 2.8M14.5 14.5l2.8 2.8M6.7 17.3l2.8-2.8M14.5 9.5l2.8-2.8'
};

export interface IconProps {
  name: keyof typeof ICON_PATHS | string;
  size?: number;
  sw?: number;
  fill?: string;
  className?: string;
  style?: React.CSSProperties;
}

export const Icon: React.FC<IconProps> = ({
  name,
  size = 20,
  sw = 1.9,
  fill = 'none',
  className = '',
  style,
}) => {
  const d = ICON_PATHS[name];
  if (!d) return null;

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      className={className}
      style={{ display: 'inline-block', verticalAlign: 'middle', flexShrink: 0, ...style }}
      aria-hidden="true"
    >
      <path
        d={d}
        fill={fill}
        stroke={fill === 'none' ? 'currentColor' : 'none'}
        strokeWidth={sw}
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
};
