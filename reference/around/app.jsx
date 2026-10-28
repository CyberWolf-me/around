/* ══════════════════════════════════════════════════════════
   APP SHELL — navigation, sheets, shared-element photo flight
   ══════════════════════════════════════════════════════════ */

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "orange",
  "paper": "bone",
  "feedLayout": "bento",
  "audienceDefault": "friends",
  "sheetMotion": "spring",
  "startScreen": "feed"
}/*EDITMODE-END*/;

const ACCENTS = {
  orange: { name: 'Signal', main: '#FF5A1F', soft: '#FFE07A' },
  cobalt: { name: 'Cobalt', main: '#2B4CFF', soft: '#D7E3EC' },
  moss:   { name: 'Moss',   main: '#1F7A4C', soft: '#D5E8CB' },
  plum:   { name: 'Plum',   main: '#8A2E5C', soft: '#F6D2C4' },
};
const PAPERS = {
  bone:  { name: 'Bone',  base: '#FBFAF6', tint: '#F1EEE4', deep: '#E6E1D3' },
  chalk: { name: 'Chalk', base: '#FFFFFF', tint: '#F4F4F2', deep: '#E8E8E4' },
  sand:  { name: 'Sand',  base: '#F8F3E9', tint: '#EFE7D7', deep: '#E0D6C1' },
};

function usePalette(t) {
  React.useEffect(() => {
    const r = document.documentElement.style;
    r.setProperty('--orange', ACCENTS[t.accent].main);
    r.setProperty('--butter', ACCENTS[t.accent].soft);
    r.setProperty('--paper', PAPERS[t.paper].base);
    r.setProperty('--paper-2', PAPERS[t.paper].tint);
    r.setProperty('--paper-3', PAPERS[t.paper].deep);
  }, [t.accent, t.paper]);
}

/* ── shared-element photo flight ─────────────────────────── */
function useFlight() {
  const [flight, setFlight] = React.useState(null);
  const start = React.useCallback((el, src, radius = 20) => {
    if (!el || !src) return null;
    const img = el.querySelector('img');
    const box = (img || el).getBoundingClientRect();
    setFlight({ src, x: box.left, y: box.top, w: box.width, h: box.height, radius, phase: 'in' });
    return true;
  }, []);
  const settle = React.useCallback(() => {
    setFlight(f => (f ? { ...f, phase: 'out' } : null));
    setTimeout(() => setFlight(null), 240);
  }, []);
  return { flight, start, settle };
}

function Flight({ flight }) {
  const [style, setStyle] = React.useState({});
  React.useEffect(() => {
    if (!flight) return;
    const host = document.getElementById('place-hero-target');
    const target = host ? host.getBoundingClientRect() : null;
    const t = target
      ? { x: target.left, y: target.top, w: target.width, h: target.height }
      : { x: flight.x, y: flight.y, w: flight.w, h: flight.h };
    if (flight.phase === 'in') {
      setStyle({
        transform: `translate(${flight.x}px, ${flight.y}px)`,
        width: flight.w, height: flight.h, borderRadius: 18,
      });
      requestAnimationFrame(() => requestAnimationFrame(() => {
        setStyle({
          transform: `translate(${t.x}px, ${t.y}px)`,
          width: t.w, height: t.h, borderRadius: 22,
        });
      }));
    } else {
      setStyle({ opacity: 0 });
    }
  }, [flight]);
  if (!flight) return null;
  return (
    <div className="flight" style={{ ...style, transitionDuration: flight.phase === 'in' ? '380ms' : '200ms' }}>
      <img src={flight.src} alt="" />
    </div>
  );
}

