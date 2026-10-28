/* ══════════════════════════════════════════════════════════
   Around — data + primitives
   ══════════════════════════════════════════════════════════ */

const C = {
  paper:'#FBFAF6', paper2:'#F1EEE4', paper3:'#E6E1D3',
  ink:'#15130F', ink2:'#575247', ink3:'#8E8877',
  orange:'#FF5A1F', cobalt:'#2B4CFF', butter:'#FFE07A',
  mint:'#D5E8CB', water:'#D7E3EC', blush:'#F6D2C4',
};

const PEOPLE = {
  noor:   { name:'Noor Haddad',    init:'NH', bg:C.butter,  handle:'noorh' },
  teo:    { name:'Teo Vasquez',    init:'TV', bg:C.mint,    handle:'teovas' },
  mina:   { name:'Mina Osei',      init:'MO', bg:C.water,   handle:'minaosei' },
  ari:    { name:'Ari Lindqvist',  init:'AL', bg:C.blush,   handle:'arilind' },
  priya:  { name:'Priya Raman',    init:'PR', bg:C.cobalt,  handle:'priyar' },
  jonah:  { name:'Jonah Beck',     init:'JB', bg:C.orange,  handle:'jonahb' },
  you:    { name:'You',            init:'YO', bg:C.orange,  handle:'you' },
  hana:   { name:'Hana Ito',       init:'HI', bg:C.mint,    handle:'hana' },
  dell:   { name:'Dell Okafor',    init:'DO', bg:C.butter,  handle:'dello' },
};

const PLACES = [
  {
    id:'kettle', name:'Kettle & Loaf', cat:'Bakery · Café', street:'14 Ledger Street',
    dist:'4 min walk', price:'€', img:'assets/kettle-hero.jpg',
    hours:'7am – 4pm', closed:'Opens tomorrow 7am', rating:4.7, reviews:184,
    tags:['quiet mornings','good cortado','work-friendly','solo seats'],
    line:'Bread out of the oven at 7, gone by 11. The back room is the quiet one.',
    imgs:['assets/bakery-counter.jpg','assets/cafe-light.jpg','assets/pastries.jpg'],
  },
  {
    id:'fern', name:'The Fern Room', cat:'Study café', street:'2 Ostrander Avenue',
    dist:'7 min walk', price:'€€', img:'assets/study-desk.jpg',
    hours:'8am – 6pm', closed:'Closes in 2 hours', rating:4.5, reviews:96,
    tags:['outlets','big tables','silent-ish','long stays'],
    line:'Twenty sockets, twelve tables, one rule: headphones on.',
    imgs:['assets/study-table.jpg','assets/cafe-light.jpg','assets/window-girl.jpg'],
  },
  {
    id:'sable', name:'Sable Records', cat:'Record shop', street:'63 Kestrel Lane',
    dist:'9 min walk', price:'€€', img:'assets/records.jpg',
    hours:'11am – 7pm', closed:'Closes in 5 hours', rating:4.8, reviews:62,
    tags:['crate digging','second-hand','staff picks','no rush'],
    line:'Two thousand records and a chair nobody uses. Ask Dilan for the shellac.',
    imgs:['assets/records-crates.jpg','assets/storefront.jpg','assets/street.jpg'],
  },
  {
    id:'castellan', name:'Castellan', cat:'Wine bar', street:'8 Prine Row',
    dist:'11 min walk', price:'€€€', img:'assets/wine-tall.jpg',
    hours:'5pm – 1am', closed:'Opens 5pm', rating:4.6, reviews:210,
    tags:['date night','natural wine','small plates','standing room'],
    line:'No menu. Tell them what you liked last time and they pour it.',
    imgs:['assets/wine-wide.jpg','assets/wine-tall.jpg','assets/street.jpg'],
  },
  {
    id:'volta', name:'Volta Books', cat:'Bookshop', street:'21 Fenwick Walk',
    dist:'6 min walk', price:'€', img:'assets/bookshop.jpg',
    hours:'10am – 8pm', closed:'Closes in 6 hours', rating:4.9, reviews:143,
    tags:['browsing','staff picks','€4 shelf','tiny staircase'],
    line:'Three floors, one staircase built for one person at a time.',
    imgs:['assets/bookshop-tall.jpg','assets/bookshop.jpg','assets/storefront.jpg'],
  },
  {
    id:'noodle', name:'Noodle Union', cat:'Ramen', street:'40 Halloway Street',
    dist:'3 min walk', price:'€€', img:'assets/ramen-bowl.jpg',
    hours:'12pm – 10pm', closed:'Closes in 4 hours', rating:4.4, reviews:308,
    tags:['counter seats','fast','spicy miso','cash only'],
    line:'Twelve stools. Eat, pay, leave. Nobody has ever lingered here.',
    imgs:['assets/ramen.jpg','assets/ramen-bowl.jpg','assets/street.jpg'],
  },
  {
    id:'marigold', name:'Marigold Patisserie', cat:'Patisserie', street:'5 Duarte Court',
    dist:'8 min walk', price:'€€', img:'assets/patisserie.jpg',
    hours:'8am – 3pm', closed:'Opens tomorrow 8am', rating:4.6, reviews:77,
    tags:['kouign-amann','sells out early','standing only','cash + card'],
    line:'Two trays, one oven, a queue that starts at 8:40.',
    imgs:['assets/pastries.jpg','assets/patisserie.jpg','assets/bakery-counter.jpg'],
  },
  {
    id:'longtable', name:'The Long Table', cat:'Work space', street:'11 Marrow Lane',
    dist:'12 min walk', price:'€€', img:'assets/study-table.jpg',
    hours:'9am – 9pm', closed:'Closes in 7 hours', rating:4.3, reviews:58,
    tags:['outlets','day pass','printers','quiet zone'],
    line:'One 14-metre table. Day pass costs a coffee and a pastry.',
    imgs:['assets/study-desk.jpg','assets/study-table.jpg','assets/cafe-light.jpg'],
  },
  {
    id:'quiet', name:'Quiet Hours', cat:'Late café', street:'27 Ledger Street',
    dist:'5 min walk', price:'€', img:'assets/cafe-bw.jpg',
    hours:'6pm – 2am', closed:'Opens 6pm', rating:4.5, reviews:131,
    tags:['late night','no music','reading','cheap'],
    line:'Candles after nine. The espresso machine turns off at ten.',
    imgs:['assets/window-girl.jpg','assets/cafe-bw.jpg','assets/storefront.jpg'],
  },
];

