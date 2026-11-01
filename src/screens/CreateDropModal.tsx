import React, { useState, useEffect, useRef } from 'react';
import { useApp } from '../context/AppContext';
import { Icon } from '../components/ui/Icon';
import { StarRating } from '../components/ui/StarRating';
import { AVAILABLE_TAGS } from '../data/mockData';
import { Audience, Place } from '../types';
import { buzz } from '../services/haptics';

export const CreateDropModal: React.FC = () => {
  const {
    createModal,
    closeCreateDrop,
    publishDrop,
    places,
    addCustomPlace,
    privacySettings,
    getPlaceById,
  } = useApp();

  const [step, setStep] = useState<number>(0);
  const [photo, setPhoto] = useState<string | null>('/assets/bakery-counter.jpg');
  const [selectedPlaceId, setSelectedPlaceId] = useState<string>('breadly');
  const [note, setNote] = useState<string>('');
  const [rating, setRating] = useState<number>(5);
  const [tags, setTags] = useState<string[]>(['specialty coffee']);
  const [aud, setAud] = useState<Audience>(privacySettings.defaultAudience || 'friends');
  const [venueSearch, setVenueSearch] = useState<string>('');
  const [addingVenue, setAddingVenue] = useState<boolean>(false);
  const [newVenueName, setNewVenueName] = useState<string>('');
  const [newVenueStreet, setNewVenueStreet] = useState<string>('');
  const [newVenueCat, setNewVenueCat] = useState<string>('Café · Bakery');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [dragY, setDragY] = useState<number>(0);
  const isDragging = useRef<boolean>(false);
  const startY = useRef<number>(0);

  useEffect(() => {
    if (createModal.open) {
      setStep(createModal.initialStep || 0);
      if (createModal.presetPlaceId) {
        setSelectedPlaceId(createModal.presetPlaceId);
      }
      setAud(privacySettings.defaultAudience || 'friends');
      setDragY(0);
    }
  }, [createModal.open, createModal.presetPlaceId, createModal.initialStep, privacySettings.defaultAudience]);

  if (!createModal.open) return null;

  const currentPlace = getPlaceById(selectedPlaceId) || places[0];

  const curatedPhotos = [
    '/assets/bakery-counter.jpg',
    '/assets/study-desk.jpg',
    '/assets/patisserie.jpg',
    '/assets/cafe-light.jpg',
    '/assets/street.jpg',
    '/assets/window-girl.jpg',
    '/assets/wine-wide.jpg',
    '/assets/bookshop-tall.jpg',
  ];

  // Compress uploaded photo on an offscreen canvas to avoid exhausting 5MB localStorage quota
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const dataUrl = event.target?.result as string;
      if (!dataUrl) return;
      const img = new Image();
      img.onload = () => {
        const maxDim = 800;
        let { width, height } = img;
        if (width > maxDim || height > maxDim) {
          if (width > height) {
            height = Math.round((height * maxDim) / width);
            width = maxDim;
          } else {
            width = Math.round((width * maxDim) / height);
            height = maxDim;
          }
        }
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext('2d');
        if (ctx) {
          ctx.drawImage(img, 0, 0, width, height);
          setPhoto(canvas.toDataURL('image/jpeg', 0.75));
        } else {
          setPhoto(dataUrl);
        }
        buzz(10);
      };
      img.src = dataUrl;
    };
    reader.readAsDataURL(file);
  };

  const handleCreateCustomVenue = () => {
    if (!newVenueName.trim()) return;
    const newId = `custom_${Date.now()}`;
    const customPlace: Place = {
      id: newId,
      name: newVenueName.trim(),
      cat: newVenueCat.trim() || 'Café',
      street: newVenueStreet.trim() || '15 Taras Shevchenko Street, Tashkent',
      dist: '5 min walk',
      price: '$$',
      img: photo || '/assets/bakery-counter.jpg',
      hours: '08:00 – 22:00',
      closed: 'Open today',
      rating: 4.8,
      reviews: 1,
      tags: ['specialty coffee'],
      line: 'Newly discovered Tashkent neighborhood spot.',
      imgs: [photo || '/assets/bakery-counter.jpg'],
      coords: { x: 50, y: 50 },
    };
    addCustomPlace(customPlace);
    setSelectedPlaceId(newId);
    setAddingVenue(false);
    setNewVenueName('');
    setNewVenueStreet('');
  };

  const toggleTag = (t: string) => {
    setTags((prev: string[]) => (prev.includes(t) ? prev.filter((x: string) => x !== t) : [...prev, t]));
    buzz(6);
  };

  const handleNext = () => {
    if (step < 3) {
      setStep((s: number) => s + 1);
      buzz(8);
    } else {
      publishDrop({
        placeId: currentPlace.id,
        note,
        rating,
        tags,
        aud,
        photoUrl: photo,
      });
    }
  };

  const handleBack = () => {
    if (step > 0) {
      setStep((s: number) => s - 1);
      buzz(6);
    } else {
      closeCreateDrop();
    }
  };

  const filteredPlaces = places.filter(
    (p: Place) =>
      p.name.toLowerCase().includes(venueSearch.toLowerCase()) ||
      p.cat.toLowerCase().includes(venueSearch.toLowerCase())
  );

  const onPointerDown = (e: React.PointerEvent) => {
    isDragging.current = true;
    startY.current = e.clientY;
  };

  const onPointerMove = (e: React.PointerEvent) => {
    if (!isDragging.current) return;
    const dy = Math.max(0, e.clientY - startY.current);
    setDragY(dy);
  };

  const onPointerUp = () => {
    if (!isDragging.current) return;
    isDragging.current = false;
    if (dragY > 120) {
      closeCreateDrop();
      buzz(12);
    } else {
      setDragY(0);
    }
  };

  const stepTitles = ['Select Photo', 'Choose Venue', 'Add Note & Tags', 'Audience & Privacy'];

  return (
    <>
      <div
        className="sheet-scrim"
        onClick={closeCreateDrop}
        style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(21, 19, 15, 0.65)',
          zIndex: 9000,
          backdropFilter: 'blur(3px)',
        }}
      />

      <div
        className="sheet"
        style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          maxHeight: '92vh',
          zIndex: 9001,
          background: 'var(--paper)',
          borderTopLeftRadius: 24,
          borderTopRightRadius: 24,
          borderTop: '2.5px solid var(--ink)',
          borderLeft: '2px solid var(--ink)',
          borderRight: '2px solid var(--ink)',
          boxShadow: '0 -8px 30px rgba(0,0,0,0.3)',
          transform: `translateY(${dragY}px)`,
          transition: isDragging.current ? 'none' : 'transform 0.3s cubic-bezier(0.2, 0.9, 0.3, 1)',
          display: 'flex',
          flexDirection: 'column',
          maxWidth: 440,
          margin: '0 auto',
        }}
      >
        <div
          className="sheet-grab"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
          style={{
            padding: '12px 0 6px',
            display: 'flex',
            justifyContent: 'center',
            cursor: 'grab',
            touchAction: 'none',
          }}
        >
          <div
            style={{
              width: dragY > 0 ? 56 : 42,
              height: 5,
              borderRadius: 99,
              background: 'var(--ink)',
              transition: 'width 0.2s',
            }}
          />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '6px 18px 10px', borderBottom: '1px solid rgba(21,19,15,.12)' }}>
          <button
            onClick={handleBack}
            style={{ background: 'none', border: 0, padding: 4, cursor: 'pointer', color: 'var(--ink-2)' }}
            aria-label="Back"
          >
            <Icon name={step === 0 ? 'x' : 'chevL'} size={18} sw={2.4} />
          </button>

          <div style={{ textAlign: 'center' }}>
            <div className="mono-sm" style={{ color: 'var(--orange)', fontSize: 9.5, fontWeight: 700 }}>
              STEP {step + 1} OF 4
            </div>
            <div className="display d-sm" style={{ fontSize: 14 }}>
              {stepTitles[step]}
            </div>
          </div>

          <button
            onClick={closeCreateDrop}
            style={{ background: 'none', border: 0, padding: 4, cursor: 'pointer', color: 'var(--ink-3)' }}
            aria-label="Close"
          >
            <Icon name="x" size={16} sw={2.4} />
          </button>
        </div>

        <div style={{ padding: '16px 18px 24px', overflowY: 'auto', flex: 1, minHeight: 320 }}>
          {step === 0 && (
            <div>
              <div
                style={{
                  height: 200,
                  borderRadius: 16,
                  overflow: 'hidden',
                  border: '2px solid var(--ink)',
                  boxShadow: 'var(--sh)',
                  marginBottom: 14,
                  position: 'relative',
                  background: 'var(--paper-2)',
                }}
              >
                {photo ? (
                  <img
                    src={photo}
                    alt="Drop preview"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                ) : (
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', color: 'var(--ink-3)' }}>
                    No photo selected
                  </div>
                )}
              </div>

              <input
                type="file"
                ref={fileInputRef}
                accept="image/*"
                style={{ display: 'none' }}
                onChange={handleFileUpload}
              />

              <button
                className="btn btn-ghost btn-block"
                onClick={() => fileInputRef.current?.click()}
                style={{ marginBottom: 14, height: 40 }}
              >
                <Icon name="camera" size={15} sw={2.2} /> Choose from Photo Library
              </button>

              <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 10, marginBottom: 8, textTransform: 'uppercase' }}>
                Or select curated Tashkent venue snapshot:
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
                {curatedPhotos.map((imgSrc, i) => (
                  <button
                    key={i}
                    onClick={() => {
                      setPhoto(imgSrc);
                      buzz(6);
                    }}
                    style={{
                      height: 60,
                      borderRadius: 10,
                      overflow: 'hidden',
                      padding: 0,
                      border: `2px solid ${photo === imgSrc ? 'var(--orange)' : 'var(--ink)'}`,
                      cursor: 'pointer',
                      transform: photo === imgSrc ? 'scale(0.96)' : 'none',
                    }}
                  >
                    <img
                      src={imgSrc}
                      alt=""
                      style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                    />
                  </button>
                ))}
              </div>
            </div>
          )}

          {step === 1 && (
            <div>
              <div style={{ display: 'flex', gap: 6, marginBottom: 12 }}>
                <div
                  style={{
                    flex: 1,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                    background: 'var(--paper-2)',
                    border: '1.5px solid var(--ink)',
                    borderRadius: 10,
                    padding: '7px 10px',
                  }}
                >
                  <Icon name="search" size={14} sw={2.2} style={{ color: 'var(--ink-3)' }} />
                  <input
                    type="text"
                    placeholder="Search Tashkent venues..."
                    value={venueSearch}
                    onChange={(e) => setVenueSearch(e.target.value)}
                    style={{ border: 0, background: 'none', outline: 'none', width: '100%', fontSize: 12 }}
                  />
                </div>
                <button
                  type="button"
                  className="btn btn-sm btn-ghost"
                  onClick={() => setAddingVenue(v => !v)}
                  title="Add custom venue"
                >
                  <Icon name="plus" size={14} sw={2.5} />
                </button>
              </div>

              {addingVenue && (
                <div style={{ padding: 12, background: 'var(--paper-2)', border: '1.5px solid var(--ink)', borderRadius: 12, marginBottom: 12 }}>
                  <div className="display d-sm" style={{ fontSize: 13, marginBottom: 6 }}>Add New Tashkent Venue</div>
                  <input
                    type="text"
                    placeholder="Venue name *"
                    value={newVenueName}
                    onChange={(e) => setNewVenueName(e.target.value)}
                    style={{ width: '100%', padding: 6, borderRadius: 6, border: '1px solid var(--ink)', marginBottom: 6 }}
                  />
                  <input
                    type="text"
                    placeholder="Street address"
                    value={newVenueStreet}
                    onChange={(e) => setNewVenueStreet(e.target.value)}
                    style={{ width: '100%', padding: 6, borderRadius: 6, border: '1px solid var(--ink)', marginBottom: 6 }}
                  />
                  <input
                    type="text"
                    placeholder="Category"
                    value={newVenueCat}
                    onChange={(e) => setNewVenueCat(e.target.value)}
                    style={{ width: '100%', padding: 6, borderRadius: 6, border: '1px solid var(--ink)', marginBottom: 8 }}
                  />
                  <button type="button" className="btn btn-primary btn-sm btn-block" onClick={handleCreateCustomVenue}>
                    Add & Select Venue
                  </button>
                </div>
              )}

              <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 260, overflowY: 'auto' }}>
                {filteredPlaces.map((p: Place) => {
                  const isSelected = currentPlace.id === p.id;
                  return (
                    <button
                      key={p.id}
                      onClick={() => {
                        setSelectedPlaceId(p.id);
                        buzz(6);
                      }}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: 10,
                        padding: '8px 10px',
                        borderRadius: 12,
                        border: `1.8px solid ${isSelected ? 'var(--orange)' : 'rgba(21,19,15,.18)'}`,
                        background: isSelected ? 'var(--butter)' : 'var(--paper)',
                        textAlign: 'left',
                        cursor: 'pointer',
                        boxShadow: isSelected ? '2px 2px 0 var(--ink)' : 'none',
                      }}
                    >
                      <div style={{ width: 40, height: 40, borderRadius: 8, overflow: 'hidden', border: '1px solid var(--ink)', flexShrink: 0 }}>
                        <img src={p.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 13, fontWeight: 700 }}>{p.name}</div>
                        <div className="mono-sm" style={{ color: 'var(--ink-3)', fontSize: 9.5 }}>
                          {p.cat} · {p.street}
                        </div>
                      </div>
                      {isSelected && <Icon name="check" size={15} sw={3} style={{ color: 'var(--ink)' }} />}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {step === 2 && (
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12, padding: '8px 10px', background: 'var(--paper-2)', borderRadius: 10 }}>
                <Icon name="map" size={14} sw={2.4} style={{ color: 'var(--orange)' }} />
                <span style={{ fontSize: 12, fontWeight: 700 }}>{currentPlace.name}</span>
                <span className="mono-sm" style={{ color: 'var(--ink-3)', marginLeft: 'auto', fontSize: 10 }}>
                  {currentPlace.cat.split(' · ')[0]}
                </span>
              </div>

              <div style={{ marginBottom: 14 }}>
                <label className="mono-sm" style={{ display: 'block', marginBottom: 6, color: 'var(--ink-2)', fontSize: 10.5 }}>
                  What's the real vibe? (Short note)
                </label>
                <textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="e.g. Lavender matcha and warm sourdough on the Taras Shevchenko courtyard..."
                  rows={3}
                  maxLength={180}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    borderRadius: 12,
                    border: '1.8px solid var(--ink)',
                    background: 'var(--paper)',
                    fontFamily: 'var(--body)',
                    fontSize: 13,
                    lineHeight: 1.4,
                    color: 'var(--ink)',
                    resize: 'none',
                    boxShadow: '2px 2px 0 var(--ink)',
                    outline: 'none',
                  }}
                />
                <div style={{ textAlign: 'right', fontFamily: 'var(--mono)', fontSize: 9, color: 'var(--ink-3)', marginTop: 2 }}>
                  {180 - note.length} chars left
                </div>
              </div>

              <div style={{ marginBottom: 14 }}>
                <label className="mono-sm" style={{ display: 'block', marginBottom: 6, color: 'var(--ink-2)', fontSize: 10.5 }}>
                  Rating (Optional)
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <StarRating rating={rating} size={20} gap={6} interactive={true} onChange={(r: number) => setRating(r)} />
                  <span style={{ fontFamily: 'var(--mono)', fontSize: 12, fontWeight: 700, marginLeft: 6 }}>
                    {rating} / 5
                  </span>
                </div>
              </div>

              <div>
                <label className="mono-sm" style={{ display: 'block', marginBottom: 6, color: 'var(--ink-2)', fontSize: 10.5 }}>
                  Descriptive Tags
                </label>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {AVAILABLE_TAGS.slice(0, 8).map((t: string) => {
                    const isSelected = tags.includes(t);
                    return (
                      <button
                        key={t}
                        type="button"
                        onClick={() => toggleTag(t)}
                        className={`pill ${isSelected ? 'fill-ink' : 'ghost'}`}
                        style={{ cursor: 'pointer', height: 26, fontSize: 10.5 }}
                      >
                        {isSelected && <Icon name="check" size={9} sw={3} />}
                        {t}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {step === 3 && (
            <div>
              <div className="mono-sm" style={{ color: 'var(--ink-3)', marginBottom: 10, fontSize: 10.5 }}>
                Who can see this Place Drop?
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <button
                  type="button"
                  onClick={() => {
                    setAud('friends');
                    buzz(6);
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: 12,
                    padding: 14,
                    borderRadius: 16,
                    border: `2px solid ${aud === 'friends' ? 'var(--ink)' : 'rgba(21,19,15,.2)'}`,
                    background: aud === 'friends' ? 'var(--butter)' : 'var(--paper)',
                    boxShadow: aud === 'friends' ? 'var(--sh)' : 'none',
                    textAlign: 'left',
                    cursor: 'pointer',
                  }}
                >
                  <div
                    style={{
                      width: 36,
                      height: 36,
                      borderRadius: 10,
                      background: 'var(--paper)',
                      border: '1.5px solid var(--ink)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}
                  >
                    <Icon name="lock" size={17} sw={2.4} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                      <span className="display d-sm" style={{ fontSize: 15, fontWeight: 700 }}>
                        Friends Only
                      </span>
                      <span className="pill fill-or" style={{ fontSize: 9 }}>
                        Recommended
                      </span>
                    </div>
                    <p style={{ margin: 0, fontSize: 11.5, lineHeight: 1.4, color: 'var(--ink-2)' }}>
                      Only mutual friends you follow see this. Appears on their feed and on this venue page for them.
                    </p>
                  </div>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    setAud('public');
                    buzz(6);
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: 12,
                    padding: 14,
                    borderRadius: 16,
                    border: `2px solid ${aud === 'public' ? 'var(--ink)' : 'rgba(21,19,15,.2)'}`,
                    background: aud === 'public' ? 'var(--paper-2)' : 'var(--paper)',
                    boxShadow: aud === 'public' ? 'var(--sh)' : 'none',
                    textAlign: 'left',
                    cursor: 'pointer',
                  }}
                >
                  <div
                    style={{
                      width: 36,
                      height: 36,
                      borderRadius: 10,
                      background: 'var(--paper)',
                      border: '1.5px solid var(--ink)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                    }}
                  >
                    <Icon name="globe" size={17} sw={2.4} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div className="display d-sm" style={{ fontSize: 15, fontWeight: 700, marginBottom: 3 }}>
                      Public Discovery
                    </div>
                    <p style={{ margin: 0, fontSize: 11.5, lineHeight: 1.4, color: 'var(--ink-2)' }}>
                      Discoverable by the wider Tashkent community in Explore and search. Your live location history remains strictly private.
                    </p>
                  </div>
                </button>
              </div>
            </div>
          )}
        </div>

        <div style={{ padding: '12px 18px 24px', borderTop: '1px solid rgba(21,19,15,.12)', display: 'flex', gap: 10 }}>
          {step > 0 && (
            <button
              className="btn btn-ghost"
              onClick={handleBack}
              style={{ flex: 1, height: 44, borderRadius: 12 }}
            >
              Back
            </button>
          )}

          <button
            className="btn btn-primary"
            onClick={handleNext}
            style={{ flex: 2, height: 44, borderRadius: 12, boxShadow: 'var(--sh)' }}
          >
            {step === 3 ? (
              <>
                <Icon name="send" size={14} sw={2.2} /> Publish Drop
              </>
            ) : (
              <>
                Continue <Icon name="chevR" size={14} sw={2.4} />
              </>
            )}
          </button>
        </div>
      </div>
    </>
  );
};
