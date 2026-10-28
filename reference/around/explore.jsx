/* ══════════════════════════════════════════════════════════
   EXPLORE — map / list, one tab, equal weight
   ══════════════════════════════════════════════════════════ */

const PIN_POS = {
  kettle:{ x:35, y:58 }, fern:{ x:52, y:33 }, sable:{ x:73, y:62 },
  castellan:{ x:12, y:26 }, volta:{ x:44, y:76 }, noodle:{ x:63, y:43 },
  marigold:{ x:86, y:35 }, longtable:{ x:22, y:77 }, quiet:{ x:31, y:19 },
};

function CityMap({ active, onPick, me }) {
  const blocks = [];
  const cols = [0, 74, 148, 222, 296];
  const rows = [0, 62, 124, 186];
  cols.forEach((x, i) => {
    rows.forEach((y, j) => {
      const w = i === cols.length - 1 ? 366 - x - 6 : 62;
      const h = j === rows.length - 1 ? 250 - y - 6 : 50;
      if (w <= 0 || h <= 0) return;
      const isPark = (i === 2 && j === 1);
      const isWater = (i === 3 && j === 2);
      blocks.push({ x: x + 4, y: y + 4, w, h, isPark, isWater, k: `${i}-${j}` });
    });
  });

  return (
    <div className="mapframe">
      <svg viewBox="0 0 366 250" className="map-svg" style={{ display: 'block' }}>
        <rect width="366" height="250" fill="#F3F0E4" />
        {blocks.map(b => (
          <rect key={b.k} x={b.x} y={b.y} width={b.w} height={b.h} rx="2.5"
            fill={b.isPark ? '#CFE2C4' : b.isWater ? '#CBDCE7' : '#E9E4D5'}
            stroke="rgba(21,19,15,.30)" strokeWidth="1" />
        ))}
        {/* the diagonal that gives the grid a memory */}
        <path d="M-4 232 L150 118 L250 118" stroke="#FBFAF6" strokeWidth="11" fill="none" />
        <path d="M-4 232 L150 118 L250 118" stroke="rgba(21,19,15,.24)" strokeWidth="1.4"
          fill="none" strokeDasharray="0" />
        <path d="M-4 232 L150 118 L250 118" stroke="#FBFAF6" strokeWidth="9" fill="none" />
        {/* labels */}
        <text x="230" y="106" fontFamily="Space Mono, monospace" fontSize="6.5"
          fill="rgba(21,19,15,.5)" letterSpacing="1">KESTREL LANE</text>
        <text x="160" y="216" fontFamily="Space Mono, monospace" fontSize="6.5"
          fill="rgba(21,19,15,.5)" letterSpacing="1" transform="rotate(-38 160 216)">PRINE ROW</text>
        <text x="180" y="152" fontFamily="Space Mono, monospace" fontSize="6"
          fill="rgba(21,19,15,.38)" letterSpacing=".8">FENWICK</text>
        <text x="46" y="96" fontFamily="Space Mono, monospace" fontSize="6"
          fill="rgba(21,19,15,.38)" letterSpacing=".8">HALLOWAY ST</text>
      </svg>

      {PLACES.map(p => {
        const pos = PIN_POS[p.id];
        const on = active === p.id;
        return (
          <button key={p.id} className={'pin' + (on ? ' on' : '')}
            style={{ left: pos.x + '%', top: pos.y + '%' }}
            onClick={() => onPick(p.id)} aria-label={p.name}>
            <span className="bulb"><img src={p.img} alt="" /></span>
            {on && <span className="stem" />}
            {on && <span className="lbl">{p.name}</span>}
          </button>
        );
      })}

      {me && <span className="map-me" style={{ left: '47%', top: '52%' }} />}
    </div>
  );
}