/* ── the app ─────────────────────────────────────────────── */
function App() {
  const [t, setTweak] = React.useState(TWEAK_DEFAULTS);
  usePalette(t);

  const [booted, setBooted] = React.useState(false);
  const [tab, setTab] = React.useState(TWEAK_DEFAULTS.startScreen === 'explore' ? 'explore' : 'feed');
  const [mode, setMode] = React.useState('map');
  const [stack, setStack] = React.useState([]);
  const [saved, setSaved] = React.useState(['kettle', 'sable', 'castellan']);
  const [create, setCreate] = React.useState({ open: false, place: null, step: 0 });
  const [toast, setToast] = React.useState(null);
  const [drops, setDrops] = React.useState(DROPS);
  const [heroId, setHeroId] = React.useState(null);
  const { flight, start, settle } = useFlight();
  const [defaultAud, setDefaultAud] = React.useState('friends');
  const scroller = React.useRef(null);

  const top = stack[stack.length - 1];

  const showToast = msg => {
    setToast(msg);
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => setToast(null), 2200);
  };

  const toggleSave = id => {
    setSaved(s => {
      const on = s.includes(id);
      showToast(on ? 'Removed from saved' : 'Saved to your shortlist');
      return on ? s.filter(x => x !== id) : [...s, id];
    });
  };

  const openPlace = (id, el) => {
    setHeroId(id);
    const p = placeOf(id);
    const ok = start(el, p.img, 18);
    setStack(s => [...s, { kind: 'place', id }]);
    if (ok) setTimeout(settle, 400);
  };
  const push = v => setStack(s => [...s, v]);
  const pop = () => setStack(s => s.slice(0, -1));
  const switchTab = id => { setStack([]); setTab(id); if (scroller.current) scroller.current.scrollTop = 0; };

  const publish = d => {
    setDrops(ds => [{
      id: 'new' + Date.now(), who: 'you', place: d.place,
      img: d.photo, size: 'hero', note: d.note || 'Dropped this place.',
      rating: d.rating || null, when: 'now', saves: 0,
      aud: d.aud, tags: d.tags, fresh: true,
    }, ...ds]);
    setTimeout(() => showToast(d.aud === 'friends' ? 'Dropped for your friends' : 'Dropped publicly'), 300);
  };

  const notifCount = 3;

  const screenBody = () => {
    if (top) {
      if (top.kind === 'place')
        return <PlacePage id={top.id} onBack={pop} onSave={toggleSave} saved={saved}
          onDrop={() => setCreate({ open: true, place: top.id, step: 2 })}
          onOpenProfile={() => {}} />;
      if (top.kind === 'notifs')
        return <Notifications onBack={pop} onOpenPlace={openPlace} />;
      if (top.kind === 'profile')
        return <ProfileScreen saved={saved} onOpenPlace={openPlace}
          onSettings={() => push({ kind: 'settings' })} />;
      if (top.kind === 'settings')
        return <Settings onBack={pop} defaultAud={defaultAud} setDefaultAud={setDefaultAud}
          toast={() => showToast('Not wired in this prototype')} />;
    }
    if (!booted) return <Onboarding onDone={() => setBooted(true)} />;
    if (tab === 'feed')
      return <Feed saved={saved} onSave={toggleSave} onOpenDrop={(d, el) => openPlace(d.place, el)}
        onOpenPlace={openPlace}
        drops={drops}
        onBell={() => push({ kind: 'notifs' })}
        onProfile={() => push({ kind: 'profile' })}
        notifCount={notifCount}
        onExplore={() => switchTab('explore')} />;
    if (tab === 'explore')
      return <Explore mode={mode} setMode={setMode} saved={saved}
        onSave={toggleSave} onOpenPlace={openPlace} />;
    if (tab === 'saved')
      return <SavedScreen saved={saved} onOpenPlace={openPlace}
        onUnsave={toggleSave} onExplore={() => switchTab('explore')} />;
    return null;
  };

  const hideChrome = !booted || (top && top.kind === 'place');

  return (
    <div className="stage">
      <aside className="rail">
        <div className="mark">Around<span>.</span></div>
        <div className="sub">Places from people<br />you actually trust.</div>
        <div className="rail-h">Screens</div>
        <nav className="rail-nav">
          {[
            ['feed', 'Friends feed'], ['explore', 'Explore · map'], ['explore-list', 'Explore · list'],
            ['place', 'Place page'], ['create', 'Create a drop'], ['saved', 'Saved places'],
            ['profile', 'Profile'], ['settings', 'Settings'], ['notifs', 'Activity'], ['onboard', 'Onboarding'],
          ].map(([k, label], i) => {
            const active = (k === 'feed' && tab === 'feed' && !top && booted) ||
              (k === 'explore' && tab === 'explore' && mode === 'map' && !top && booted) ||
              (k === 'explore-list' && tab === 'explore' && mode === 'list' && !top && booted) ||
              (k === 'saved' && tab === 'saved' && !top && booted) ||
              (k === 'place' && top && top.kind === 'place') ||
              (k === 'notifs' && top && top.kind === 'notifs') ||
              (k === 'profile' && top && top.kind === 'profile') ||
              (k === 'settings' && top && top.kind === 'settings') ||
              (k === 'onboard' && !booted);
            return (
              <button key={k} className={active ? 'on' : ''} onClick={() => {
                setStack([]);
                setCreate(c => ({ ...c, open: false }));
                if (k === 'feed') { setTab('feed'); setBooted(true); }
                else if (k === 'explore') { setTab('explore'); setMode('map'); setBooted(true); }
                else if (k === 'explore-list') { setTab('explore'); setMode('list'); setBooted(true); }
                else if (k === 'saved') { setTab('saved'); setBooted(true); }
                else if (k === 'place') { setBooted(true); setTab('feed'); setHeroId('kettle'); setTimeout(() => setStack(s => [...s, { kind: 'place', id: 'kettle' }]), 40); }
                else if (k === 'notifs') { setBooted(true); setTab('feed'); setTimeout(() => setStack(s => [{ kind: 'notifs' }]), 40); }
                else if (k === 'profile') { setBooted(true); setTab('feed'); setTimeout(() => setStack(s => [{ kind: 'profile' }]), 40); }
                else if (k === 'settings') { setBooted(true); setTab('feed'); setTimeout(() => setStack(s => [{ kind: 'settings' }]), 40); }
                else if (k === 'create') { setBooted(true); setTab('feed'); setCreate({ open: true, place: 'kettle', step: 0 }); }
                else if (k === 'onboard') { setBooted(false); setTab('feed'); }
                if (scroller.current) scroller.current.scrollTop = 0;
              }}>
                <i>{String(i + 1).padStart(2, '0')}</i>{label}
              </button>
            );
          })}
        </nav>
        <div className="rail-note">
          Click through — every screen<br />is wired. Drag a sheet down<br />to dismiss it.
        </div>
      </aside>

      <div className="device-hold">
        <div className="device" style={{
          background: PAPERS[t.paper].base,
        }}>
          <div className="island" />
          <div className="statusbar" style={{ color: '#15130F' }}>
            <span>9:41</span>
            <span className="sb-r">
              <svg width="17" height="11" viewBox="0 0 17 11"><rect x="0" y="7" width="3" height="4" rx="1" fill="currentColor"/><rect x="4.5" y="4.6" width="3" height="6.4" rx="1" fill="currentColor"/><rect x="9" y="2.3" width="3" height="8.7" rx="1" fill="currentColor"/><rect x="13.5" y="0" width="3" height="11" rx="1" fill="currentColor"/></svg>
              <svg width="16" height="11" viewBox="0 0 16 11"><path d="M8 2.6c2.1 0 4 .8 5.4 2.2l1-1C12.8 2.2 10.5 1.3 8 1.3S3.2 2.2 1.6 3.8l1 1C4 3.4 5.9 2.6 8 2.6z" fill="currentColor"/><path d="M8 6c1.2 0 2.3.5 3.1 1.3l1-1C10.9 5.1 9.5 4.5 8 4.5s-2.9.6-4.1 1.8l1 1C5.7 6.5 6.8 6 8 6z" fill="currentColor"/><circle cx="8" cy="9.6" r="1.4" fill="currentColor"/></svg>
              <svg width="25" height="12" viewBox="0 0 25 12"><rect x="0.5" y="0.5" width="21" height="11" rx="3.2" fill="none" stroke="currentColor" strokeOpacity=".4"/><rect x="2" y="2" width="18" height="8" rx="2" fill="currentColor"/><path d="M23 4.2v3.6c.8-.3 1.4-1 1.4-1.8s-.6-1.5-1.4-1.8z" fill="currentColor" fillOpacity=".45"/></svg>
            </span>
          </div>

          <div className={'viewport' + (hideChrome ? ' no-tab' : '')}
            id={top && top.kind === 'place' ? 'place-hero-target-wrap' : undefined}
            ref={scroller} key={top ? top.kind + (top.id || '') : tab + booted}>
            {screenBody()}
          </div>

          {!hideChrome && (
            <div className="tabbar">
              {[
                ['feed', 'home', 'Feed'],
                ['explore', 'compass', 'Explore'],
                [null, null, null],
                ['saved', 'bookmark', 'Saved'],
                ['profile', 'user', 'You'],
              ].map(([id, icon, label], i) => {
                if (id === null) return (
                  <button key="drop" className="tab-drop" onClick={() => { setCreate({ open: true, place: null, step: 0 }); buzz(12); }}>
                    <span className="orb"><Icon name="plus" size={24} sw={2.8} /></span>
                    <span>Drop</span>
                  </button>
                );
                if (id === 'profile') return (
                  <button key="profile" className={'tab' + (top && top.kind === 'profile' ? ' on' : '')}
                    onClick={() => push({ kind: 'profile' })}>
                    <Icon name="user" size={19} sw={2} />
                    <span>{label}</span>
                    <span className="tab-dot" />
                  </button>
                );
                return (
                  <button key={id} className={'tab' + (tab === id && !top ? ' on' : '')}
                    onClick={() => switchTab(id)}>
                    <Icon name={icon} size={19} sw={2} />
                    <span>{label}</span>
                    <span className="tab-dot" />
                  </button>
                );
              })}
            </div>
          )}

          <div className="homebar"><div /></div>

          <CreateFlow open={create.open} presetPlace={create.place}
            initialStep={create.step}
            defaultAud={defaultAud}
            onClose={() => setCreate(c => ({ ...c, open: false }))}
            onPublish={publish} />

          {toast && (
            <div className="pop" style={{
              position: 'absolute', bottom: 96, left: 18, right: 18, zIndex: 90,
              background: C.ink, color: C.paper, borderRadius: 13,
              padding: '11px 14px', display: 'flex', alignItems: 'center', gap: 8,
              boxShadow: '3px 3px 0 rgba(21,19,15,.3)',
            }}>
              <Icon name="check" size={14} sw={2.8} style={{ color: '#FFE07A' }} />
              <span style={{ fontSize: 12.5, fontWeight: 600 }}>{toast}</span>
            </div>
          )}
        </div>
      </div>

      <aside className="stage-side">
        <div style={{ marginBottom: 18 }}>
          <b>Product</b>
          Places-first social<br />discovery. Friends layer<br />+ public layer.
        </div>
        <div style={{ marginBottom: 18 }}>
          <b>Type</b>
          Bricolage Grotesque<br />Instrument Sans<br />Space Mono
        </div>
        <div style={{ marginBottom: 18 }}>
          <b>Palette</b>
          Bone paper · ink<br />One signal accent
        </div>
        <div>
          <b>Try</b>
          The bookmark on any<br />card. The Drop button.<br />The audience step.
        </div>
      </aside>

      <Flight flight={flight} />
    </div>
  );
}

/* mount after all modules have registered globals */
function boot() {
  if (!window.PLACES || !window.CreateFlow || !window.SavedScreen) {
    setTimeout(boot, 60);
    return;
  }
  ReactDOM.createRoot(document.getElementById('root')).render(<App />);
}
boot();
