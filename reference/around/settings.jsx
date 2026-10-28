/* ══════════════════════════════════════════════════════════
   SETTINGS — privacy, audience defaults, safety
   ══════════════════════════════════════════════════════════ */

function Switch({ on, onChange }) {
  return (
    <span className={'switch' + (on ? ' on' : '')} role="switch" tabIndex={0} aria-checked={on}
      onClick={e => { e.stopPropagation(); onChange(!on); buzz(6); }}
      onKeyDown={e => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); e.stopPropagation(); onChange(!on); buzz(6); }
      }}>
      <i />
    </span>
  );
}

function SetRow({ icon, tint, label, sub, right, onClick, danger }) {
  /* rows that hold a switch must not be buttons — nested interactive elements
     break keyboard access and are invalid HTML */
  const interactive = !!onClick;
  const Tag = interactive ? 'button' : 'div';
  return (
    <Tag className="setrow" onClick={onClick}
      {...(interactive ? {} : { role: 'group' })}
      style={interactive ? undefined : { cursor: 'default' }}>
      {icon && (
        <span style={{
          width: 27, height: 27, borderRadius: 8, flexShrink: 0,
          border: '1.5px solid var(--ink)',
          background: danger ? C.paper3 : (tint || C.paper2),
          color: danger ? '#B3261E' : C.ink,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name={icon} size={13} sw={2.2} />
        </span>
      )}
      <span className="lbl" style={danger ? { color: '#B3261E' } : undefined}>
        {label}
        {sub && <span className="sub">{sub}</span>}
      </span>
      {right}
    </Tag>
  );
}

function Settings({ onBack, defaultAud, setDefaultAud, toast }) {
  const [quietHours, setQuietHours] = React.useState(false);
  const [friendRequests, setFriendRequests] = React.useState(true);
  const [hideHistory, setHideHistory] = React.useState(true);
  const [discoverable, setDiscoverable] = React.useState(true);

  return (
    <div className="screen" style={{ paddingTop: 4 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <button className="iconbtn tap" onClick={onBack} aria-label="Back">
          <Icon name="chevL" size={15} sw={2.5} />
        </button>
        <div className="display d-lg" style={{ flex: 1 }}>Settings</div>
      </div>

      <span className="setlabel">Who sees your drops</span>
      <div className="setgroup" style={{ padding: '11px 13px' }}>
        <div style={{ display: 'flex', gap: 5, marginBottom: 8 }}>
          {[['friends', 'Friends only'], ['public', 'Public']].map(([id, l]) => (
            <button key={id} onClick={() => { setDefaultAud(id); buzz(6); }}
              style={{
                flex: 1, height: 36, borderRadius: 10, cursor: 'pointer',
                border: `2px solid ${defaultAud === id ? C.ink : 'rgba(21,19,15,.18)'}`,
                background: defaultAud === id ? (id === 'friends' ? C.butter : C.ink) : 'transparent',
                color: defaultAud === id && id === 'public' ? C.paper : C.ink,
                fontFamily: 'var(--body)', fontWeight: 700, fontSize: 11.5,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 4,
              }}>
              <Icon name={id === 'friends' ? 'lock' : 'globe'} size={11} sw={2.4} />
              {l}
            </button>
          ))}
        </div>
        <div style={{ fontSize: 10.8, lineHeight: 1.4, color: C.ink2 }}>
          This is what every new drop starts as. You can still change it
          on each post before publishing.
        </div>
      </div>

      <span className="setlabel">Privacy</span>
      <div className="setgroup">
        <SetRow icon="lock" tint={C.butter} label="Keep my visits private"
          sub="Places you visit are never shown to anyone, even on public drops."
          right={<Switch on={hideHistory} onChange={setHideHistory} />} />
        <SetRow icon="users" label="Let friends find me"
          sub="People who already follow you can see your profile."
          right={<Switch on={discoverable} onChange={setDiscoverable} />} />
        <SetRow icon="bell" label="Quiet hours"
          sub="No notifications between 11pm and 8am."
          right={<Switch on={quietHours} onChange={setQuietHours} />} />
        <SetRow icon="user" label="Friend requests"
          sub="Anyone on Around can ask to follow you."
          right={<Switch on={friendRequests} onChange={setFriendRequests} />} />
      </div>

      <span className="setlabel">Account</span>
      <div className="setgroup">
        <SetRow icon="user" label="Edit profile"
          right={<Icon name="chevR" size={13} sw={2.3} style={{ color: C.ink3 }} />} />
        <SetRow icon="globe" label="Home neighbourhood" sub="Barlow Hill"
          right={<Icon name="chevR" size={13} sw={2.3} style={{ color: C.ink3 }} />} />
        <SetRow icon="flag" label="Blocked accounts" sub="Nobody blocked"
          right={<Icon name="chevR" size={13} sw={2.3} style={{ color: C.ink3 }} />} />
        <SetRow icon="image" label="Export my data"
          right={<Icon name="chevR" size={13} sw={2.3} style={{ color: C.ink3 }} />} />
      </div>

      <span className="setlabel">Safety</span>
      <div className="setgroup">
        <SetRow icon="flag" danger label="Report a problem" onClick={toast} />
        <SetRow icon="trash" danger label="Delete account"
          sub="Removes your drops and saves permanently." onClick={toast} />
      </div>

      <div style={{
        textAlign: 'center', fontFamily: 'var(--mono)', fontSize: 8,
        letterSpacing: '.1em', color: C.ink3, textTransform: 'uppercase',
        lineHeight: 1.8, marginTop: 4,
      }}>
        Around 1.0 · Barlow Hill pilot<br />
        Made for people, not listings.
      </div>
    </div>
  );
}

Object.assign(window, { Settings, Switch, SetRow });