function VenueRow({ p, onOpen, saved, onSave, active }) {
  return (
    <button className="venrow" onClick={onOpen}
      style={active ? { boxShadow: '3px 3px 0 var(--orange)', borderColor: C.ink } : undefined}>
      <div className="thumb">
        <img src={p.img} alt="" className="photo" />
      </div>
      <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 3 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 5 }}>
          <span className="display d-sm" style={{ fontSize: 15.5, flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</span>
          <span className="mono-sm" style={{ color: 'var(--ink-3)' }}>{p.price}</span>
        </div>
        <div className="mono-sm" style={{ color: 'var(--ink-2)' }}>{p.cat} · {p.dist}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginTop: 1 }}>
          <Stars n={Math.round(p.rating)} size={9} gap={1} />
          <span style={{ fontSize: 10, fontWeight: 700 }}>{p.rating}</span>
          <span className="mono-sm" style={{ color: 'var(--ink-3)' }}>({p.reviews})</span>
          <span style={{ flex: 1 }} />
          <span onClick={e => { e.stopPropagation(); onSave(p.id); }}
            style={{
              display: 'flex', padding: 3,
              color: saved.includes(p.id) ? C.orange : 'rgba(21,19,15,.35)',
            }}>
            <Icon name="bookmark" size={15} sw={2.2}
              fill={saved.includes(p.id) ? 'currentColor' : 'none'} />
          </span>
        </div>
      </div>
    </button>
  );
}