/* drops — `size` drives the bento rhythm */
const DROPS = [
  {
    id:'d1', who:'noor', place:'kettle', img:'assets/kettle-hero.jpg', size:'hero',
    note:'Cortado is the good one here. The back room stays quiet until about eleven, then the whole street comes in at once.',
    rating:5, when:'2h', saves:12, aud:'friends', tags:['quiet mornings'],
  },
  {
    id:'d2', who:'teo', place:'fern', img:'assets/study-desk.jpg', size:'half',
    note:'Six hours on my thesis. Nobody looked at me once.',
    rating:5, when:'5h', saves:31, aud:'friends',
  },
  {
    id:'d3', who:'mina', place:'sable', img:'assets/records-crates.jpg', size:'half',
    note:'Shellac bin is unreasonably deep.',
    rating:5, when:'6h', saves:8, aud:'public',
  },
  {
    id:'d4', who:'ari', place:'castellan', img:null, size:'note', tint:C.butter,
    note:'Ask for something orange and cold and let them choose. It has never once gone badly.',
    rating:null, when:'9h', saves:19, aud:'friends', tags:['date night'],
  },
  {
    id:'d5', who:'priya', place:'volta', img:'assets/bookshop-tall.jpg', size:'half',
    note:'The €4 shelf by the door is a trap. I lost an hour.',
    rating:4, when:'1d', saves:24, aud:'public',
  },
  {
    id:'d6', who:'jonah', place:'noodle', img:'assets/ramen.jpg', size:'half',
    note:'Spicy miso, counter seat, out in twenty.',
    rating:5, when:'1d', saves:44, aud:'public',
  },
  {
    id:'d7', who:'mina', place:'marigold', img:'assets/patisserie.jpg', size:'wide',
    note:'Kouign-amann sells out before ten. I have learned this the hard way four times now.',
    rating:4, when:'1d', saves:37, aud:'friends',
  },
  {
    id:'d8', who:'teo', place:'longtable', img:null, size:'note', tint:C.mint,
    note:'Outlets at every single seat. I did not believe it either.',
    rating:null, when:'2d', saves:15, aud:'friends', tags:['outlets'],
  },
];

