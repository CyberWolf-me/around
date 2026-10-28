import React from 'react';
import { INITIAL_PEOPLE, COLORS } from '../../data/mockData';

export interface AvatarProps {
  id: string;
  size?: number;
  ring?: boolean;
  className?: string;
  onClick?: (e: React.MouseEvent) => void;
}

export const Avatar: React.FC<AvatarProps> = ({
  id,
  size = 28,
  ring = true,
  className = '',
  onClick,
}) => {
  const p = INITIAL_PEOPLE[id] || INITIAL_PEOPLE.you;
  const isDark = p.bg === COLORS.cobalt || p.bg === COLORS.orange;

  return (
    <div
      className={`avatar-circle ${className}`}
      onClick={onClick}
      style={{
        width: size,
        height: size,
        minWidth: size,
        background: p.bg,
        color: isDark ? '#FFFFFF' : COLORS.ink,
        fontSize: Math.max(9, Math.round(size * 0.38)),
        borderWidth: ring ? Math.max(1.4, Math.round(size * 0.05)) : 0,
        borderColor: COLORS.ink,
        borderStyle: 'solid',
        borderRadius: '50%',
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: 'var(--display)',
        fontWeight: 700,
        letterSpacing: '-0.02em',
        boxSizing: 'border-box',
        cursor: onClick ? 'pointer' : 'default',
        userSelect: 'none',
      }}
      title={`${p.name} (@${p.handle})`}
    >
      {p.init}
    </div>
  );
};