function Explore({ mode, setMode, onOpenPlace, saved, onSave, onSavePlace }) {
  const [active, setActive] = React.useState('kettle');
  const [filter, setFilter] = React.useState('All');
  const filters = ['All', 'Café', 'Food', 'Study', 'Drinks', 'Shops'];

  const match = p => {
    if (filter === 'All') return true;
    if (filter === 'Café') return /Café|Bakery|Patisserie|Late café/.test(p.cat);
    if (filter === 'Food') return /Ramen|Patisserie|Bakery/.test(p.cat);
    if (filter === 'Study') return /Study|Work|Late café/.test(p.cat);
    if (filter === 'Drinks') return /Wine/.test(p.cat);
    if (filter === 'Shops') return /Record|Bookshop/.test(p.cat);
    return true;
  };
  const list = PLACES.filter(match);
  const activePlace = placeOf(active);

  return (
    <div className="screen">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingBottom: 12 }}>
        <div>
          <div className="mono" style={{ color: 'var(--ink-3)', marginBottom: 3 }}>Barlow Hill</div>
          <div className="display d-lg">Explore</div>
        </div>
        <button className="iconbtn tap" onClick={() => {}} aria-label="Filters">
          <Icon name="sliders" size={17} />
        </button>
      </div>

      <div className="field" style={{ marginBottom: 11 }}>
        <Icon name="search" size={16} sw={2.2} style={{ color: 'var(--ink-3)' }} />
        <input placeholder="Search places, tags, people" readOnly onFocus={e => e.target.blur()} />
        <span className="mono-sm" style={{ color: 'var(--ink-3)' }}>⌘K</span>
      </div>

      <div className="seg" style={{ marginBottom: 12 }}>
        <button className={mode === 'map' ? 'on' : ''} onClick={() => setMode('map')}>
          <Icon name="map" size={13} sw={2.3} /> Map
        </button>
        <button className={mode === 'list' ? 'on' : ''} onClick={() => setMode('list')}>
          <Icon name="list" size={13} sw={2.3} /> List
        </button>
      </div>

      <div className="scroll-x" style={{ marginBottom: 12 }}>
        {filters.map(f => (
          <button key={f} className={'tagchip' + (filter === f ? ' on' : '')}
            style={{ height: 27, fontSize: 11 }}
            onClick={() => { setFilter(f); buzz(5); }}>{f}</button>
        ))}
      </div>

      {mode === 'map' ? (
        <>
          <CityMap active={active} onPick={id => { setActive(id); buzz(6); }} me />
          {/* selected pin card — the map's answer to "so what?" */}
          <div style={{ marginTop: 12 }}>
            <div className="mono" style={{ color: 'var(--ink-3)', marginBottom: 7 }}>
              Nearest to you · {list.length} places
            </div>
            <button className="card" onClick={() => onOpenPlace(active, null)}
              style={{ width: '100%', textAlign: 'left', padding: 0, border: `2px solid ${C.ink}` }}>
              <div style={{ display: 'flex', gap: 0 }}>
                <div className="photo-wrap" style={{ width: 96, flexShrink: 0 }}>
                  <img src={activePlace.img} alt="" />
                </div>
                <div style={{ flex: 1, padding: '10px 11px', display: 'flex', flexDirection: 'column', gap: 4, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                    <span className="display d-sm" style={{ fontSize: 16, flex: 1 }}>{activePlace.name}</span>
                    <span className="mono-sm" style={{ color: 'var(--ink-3)' }}>{activePlace.price}</span>
                  </div>
                  <div className="mono-sm" style={{ color: 'var(--ink-2)' }}>
                    {activePlace.cat} · {activePlace.dist}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                    <Stars n={Math.round(activePlace.rating)} size={9} gap={1} />
                    <span style={{ fontSize: 10, fontWeight: 700 }}>{activePlace.rating}</span>
                    <span className="mono-sm" style={{ color: 'var(--ink-3)' }}>· 3 friends been</span>
                  </div>
                  <div className="body-s" style={{ fontSize: 11, lineHeight: 1.35, marginTop: 1 }}>
                    {activePlace.line}
                  </div>
                </div>
              </div>
            </button>

            {/* what friends did here — the reason a map beats a listing */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginTop: 11, padding: '9px 11px',
              border: '1.5px solid rgba(21,19,15,.16)', borderRadius: 14, background: 'rgba(255,224,122,.22)' }}>
              <span className="av-stack">
                {['noor', 'teo', 'mina'].map(f => <Av key={f} id={f} size={22} />)}
              </span>
              <span style={{ flex: 1, fontSize: 11, lineHeight: 1.35, color: C.ink2 }}>
                <b style={{ color: C.ink }}>Noor</b> and 3 friends have been here recently.
              </span>
              <span className="pill" style={{ height: 19 }}>
                <Icon name="lock" size={8} sw={2.6} /> Friends
              </span>
            </div>

            <div className="sectionhead" style={{ marginTop: 16 }}>
              <span className="display d-sm">Also nearby</span>
              <button className="mono" onClick={() => setMode('list')}
                style={{ background: 'none', border: 0, color: C.ink2, cursor: 'pointer' }}>
                See all {list.length}
              </button>
            </div>
            <div className="scroll-x" style={{ gap: 8 }}>
              {list.filter(p => p.id !== active).slice(0, 4).map(p => (
                <button key={p.id} onClick={() => { setActive(p.id); buzz(5); }}
                  style={{ width: 104, flexShrink: 0, border: 0, background: 'none', padding: 0, cursor: 'pointer', textAlign: 'left' }}>
                  <div style={{ height: 64, borderRadius: 11, overflow: 'hidden', border: '1.5px solid var(--ink)', boxShadow: '1.5px 1.5px 0 var(--ink)' }}>
                    <img src={p.img} alt="" className="photo" />
                  </div>
                  <div style={{ fontSize: 10, fontWeight: 700, marginTop: 5, lineHeight: 1.2,
                    overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</div>
                  <div className="mono-sm" style={{ color: C.ink3, marginTop: 1 }}>{p.dist}</div>
                </button>
              ))}
            </div>
          </div>
        </>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
            <span className="mono" style={{ color: 'var(--ink)' }}>{list.length} places</span>
            <span style={{ flex: 1, height: 1.5, background: 'rgba(21,19,15,.16)' }} />
            <span className="mono" style={{ color: 'var(--ink-3)' }}>Closest first</span>
          </div>
          {list.map(p => (
            <VenueRow key={p.id} p={p} saved={saved} onSave={onSave}
              active={active === p.id}
              onOpen={e => onOpenPlace(p.id, e.currentTarget)} />
          ))}
        </div>
      )}
    </div>
  );
}

Object.assign(window, { Explore, CityMap, VenueRow, PIN_POS });
