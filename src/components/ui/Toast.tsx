import React from 'react';
import { Icon } from './Icon';
import { COLORS } from '../../data/mockData';

export interface ToastProps {
  message: string | null;
  kind?: 'success' | 'info' | 'warning';
}

export const Toast: React.FC<ToastProps> = ({ message, kind = 'success' }) => {
  if (!message) return null;

  return (
    <div
      className="toast-container"
      role="status"
      aria-live="polite"
      style={{
        position: 'absolute',
        bottom: 96,
        left: 18,
        right: 18,
        zIndex: 9999,
        background: COLORS.ink,
        color: COLORS.paper,
        borderRadius: 14,
        padding: '11px 16px',
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        boxShadow: '0 8px 24px rgba(21, 19, 15, 0.35), 3px 3px 0 rgba(0,0,0,0.2)',
        border: '1.5px solid rgba(255,255,255,0.12)',
        animation: 'popIn 0.25s cubic-bezier(0.2, 0.9, 0.3, 1)',
      }}
    >
      <Icon
        name={kind === 'warning' ? 'flag' : 'check'}
        size={16}
        sw={2.8}
        style={{ color: kind === 'warning' ? '#FFB74D' : COLORS.butter }}
      />
      <span style={{ fontSize: 13, fontWeight: 600, letterSpacing: '-0.01em', flex: 1 }}>
        {message}
      </span>
    </div>
  );
};
