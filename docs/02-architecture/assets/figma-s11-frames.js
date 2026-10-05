// Figma plugin script for story S11. Run once through the Figma MCP tool `use_figma`
// on file HuVlA9b5rdyosFw0LVO2sR. Not yet run: refused by the plan's call limit on 5 Oct 2026.
// Adds to the Screens page, below the existing frames: a logo sheet, Splash, Today (visitor), Create account.
// Colours are the file's own token values (primary #4355B9), not the app's derived #515B92.
const page = figma.root.children.find(p => p.name === 'Screens');
await figma.setCurrentPageAsync(page);
let maxNum = 0, maxY = -Infinity, minX = Infinity;
for (const n of page.children) {
  const m = /^(\d+)/.exec(n.name);
  if (m) maxNum = Math.max(maxNum, +m[1]);
  maxY = Math.max(maxY, n.y + n.height);
  minX = Math.min(minX, n.x);
}
if (!isFinite(maxY)) { maxY = 0; minX = 200; }

const avail = await figma.listAvailableFontsAsync();
const has = (f, s) => avail.some(a => a.fontName.family === f && a.fontName.style === s);
const FAM = has('Roboto', 'Regular') && has('Roboto', 'Medium') ? 'Roboto' : 'Inter';
const REG = { family: FAM, style: 'Regular' }, MED = { family: FAM, style: 'Medium' };
await figma.loadFontAsync(REG); await figma.loadFontAsync(MED);

const hex = h => ({ r: parseInt(h.slice(1, 3), 16) / 255, g: parseInt(h.slice(3, 5), 16) / 255, b: parseInt(h.slice(5, 7), 16) / 255 });
const solid = h => [{ type: 'SOLID', color: hex(h) }];
const C = { primary: '#4355B9', onPrimary: '#FFFFFF', pc: '#DEE0FF', onPc: '#00105C', surface: '#FBF8FF', on: '#1B1B1F', onVar: '#46464F', outline: '#777680', sc: '#EFEDF4' };

function text(chars, size, color, font, width, align) {
  const t = figma.createText();
  t.fontName = font || REG; t.characters = chars; t.fontSize = size; t.fills = solid(color);
  if (width) { t.resize(width, t.height); t.textAutoResize = 'HEIGHT'; }
  if (align) t.textAlignHorizontal = align;
  return t;
}
function screen(name, bg) {
  const f = figma.createAutoLayout('VERTICAL', { name });
  f.resize(412, 917); f.primaryAxisSizingMode = 'FIXED'; f.counterAxisSizingMode = 'FIXED';
  f.fills = solid(bg); f.clipsContent = true;
  return f;
}
function spacer(parent) {
  const s = figma.createFrame(); s.name = 'spacer'; s.fills = []; s.resize(10, 10);
  parent.appendChild(s); s.layoutGrow = 1; return s;
}
function button(label, parent, filled) {
  const b = figma.createAutoLayout('HORIZONTAL', { name: 'Button / ' + label });
  b.paddingLeft = b.paddingRight = 24; b.paddingTop = b.paddingBottom = 10; b.cornerRadius = 100;
  b.primaryAxisAlignItems = 'CENTER'; b.counterAxisAlignItems = 'CENTER';
  b.fills = filled ? solid(C.primary) : [];
  b.appendChild(text(label, 14, filled ? C.onPrimary : C.primary, MED));
  parent.appendChild(b);
  return b;
}
const markPaths = (light) => `<g transform="translate(0 4) translate(54 50) scale(0.88) translate(-54 -50)">
<path d="M30,44 L52,50 L52,80 L30,74 Z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="3" stroke-linejoin="round"/>
<path d="M78,44 L56,50 L56,80 L78,74 Z" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="3" stroke-linejoin="round"/>
<g transform="translate(54 31) rotate(-35)"><path d="M0,-5.5 H-7.5 A5.5,5.5 0 0 0 -7.5,5.5 H0 Z" fill="#FFFFFF"/><path d="M0,-5.5 H7.5 A5.5,5.5 0 0 1 7.5,5.5 H0 Z" fill="${light}"/></g></g>`;
function logo(size, badge, name) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108">${badge ? `<rect width="108" height="108" rx="24" fill="${C.primary}"/>` : ''}${markPaths(C.pc)}</svg>`;
  const n = figma.createNodeFromSvg(svg); n.name = name; n.rescale(size / 108); return n;
}

