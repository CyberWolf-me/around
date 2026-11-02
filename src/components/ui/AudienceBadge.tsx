import React from 'react';
import { Audience } from '../../types';
import { Icon } from './Icon';
import { playSoundWithHaptic } from '../../services/soundEffects';

export interface AudienceBadgeProps {
  aud: Audience;
  lg?: boolean;
  className?: string;
  interactive?: boolean;
  onClick?: () => void;
}

export const AudienceBadge: React.FC<AudienceBadgeProps> = ({
  aud,
  lg = false,
  className = '',
  interactive = false,
  onClick,
}) => {
  const isFriends = aud === 'friends';

  const handleClick = (e: React.MouseEvent) => {
    if (interactive && onClick) {
      e.stopPropagation();
      playSoundWithHaptic('click', 'selection');
      onClick();
    }
  };

  return (
    <span
      className={`pill ${isFriends ? 'fill-bu' : 'fill-ink'} ${lg ? 'lg' : ''} ${className}`}
      title={isFriends ? 'Only visible to your friends' : 'Publicly discoverable by everyone'}
      onClick={interactive ? handleClick : undefined}
      style={interactive ? { cursor: 'pointer', userSelect: 'none' } : undefined}
      role={interactive ? 'button' : undefined}
      tabIndex={interactive ? 0 : undefined}
    >
      <Icon name={isFriends ? 'lock' : 'globe'} size={lg ? 11 : 9} sw={2.4} />
      <span>{isFriends ? 'Friends' : 'Public'}</span>
    </span>
  );
};