const PUBLIC_NOTES = [
  { who:'hana', rating:5, when:'3 days ago', txt:'Got here at 7:20 and there were still two seats at the counter. By 8 there was a queue to the door. The bread is worth the early alarm.' },
  { who:'dell', rating:4, when:'1 week ago', txt:'Great coffee, slightly chaotic at peak. Sit in the back if you need to think — the front is all noise and pushchairs.' },
];

const STORIES = ['kettle','castellan','sable','volta','marigold'];

/* ── icons ───────────────────────────────────────────────── */
const ICONS = {
  home:'M3.5 10.5 12 3.5l8.5 7v9.2a.8.8 0 0 1-.8.8h-5.2v-6h-5v6H4.3a.8.8 0 0 1-.8-.8z',
  compass:'M12 20.5a8.5 8.5 0 1 0 0-17 8.5 8.5 0 0 0 0 17zm3.4-11.9-2.3 5.4-5.4 2.3 2.3-5.4z',
  bookmark:'M6 3.5h12v17l-6-4.2-6 4.2z',
  user:'M4.6 20.5c0-3.7 3.3-6.2 7.4-6.2s7.4 2.5 7.4 6.2M12 12.5a4.2 4.2 0 1 0 0-8.4 4.2 4.2 0 0 0 0 8.4z',
  bell:'M6.5 10.2a5.5 5.5 0 0 1 11 0c0 3.9 1.4 5.4 1.4 5.4H5.1s1.4-1.5 1.4-5.4zM10 19.2a2.1 2.1 0 0 0 4 0',
  search:'M10.8 17a6.4 6.4 0 1 0 0-12.8 6.4 6.4 0 0 0 0 12.8zM15.6 15.8 20.5 20.7',
  plus:'M12 5.2v13.6M5.2 12h13.6',
  camera:'M3.4 8.6h3.2L8.2 6h7.6l1.6 2.6h3.2v10.8H3.4zM12 17.2a3.4 3.4 0 1 0 0-6.8 3.4 3.4 0 0 0 0 6.8z',
  x:'M6.2 6.2 17.8 17.8M17.8 6.2 6.2 17.8',
  chevL:'M14.6 5 8 12l6.6 7',
  chevR:'M9.4 5 16 12l-6.6 7',
  arrowUR:'M7 17 17 7M9.2 7H17v7.8',
  map:'M3.5 6.6 9 4.1l6 2.5 5.5-2.5v13.4L15 20l-6-2.5-5.5 2.5zM9 4.1v13.4M15 6.6V20',
  list:'M4 7.2h16M4 12h16M4 16.8h11',
  star:'M12 3.6l2.55 5.5 6 .8-4.4 4.1 1.15 5.9L12 16.9l-5.3 3 1.15-5.9L3.45 9.9l6-.8z',
  clock:'M12 20.5a8.5 8.5 0 1 0 0-17 8.5 8.5 0 0 0 0 17zM12 7.4V12l3 2',
  nav:'M12 3.4 19.2 20.6 12 16.6 4.8 20.6z',
  share:'M12 15.2V3.8M8.4 7.4 12 3.8l3.6 3.6M5.4 12.6v7h13.2v-7',
  check:'M4.8 12.4 9.4 17 19.2 6.8',
  lock:'M5.4 10.6h13.2v9.4H5.4zM8.6 10.6V8a3.4 3.4 0 0 1 6.8 0v2.6',
  globe:'M12 20.5a8.5 8.5 0 1 0 0-17 8.5 8.5 0 0 0 0 17zM3.6 12h16.8M12 3.5c2.4 2.4 3.6 5.3 3.6 8.5s-1.2 6.1-3.6 8.5c-2.4-2.4-3.6-5.3-3.6-8.5S9.6 5.9 12 3.5z',
  image:'M3.6 4.6h16.8v14.8H3.6zM3.6 15.6l4.8-4.8 4 4 2.6-2.6 5.4 5.4M8.2 9.4a1.1 1.1 0 1 0 0-.1',
  flash:'M13.4 3 6.6 13.6h4.6L10.6 21l6.8-10.6h-4.6z',
  send:'M3.8 12 20.4 4.6 13 21l-2.1-7z',
  trash:'M5 7h14M9.2 7V4.6h5.6V7M7.2 7l.9 13h7.8l.9-13',
  flag:'M6 3.6v16.8M6 4.6h11.4l-2.1 4 2.1 4H6',
  sliders:'M4 8.2h9.4M17 8.2h3M4 15.8h3M10.6 15.8H20M15.6 8.2a1.8 1.8 0 1 0 0-.1M8.6 15.8a1.8 1.8 0 1 0 0-.1',
  grid:'M4 4h6.4v6.4H4zM13.6 4H20v6.4h-6.4zM4 13.6h6.4V20H4zM13.6 13.6H20V20h-6.4z',
  heart:'M12 20s-7.6-4.6-7.6-9.6a4.3 4.3 0 0 1 7.6-2.6 4.3 4.3 0 0 1 7.6 2.6C19.6 15.4 12 20 12 20z',
  dots:'M6 12h.1M12 12h.1M18 12h.1',
  coffee:'M5 5h11v9a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4zM16 7h2.2a2.4 2.4 0 0 1 0 4.8H16M4 21h13',
  users:'M9 20.4c0-2.9 2.2-4.8 5-4.8s5 1.9 5 4.8M14 12.2a3.6 3.6 0 1 0 0-7.2 3.6 3.6 0 0 0 0 7.2zM4 20.4c0-2.2 1.2-3.7 3-4.3M7.4 12a2.9 2.9 0 1 0 0-5.8',
  fork:'M7 3.4v7.2a2 2 0 0 0 4 0V3.4M9 12.6v8M16.4 3.4c-1.4 2-2 4-2 6.4 0 1.6.8 2.4 2 2.4s2-.8 2-2.4c0-2.4-.6-4.4-2-6.4zM16.4 12.2v8.4',
};