const y0 = maxY + 240; let x = minX; const made = [];
const place = f => { page.appendChild(f); f.x = x; f.y = y0; x += f.width + 100; made.push(f); };

// Logo sheet
const sheet = figma.createAutoLayout('VERTICAL', { name: 'Logo / DoseBook' });
sheet.paddingLeft = sheet.paddingRight = sheet.paddingTop = sheet.paddingBottom = 32; sheet.itemSpacing = 24;
sheet.fills = solid(C.surface); sheet.counterAxisAlignItems = 'MIN';
sheet.appendChild(text('DoseBook logo', 22, C.on, REG));
const row = figma.createAutoLayout('HORIZONTAL', { name: 'Marks' }); row.itemSpacing = 32; row.counterAxisAlignItems = 'CENTER'; row.fills = [];
row.appendChild(logo(192, true, 'App icon 192'));
row.appendChild(logo(96, true, 'App icon 96'));
row.appendChild(logo(48, true, 'App icon 48'));
sheet.appendChild(row);
const lock = figma.createAutoLayout('HORIZONTAL', { name: 'Mark + wordmark' }); lock.itemSpacing = 12; lock.counterAxisAlignItems = 'CENTER'; lock.fills = [];
lock.appendChild(logo(56, true, 'Mark'));
lock.appendChild(text('DoseBook', 28, C.on, MED));
sheet.appendChild(lock);
sheet.appendChild(text('Open book with a capsule above the fold: your own record of medicines.\nDrawn on a 108 grid inside the centre two thirds (Android adaptive icon safe zone).\nSame geometry in mobile/lib/widgets/logo.dart and res/drawable/ic_logo_foreground.xml.', 12, C.onVar, REG, 420));
place(sheet);

const n1 = String(maxNum + 1).padStart(2, '0'), n2 = String(maxNum + 2).padStart(2, '0'), n3 = String(maxNum + 3).padStart(2, '0');

// Splash
const splash = screen(n1 + ' Splash', C.primary);
splash.primaryAxisAlignItems = 'CENTER'; splash.counterAxisAlignItems = 'CENTER'; splash.itemSpacing = 12; splash.paddingLeft = splash.paddingRight = 32;
splash.appendChild(logo(144, false, 'Mark'));
splash.appendChild(text('DoseBook', 28, C.onPrimary, REG));
splash.appendChild(text('We recall, we remind, we never prescribe.', 16, C.pc, REG, 320, 'CENTER'));
place(splash);

