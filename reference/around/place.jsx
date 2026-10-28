/* ══════════════════════════════════════════════════════════
   PLACE PAGE — structured record × social proof
   ══════════════════════════════════════════════════════════ */

function MiniMap({ p, onOpen }) {
  const pos = PIN_POS[p.id] || { x: 50, y: 50 };
  return (
    <button className="mapstrip" onClick={onOpen}
      style={{ width: '100%', padding: 0, cursor: 'pointer', display: 'block' }}>
      <svg viewBox="0 0 366 96" style={{ display: 'block', width: '100%', height: '100%' }}>
        <rect width="366" height="96" fill="#F3F0E4" />
        {[0, 1, 2, 3, 4].map(i => (
          <rect key={'a' + i} x={i * 74 + 4} y="4" width="60" height="34" rx="2"
            fill="#E9E4D5" stroke="rgba(21,19,15,.28)" strokeWidth="1" />
        ))}
        {[0, 1, 2, 3, 4].map(i => (
          <rect key={'b' + i} x={i * 74 + 4} y="58" width="60" height="32" rx="2"
            fill={i === 2 ? '#CFE2C4' : '#E9E4D5'} stroke="rgba(21,19,15,.28)" strokeWidth="1" />
        ))}
        <rect x="0" y="42" width="366" height="14" fill="#FBFAF6" />
        <line x1="0" y1="49" x2="366" y2="49" stroke="rgba(21,19,15,.22)" strokeWidth="1" strokeDasharray="4 5" />
      </svg>
      <span className="map-me" style={{ left: pos.x + '%', top: pos.y + '%' }} />
      <span style={{
        position: 'absolute', right: 8, bottom: 8,
        display: 'flex', alignItems: 'center', gap: 4,
        background: 'var(--paper)', border: '1.5px solid var(--ink)',
        borderRadius: 999, padding: '3px 8px',
        fontFamily: 'var(--mono)', fontSize: 7.5, letterSpacing: '.08em',
        textTransform: 'uppercase', boxShadow: '2px 2px 0 var(--ink)',
      }}>
        <Icon name="nav" size={9} sw={2.4} fill="currentColor" /> 4 min
      </span>
    </button>
  );
}