function Icon({ name, size = 20, sw = 1.9, fill = 'none', style }) {
  const d = ICONS[name];
  if (!d) return null;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={style} aria-hidden="true">
      <path d={d} fill={fill} stroke={fill === 'none' ? 'currentColor' : 'none'}
        strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function Av({ id, size = 22, ring = true }) {
  const p = PEOPLE[id] || PEOPLE.you;
  const dark = p.bg === C.cobalt || p.bg === C.orange;
  return (
    <div className="avatar" style={{
      width: size, height: size, background: p.bg,
      color: dark ? '#fff' : C.ink,
      fontSize: size * 0.4, borderWidth: ring ? Math.max(1.4, size * 0.045) : 0,
      borderColor: C.ink,
    }}>{p.init}</div>
  );
}

function Aud({ aud, lg }) {
  const friends = aud === 'friends';
  return (
    <span className={'pill ' + (friends ? 'fill-bu' : 'fill-ink') + (lg ? ' lg' : '')}>
      <Icon name={friends ? 'lock' : 'globe'} size={lg ? 10 : 9} sw={2.4} />
      {friends ? 'Friends' : 'Public'}
    </span>
  );
}

function Stars({ n = 0, size = 12, gap = 2 }) {
  return (
    <span style={{ display: 'inline-flex', gap, alignItems: 'center' }}>
      {[1, 2, 3, 4, 5].map(i => (
        <svg key={i} width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block' }}>
          <path d={ICONS.star} fill={i <= n ? C.orange : 'none'}
            stroke={i <= n ? C.orange : 'rgba(21,19,15,.28)'} strokeWidth="2.2"
            strokeLinejoin="round" />
        </svg>
      ))}
    </span>
  );
}

const buzz = (ms = 8) => { try { navigator.vibrate && navigator.vibrate(ms); } catch (e) {} };
/* how many people you follow have actually been — not the same as drops */
const FRIENDS_BEEN = {
  kettle:4, fern:6, sable:3, castellan:5, volta:7,
  noodle:2, marigold:4, longtable:3, quiet:5,
};

const placeOf = id => PLACES.find(p => p.id === id);

Object.assign(window, {
  C, PEOPLE, PLACES, DROPS, PUBLIC_NOTES, STORIES, ICONS,
  Icon, Av, Aud, Stars, buzz, placeOf, FRIENDS_BEEN,
});
