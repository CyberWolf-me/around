import React, { useState } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { Avatar } from '../components/ui/Avatar';
import { CityMap } from '../components/map/CityMap';
import { buzz } from '../services/haptics';
import { INITIAL_PEOPLE } from '../data/mockData';

export const OnboardingScreen: React.FC = () => {
  const { setBooted, places, followedUserIds, toggleFollowUser } = useApp();
  const [step, setStep] = useState<number>(0);

  const steps = [
    {
      kicker: 'Around · Tashkent',
      title: 'Where should\nwe go?',
      body: 'A map built from places in Tashkent your friends actually went — not from ratings written by strangers.',
      art: 'collage',
    },
    {
      kicker: 'Step 1 of 2',
      title: 'Follow five\nfriends.',
      body: 'Your feed is only as good as the people on it. Start with the friends in Tashkent you’d text for a recommendation.',
      art: 'people',
    },
    {
      kicker: 'Step 2 of 2',
      title: 'Pick your\ndistrict.',
      body: 'We’ll start around Mirabad, Yakkasaray, and Yunusabad so everything you see is walkable. You can widen this any time.',
      art: 'map',
    },
  ];

  const current = steps[step];

  const renderArt = () => {
    if (current.art === 'collage') {
      return (
        <div style={{ position: 'relative', flex: 1, minHeight: 240, maxHeight: 300, marginBottom: 16 }}>
          {/* Main photo */}
          <div
            style={{
              position: 'absolute',
              left: 4,
              top: 14,
              width: '64%',
              height: '76%',
              borderRadius: 18,
              overflow: 'hidden',
              border: '2.5px solid var(--ink)',
              boxShadow: 'var(--sh-lg)',
              transform: 'rotate(-3deg)',
            }}
          >
            <img src="/assets/bakery-counter.jpg" alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>

          {/* Top right photo */}
          <div
            style={{
              position: 'absolute',
              right: 4,
              top: 0,
              width: '46%',
              height: '52%',
              borderRadius: 16,
              overflow: 'hidden',
              border: '2px solid var(--ink)',
              boxShadow: 'var(--sh)',
              transform: 'rotate(4deg)',
            }}
          >
            <img src="/assets/patisserie.jpg" alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>

          {/* Bottom right photo */}
          <div
            style={{
              position: 'absolute',
              right: '6%',
              bottom: '6%',
              width: '42%',
              height: '34%',
              borderRadius: 14,
              overflow: 'hidden',
              border: '2px solid var(--ink)',
              boxShadow: 'var(--sh)',
              transform: 'rotate(-1.5deg)',
            }}
          >
            <img src="/assets/bookshop-tall.jpg" alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>

          {/* Floating Sticker */}
          <div
            style={{
              position: 'absolute',
              left: '8%',
              bottom: '4%',
              padding: '7px 12px',
              background: 'var(--butter)',
              border: '2px solid var(--ink)',
              borderRadius: 999,
              boxShadow: '2.5px 2.5px 0 var(--ink)',
              transform: 'rotate(-2deg)',
              display: 'flex',
              alignItems: 'center',
              gap: 6,
            }}
          >
            <Avatar id="kamila" size={19} />
            <span className="mono" style={{ color: 'var(--ink)', fontSize: 10, fontWeight: 700 }}>
              Kamila says go
            </span>
          </div>
        </div>
      );
    }

    if (current.art === 'people') {
      return (
        <div style={{ marginBottom: 20, display: 'flex', flexDirection: 'column', gap: 8, flex: 1, justifyContent: 'center' }}>
          {['kamila', 'bekzod', 'aziza', 'diyor', 'madina'].map((id) => {
            const p = INITIAL_PEOPLE[id];
            if (!p) return null;
            const isFollowing = followedUserIds.has(id);
            return (
              <div
                key={id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  padding: '8px 12px',
                  border: '2px solid var(--ink)',
                  borderRadius: 14,
                  background: 'var(--paper)',
                  boxShadow: '2px 2px 0 var(--ink)',
                }}
              >
                <Avatar id={id} size={32} />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 700 }}>{p.name}</div>
                  <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>
                    @{p.handle} · {p.neighborhood} · {p.dropsCount} drops
                  </div>
                </div>
                <button
                  className={`pill ${isFollowing ? 'fill-ink' : 'fill-or'}`}
                  style={{ height: 26, padding: '0 10px', cursor: 'pointer', fontSize: 10.5 }}
                  onClick={() => toggleFollowUser(id)}
                >
                  {isFollowing ? (
                    <>
                      <Icon name="check" size={9} sw={3} /> Following
                    </>
                  ) : (
                    '+ Follow'
                  )}
                </button>
              </div>
            );
          })}
        </div>
      );
    }

    return (
      <div style={{ marginBottom: 20, flex: 1, display: 'flex', alignItems: 'center' }}>
        <CityMap places={places} activePlaceId="breadly" onSelectPlace={() => {}} />
      </div>
    );
  };

  const handleNext = () => {
    if (step < 2) {
      setStep((s: number) => s + 1);
      buzz(8);
    } else {
      setBooted(true);
      buzz(16);
    }
  };

  return (
    <div
      className="screen onboarding-screen"
      style={{
        padding: '14px 18px 24px',
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        minHeight: '100vh',
        boxSizing: 'border-box',
      }}
    >
      {/* Top Bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div className="wordmark" style={{ fontSize: 21, fontWeight: 800 }}>
          Around<em style={{ color: 'var(--orange)', fontStyle: 'normal' }}>.</em>
        </div>
        <button
          className="mono-sm"
          onClick={() => setBooted(true)}
          style={{ background: 'none', border: 0, color: 'var(--ink-3)', cursor: 'pointer', fontSize: 11 }}
        >
          Skip
        </button>
      </div>

      {/* Dynamic Art Area */}
      <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
        {renderArt()}
      </div>

      {/* Copy Area */}
      <div style={{ marginTop: 6, flexShrink: 0 }}>
        <div className="mono-sm" style={{ color: 'var(--orange)', fontWeight: 700, marginBottom: 6, fontSize: 10 }}>
          {current.kicker}
        </div>
        <div className="display d-xl" style={{ whiteSpace: 'pre-line', marginBottom: 8, fontSize: 24, fontWeight: 800 }}>
          {current.title}
        </div>
        <div style={{ color: 'var(--ink-2)', fontSize: 13, lineHeight: 1.45, maxWidth: 320 }}>
          {current.body}
        </div>
      </div>

      {/* Footer Navigation */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 20, flexShrink: 0 }}>
        <div style={{ display: 'flex', gap: 5 }}>
          {steps.map((_, i) => (
            <span
              key={i}
              style={{
                width: i === step ? 20 : 6,
                height: 6,
                borderRadius: 99,
                background: i === step ? 'var(--ink)' : 'rgba(21,19,15,.2)',
                transition: 'all .3s',
              }}
            />
          ))}
        </div>

        <button
          className="btn btn-primary"
          style={{ flex: 1, height: 44, borderRadius: 12, boxShadow: 'var(--sh)' }}
          onClick={handleNext}
        >
          {step === 2 ? 'Launch Tashkent' : 'Next'}
          <Icon name="chevR" size={15} sw={2.5} />
        </button>
      </div>
    </div>
  );
};
