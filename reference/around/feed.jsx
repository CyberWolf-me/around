/* ══════════════════════════════════════════════════════════
   FEED — friends layer, bento grid, finite (no infinite scroll)
   ══════════════════════════════════════════════════════════ */

function AppHead({ notifCount, onBell, onProfile, saved }) {
  return (
    <>
      <div className="apphead">
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 7 }}>
          <div className="wordmark">Around<em>.</em></div>
        </div>
        <div style={{ display: 'flex', gap: 7, alignItems: 'center' }}>
          <button className="iconbtn sm plain bell tap" onClick={onBell} aria-label="Notifications">
            <Icon name="bell" size={19} />
            {notifCount > 0 && <span className="bell-dot" />}
          </button>
          <button className="iconbtn plain tap" onClick={onProfile} aria-label="Profile"
            style={{ width: 33, height: 33 }}>
            <Av id="you" size={31} />
          </button>
        </div>
      </div>
    </>
  );
}

function StoryRail({ onOpen }) {
  return (
    <div className="scroll-x" style={{ paddingTop: 3 }}>
      {STORIES.map(id => {
        const p = placeOf(id);
        const d = DROPS.find(x => x.place === id);
        return (
          <button key={id} onClick={e => onOpen(id, e.currentTarget)}
            style={{
              border: 0, background: 'none', padding: 0, cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 5,
              flexShrink: 0, width: 62,
            }}>
            <div style={{
              width: 58, height: 58, borderRadius: 999, padding: 2.5,
              border: `2px solid var(--ink)`, background: 'var(--paper)',
              boxShadow: '2px 2px 0 var(--ink)',
            }}>
              <div style={{ width: '100%', height: '100%', borderRadius: 999, overflow: 'hidden' }}>
                <img src={d.img || p.img} alt="" className="photo" />
              </div>
            </div>
            <span style={{
              fontFamily: 'var(--mono)', fontSize: 7, letterSpacing: '.06em',
              textTransform: 'uppercase', color: 'var(--ink-2)', textAlign: 'center',
              lineHeight: 1.25, width: 62, overflow: 'hidden', textOverflow: 'ellipsis',
            }}>{p.name.split(' ')[0]}</span>
          </button>
        );
      })}
      <div style={{ flexShrink: 0, width: 2 }} />
    </div>
  );
}

