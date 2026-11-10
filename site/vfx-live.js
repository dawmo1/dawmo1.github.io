// Live VFX playground: eight abilities on a small hand-written particle engine.
// Pick an effect, click the arena to cast it there. Sounds are the portfolio's own SFX.
(() => {
  'use strict';
  const root = document.querySelector('.playground');
  if (!root) return;
  const cv = root.querySelector('canvas'), g = cv.getContext('2d');
  const picks = [...root.querySelectorAll('[data-fx]')], soundBtn = root.querySelector('.pg-sound'), hint = root.querySelector('.pg-hint');
  const calm = matchMedia('(prefers-reduced-motion: reduce)');

  /* ---------- helpers ---------- */
  const rnd = (a, b) => a + Math.random() * (b - a);
  const pick = (arr) => arr[Math.floor(Math.random() * arr.length)];
  const lerp = (a, b, t) => a + (b - a) * t;
  const ease = (t) => 1 - (1 - t) ** 3;
  const TAU = Math.PI * 2;

  let W = 0, H = 0, bg = null;
  const horizon = () => H * 0.5, floorTop = () => H * 0.56;
  function fit() {
    const dpr = Math.min(devicePixelRatio || 1, 2), r = cv.getBoundingClientRect();
    W = r.width; H = r.height; cv.width = Math.round(W * dpr); cv.height = Math.round(H * dpr);
    g.setTransform(dpr, 0, 0, dpr, 0, 0);
    // arena backdrop drawn once per size: dark sky, spotlight, perspective floor grid
    bg = document.createElement('canvas'); bg.width = cv.width; bg.height = cv.height;
    const b = bg.getContext('2d'); b.setTransform(dpr, 0, 0, dpr, 0, 0);
    const sky = b.createLinearGradient(0, 0, 0, H); sky.addColorStop(0, '#07080d'); sky.addColorStop(1, '#10131b');
    b.fillStyle = sky; b.fillRect(0, 0, W, H);
    const spot = b.createRadialGradient(W / 2, H * 0.62, 0, W / 2, H * 0.62, W * 0.5);
    spot.addColorStop(0, 'rgba(90,240,255,.07)'); spot.addColorStop(1, 'rgba(90,240,255,0)');
    b.fillStyle = spot; b.fillRect(0, 0, W, H);
    const hz = horizon(); b.strokeStyle = 'rgba(90,240,255,.07)'; b.lineWidth = 1;
    for (let i = 1; i < 14; i++) { const y = hz + (H - hz) * (i / 13) ** 1.8; b.beginPath(); b.moveTo(0, y); b.lineTo(W, y); b.stroke(); }
    for (let i = -12; i <= 12; i++) { b.beginPath(); b.moveTo(W / 2 + i * 14, hz); b.lineTo(W / 2 + i * W * 0.16, H); b.stroke(); }
    const fade = b.createLinearGradient(0, hz - 30, 0, hz + 40); fade.addColorStop(0, '#07080d'); fade.addColorStop(1, 'rgba(7,8,13,0)');
    b.fillStyle = fade; b.fillRect(0, hz - 30, W, 70);
  }

  // soft round sprite per colour, so thousands of glows stay cheap
  const sprites = new Map();
  function sprite(rgb, soft = false) {
    const key = rgb + soft; let c = sprites.get(key);
    if (c) return c;
    c = document.createElement('canvas'); c.width = c.height = 64;
    const x = c.getContext('2d'), gr = x.createRadialGradient(32, 32, 0, 32, 32, 32);
    if (soft) { gr.addColorStop(0, `rgba(${rgb},.55)`); gr.addColorStop(0.6, `rgba(${rgb},.25)`); gr.addColorStop(1, `rgba(${rgb},0)`); }
    else { gr.addColorStop(0, `rgba(${rgb},1)`); gr.addColorStop(0.3, `rgba(${rgb},.5)`); gr.addColorStop(1, `rgba(${rgb},0)`); }
    x.fillStyle = gr; x.fillRect(0, 0, 64, 64); sprites.set(key, c); return c;
  }
  const blob = (rgb, x, y, size, a, soft) => { if (a <= 0 || size <= 0) return; g.globalAlpha = Math.min(1, a); g.drawImage(sprite(rgb, soft), x - size, y - size, size * 2, size * 2); g.globalAlpha = 1; };

  /* ---------- simulation state ---------- */
  const parts = [], fx = [], timers = [];
  let shake = 0, flash = 0, flashRGB = '255,255,255', clock = 0;
  const after = (s, fn) => timers.push({ at: clock + s, fn });
  const kick = (amount) => { if (!calm.matches) shake = Math.max(shake, amount); };
  const flashOf = (a, rgb = '255,255,255') => { if (!calm.matches) { flash = Math.max(flash, a); flashRGB = rgb; } };

  // particle kinds: glow (additive sprite), streak (motion line), smoke (soft, normal blend), shard (spinning triangle), plus (heal cross)
  function P(o) {
    const p = Object.assign({ x: 0, y: 0, vx: 0, vy: 0, ay: 0, drag: 0, life: 1, size: 8, size1: null, rgb: '255,255,255', a: 1,
      kind: 'glow', rot: rnd(0, TAU), vr: 0, bounce: false }, o);
    p.max = p.life; if (p.size1 === null) p.size1 = p.size; parts.push(p);
  }
  function ring(x, y, r1, life, rgb, width = 4, squash = 0.32, r0 = 4) { fx.push({ layer: 1, t: 0, life, draw(t) {
    const k = ease(t / this.life), a = 1 - t / this.life;
    g.globalCompositeOperation = 'lighter'; g.strokeStyle = `rgba(${rgb},${0.85 * a})`; g.lineWidth = width * a + 0.5;
    g.beginPath(); g.ellipse(x, y, lerp(r0, r1, k), lerp(r0, r1, k) * squash, 0, 0, TAU); g.stroke();
  } }); }
  function decal(life, draw) { fx.push({ layer: 0, t: 0, life, draw(t) { draw(1 - t / this.life, t); } }); }

  const sounds = new Map();
  let soundOn = true;
  function play(name, vol = 0.55) {
    if (!soundOn || !userCast) return;   // the attract loop stays silent
    let pool = sounds.get(name); if (!pool) { pool = [new Audio(`sfx/ogg/${name}.ogg`)]; sounds.set(name, pool); }
    const a = pool.find(x => x.paused || x.ended) || pool[pool.push(pool[0].cloneNode()) - 1];
    a.volume = vol; a.currentTime = 0; a.play().catch(() => {});
  }

  /* ---------- the eight abilities ---------- */
  function boltPath(x0, y0, x1, y1, jag) {
    const n = Math.max(6, Math.round(Math.hypot(x1 - x0, y1 - y0) / 20)), pts = [{ x: x0, y: y0 }];
    for (let i = 1; i < n; i++) { const t = i / n; pts.push({ x: lerp(x0, x1, t) + rnd(-jag, jag) * Math.sin(Math.PI * t), y: lerp(y0, y1, t) + rnd(-5, 5) }); }
    pts.push({ x: x1, y: y1 }); return pts;
  }
  function strokePath(pts, w, color) { g.strokeStyle = color; g.lineWidth = w; g.beginPath(); pts.forEach((q, i) => i ? g.lineTo(q.x, q.y) : g.moveTo(q.x, q.y)); g.stroke(); }

  const FX = {
    storm(p) {
      play('lightning_strike');
      for (let k = 0; k < 3; k++) after(k * 0.09, () => {
        const x0 = p.x + rnd(-70, 70), build = () => {
          const main = boltPath(x0, -10, p.x + rnd(-6, 6), p.y, 34), forks = [];
          for (let f = 0; f < 2; f++) { const s = main[Math.floor(rnd(0.3, 0.7) * main.length)]; forks.push(boltPath(s.x, s.y, s.x + rnd(-90, 90), s.y + rnd(50, 110), 16)); }
          return [main, ...forks];
        };
        let paths = build(), regen = 0;
        fx.push({ layer: 1, t: 0, life: 0.32, draw(t) {
          regen += 1; if (regen % 3 === 0) paths = build();   // re-jag for a crackling flicker
          const a = (t < 0.06 || (t > 0.1 && t < 0.16) ? 1 : 0.55) * (1 - t / this.life);
          g.globalCompositeOperation = 'lighter'; g.lineJoin = 'round';
          paths.forEach((pts, i) => { const s = i ? 0.55 : 1;
            strokePath(pts, 14 * s, `rgba(90,200,255,${0.12 * a})`); strokePath(pts, 5 * s, `rgba(140,230,255,${0.45 * a})`); strokePath(pts, 1.8 * s, `rgba(255,255,255,${a})`); });
        } });
        flashOf(0.28, '170,235,255'); kick(7);
      });
      after(0.05, () => {
        ring(p.x, p.y, 150, 0.55, '120,220,255', 5); ring(p.x, p.y, 90, 0.4, '255,255,255', 2);
        P({ x: p.x, y: p.y - 10, size: 70, size1: 20, life: 0.6, rgb: '120,210,255' });
        for (let i = 0; i < 36; i++) { const a = rnd(-Math.PI, 0), s = rnd(150, 520);
          P({ kind: 'streak', x: p.x, y: p.y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, ay: 900, drag: 1.2, life: rnd(0.3, 0.7), size: rnd(1.5, 3), rgb: pick(['190,240,255', '255,255,255']), bounce: true }); }
        decal(1.6, (a) => { g.globalCompositeOperation = 'source-over'; blob('0,0,0', p.x, p.y, 70, 0.6 * a, true); g.save(); g.translate(p.x, p.y); g.scale(1, 0.3); blob('90,200,255', 0, 0, 60, 0.35 * a); g.restore(); });
      });
    },

    inferno(p) {
      const c = { x: p.x, y: p.y - 46 };
      play('fireball_cast', 0.4); after(0.12, () => play('fire_explosion'));
      // incoming fireball, then detonation
      fx.push({ layer: 1, t: 0, life: 0.14, draw(t) { const k = t / this.life; g.globalCompositeOperation = 'lighter'; blob('255,170,60', lerp(c.x - 160, c.x, k), lerp(c.y - 120, c.y, k), 26, 1); } });
      after(0.14, () => {
        flashOf(0.22, '255,170,90'); kick(9);
        P({ x: c.x, y: c.y, size: 30, size1: 150, life: 0.35, rgb: '255,240,200' });
        P({ x: c.x, y: c.y, size: 60, size1: 120, life: 0.6, rgb: '255,120,40' });
        for (let i = 0; i < 70; i++) { const a = rnd(0, TAU), s = rnd(80, 330);
          P({ x: c.x, y: c.y, vx: Math.cos(a) * s, vy: Math.sin(a) * s * 0.75, ay: -140, drag: 2.6, life: rnd(0.45, 0.9), size: rnd(12, 22), size1: 3, rgb: pick(['255,210,90', '255,150,50', '255,95,35']) }); }
        for (let i = 0; i < 24; i++) after(rnd(0.05, 0.2), () =>
          P({ kind: 'smoke', x: c.x + rnd(-40, 40), y: c.y + rnd(-25, 15), vx: rnd(-60, 60), vy: rnd(-90, -35), drag: 1, life: rnd(1.3, 2.3), size: rnd(26, 40), size1: rnd(90, 130), rgb: pick(['55,50,55', '70,60,60']), a: 0.55 }));
        for (let i = 0; i < 26; i++) { const a = rnd(-Math.PI, 0), s = rnd(200, 520);
          P({ kind: 'streak', x: c.x, y: c.y, vx: Math.cos(a) * s, vy: Math.sin(a) * s, ay: 700, drag: 0.8, life: rnd(0.6, 1.2), size: rnd(1.5, 2.5), rgb: '255,180,80', bounce: true }); }
        ring(p.x, p.y, 170, 0.55, '255,150,60', 5);
        decal(2.2, (a) => { g.globalCompositeOperation = 'source-over'; g.save(); g.translate(p.x, p.y); g.scale(1, 0.3); blob('0,0,0', 0, 0, 110, 0.7 * a, true); blob('255,110,30', 0, 0, 70, 0.3 * a * a); g.restore(); });
      });
    },

    portal(p) {
      const c = { x: p.x, y: p.y - 84 }, D = 2.4;
      play('portal_open');
      const o = { layer: 1, t: 0, life: D + 0.28,
        r(t) { return 66 * (t < 0.35 ? ease(t / 0.35) : t > D ? Math.max(0, 1 - (t - D) / 0.28) : 1 + 0.05 * Math.sin(t * 7)); },
        tick(t) { if (t > D) return; const r = this.r(t);
          for (let i = 0; i < 3; i++) { const a = rnd(0, TAU), R = r * rnd(1.5, 2.3);
            P({ x: c.x + Math.cos(a) * R, y: c.y + Math.sin(a) * R * 0.68, vx: -Math.sin(a) * R * 2.4 - Math.cos(a) * R * 1.5, vy: (Math.cos(a) * R * 2.4 - Math.sin(a) * R * 1.5) * 0.68,
               drag: 1.6, life: 0.55, size: rnd(4, 8), size1: 1, rgb: pick(['185,120,255', '130,90,255', '255,150,255']) }); } },
        draw(t) { const r = this.r(t); if (r <= 0.5) return;
          g.globalCompositeOperation = 'lighter'; blob('140,70,255', c.x, c.y, r * 3.2, 0.45);
          g.lineWidth = 3;
          for (let k = 0; k < 4; k++) { const a0 = t * 3.4 + k * TAU / 4; g.strokeStyle = 'rgba(210,160,255,.55)';
            g.beginPath(); g.ellipse(c.x, c.y, r * 1.18, r * 0.8, 0, a0, a0 + 1.4); g.stroke(); }
          g.globalCompositeOperation = 'source-over';
          g.save(); g.translate(c.x, c.y); g.scale(1, 0.68);
          const gr = g.createRadialGradient(0, 0, 0, 0, 0, r); gr.addColorStop(0, '#030008'); gr.addColorStop(0.72, '#12002a'); gr.addColorStop(1, 'rgba(190,130,255,.95)');
          g.fillStyle = gr; g.beginPath(); g.arc(0, 0, r, 0, TAU); g.fill(); g.restore();
        } };
      fx.push(o);
      after(D, () => { kick(6); flashOf(0.14, '200,150,255'); ring(c.x, c.y, 160, 0.5, '200,150,255', 4, 0.68);
        for (let i = 0; i < 48; i++) { const a = rnd(0, TAU), s = rnd(120, 380);
          P({ x: c.x, y: c.y, vx: Math.cos(a) * s, vy: Math.sin(a) * s * 0.68, drag: 2.4, life: rnd(0.4, 0.8), size: rnd(5, 10), size1: 1, rgb: pick(['200,150,255', '255,170,255']) }); } });
      decal(D + 0.4, (a) => { g.globalCompositeOperation = 'lighter'; g.save(); g.translate(p.x, p.y); g.scale(1, 0.28); blob('140,70,255', 0, 0, 90, 0.35 * Math.min(1, a * 3)); g.restore(); });
    },

    dash(p) {
      const c = { x: p.x, y: p.y - 64 };
      const cuts = [[-2.6, 0.2, -0.45, 1], [0.6, -2.3, 0.5, 2], [-3.0, 0.1, 0.05, 3]];
      cuts.forEach(([a0, a1, tilt, n], i) => after(i * 0.15, () => {
        play(`slash_heavy_${n}`, 0.45); kick(4);
        const R = rnd(90, 115);
        fx.push({ layer: 1, t: 0, life: 0.38, draw(t) {
          const k = t / this.life, head = ease(Math.min(1, k / 0.4)), tail = ease(Math.max(0, (k - 0.12) / 0.88));
          const A = lerp(a0, a1, head), B = lerp(a0, a1, tail), segs = 26;
          if (Math.abs(A - B) < 0.01) return;
          g.globalCompositeOperation = 'lighter'; g.lineCap = 'round';
          for (let s = 0; s < segs; s++) {
            const u0 = s / segs, u1 = (s + 1) / segs, w = 20 * u1 ** 1.3 * (1 - u1 ** 10) * (1 - k * 0.5);
            const aa = lerp(B, A, u0), ab = lerp(B, A, u1);
            g.save(); g.translate(c.x, c.y); g.rotate(tilt); g.scale(1, 0.55);
            g.strokeStyle = `rgba(90,220,255,${0.75 * (1 - k)})`; g.lineWidth = w; g.beginPath(); g.arc(0, 0, R, aa, ab, ab < aa); g.stroke();
            g.strokeStyle = `rgba(255,255,255,${0.95 * (1 - k)})`; g.lineWidth = w * 0.3; g.beginPath(); g.arc(0, 0, R, aa, ab, ab < aa); g.stroke();
            g.restore();
          }
        } });
        for (let s = 0; s < 12; s++) { const a = a1 + rnd(-0.4, 0.4), sp = rnd(200, 460);
          const ex = c.x + Math.cos(a1) * R * Math.cos(tilt), ey = c.y + Math.sin(a1) * R * 0.55;
          P({ kind: 'streak', x: ex, y: ey, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, drag: 3, life: rnd(0.2, 0.4), size: rnd(1.5, 2.5), rgb: '200,245,255' }); }
      }));
      after(0.45, () => { flashOf(0.12, '160,235,255'); P({ x: c.x, y: c.y, size: 20, size1: 110, life: 0.35, rgb: '180,240,255' });
        fx.push({ layer: 1, t: 0, life: 0.3, draw(t) { const a = 1 - t / this.life; g.globalCompositeOperation = 'lighter';
          g.strokeStyle = `rgba(255,255,255,${a})`; g.lineWidth = 2; g.beginPath(); g.moveTo(c.x - 140 * ease(t / this.life + 0.2), c.y); g.lineTo(c.x + 140 * ease(t / this.life + 0.2), c.y); g.stroke(); } }); });
    },

    slam(p) {
      play('ground_slam'); kick(15);
      ring(p.x, p.y, 230, 0.7, '220,190,150', 6); after(0.08, () => ring(p.x, p.y, 150, 0.6, '255,230,200', 3));
      P({ x: p.x, y: p.y - 10, size: 40, size1: 120, life: 0.3, rgb: '255,220,170' });
      for (let i = 0; i < 28; i++) { const a = rnd(0, TAU);
        P({ kind: 'shard', x: p.x + rnd(-20, 20), y: p.y, vx: Math.cos(a) * rnd(60, 320), vy: -rnd(260, 640), ay: 1500, drag: 0.4, life: rnd(1.2, 1.9), size: rnd(4, 11),
           vr: rnd(-12, 12), rgb: pick(['120,100,85', '95,85,78', '150,130,110']), bounce: true }); }
      for (let i = 0; i < 22; i++) { const side = Math.random() < 0.5 ? -1 : 1;
        P({ kind: 'smoke', x: p.x + side * rnd(10, 60), y: p.y - rnd(0, 20), vx: side * rnd(90, 260), vy: rnd(-50, -10), drag: 2, life: rnd(1, 1.8), size: rnd(20, 30), size1: rnd(80, 120), rgb: '135,115,95', a: 0.4 }); }
      const cracks = Array.from({ length: 8 }, (_, i) => { const a = i / 8 * TAU + rnd(-0.2, 0.2), pts = [{ x: 0, y: 0 }]; let r = 0;
        while (r < 120) { r += rnd(14, 26); const aa = a + rnd(-0.25, 0.25); pts.push({ x: Math.cos(aa) * r, y: Math.sin(aa) * r * 0.32 }); } return pts; });
      decal(2.6, (a, t) => { g.save(); g.translate(p.x, p.y); g.globalCompositeOperation = 'source-over'; g.lineJoin = 'round';
        cracks.forEach(pts => { const grow = Math.min(1, t / 0.12), n = Math.max(2, Math.ceil(pts.length * grow)), seg = pts.slice(0, n);
          strokePath(seg, 4, `rgba(0,0,0,${0.75 * a})`);
          if (t < 0.6) { g.globalCompositeOperation = 'lighter'; strokePath(seg, 1.6, `rgba(255,170,80,${(1 - t / 0.6) * a})`); g.globalCompositeOperation = 'source-over'; } });
        g.restore(); });
    },

    frost(p) {
      play('egg_crack_1', 0.5); after(0.05, () => play('impact_heavy_2', 0.35));
      flashOf(0.16, '200,245,255'); kick(5);
      ring(p.x, p.y, 190, 0.7, '170,235,255', 5); after(0.1, () => ring(p.x, p.y, 120, 0.6, '255,255,255', 2));
      P({ x: p.x, y: p.y - 20, size: 30, size1: 110, life: 0.4, rgb: '200,245,255' });
      for (let i = 0; i < 34; i++) { const a = rnd(0, TAU), s = rnd(140, 420);
        P({ kind: 'shard', x: p.x, y: p.y - 14, vx: Math.cos(a) * s, vy: Math.sin(a) * s * 0.45 - rnd(60, 220), ay: 900, drag: 1.2, life: rnd(0.7, 1.2), size: rnd(4, 10),
           vr: rnd(-10, 10), rgb: pick(['190,240,255', '230,250,255', '140,210,255']), add: true, bounce: true }); }
      for (let i = 0; i < 40; i++) after(rnd(0, 0.5), () =>
        P({ x: p.x + rnd(-150, 150), y: p.y - rnd(0, 120), vx: rnd(-15, 15), vy: rnd(-30, 10), life: rnd(1, 1.8), size: rnd(2, 5), size1: 0.5, rgb: '220,250,255' }));
      // ice spikes burst up from the ground around the cast point
      const spikes = Array.from({ length: 9 }, () => ({ x: rnd(-110, 110), h: rnd(30, 75), w: rnd(8, 16), d: rnd(0, 0.15) }));
      spikes.forEach(s => { s.y = Math.sqrt(Math.max(0, 1 - (s.x / 120) ** 2)) * rnd(-34, 34); });
      spikes.sort((a, b) => a.y - b.y);
      decal(2.4, (a, t) => { g.save(); g.translate(p.x, p.y);
        g.globalCompositeOperation = 'lighter'; g.save(); g.scale(1, 0.3); blob('120,210,255', 0, 0, 150, 0.4 * a); g.restore();
        g.globalCompositeOperation = 'source-over';
        spikes.forEach(s => { const k = ease(Math.min(1, Math.max(0, (t - s.d) / 0.12))) * Math.min(1, a * 2.5), h = s.h * k;
          if (h < 1) return;
          g.fillStyle = `rgba(170,230,255,${0.85 * Math.min(1, a * 2.5)})`; g.beginPath(); g.moveTo(s.x - s.w / 2, s.y); g.lineTo(s.x, s.y - h); g.lineTo(s.x + s.w / 2, s.y); g.fill();
          g.fillStyle = `rgba(255,255,255,${0.7 * Math.min(1, a * 2.5)})`; g.beginPath(); g.moveTo(s.x - s.w * 0.1, s.y); g.lineTo(s.x, s.y - h); g.lineTo(s.x + s.w * 0.35, s.y); g.fill(); });
        g.restore(); });
    },

    beam(p) {
      const o = { x: p.x, y: p.y - 70 }, dir = p.x < W / 2 ? 1 : -1, end = dir > 0 ? W + 20 : -20;
      play('charge_up', 0.45);
      fx.push({ layer: 1, t: 0, life: 0.75,
        tick(t) { if (t > 0.65) return; for (let i = 0; i < 3; i++) { const a = rnd(0, TAU), R = rnd(70, 130);
          P({ x: o.x + Math.cos(a) * R, y: o.y + Math.sin(a) * R, vx: -Math.cos(a) * R * 3.4, vy: -Math.sin(a) * R * 3.4, life: 0.28, size: rnd(3, 6), size1: 1, rgb: pick(['120,240,255', '255,255,255']) }); } },
        draw(t) { g.globalCompositeOperation = 'lighter'; const k = t / this.life; blob('90,230,255', o.x, o.y, 14 + 34 * k + Math.sin(t * 50) * 3, 0.9); blob('255,255,255', o.x, o.y, 8 + 12 * k, 1); } });
      after(0.72, () => {
        play('charge_release'); kick(8); flashOf(0.18, '160,240,255');
        fx.push({ layer: 1, t: 0, life: 0.62, draw(t) {
          const k = t / this.life, grow = ease(Math.min(1, t / 0.08)), x1 = lerp(o.x, end, grow), a = k < 0.7 ? 1 : 1 - (k - 0.7) / 0.3;
          const j = Math.sin(t * 90) * 2.5, w = (1 - k * 0.6);
          g.globalCompositeOperation = 'lighter'; g.lineCap = 'round';
          [[46, 'rgba(60,180,255,.12)'], [26, 'rgba(90,220,255,.3)'], [12 + j, 'rgba(160,245,255,.7)'], [4, 'rgba(255,255,255,1)']].forEach(([lw, col]) => {
            g.globalAlpha = a; g.strokeStyle = col; g.lineWidth = lw * w; g.beginPath(); g.moveTo(o.x, o.y); g.lineTo(x1, o.y); g.stroke(); });
          g.globalAlpha = 1; blob('140,240,255', o.x, o.y, 50 * w, a);
          if (Math.random() < 0.6) P({ kind: 'streak', x: lerp(o.x, x1, Math.random()), y: o.y + rnd(-6, 6), vx: dir * rnd(200, 500), vy: rnd(-160, 160), drag: 3, life: 0.25, size: 1.6, rgb: '200,250,255' });
        } });
      });
    },

    heal(p) {
      play('reward_jingle', 0.4);
      ring(p.x, p.y, 120, 0.9, '120,255,160', 4); after(0.25, () => ring(p.x, p.y, 120, 0.9, '200,255,210', 2));
      decal(1.6, (a) => { g.globalCompositeOperation = 'lighter';
        const col = g.createLinearGradient(0, p.y - 220, 0, p.y); col.addColorStop(0, 'rgba(120,255,160,0)'); col.addColorStop(1, `rgba(120,255,160,${0.28 * a})`);
        g.fillStyle = col; g.fillRect(p.x - 46, p.y - 220, 92, 220);
        g.save(); g.translate(p.x, p.y); g.scale(1, 0.3); blob('120,255,160', 0, 0, 100, 0.5 * a); g.restore(); });
      for (let i = 0; i < 46; i++) after(rnd(0, 0.8), () => { const a = rnd(0, TAU), r = rnd(0, 60);
        P({ x: p.x + Math.cos(a) * r, y: p.y + Math.sin(a) * r * 0.3, vx: rnd(-10, 10), vy: -rnd(50, 140), life: rnd(0.9, 1.6), size: rnd(3, 7), size1: 1, rgb: pick(['120,255,160', '200,255,210', '255,255,200']) }); });
      for (let i = 0; i < 9; i++) after(rnd(0.1, 0.8), () =>
        P({ kind: 'plus', x: p.x + rnd(-55, 55), y: p.y - rnd(0, 40), vy: -rnd(40, 80), life: rnd(1, 1.5), size: rnd(5, 8), rgb: '150,255,180' }));
    },
  };

  /* ---------- frame ---------- */
  let raf = 0, last = 0, visible = false;
  function draw(p, t) {
    const k = 1 - p.life / p.max, s = lerp(p.size, p.size1, k);
    if (p.kind === 'smoke') { blob(p.rgb, p.x, p.y, s, p.a * Math.sin(Math.PI * Math.min(1, k * 1.15)), true); return; }
    const a = p.a * (1 - k);
    if (p.kind === 'glow') blob(p.rgb, p.x, p.y, s, a);
    else if (p.kind === 'streak') { g.strokeStyle = `rgba(${p.rgb},${a})`; g.lineWidth = s; g.lineCap = 'round';
      g.beginPath(); g.moveTo(p.x, p.y); g.lineTo(p.x - p.vx * 0.035, p.y - p.vy * 0.035); g.stroke(); }
    else if (p.kind === 'shard') { g.save(); g.translate(p.x, p.y); g.rotate(p.rot); g.fillStyle = `rgba(${p.rgb},${Math.min(1, a * 1.6)})`;
      g.beginPath(); g.moveTo(0, -s); g.lineTo(s * 0.7, s * 0.6); g.lineTo(-s * 0.6, s * 0.4); g.fill(); g.restore(); }
    else if (p.kind === 'plus') { blob(p.rgb, p.x, p.y, s * 2.4, a * 0.5); g.fillStyle = `rgba(255,255,255,${a})`;
      g.fillRect(p.x - s / 2, p.y - s * 0.15, s, s * 0.3); g.fillRect(p.x - s * 0.15, p.y - s / 2, s * 0.3, s); }
  }
  function frame(t) {
    const dt = Math.min((t - last) / 1000, 1 / 30); last = t; clock += dt;
    for (let i = timers.length - 1; i >= 0; i--) if (timers[i].at <= clock) { const f = timers[i].fn; timers.splice(i, 1); f(); }
    const fl = H - 6;
    for (let i = parts.length - 1; i >= 0; i--) {
      const p = parts[i]; p.life -= dt; if (p.life <= 0) { parts.splice(i, 1); continue; }
      const d = Math.exp(-p.drag * dt); p.vx *= d; p.vy = p.vy * d + p.ay * dt; p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt;
      if (p.bounce && p.y > fl && p.vy > 0) { p.y = fl; p.vy *= -0.32; p.vx *= 0.6; p.vr *= 0.5; }
    }
    for (let i = fx.length - 1; i >= 0; i--) { const f = fx[i]; f.t += dt; f.tick?.(f.t); if (f.t >= f.life) fx.splice(i, 1); }

    g.setTransform(1, 0, 0, 1, 0, 0); g.globalCompositeOperation = 'source-over'; g.drawImage(bg, 0, 0);
    const dpr = cv.width / W; g.setTransform(dpr, 0, 0, dpr, 0, 0);
    shake *= Math.exp(-dt * 9); if (shake > 0.2) g.translate(rnd(-shake, shake), rnd(-shake, shake) * 0.6);
    fx.forEach(f => f.layer === 0 && f.draw(f.t));
    g.globalCompositeOperation = 'source-over'; parts.forEach(p => p.kind === 'smoke' && draw(p, t));
    g.globalCompositeOperation = 'lighter'; parts.forEach(p => p.kind !== 'smoke' && p.kind !== 'shard' && draw(p, t));
    g.globalCompositeOperation = 'source-over'; parts.forEach(p => p.kind === 'shard' && !p.add && draw(p, t));
    g.globalCompositeOperation = 'lighter'; parts.forEach(p => p.kind === 'shard' && p.add && draw(p, t));
    fx.forEach(f => f.layer === 1 && f.draw(f.t));
    g.globalCompositeOperation = 'source-over';
    if (flash > 0.01) { g.setTransform(1, 0, 0, 1, 0, 0); g.fillStyle = `rgba(${flashRGB},${flash})`; g.fillRect(0, 0, cv.width, cv.height); flash *= Math.exp(-dt * 12); }

    if (attract && clock > nextDemo) demo();
    raf = visible && !document.hidden ? requestAnimationFrame(frame) : 0;
  }
  const run = () => { if (!raf && visible && !document.hidden) { last = performance.now(); raf = requestAnimationFrame(frame); } };

  /* ---------- input ---------- */
  let current = 'storm', userCast = false, attract = !calm.matches, nextDemo = 0.6, demoIndex = 0;
  const order = picks.map(b => b.dataset.fx);
  const groundPoint = (x, y) => ({ x: Math.min(W - 30, Math.max(30, x)), y: Math.min(H - 24, Math.max(floorTop() + 20, y)) });
  const center = () => ({ x: W / 2, y: H * 0.78 });
  function select(name) { current = name; picks.forEach(b => b.setAttribute('aria-pressed', b.dataset.fx === name ? 'true' : 'false')); }
  function cast(name, pt) { FX[name](pt); run(); }
  function demo() { const name = order[demoIndex++ % order.length]; select(name); cast(name, groundPoint(W / 2 + rnd(-W * 0.15, W * 0.15), H * rnd(0.72, 0.84))); nextDemo = clock + 2.8; }
  function takeOver() { if (!userCast) { userCast = true; attract = false; hint.textContent = 'Click anywhere in the arena to cast'; } }

  cv.addEventListener('pointerdown', (e) => { if (e.button > 0) return; takeOver(); const r = cv.getBoundingClientRect(); cast(current, groundPoint(e.clientX - r.left, e.clientY - r.top)); });
  picks.forEach(b => b.addEventListener('click', () => { takeOver(); select(b.dataset.fx); cast(b.dataset.fx, center()); }));
  soundBtn.addEventListener('click', () => { soundOn = !soundOn; soundBtn.setAttribute('aria-pressed', String(soundOn)); soundBtn.textContent = soundOn ? 'Sound on' : 'Sound off'; });

  new IntersectionObserver(([e]) => { visible = e.isIntersecting; if (visible) run(); }).observe(cv);
  document.addEventListener('visibilitychange', run);
  new ResizeObserver(() => { fit(); if (!raf) { g.setTransform(1, 0, 0, 1, 0, 0); g.drawImage(bg, 0, 0); } }).observe(cv);
  select(current);
})();
