/* ══════════════════════════════════════════════════════════
   SAVED · PROFILE · NOTIFICATIONS · ONBOARDING
   ══════════════════════════════════════════════════════════ */

function SavedScreen({ saved, onOpenPlace, onUnsave, onExplore }) {
  const [filter, setFilter] = React.useState('All');
  const ids = saved.length ? saved : ['kettle', 'sable', 'castellan'];
  const filters = ['All', 'Want to go', 'Been'];
  const plans = [
    { id: 'kettle', who: ['noor', 'teo'], when: 'Sat' },
    { id: 'castellan', who: ['ari'], when: 'Fri' },
  ];

  return (
    <div className="screen">
      <div style={{ paddingBottom: 12 }}>
        <div className="mono" style={{ color: C.ink3, marginBottom: 3 }}>Your shortlist</div>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
          <div className="display d-xl">Saved</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
            <span className="display d-md" style={{ color: C.orange }}>{ids.length}</span>
            <span className="mono" style={{ color: C.ink3 }}>places</span>
          </div>
        </div>
      </div>

      <div className="seg" style={{ marginBottom: 13 }}>
        {filters.map(f => (
          <button key={f} className={filter === f ? 'on' : ''} onClick={() => setFilter(f)}>{f}</button>
        ))}
      </div>

      {/* shared plans — the reason to come back */}
      <div style={{
        border: `2px solid ${C.ink}`, borderRadius: 18, background: C.mint,
        padding: '11px 12px', boxShadow: '3px 3px 0 var(--ink)', marginBottom: 15,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
          <Icon name="users" size={13} sw={2.3} />
          <span className="mono" style={{ color: C.ink }}>2 plans with friends</span>
        </div>
        {plans.map(pl => {
          const p = placeOf(pl.id);
          return (
            <button key={pl.id} onClick={() => onOpenPlace(pl.id, null)}
              style={{
                display: 'flex', alignItems: 'center', gap: 8, width: '100%',
                padding: '6px 0', background: 'none', border: 0, cursor: 'pointer',
                borderTop: '1px solid rgba(21,19,15,.16)', textAlign: 'left',
              }}>
              <span className="av-stack">
                {pl.who.map(w => <Av key={w} id={w} size={19} />)}
              </span>
              <span style={{ fontSize: 12, fontWeight: 700, flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</span>
              <span className="pill fill-ink" style={{ height: 19 }}>{pl.when}</span>
            </button>
          );
        })}
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {ids.map((id, i) => {
          const p = placeOf(id);
          if (!p) return null;
          return (
            <div key={id} style={{ display: 'flex', gap: 9, alignItems: 'stretch' }}>
              <button className="venrow" style={{ flex: 1 }}
                onClick={e => onOpenPlace(id, e.currentTarget)}>
                <div className="thumb" style={{ width: 56, height: 56 }}>
                  <img src={p.img} alt="" className="photo" />
                </div>
                <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 3 }}>
                  <span className="display d-sm" style={{ fontSize: 15 }}>{p.name}</span>
                  <span className="mono-sm" style={{ color: C.ink3 }}>{p.cat} · {p.dist}</span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <Stars n={Math.round(p.rating)} size={8} gap={1} />
                    <span style={{ fontSize: 9.5, fontWeight: 700 }}>{p.rating}</span>
                  </span>
                </div>
              </button>
              <button className="iconbtn" onClick={() => { onUnsave(id); buzz(); }}
                style={{ alignSelf: 'center', background: C.orange, color: '#fff' }}
                aria-label="Remove">
                <Icon name="bookmark" size={14} sw={2.2} fill="currentColor" />
              </button>
            </div>
          );
        })}
      </div>

      <button className="btn btn-ghost btn-block btn-sm" style={{ marginTop: 14, height: 38 }}
        onClick={onExplore}>
        <Icon name="compass" size={14} sw={2.2} /> Find more places
      </button>
    </div>
  );
}

function ProfileScreen({ saved, onOpenPlace, onSettings }) {
  const mine = [
    { place: 'kettle', note: 'Back room, second table, 9am. The only correct answer.', aud: 'friends', when: '2d', likes: 14 },
    { place: 'sable', note: 'Found a 1978 pressing of the thing I have been looking for all year.', aud: 'public', when: '1w', likes: 41 },
    { place: 'volta', note: 'Third floor, poetry, nobody up there.', aud: 'friends', when: '2w', likes: 9 },
  ];
  return (
    <div className="screen">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14, paddingTop: 4 }}>
        <span className="mono" style={{ color: C.ink3 }}>Profile</span>
        <button className="iconbtn sm plain tap" onClick={onSettings} aria-label="Settings">
          <Icon name="dots" size={18} sw={3.2} />
        </button>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 13, marginBottom: 15 }}>
        <div style={{
          width: 74, height: 74, borderRadius: 999, border: `2.5px solid ${C.ink}`,
          background: C.orange, color: '#fff', display: 'flex', alignItems: 'center',
          justifyContent: 'center', fontFamily: 'var(--display)', fontWeight: 800,
          fontSize: 27, letterSpacing: '-.03em', boxShadow: '3px 3px 0 var(--ink)', flexShrink: 0,
        }}>YO</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="display d-md" style={{ marginBottom: 1 }}>Yusuf Okonjo</div>
          <div className="mono-sm" style={{ color: C.ink3, marginBottom: 5 }}>@yusuf · Barlow Hill</div>
          <div style={{ display: 'flex', gap: 11 }}>
            {[['24', 'drops'], ['5', 'friends'], ['18', 'saved']].map(([n, l]) => (
              <span key={l} style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
                <span style={{ fontSize: 13, fontWeight: 700 }}>{n}</span>
                <span className="mono-sm" style={{ color: C.ink3 }}>{l}</span>
              </span>
            ))}
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: 7, marginBottom: 16 }}>
        <button className="btn btn-sm" style={{ flex: 1 }}>Edit profile</button>
        <button className="btn btn-sm btn-ghost" style={{ flex: 1 }}>
          <Icon name="users" size={13} sw={2.2} /> Find friends
        </button>
      </div>

      <div className="sectionhead">
        <span className="display d-sm">Your drops</span>
        <span className="mono" style={{ color: C.ink3 }}>Friends & public</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
        {mine.map((m, i) => {
          const p = placeOf(m.place);
          return (
            <div key={i} className="card-flat" style={{ display: 'flex', gap: 9, padding: 9 }}
              onClick={() => onOpenPlace(m.place, null)}>
              <div className="photo-wrap" style={{ width: 52, height: 52, borderRadius: 10, overflow: 'hidden', flexShrink: 0, border: '1.5px solid var(--ink)' }}>
                <img src={p.img} alt="" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 5, marginBottom: 3 }}>
                  <span style={{ fontSize: 11.5, fontWeight: 700, flex: 1, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.name}</span>
                  <Aud aud={m.aud} />
                </div>
                <div style={{ fontSize: 11.3, lineHeight: 1.38, color: C.ink2 }}>{m.note}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                  <span className="mono-sm" style={{ color: C.ink3 }}>{m.when}</span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
                    <Icon name="heart" size={10} sw={2.2} style={{ color: C.orange }} />
                    <span style={{ fontSize: 9.5, fontWeight: 700 }}>{m.likes}</span>
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div style={{ marginTop: 18, paddingTop: 12, borderTop: '1.5px solid rgba(21,19,15,.12)' }}>
        <div className="mono" style={{ color: C.ink3, marginBottom: 9 }}>You also saved</div>
        <div className="scroll-x">
          {(saved.length ? saved : ['kettle', 'sable']).slice(0, 4).map(id => {
            const p = placeOf(id);
            return (
              <button key={id} onClick={() => onOpenPlace(id, null)}
                style={{ border: 0, background: 'none', padding: 0, width: 72, flexShrink: 0, cursor: 'pointer' }}>
                <div style={{ height: 72, borderRadius: 12, overflow: 'hidden', border: '1.5px solid var(--ink)' }}>
                  <img src={p.img} alt="" className="photo" />
                </div>
                <div style={{ fontSize: 9.5, fontWeight: 700, marginTop: 4, lineHeight: 1.2 }}>{p.name}</div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

const NOTIFS = [
  { who:'noor', kind:'drop', place:'kettle', txt:'dropped Kettle & Loaf', when:'2h', unread:true },
  { who:'teo', kind:'save', place:'fern', txt:'saved your drop at The Fern Room', when:'5h', unread:true },
  { who:'mina', kind:'follow', place:null, txt:'started following you', when:'7h', unread:true },
  { who:'ari', kind:'plan', place:'castellan', txt:'added Castellan to your Friday plan', when:'1d', unread:false },
  { who:'priya', kind:'drop', place:'volta', txt:'dropped Volta Books', when:'1d', unread:false },
  { who:'jonah', kind:'save', place:'noodle', txt:'saved your drop at Noodle Union', when:'2d', unread:false },
];

function Notifications({ onOpenPlace, onBack }) {
  return (
    <div className="screen">
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, paddingTop: 4, marginBottom: 13 }}>
        <button className="iconbtn tap" onClick={onBack}><Icon name="chevL" size={15} sw={2.5} /></button>
        <div className="display d-lg" style={{ flex: 1 }}>Activity</div>
        <span className="pill fill-or lg">3 new</span>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column' }}>
        {NOTIFS.map((n, i) => (
          <button key={i} onClick={() => n.place && onOpenPlace(n.place, null)}
            style={{
              display: 'flex', alignItems: 'center', gap: 9, padding: '10px 0',
              background: n.unread ? 'rgba(255,224,122,.28)' : 'none',
              border: 0, borderRadius: 0,
              borderBottom: '1.5px solid rgba(21,19,15,.09)',
              textAlign: 'left', cursor: 'pointer', width: '100%',
              marginLeft: 0,
            }}>
            <div style={{ position: 'relative', flexShrink: 0 }}>
              <Av id={n.who} size={32} />
              <span style={{
                position: 'absolute', right: -3, bottom: -3, width: 16, height: 16,
                borderRadius: 999, background: C.paper, border: '1.5px solid var(--ink)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={n.kind === 'drop' ? 'map' : n.kind === 'save' ? 'bookmark' : n.kind === 'follow' ? 'users' : 'clock'}
                  size={8} sw={2.6} />
              </span>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 12.3, lineHeight: 1.35 }}>
                <b>{PEOPLE[n.who].name}</b> <span style={{ color: C.ink2 }}>{n.txt}</span>
              </div>
              <div className="mono-sm" style={{ color: C.ink3, marginTop: 2 }}>{n.when}</div>
            </div>
            {n.place && (
              <div style={{ width: 38, height: 38, borderRadius: 9, overflow: 'hidden', border: '1.5px solid var(--ink)', flexShrink: 0 }}>
                <img src={placeOf(n.place).img} alt="" className="photo" />
              </div>
            )}
          </button>
        ))}
      </div>
      <div className="mono" style={{ color: C.ink3, textAlign: 'center', marginTop: 16 }}>
        That’s everything from the last 2 days
      </div>
    </div>
  );
}

/* ── onboarding ────────────────────────────────────────────── */
function Onboarding({ onDone }) {
  const [step, setStep] = React.useState(0);
  const steps = [
    {
      kicker: 'Around · Barlow Hill',
      title: 'Where should\nwe go?',
      body: 'A map built from places your friends actually went — not from ratings written by strangers.',
      art: 'collage',
    },
    {
      kicker: 'Step 1 of 2',
      title: 'Follow five\npeople.',
      body: 'Your feed is only as good as the people on it. Start with the ones you’d text for a recommendation.',
      art: 'people',
    },
    {
      kicker: 'Step 2 of 2',
      title: 'Pick a\nneighbourhood.',
      body: 'We’ll start with one area so everything you see is walkable. You can widen this any time.',
      art: 'map',
    },
  ];
  const s = steps[step];

  const Art = () => {
    if (s.art === 'collage') {
      return (
        <div style={{ position: 'relative', flex: 1, minHeight: 0, maxHeight: 300, marginBottom: 20 }}>
          <div style={{
            position: 'absolute', left: 0, top: 18, width: '62%', height: '76%',
            borderRadius: 18, overflow: 'hidden', border: `2px solid ${C.ink}`,
            boxShadow: '5px 5px 0 var(--ink)', transform: 'rotate(-3deg)',
          }}>
            <img src="assets/kettle-hero.jpg" alt="" className="photo" />
          </div>
          <div style={{
            position: 'absolute', right: 0, top: 0, width: '46%', height: '52%',
            borderRadius: 18, overflow: 'hidden', border: `2px solid ${C.ink}`,
            boxShadow: '5px 5px 0 var(--ink)', transform: 'rotate(4deg)',
          }}>
            <img src="assets/wine-tall.jpg" alt="" className="photo" />
          </div>
          <div style={{
            position: 'absolute', right: '4%', bottom: '6%', width: '42%', height: '34%',
            borderRadius: 16, overflow: 'hidden', border: `2px solid ${C.ink}`,
            boxShadow: '4px 4px 0 var(--ink)', transform: 'rotate(-1.5deg)',
          }}>
            <img src="assets/bookshop-tall.jpg" alt="" className="photo" />
          </div>
          <div style={{
            position: 'absolute', left: '6%', bottom: '2%', padding: '8px 12px',
            background: C.butter, border: `2px solid ${C.ink}`, borderRadius: 999,
            boxShadow: '2.5px 2.5px 0 var(--ink)', transform: 'rotate(-2deg)',
            display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <Av id="noor" size={18} />
            <span className="mono" style={{ color: C.ink }}>Noor says go</span>
          </div>
        </div>
      );
    }
    if (s.art === 'people') {
      return (
        <div style={{ marginBottom: 26, display: 'flex', flexDirection: 'column', gap: 8, flex: 1, justifyContent: 'center' }}>
          {['noor', 'teo', 'mina', 'ari'].map((id, i) => (
            <div key={id} style={{
              display: 'flex', alignItems: 'center', gap: 9, padding: '8px 10px',
              border: `2px solid ${C.ink}`, borderRadius: 14, background: C.paper,
              boxShadow: '2px 2px 0 var(--ink)',
            }}>
              <Av id={id} size={30} />
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 12.5, fontWeight: 700 }}>{PEOPLE[id].name}</div>
                <div className="mono-sm" style={{ color: C.ink3 }}>@{PEOPLE[id].handle} · 14 drops</div>
              </div>
              <span className="pill fill-or" style={{ height: 24, padding: '0 10px' }}>
                <Icon name="check" size={9} sw={3} /> Follow
              </span>
            </div>
          ))}
        </div>
      );
    }
    return (
      <div style={{ marginBottom: 26, flex: 1, display: 'flex', alignItems: 'center' }}>
        <CityMap active="kettle" onPick={() => {}} me />
      </div>
    );
  };

  return (
    <div className="screen" style={{ paddingTop: 12, paddingBottom: 20, display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <div className="wordmark" style={{ fontSize: 19 }}>Around<em>.</em></div>
        <button className="mono" onClick={onDone}
          style={{ background: 'none', border: 0, color: C.ink3, cursor: 'pointer' }}>
          Skip
        </button>
      </div>

      <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
        <Art />
      </div>

      <div style={{ marginTop: 4, flexShrink: 0 }}>
        <div className="mono" style={{ color: C.orange, marginBottom: 8 }}>{s.kicker}</div>
        <div className="display d-xl" style={{ whiteSpace: 'pre-line', marginBottom: 10 }}>{s.title}</div>
        <div className="body-t" style={{ color: C.ink2, fontSize: 13.5, maxWidth: 300 }}>
          {s.body}
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 22, flexShrink: 0 }}>
        <div style={{ display: 'flex', gap: 4 }}>
          {steps.map((_, i) => (
            <span key={i} style={{
              width: i === step ? 18 : 6, height: 6, borderRadius: 99,
              background: i === step ? C.ink : 'rgba(21,19,15,.2)',
              transition: 'all .3s',
            }} />
          ))}
        </div>
        <button className="btn btn-primary" style={{ flex: 1 }}
          onClick={() => { if (step < 2) { setStep(step + 1); buzz(6); } else onDone(); }}>
          {step === 2 ? 'Show me Barlow Hill' : 'Next'}
          <Icon name="chevR" size={15} sw={2.5} />
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { SavedScreen, ProfileScreen, Notifications, Onboarding, NOTIFS });