// Today as a visitor
const guest = screen(n2 + ' Today (visitor)', C.surface);
guest.counterAxisAlignItems = 'CENTER';
const bar = figma.createAutoLayout('HORIZONTAL', { name: 'Top bar' }); bar.fills = []; bar.paddingLeft = bar.paddingRight = 16; bar.paddingTop = 20; bar.paddingBottom = 16; bar.primaryAxisAlignItems = 'SPACE_BETWEEN'; bar.counterAxisAlignItems = 'CENTER';
bar.appendChild(text('Today', 22, C.on, REG)); bar.appendChild(text('Account', 12, C.onVar, REG));
guest.appendChild(bar); bar.layoutSizingHorizontal = 'FILL';
spacer(guest);
const col = figma.createAutoLayout('VERTICAL', { name: 'Explain' }); col.fills = []; col.itemSpacing = 12; col.counterAxisAlignItems = 'CENTER';
const av = figma.createEllipse(); av.resize(72, 72); av.fills = solid(C.pc); av.name = 'Icon circle'; col.appendChild(av);
col.appendChild(text('Your doses for today', 16, C.on, MED));
col.appendChild(text('After you confirm a prescription, the doses due each day appear here to mark Taken or Skipped, and your phone reminds you. You can add your own reminders too.', 14, C.onVar, REG, 300, 'CENTER'));
const gap = figma.createFrame(); gap.resize(10, 12); gap.fills = []; gap.name = 'gap'; col.appendChild(gap);
button('Sign in', col, true); button('Create account', col, false);
guest.appendChild(col);
spacer(guest);
const fabRow = figma.createAutoLayout('HORIZONTAL', { name: 'FAB row' }); fabRow.fills = []; fabRow.paddingRight = 16; fabRow.paddingBottom = 16; fabRow.primaryAxisAlignItems = 'MAX';
const fab = figma.createAutoLayout('HORIZONTAL', { name: 'FAB / My reminder (asks to sign in)' }); fab.paddingLeft = fab.paddingRight = 20; fab.paddingTop = fab.paddingBottom = 18; fab.cornerRadius = 16; fab.fills = solid(C.pc);
fab.appendChild(text('+  My reminder', 14, C.onPc, MED)); fabRow.appendChild(fab);
guest.appendChild(fabRow); fabRow.layoutSizingHorizontal = 'FILL';
const nav = figma.createAutoLayout('HORIZONTAL', { name: 'Navigation bar' }); nav.fills = solid(C.sc); nav.paddingTop = 28; nav.paddingBottom = 28; nav.primaryAxisAlignItems = 'SPACE_BETWEEN'; nav.paddingLeft = nav.paddingRight = 32;
['Today', 'Timeline', 'Chat', 'Notes'].forEach((l, i) => nav.appendChild(text(l, 12, i === 0 ? C.on : C.onVar, i === 0 ? MED : REG)));
guest.appendChild(nav); nav.layoutSizingHorizontal = 'FILL';
place(guest);

// Create account
const su = screen(n3 + ' Create account', C.surface);
su.paddingLeft = su.paddingRight = 24; su.paddingTop = 24; su.itemSpacing = 16;
su.appendChild(text('←', 22, C.on, REG));
su.appendChild(logo(56, true, 'Mark'));
su.appendChild(text('Create account', 24, C.on, REG));
su.appendChild(text('Your records are visible only to you.', 16, C.onVar, REG, 364));
for (const [label, helper] of [['Email', null], ['Password', 'At least 8 characters'], ['Password again', null]]) {
  const wrap = figma.createAutoLayout('VERTICAL', { name: 'Field / ' + label }); wrap.fills = []; wrap.itemSpacing = 4;
  const f = figma.createAutoLayout('HORIZONTAL', { name: 'Outline' }); f.fills = []; f.strokes = solid(C.outline); f.strokeWeight = 1; f.cornerRadius = 4;
  f.paddingLeft = f.paddingRight = 16; f.paddingTop = f.paddingBottom = 18; f.primaryAxisAlignItems = 'SPACE_BETWEEN'; f.counterAxisAlignItems = 'CENTER';
  f.appendChild(text(label, 16, C.onVar, REG));
  if (label === 'Password') f.appendChild(text('Show', 12, C.onVar, REG));
  wrap.appendChild(f); f.layoutSizingHorizontal = 'FILL';
  if (helper) wrap.appendChild(text('    ' + helper, 12, C.onVar, REG));
  su.appendChild(wrap); wrap.layoutSizingHorizontal = 'FILL';
}
const b1 = button('Create account', su, true); b1.layoutSizingHorizontal = 'FILL';
const b2 = button('I already have an account', su, false); b2.layoutSizingHorizontal = 'FILL';
su.appendChild(text('Future scope: verify the email address before the account is used.', 12, C.onVar, REG, 364));
place(su);

await sheet.screenshot(); await splash.screenshot(); await guest.screenshot(); await su.screenshot();
return { font: FAM, maxNumBefore: maxNum, created: made.map(f => ({ id: f.id, name: f.name, x: f.x, y: f.y, w: f.width, h: f.height })) };