function PlacePage({ id, onBack, onSave, saved, onDrop, onOpenProfile }) {
  const p = placeOf(id) || PLACES[0];
  const isSaved = saved.includes(p.id);
  const friendDrops = DROPS.filter(d => d.place === p.id);
  const [tab, setTab] = React.useState('people');
  const [showAll, setShowAll] = React.useState(false);

  return (
    <div className="screen" style={{ paddingTop: 6 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 11 }}>
        <button className="iconbtn tap" onClick={onBack} aria-label="Back">
          <Icon name="chevL" size={15} sw={2.5} />
        </button>
        <span className="mono" style={{ color: 'var(--ink-3)', flex: 1 }}>
          Place · {p.cat.split(' · ')[0]}
        </span>
        <button className={'iconbtn tap'} onClick={() => { onSave(p.id); buzz(); }}
          style={isSaved ? { background: C.orange, color: '#fff' } : undefined}
          aria-label="Save">
          <Icon name="bookmark" size={15} sw={2.2} fill={isSaved ? 'currentColor' : 'none'} />
        </button>
        <button className="iconbtn tap" aria-label="Share">
          <Icon name="share" size={15} sw={2.2} />
        </button>
      </div>

      {/* hero */}
      <div className="hero-card" style={{ marginBottom: 13 }}>
        <div className="photo-wrap" id="place-hero-target" style={{ height: 232 }} data-flight={p.id}>
          <img src={p.img} alt={p.name} />
          <div style={{
            position: 'absolute', inset: 0,
            background: 'linear-gradient(to top, rgba(21,19,15,.62) 0%, rgba(21,19,15,.06) 46%, transparent 70%)',
          }} />
          <div style={{ position: 'absolute', left: 13, right: 13, bottom: 12, color: '#fff' }}>
            <div style={{ display: 'flex', gap: 5, marginBottom: 5 }}>
              <span className="pill fill-or" style={{ borderColor: 'rgba(255,255,255,.5)' }}>
                {p.cat.split(' · ')[0]}
              </span>
              <span className="pill" style={{ background: 'rgba(251,250,246,.94)' }}>
                Open · till {p.hours.split('– ')[1]}
              </span>
            </div>
            <div className="display" style={{ fontSize: 29, color: '#fff', textShadow: '0 1px 12px rgba(0,0,0,.3)' }}>
              {p.name}
            </div>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 5, marginTop: 4,
              fontSize: 11.5, fontWeight: 500, color: 'rgba(255,255,255,.9)',
            }}>
              <Icon name="map" size={11} sw={2.3} />
              {p.street} · {p.dist}
            </div>
          </div>
        </div>
      </div>

      {/* the trust split: friends first, then the crowd */}
      <div className="statgrid" style={{ marginBottom: 13 }}>
        <div className="stat">
          <b>{p.rating}</b>
          <span>{p.reviews} public ratings</span>
        </div>
        <div className="stat" style={{ background: C.butter }}>
          <b>{FRIENDS_BEEN[p.id] || 3}</b>
          <span>friends have been</span>
        </div>
        <div className="stat">
          <b>{p.price}</b>
          <span>price range</span>
        </div>
      </div>

      {/* friend proof — the differentiator, given real estate */}
      {friendDrops.length > 0 && (
        <div style={{ marginBottom: 15 }}>
          <div className="sectionhead">
            <span className="display d-sm">Your people</span>
            <span className="mono" style={{ color: 'var(--ink-3)' }}>Friends only</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {friendDrops.slice(0, 2).map(d => (
              <div key={d.id} className="quote" style={{ flexDirection: 'row', gap: 9, alignItems: 'flex-start' }}>
                <Av id={d.who} size={26} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginBottom: 2 }}>
                    <span style={{ fontSize: 11.5, fontWeight: 700, whiteSpace: 'nowrap' }}>
                      {PEOPLE[d.who].name.split(' ')[0]}
                    </span>
                    {d.rating && <Stars n={d.rating} size={8} gap={1} />}
                    <span className="mono-sm" style={{ color: 'var(--ink-3)', marginLeft: 'auto' }}>{d.when}</span>
                  </div>
                  <div className="txt">“{d.note}”</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* photos */}
      <div className="sectionhead">
        <span className="display d-sm">Photos</span>
        <span className="mono" style={{ color: 'var(--ink-3)' }}>{p.imgs.length + 31} · 9 people</span>
      </div>
      <div className="photogrid" style={{ marginBottom: 15 }}>
        {p.imgs.map((src, i) => (
          <div key={i} style={{ border: i > 0 ? '1.5px solid var(--ink)' : '1.5px solid var(--ink)', gridColumn: 'span 1' }}>
            <img src={src} alt="" className="photo" />
          </div>
        ))}
      </div>

      {/* tabs: people vs public */}
      <div className="seg" style={{ marginBottom: 12 }}>
        <button className={tab === 'people' ? 'on' : ''} onClick={() => setTab('people')}>
          <Icon name="users" size={13} sw={2.2} /> Friends
        </button>
        <button className={tab === 'public' ? 'on' : ''} onClick={() => setTab('public')}>
          <Icon name="globe" size={13} sw={2.2} /> Everyone
        </button>
      </div>

      {tab === 'people' ? (
        friendDrops.length === 0 ? (
          <div className="endcard" style={{ marginBottom: 14 }}>
            <div className="display d-sm">No friends yet.</div>
            <div className="body-s">Nobody you follow has dropped this place.</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 9, marginBottom: 14 }}>
            {friendDrops.map(d => (
              <div key={d.id} className="card-flat" style={{ display: 'flex', gap: 9, padding: 9 }}>
                {d.img && (
                  <div className="photo-wrap" style={{ width: 58, height: 58, borderRadius: 11, border: '1.5px solid var(--ink)', flexShrink: 0, overflow: 'hidden' }}>
                    <img src={d.img} alt="" />
                  </div>
                )}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginBottom: 3 }}>
                    <Av id={d.who} size={17} />
                    <span style={{ fontSize: 11, fontWeight: 700 }}>{PEOPLE[d.who].name.split(' ')[0]}</span>
                    <span className="mono-sm" style={{ color: 'var(--ink-3)', marginLeft: 'auto' }}>{d.when}</span>
                  </div>
                  <div style={{ fontSize: 11.8, lineHeight: 1.4 }}>{d.note}</div>
                </div>
              </div>
            ))}
            <button className="btn btn-ghost btn-sm btn-block" style={{ height: 34 }} onClick={() => {}}>
              See all {friendDrops.length} friend drops
            </button>
          </div>
        )
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11, marginBottom: 14 }}>
          {(showAll ? PUBLIC_NOTES.concat(PUBLIC_NOTES) : PUBLIC_NOTES).map((n, i) => (
            <div key={i} style={{
              paddingBottom: 11,
              borderBottom: '1.5px solid rgba(21,19,15,.1)',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                <Av id={n.who} size={20} />
                <span style={{ fontSize: 11.5, fontWeight: 700 }}>{PEOPLE[n.who].name}</span>
                <Stars n={n.rating} size={8} gap={1} />
                <span className="mono-sm" style={{ color: 'var(--ink-3)', marginLeft: 'auto' }}>{n.when}</span>
              </div>
              <div style={{ fontSize: 12.3, lineHeight: 1.45, color: C.ink2 }}>{n.txt}</div>
            </div>
          ))}
          <button className="btn btn-ghost btn-sm btn-block" style={{ height: 34 }}
            onClick={() => setShowAll(!showAll)}>
            {showAll ? 'Show fewer' : 'Load 182 more reviews'}
          </button>
        </div>
      )}

      {/* location */}
      <div className="sectionhead">
        <span className="display d-sm">Getting there</span>
        <span className="mono" style={{ color: 'var(--ink-3)' }}>{p.street}</span>
      </div>
      <MiniMap p={p} onOpen={() => {}} />

      <div style={{ display: 'flex', gap: 7, marginTop: 11, marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 5, flex: 1 }}>
          <Icon name="clock" size={12} sw={2.2} style={{ color: 'var(--ink-3)' }} />
          <span className="mono-sm" style={{ color: 'var(--ink-2)' }}>{p.hours} · {p.closed}</span>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <button className="btn btn-ink" style={{ flex: 1 }} onClick={onDrop}>
          <Icon name="plus" size={16} sw={2.6} /> Drop it
        </button>
        <button className="btn" style={{ width: 52, padding: 0, flexShrink: 0 }}>
          <Icon name="nav" size={16} sw={2.2} fill="currentColor" />
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { PlacePage, MiniMap });
