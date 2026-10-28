/* ══════════════════════════════════════════════════════════
   CREATE A DROP — camera → venue → note → audience → done
   ══════════════════════════════════════════════════════════ */

const AUDIENCES = [
  {
    id:'friends', title:'Friends only', icon:'lock', tint:C.butter,
    body:'Only people you follow back can see this. It shows up in their feed and on this place, for them.',
    foot:'4 friends will see it',
  },
  {
    id:'public', title:'Public', icon:'globe', tint:C.paper2,
    body:'Anyone on Around can find this — in Explore and on the place page. Your location history stays private.',
    foot:'Everyone in Barlow Hill',
  },
];

const TAGSET = ['quiet mornings','good cortado','outlets','date night','late night','cash only','big tables','solo seats','sells out early','staff picks'];

function CreateFlow({ open, onClose, presetPlace, onPublish, initialStep, defaultAud }) {
  const [step, setStep] = React.useState(0);
  const [photo, setPhoto] = React.useState('assets/kettle-hero.jpg');
  const [place, setPlace] = React.useState(presetPlace || 'kettle');
  const [note, setNote] = React.useState('');
  const [rating, setRating] = React.useState(0);
  const [tags, setTags] = React.useState([]);
  const [aud, setAud] = React.useState('friends');
  const [done, setDone] = React.useState(false);
  const [q, setQ] = React.useState('');
  const [drag, setDrag] = React.useState({ y: 0, active: false });
  const dragStart = React.useRef(null);
  const dragY = React.useRef(0);

  React.useEffect(() => {
    if (!open) return;
    const onKey = e => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  const onPointerDown = e => {
    dragStart.current = e.clientY;
    dragY.current = 0;
    setDrag({ y: 0, active: true });
  };
  const onPointerMove = e => {
    if (dragStart.current == null) return;
    const dy = Math.max(0, e.clientY - dragStart.current);
    dragY.current = dy;
    setDrag({ y: dy, active: true });
  };
  const onPointerUp = () => {
    if (dragStart.current == null) return;
    const dy = dragY.current;
    dragStart.current = null;
    dragY.current = 0;
    setDrag({ y: 0, active: false });
    if (dy > 100) { onClose(); buzz(10); }
  };

  React.useEffect(() => {
    if (open) {
      setStep(initialStep || 0);
      setPlace(presetPlace || 'kettle');
      setDone(false);
      setNote(''); setRating(0); setTags([]); setAud(defaultAud || 'friends');
    }
  }, [open, presetPlace, initialStep, defaultAud]);

  if (!open) return null;

  const STEPS = ['Photo', 'Place', 'Note', 'Who'];
  const sel = placeOf(place);
  const canNext = step === 0 ? !!photo : step === 1 ? !!place : true;
  const sheetH = done ? 470 : step === 0 ? 500
    : step === 1 ? 640 : step === 2 ? 508 : 482;

  const next = () => {
    if (step < 3) { setStep(step + 1); buzz(6); }
    else { setDone(true); buzz(18); onPublish({ place, note, rating, tags, aud, photo }); }
  };
  const back = () => { if (step > 0) setStep(step - 1); else onClose(); };

  const gallery = ['assets/kettle-hero.jpg','assets/pastries.jpg','assets/wine-tall.jpg','assets/records-crates.jpg','assets/ramen.jpg','assets/bookshop-tall.jpg','assets/study-desk.jpg','assets/street.jpg'];

  return (
    <>
      <div className="sheet-scrim" onClick={onClose} />
      <div className="sheet" style={{
        height: sheetH,
        transform: drag.y ? `translateY(${drag.y}px)` : undefined,
        transition: drag.active ? 'none' : 'height .34s cubic-bezier(.22,1,.36,1), transform .3s cubic-bezier(.22,1,.36,1)',
      }}>
        <div className="sheet-grab"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
          style={{ cursor: drag.active ? 'grabbing' : 'grab', touchAction: 'none', paddingBottom: 8 }}>
          <div style={{ width: drag.y ? 52 : 42 }} />
        </div>

        {done ? (
          <div className="sheet-body" style={{ display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', paddingBottom: 40 }}>
            <div className="success-stamp" style={{
              width: 92, height: 92, borderRadius: 999, border: `2.5px solid ${C.ink}`,
              background: aud === 'friends' ? C.butter : C.ink,
              color: aud === 'friends' ? C.ink : C.paper,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '4px 4px 0 var(--ink)', marginBottom: 18,
            }}>
              <Icon name={aud === 'friends' ? 'lock' : 'globe'} size={42} sw={2.2} />
            </div>
            <div className="display d-lg" style={{ textAlign: 'center', marginBottom: 6 }}>
              Dropped.
            </div>
            <div className="body-t" style={{ textAlign: 'center', maxWidth: 260, color: C.ink2, marginBottom: 4 }}>
              Your note is live on <b style={{ color: C.ink }}>{sel.name}</b>.
            </div>
            <div className="mono" style={{ color: C.ink3, marginBottom: 22 }}>
              {aud === 'friends' ? 'Visible to your friends' : 'Visible to everyone on Around'}
            </div>

            <div className="card-flat" style={{ display: 'flex', gap: 9, padding: 9, width: '100%', marginBottom: 16 }}>
              <div className="photo-wrap" style={{ width: 54, height: 54, borderRadius: 10, overflow: 'hidden', flexShrink: 0, border: '1.5px solid var(--ink)' }}>
                <img src={photo} alt="" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 700, marginBottom: 2 }}>{sel.name}</div>
                <div className="body-s" style={{ fontSize: 11, lineHeight: 1.35 }}>
                  {note ? `“${note.slice(0, 58)}${note.length > 58 ? '…' : ''}”` : 'No note — just the photo.'}
                </div>
              </div>
            </div>

            <button className="btn btn-ink btn-block" onClick={onClose}>Back to the feed</button>
            <button className="btn btn-ghost btn-sm btn-block" style={{ marginTop: 8, height: 36 }}
              onClick={() => { setDone(false); setStep(0); }}>
              Add another
            </button>
          </div>
        ) : (
          <>
            <div style={{ padding: '0 18px 10px', flexShrink: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 9 }}>
                <button className="iconbtn sm plain tap" onClick={back} style={{ marginLeft: -6 }}>
                  <Icon name={step === 0 ? 'x' : 'chevL'} size={step === 0 ? 17 : 15} sw={2.4} />
                </button>
                <div className="progress">
                  {STEPS.map((s, i) => <i key={s} className={i <= step ? 'on' : ''} />)}
                </div>
                <span className="mono" style={{ color: 'var(--ink-3)', flexShrink: 0 }}>
                  {step + 1}/4
                </span>
              </div>
              <div className="display d-md">
                {step === 0 && 'What did you see?'}
                {step === 1 && 'Where was it?'}
                {step === 2 && 'Worth knowing?'}
                {step === 3 && 'Who’s this for?'}
              </div>
            </div>

            <div className="sheet-body">
              {/* ── 1. photo ── */}
              {step === 0 && (
                <div style={{ paddingTop: 4 }}>
                  <div className="photo-wrap" style={{
                    height: 186, borderRadius: 16, border: '2px solid var(--ink)',
                    overflow: 'hidden', position: 'relative', boxShadow: '2px 2px 0 var(--ink)',
                  }}>
                    {photo ? (
                      <>
                        <img src={photo} alt="" />
                        <div style={{
                          position: 'absolute', top: 8, left: 8, display: 'flex', gap: 4,
                        }}>
                          <span className="pill" style={{ background: 'rgba(251,250,246,.94)' }}>
                            <Icon name="check" size={9} sw={3} /> Selected
                          </span>
                        </div>
                      </>
                    ) : (
                      <div style={{
                        height: '100%', display: 'flex', flexDirection: 'column',
                        alignItems: 'center', justifyContent: 'center', gap: 8,
                      }}>
                        <Icon name="camera" size={30} sw={1.7} style={{ color: C.ink3 }} />
                        <span className="mono" style={{ color: C.ink3 }}>No photo yet</span>
                      </div>
                    )}
                  </div>

                  <div style={{ display: 'flex', gap: 7, marginTop: 9 }}>
                    <button className="btn btn-sm" style={{ flex: 1 }}
                      onClick={() => { setPhoto('assets/street.jpg'); buzz(); }}>
                      <Icon name="camera" size={14} sw={2.2} /> Camera
                    </button>
                    <button className="btn btn-sm btn-ghost" style={{ flex: 1 }}
                      onClick={() => setPhoto(gallery[(gallery.indexOf(photo) + 1) % gallery.length])}>
                      <Icon name="image" size={14} sw={2.2} /> Gallery
                    </button>
                  </div>

                  <div className="mono" style={{ color: C.ink3, margin: '14px 0 7px' }}>Recent</div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
                    {gallery.map(src => (
                      <button key={src} onClick={() => { setPhoto(src); buzz(5); }}
                        style={{
                          padding: 0, border: photo === src ? `2.5px solid ${C.orange}` : '1.5px solid rgba(21,19,15,.2)',
                          borderRadius: 9, overflow: 'hidden', height: 54, cursor: 'pointer',
                          background: 'none', boxShadow: photo === src ? '2px 2px 0 var(--ink)' : 'none',
                        }}>
                        <img src={src} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* ── 2. venue ── */}
              {step === 1 && (
                <div style={{ paddingTop: 4 }}>
                  <div className="field" style={{ marginBottom: 10 }}>
                    <Icon name="search" size={15} sw={2.2} style={{ color: C.ink3 }} />
                    <input value={q} onChange={e => setQ(e.target.value)}
                      placeholder="Search a place or address" />
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
                    <Icon name="nav" size={12} sw={2.4} style={{ color: C.orange }} />
                    <span className="mono" style={{ color: C.ink }}>Nearby — Barlow Hill</span>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 336, overflowY: 'auto' }}>
                    {PLACES.filter(p => !q || p.name.toLowerCase().includes(q.toLowerCase())).map(p => {
                      const on = place === p.id;
                      return (
                        <button key={p.id} onClick={() => { setPlace(p.id); buzz(5); }}
                          style={{
                            display: 'flex', alignItems: 'center', gap: 9, padding: 7,
                            border: on ? `2px solid ${C.ink}` : '1.5px solid rgba(21,19,15,.16)',
                            borderRadius: 13, background: on ? C.butter : 'transparent',
                            cursor: 'pointer', textAlign: 'left', width: '100%',
                            boxShadow: on ? '2px 2px 0 var(--ink)' : 'none',
                          }}>
                          <div style={{
                            width: 36, height: 36, borderRadius: 9, overflow: 'hidden',
                            flexShrink: 0, border: '1.5px solid var(--ink)',
                          }}>
                            <img src={p.img} alt="" className="photo" />
                          </div>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            <div style={{ fontSize: 12.5, fontWeight: 700, letterSpacing: '-.01em' }}>{p.name}</div>
                            <div className="mono-sm" style={{ color: on ? C.ink2 : C.ink3 }}>
                              {p.cat} · {p.dist}
                            </div>
                          </div>
                          {on && (
                            <span style={{
                              width: 19, height: 19, borderRadius: 999, background: C.ink,
                              color: C.paper, display: 'flex', alignItems: 'center', justifyContent: 'center',
                              flexShrink: 0,
                            }}>
                              <Icon name="check" size={11} sw={3.2} />
                            </span>
                          )}
                        </button>
                      );
                    })}
                    <button style={{
                      display: 'flex', alignItems: 'center', gap: 7, padding: '10px 9px',
                      border: '1.5px dashed rgba(21,19,15,.34)', borderRadius: 12,
                      background: 'none', cursor: 'pointer', width: '100%',
                    }}>
                      <Icon name="plus" size={14} sw={2.4} style={{ color: C.ink3 }} />
                      <span className="mono" style={{ color: C.ink2 }}>Add a place we don’t have</span>
                    </button>
                  </div>
                </div>
              )}

              {/* ── 3. note ── */}
              {step === 2 && (
                <div style={{ paddingTop: 4 }}>
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 8, padding: '7px 9px',
                    border: '1.5px solid rgba(21,19,15,.16)', borderRadius: 12, marginBottom: 10,
                  }}>
                    <div style={{ width: 30, height: 30, borderRadius: 8, overflow: 'hidden', border: '1.5px solid var(--ink)', flexShrink: 0 }}>
                      <img src={sel.img} alt="" className="photo" />
                    </div>
                    <span style={{ fontSize: 12, fontWeight: 700, flex: 1 }}>{sel.name}</span>
                    <button className="mono" onClick={() => setStep(1)}
                      style={{ background: 'none', border: 0, color: C.orange, cursor: 'pointer' }}>
                      Change
                    </button>
                  </div>

                  <textarea className="noteinput" value={note} maxLength={140}
                    onChange={e => setNote(e.target.value)}
                    placeholder="One line is enough. What should a friend know?" />
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4, marginBottom: 11 }}>
                    <span className="mono-sm" style={{ color: C.ink3 }}>
                      {note.length ? 'Short notes get read more' : 'Optional, but it helps'}
                    </span>
                    <span className="mono-sm" style={{ color: note.length > 120 ? C.orange : C.ink3 }}>
                      {note.length}/140
                    </span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                    <span className="mono" style={{ color: C.ink2 }}>Rating</span>
                    <span className="stars">
                      {[1, 2, 3, 4, 5].map(i => (
                        <button key={i} className={'star' + (i <= rating ? ' on' : '')}
                          onClick={() => { setRating(i === rating ? 0 : i); buzz(5); }}>
                          <svg width="19" height="19" viewBox="0 0 24 24">
                            <path d={ICONS.star} fill={i <= rating ? 'currentColor' : 'none'}
                              stroke="currentColor" strokeWidth="1.9" strokeLinejoin="round" />
                          </svg>
                        </button>
                      ))}
                    </span>
                    <span className="mono-sm" style={{ color: C.ink3, marginLeft: 'auto' }}>Optional</span>
                  </div>

                  <div className="mono" style={{ color: C.ink3, marginBottom: 7 }}>Tag it so it’s findable</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5 }}>
                    {TAGSET.map(t => (
                      <button key={t} className={'tagchip' + (tags.includes(t) ? ' on' : '')}
                        onClick={() => { setTags(tags.includes(t) ? tags.filter(x => x !== t) : [...tags, t]); buzz(4); }}>
                        {tags.includes(t) && <Icon name="check" size={9} sw={3} />}
                        {t}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* ── 4. audience ── */}
              {step === 3 && (
                <div style={{ paddingTop: 4 }}>
                  <div className="body-s" style={{ marginBottom: 11, fontSize: 12.5 }}>
                    This choice is per-drop. Changing it later never changes what
                    you’ve already shared.
                  </div>
                  {AUDIENCES.map(a => {
                    const on = aud === a.id;
                    return (
                      <button key={a.id} onClick={() => { setAud(a.id); buzz(9); }}
                        style={{
                          display: 'block', width: '100%', textAlign: 'left', cursor: 'pointer',
                          padding: 11, marginBottom: 8,
                          border: `2px solid ${on ? C.ink : 'rgba(21,19,15,.2)'}`,
                          borderRadius: 16,
                          background: on ? (a.id === 'friends' ? C.butter : C.paper) : 'transparent',
                          boxShadow: on ? '3px 3px 0 var(--ink)' : 'none',
                          transition: 'all .18s',
                        }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                          <span style={{
                            width: 28, height: 28, borderRadius: 9, flexShrink: 0,
                            border: '1.5px solid var(--ink)',
                            background: a.id === 'friends' ? C.paper : C.ink,
                            color: a.id === 'friends' ? C.ink : C.paper,
                            display: 'flex', alignItems: 'center', justifyContent: 'center',
                          }}>
                            <Icon name={a.icon} size={14} sw={2.2} />
                          </span>
                          <span className="display d-sm" style={{ fontSize: 16 }}>{a.title}</span>
                          <span style={{ marginLeft: 'auto', flexShrink: 0 }}>
                            <span style={{
                              width: 18, height: 18, borderRadius: 999,
                              border: `2px solid ${on ? C.ink : 'rgba(21,19,15,.3)'}`,
                              display: 'flex', alignItems: 'center', justifyContent: 'center',
                              background: on ? C.ink : 'transparent',
                              color: C.paper,
                            }}>
                              {on && <Icon name="check" size={10} sw={3.4} />}
                            </span>
                          </span>
                        </div>
                        <div style={{ fontSize: 11.5, lineHeight: 1.45, color: C.ink2 }}>{a.body}</div>
                        <div style={{
                          display: 'flex', alignItems: 'center', gap: 5, marginTop: 7,
                          paddingTop: 7, borderTop: '1px solid rgba(21,19,15,.14)',
                        }}>
                          {a.id === 'friends' && (
                            <span className="av-stack" style={{ marginRight: 3 }}>
                              {['noor', 'teo', 'mina'].map(f => <Av key={f} id={f} size={16} />)}
                            </span>
                          )}
                          <span className="mono-sm" style={{ color: on ? C.ink : C.ink3 }}>{a.foot}</span>
                        </div>
                      </button>
                    );
                  })}
                  <div style={{
                    display: 'flex', gap: 6, alignItems: 'flex-start', marginTop: 3,
                    padding: '8px 9px', borderRadius: 10, background: C.paper2,
                  }}>
                    <Icon name="lock" size={11} sw={2.4} style={{ color: C.ink3, marginTop: 1.5, flexShrink: 0 }} />
                    <span style={{ fontSize: 10.5, lineHeight: 1.4, color: C.ink2 }}>
                      Your live location is never shared. Public drops show the place,
                      not your visit history.
                    </span>
                  </div>
                </div>
              )}
            </div>

            <div style={{ padding: '10px 18px 26px', flexShrink: 0, borderTop: '1.5px solid rgba(21,19,15,.1)', background: C.paper }}>
              <button className="btn btn-primary btn-block" onClick={next} disabled={!canNext}>
                {step === 3 ? 'Publish drop' : 'Continue'}
                <Icon name={step === 3 ? 'send' : 'chevR'} size={15} sw={2.4} />
              </button>
            </div>
          </>
        )}
      </div>
    </>
  );
}

Object.assign(window, { CreateFlow, AUDIENCES, TAGSET });
