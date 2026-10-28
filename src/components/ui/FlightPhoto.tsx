import React, { useEffect, useState } from 'react';

export interface FlightState {
  src: string;
  x: number;
  y: number;
  w: number;
  h: number;
  radius: number;
  phase: 'in' | 'out';
}

export interface FlightPhotoProps {
  flight: FlightState | null;
}

export const FlightPhoto: React.FC<FlightPhotoProps> = ({ flight }) => {
  const [style, setStyle] = useState<React.CSSProperties>({});

  useEffect(() => {
    if (!flight) return;

    const host = document.getElementById('place-hero-target');
    const target = host ? host.getBoundingClientRect() : null;

    const t = target
      ? { x: target.left, y: target.top, w: target.width, h: target.height }
      : { x: flight.x, y: flight.y, w: flight.w, h: flight.h };

    if (flight.phase === 'in') {
      setStyle({
        position: 'fixed',
        left: 0,
        top: 0,
        zIndex: 9999,
        pointerEvents: 'none',
        transform: `translate(${flight.x}px, ${flight.y}px)`,
        width: flight.w,
        height: flight.h,
        borderRadius: 18,
        overflow: 'hidden',
        boxShadow: '0 12px 32px rgba(0,0,0,0.3)',
        transition: 'transform 380ms cubic-bezier(0.2, 0.85, 0.32, 1.2), width 380ms ease, height 380ms ease, border-radius 380ms ease',
      });

      const frameId = requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          setStyle(prev => ({
            ...prev,
            transform: `translate(${t.x}px, ${t.y}px)`,
            width: t.w,
            height: t.h,
            borderRadius: 22,
          }));
        });
      });

      return () => cancelAnimationFrame(frameId);
    } else {
      setStyle(prev => ({
        ...prev,
        opacity: 0,
        transition: 'opacity 200ms ease',
      }));
    }
  }, [flight]);

  if (!flight) return null;

  return (
    <div style={style}>
      <img
        src={flight.src}
        alt=""
        style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
      />
    </div>
  );
};
