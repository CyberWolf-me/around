import React from 'react';
import { COLORS } from '../../data/mockData';
import { ICON_PATHS } from './Icon';

export interface StarRatingProps {
  rating: number;
  size?: number;
  gap?: number;
  interactive?: boolean;
  onChange?: (rating: number) => void;
}

export const StarRating: React.FC<StarRatingProps> = ({
  rating,
  size = 12,
  gap = 2,
  interactive = false,
  onChange,
}) => {
  return (
    <span
      style={{
        display: 'inline-flex',
        gap,
        alignItems: 'center',
        cursor: interactive ? 'pointer' : 'default',
      }}
    >
      {[1, 2, 3, 4, 5].map((starIndex) => {
        const isFilled = starIndex <= Math.round(rating);

        return (
          <button
            key={starIndex}
            type="button"
            disabled={!interactive}
            onClick={() => interactive && onChange && onChange(starIndex)}
            style={{
              padding: 0,
              background: 'none',
              border: 0,
              cursor: interactive ? 'pointer' : 'default',
              display: 'inline-flex',
            }}
            aria-label={`${starIndex} stars`}
          >
            <svg
              width={size}
              height={size}
              viewBox="0 0 24 24"
              style={{ display: 'block', transition: 'transform 0.15s ease' }}
            >
              <path
                d={ICON_PATHS.star}
                fill={isFilled ? COLORS.orange : 'none'}
                stroke={isFilled ? COLORS.orange : 'rgba(21, 19, 15, 0.28)'}
                strokeWidth="2.2"
                strokeLinejoin="round"
              />
            </svg>
          </button>
        );
      })}
    </span>
  );
};
