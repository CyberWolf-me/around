import React from 'react';
import { useApp } from '../../context/AppContext';
import { Toast } from '../ui/Toast';

export interface MobileFrameProps {
  children: React.ReactNode;
}

export const MobileFrame: React.FC<MobileFrameProps> = ({ children }) => {
  const { deviceFrame, toast, stack } = useApp();
  const isPlaceActive = stack.length > 0 && stack[stack.length - 1].kind === 'place';

  if (deviceFrame === 'fullscreen') {
    return (
      <div className="mobile-fullscreen-root" style={{ width: '100%', maxWidth: 440, minHeight: '100vh', margin: '0 auto', position: 'relative', background: 'var(--paper)' }}>
        <div className="viewport" style={{ minHeight: '100vh', paddingBottom: isPlaceActive ? 0 : 80 }}>
          {children}
        </div>
        <Toast message={toast} />
      </div>
    );
  }

  return (
    <div className="device-hold">
      <div
        className={`device ${deviceFrame === 'pixel' ? 'device-pixel' : 'device-iphone'}`}
        style={{ background: 'var(--paper)' }}
      >
        {/* Dynamic Island or Camera Punch Hole */}
        {deviceFrame === 'iphone' ? (
          <div className="island" />
        ) : (
          <div className="pixel-camera" />
        )}

        {/* Status Bar */}
        <div className="statusbar" style={{ color: '#15130F' }}>
          <span style={{ fontWeight: 600, fontSize: 13 }}>9:41</span>
          <span className="sb-r" style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            {/* Cellular */}
            <svg width="17" height="11" viewBox="0 0 17 11">
              <rect x="0" y="7" width="3" height="4" rx="1" fill="currentColor" />
              <rect x="4.5" y="4.6" width="3" height="6.4" rx="1" fill="currentColor" />
              <rect x="9" y="2.3" width="3" height="8.7" rx="1" fill="currentColor" />
              <rect x="13.5" y="0" width="3" height="11" rx="1" fill="currentColor" />
            </svg>
            {/* WiFi */}
            <svg width="16" height="11" viewBox="0 0 16 11">
              <path
                d="M8 2.6c2.1 0 4 .8 5.4 2.2l1-1C12.8 2.2 10.5 1.3 8 1.3S3.2 2.2 1.6 3.8l1 1C4 3.4 5.9 2.6 8 2.6z"
                fill="currentColor"
              />
              <path
                d="M8 6c1.2 0 2.3.5 3.1 1.3l1-1C10.9 5.1 9.5 4.5 8 4.5s-2.9.6-4.1 1.8l1 1C5.7 6.5 6.8 6 8 6z"
                fill="currentColor"
              />
              <circle cx="8" cy="9.6" r="1.4" fill="currentColor" />
            </svg>
            {/* Battery */}
            <svg width="25" height="12" viewBox="0 0 25 12">
              <rect x="0.5" y="0.5" width="21" height="11" rx="3.2" fill="none" stroke="currentColor" strokeOpacity=".4" />
              <rect x="2" y="2" width="18" height="8" rx="2" fill="currentColor" />
              <path d="M23 4.2v3.6c.8-.3 1.4-1 1.4-1.8s-.6-1.5-1.4-1.8z" fill="currentColor" fillOpacity=".45" />
            </svg>
          </span>
        </div>

        {/* Viewport Screen Content */}
        <div
          className={`viewport ${isPlaceActive ? 'no-tab' : ''}`}
          id="main-viewport"
        >
          {children}
        </div>

        {/* Home gesture bar */}
        <div className="homebar">
          <div />
        </div>

        {/* Toast notifications */}
        <Toast message={toast} />
      </div>
    </div>
  );
};