function DropCard({ d, onOpen, onSave, saved }) {
  const p = placeOf(d.place);
  const who = PEOPLE[d.who];

  if (d.size === 'note') {
    return (
      <button className="note-card span2" onClick={e => onOpen(d, e.currentTarget)}
        style={{ background: d.tint, gridColumn: 'span 2' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <Av id={d.who} size={19} />
          <span style={{ fontSize: 10.5, fontWeight: 700 }}>{who.name.split(' ')[0]}</span>
          <span className="mono-sm" style={{ color: 'var(--ink-2)', marginLeft: 'auto' }}>
            {p.cat.split(' · ')[0]}
          </span>
        </div>
        <div className="q">“{d.note}”</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
          <span className="pill fill-ink" style={{ borderColor: C.ink }}>
            {p.name} <Icon name="arrowUR" size={8} sw={3} />
          </span>
          {d.tags && d.tags.map(t => <span key={t} className="pill ghost">{t}</span>)}
        </div>
      </button>
    );
  }

  const hero = d.size === 'hero';
  const wide = d.size === 'wide';
  const imgH = hero ? 196 : wide ? 132 : 116;

  return (
    <button className={'drop-card' + (hero || wide ? ' span2' : '')}
      onClick={e => onOpen(d, e.currentTarget)}>
      <div className="dc-img" style={{ height: imgH }}>
        <img src={d.img} alt={p.name} loading="lazy" />
        <span className="dc-aud"><Aud aud={d.aud} /></span>
        <span className={'dc-save' + (saved.includes(d.place) ? ' on' : '')}
          onClick={e => { e.stopPropagation(); onSave(d.place); buzz(); }}>
          <Icon name="bookmark" size={14} sw={2}
            fill={saved.includes(d.place) ? 'currentColor' : 'none'} />
        </span>
        {wide && (
          <div style={{
            position: 'absolute', left: 0, right: 0, bottom: 0, height: 52,
            background: 'linear-gradient(to top, rgba(21,19,15,.5), transparent)',
          }} />
        )}
      </div>
      <div className="dc-body">
        <div className="dc-who">
          <Av id={d.who} size={17} />
          <span className="n">{who.name.split(' ')[0]}</span>
          {hero && d.rating && <Stars n={d.rating} size={9} gap={1} />}
          <span className="t">{d.when}</span>
        </div>
        <div className={'dc-note' + (hero ? ' lead' : '')}
          style={hero ? undefined : {
            display: '-webkit-box', WebkitLineClamp: wide ? 2 : 3,
            WebkitBoxOrient: 'vertical', overflow: 'hidden',
          }}>{d.note}</div>
        <div className="dc-place">
          <Icon name="map" size={9} sw={2.4} style={{ color: 'var(--ink-3)', flexShrink: 0 }} />
          <span className="pn">{p.name}</span>
          <span className="pm">· {p.dist}</span>
        </div>
      </div>
    </button>
  );
}

function Feed({ onOpenPlace, onOpenDrop, onSave, saved, onBell, onProfile, notifCount, onExplore, drops }) {
  const friends = ['noor', 'teo', 'mina', 'ari'];
  const list = drops || DROPS;
  return (
    <div className="screen">
      <AppHead notifCount={notifCount} onBell={onBell} onProfile={onProfile} />

      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 11,
      }}>
        <div>
          <div className="mono" style={{ color: 'var(--ink-3)', marginBottom: 3 }}>
            Barlow Hill · Tue 28 Oct
          </div>
          <div className="display d-lg">Today,<br />from your people</div>
        </div>
        <div className="av-stack" style={{ flexShrink: 0, paddingRight: 4 }}>
          {friends.map((f, i) => <Av key={f} id={f} size={27} />)}
          <div style={{
            marginLeft: -8, width: 27, height: 27, borderRadius: 999,
            border: '1.8px solid var(--ink)', background: 'var(--paper)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: 'var(--mono)', fontSize: 7.5, fontWeight: 700,
            boxShadow: '0 0 0 2px var(--paper)', flexShrink: 0,
          }}>+3</div>
        </div>
      </div>

      <StoryRail onOpen={onOpenPlace} />

      <div style={{ display: 'flex', alignItems: 'center', gap: 8, margin: '16px 0 2px' }}>
        <span className="mono" style={{ color: 'var(--ink)' }}>{list.length} drops</span>
        <span style={{ flex: 1, height: 1.5, background: 'rgba(21,19,15,.16)' }} />
        <span className="mono" style={{ color: 'var(--ink-3)' }}>Friends only</span>
        <Icon name="lock" size={10} sw={2.6} style={{ color: 'var(--ink-3)' }} />
      </div>

      <div className="bento">
        {list.map(d => (
          <DropCard key={d.id} d={d} saved={saved}
            onSave={onSave}
            onOpen={(drop, el) => onOpenDrop(drop, el)} />
        ))}
      </div>

      {/* finite feed — a real end state, per the product principles */}
      <div className="endcard">
        <div className="stamp">
          <Icon name="check" size={20} sw={2.6} />
        </div>
        <div className="display d-sm">That’s everything<br />from today.</div>
        <div className="body-s" style={{ maxWidth: 220 }}>
          {list.length} drops from five friends. Nothing hidden, nothing
          infinite — come back tomorrow.
        </div>
        <button className="btn btn-sm btn-ink" style={{ marginTop: 5 }} onClick={onExplore}>
          Explore the whole map
          <Icon name="arrowUR" size={13} sw={2.6} />
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { Feed, DropCard, AppHead, StoryRail });
