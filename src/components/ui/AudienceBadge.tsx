import React from 'react';
import { Audience } from '../../types';
import { Icon } from './Icon';

export interface AudienceBadgeProps {
  aud: Audience;
  lg?: boolean;
  className?: string;
}

export const AudienceBadge: React.FC<AudienceBadgeProps> = ({ aud, lg = false, className = '' }) => {
  const isFriends = aud === 'friends';

  return (
    <span
      className={`pill ${isFriends ? 'fill-bu' : 'fill-ink'} ${lg ? 'lg' : ''} ${className}`}
      title={isFriends ? 'Only visible to your friends' : 'Publicly discoverable by everyone'}
    >
      <Icon name={isFriends ? 'lock' : 'globe'} size={lg ? 11 : 9} sw={2.4} />
      <span>{isFriends ? 'Friends' : 'Public'}</span>
    </span>
  );
};
