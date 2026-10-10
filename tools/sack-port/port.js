// Kick Sack remodel -> BlockBuilder rows. Paste into the browser console on the bundle's
// "Kick Sacks.html" (served locally with a POST /save/<file> endpoint). See README.md.
const THREE = await import('three');
const S = await import('./sacks.js');
const K = 6.5, TAU = Math.PI * 2, DEG = 180 / Math.PI;
const cam = new THREE.PerspectiveCamera();
const C = new THREE.Matrix4().makeRotationY(Math.PI); // the remodel's front (+Z) becomes the game's (-Z)
const I4 = () => new THREE.Matrix4();
const RZ = (a) => new THREE.Matrix4().makeRotationZ(a), RY = (a) => new THREE.Matrix4().makeRotationY(a);
const RZ90 = RZ(Math.PI / 2), RYm90 = RY(-Math.PI / 2);
const r3 = (x) => Math.round(x * 1000) / 1000, r2 = (x) => Math.round(x * 100) / 100;
const FABRIC = /burlap|rope|canvas|cloth|thread|fray|fabric|felt|tassel|patch|wrap/i;
const GLASS = /ice|glass|crystal|frost|gem|bubble|jelly/i;

function matInfo(m) {
  const col = m.color ? m.color.clone() : new THREE.Color(1, 1, 1);
  const op = m.transparent ? (m.opacity ?? 1) : 1;
  let mat = 'SmoothPlastic', hex = col.getHexString();
  const e = m.emissive ? m.emissive : null;
  const eStrength = e ? Math.max(e.r, e.g, e.b) * (m.emissiveIntensity ?? 1) : 0;
  if (m.type === 'MeshBasicMaterial' || eStrength >= 0.45) {
    mat = 'Neon';
    if (e && eStrength >= 0.45 && Math.max(col.r, col.g, col.b) < 0.35) hex = e.getHexString();
  } else if ((m.metalness ?? 0) >= 0.6) mat = 'Metal';
  else if (FABRIC.test(m.name)) mat = 'Fabric';
  else if (GLASS.test(m.name) && op < 0.98) mat = 'Glass';
  return { hex, mat, tr: 1 - op };
}

// One mesh -> parts in the mesh's local space: { Lp (position), LR (rotation), size (metres), shape }.
function elements(geo, Sc, P, axisW) {
  const p = geo.parameters || {}, t = geo.type, out = [];
  const E = (Lp, LR, size, shape) => out.push({ Lp, LR, size, shape });
  const v = (x, y, z) => new THREE.Vector3(x, y, z);
  if (t === 'BoxGeometry') E(v(0, 0, 0), I4(), [p.width, p.height, p.depth], 'B');
  else if (t === 'CylinderGeometry') {
    const r = (p.radiusTop + p.radiusBottom) / 2, tl = p.thetaLength ?? TAU;
    if (tl < 6.2) { // a curved patch: flat tiles along the arc
      const n = Math.max(1, Math.ceil(tl / 0.45));
      for (let i = 0; i < n; i++) {
        const th = p.thetaStart + tl * (i + 0.5) / n;
        E(v(Math.sin(th) * r, 0, Math.cos(th) * r), RY(th), [r * tl / n * 1.06, p.height, 0.008], 'B');
      }
    } else E(v(0, 0, 0), RZ90.clone(), [p.height, 2 * r, 2 * r], 'C');
  } else if (t === 'LatheGeometry') {
    let rmax = 0, y0 = 1e9, y1 = -1e9;
    p.points.forEach((q) => { rmax = Math.max(rmax, q.x); y0 = Math.min(y0, q.y); y1 = Math.max(y1, q.y); });
    E(v(0, (y0 + y1) / 2, 0), RZ90.clone(), [y1 - y0, 2 * rmax, 2 * rmax], 'C');
  } else if (t === 'SphereGeometry') { // Roblox balls are round: flattened spheres become discs
    const s = [Sc.x, Sc.y, Sc.z], smin = Math.min(...s), smax = Math.max(...s);
    if (smin / smax < 0.6) {
      const idx = s.indexOf(smin);
      E(v(0, 0, 0), idx === 0 ? I4() : idx === 1 ? RZ90.clone() : RYm90.clone(), [2 * p.radius, 2 * p.radius, 2 * p.radius], 'C');
    } else E(v(0, 0, 0), I4(), [2 * p.radius, 2 * p.radius, 2 * p.radius], 'S');
  } else if (t === 'TorusGeometry') {
    const R = p.radius, tt = p.tube, sm = Math.max(Sc.x, Sc.y);
    if (Math.abs(axisW.y) > 0.97 && Math.hypot(P.x, P.z) < 0.03 && R * sm >= 0.17) {
      E(v(0, 0, 0), RYm90.clone(), [2 * tt, 2 * (R + tt), 2 * (R + tt)], 'C'); // band around the bag
    } else if (R * K * sm < 0.35) {
      E(v(0, 0, 0), I4(), [2 * (R + tt), 2 * (R + tt), 2 * tt], 'B'); // chain link: a plate
    } else {
      const n = Math.min(28, Math.max(8, Math.round(TAU * R * K * sm / 0.45)));
      for (let i = 0; i < n; i++) {
        const a = TAU * i / n;
        E(v(Math.cos(a) * R, Math.sin(a) * R, 0), RZ(a + Math.PI / 2), [TAU * R / n * 1.15, 2 * tt, 2 * tt], 'B');
      }
    }
  } else if (t === 'ConeGeometry') {
    [0.85, 0.55, 0.25].forEach((f, j) =>
      E(v(0, -p.height / 2 + p.height * (j + 0.5) / 3, 0), RZ90.clone(), [p.height / 3 * 1.02, 2 * p.radius * f, 2 * p.radius * f], 'C'));
  } else if (t === 'OctahedronGeometry') {
    const rot = new THREE.Matrix4().makeRotationFromEuler(new THREE.Euler(Math.PI / 4, 0, Math.PI / 4));
    E(v(0, 0, 0), rot, [p.radius * 1.15, p.radius * 1.15, p.radius * 1.15], 'B');
  } else if (t === 'CapsuleGeometry') {
    const r = p.radius, L = p.height ?? p.length;
    if (r * K < 0.25) E(v(0, 0, 0), RZ90.clone(), [L + 1.4 * r, 2 * r, 2 * r], 'C');
    else {
      E(v(0, 0, 0), RZ90.clone(), [L, 2 * r, 2 * r], 'C');
      E(v(0, L / 2, 0), I4(), [2 * r, 2 * r, 2 * r], 'S');
      E(v(0, -L / 2, 0), I4(), [2 * r, 2 * r, 2 * r], 'S');
    }
  } else if (t === 'ExtrudeGeometry') {
    const o = p.options || {}, depth = (o.depth ?? 0.01) + 2 * (o.bevelEnabled ? (o.bevelThickness ?? 0.002) : 0);
    [].concat(p.shapes).forEach((sh) => {
      const pts = sh.getPoints(), rs = pts.map((q) => Math.hypot(q.x, q.y));
      const rO = Math.max(...rs), rI = Math.min(...rs);
      const star = pts.length >= 10 && rI < rO * 0.7 && rs.every((r) => Math.abs(r - rO) < 1e-3 || Math.abs(r - rI) < 1e-3);
      if (star) {
        pts.forEach((q, i) => {
          const closing = i === pts.length - 1 && Math.abs(q.x - pts[0].x) < 1e-6 && Math.abs(q.y - pts[0].y) < 1e-6;
          if (Math.abs(rs[i] - rO) < 1e-3 && !closing) {
            const f = Math.atan2(q.y, q.x);
            E(v(Math.cos(f) * rO / 2, Math.sin(f) * rO / 2, depth / 2), RZ(f), [rO, rI * 1.15, depth], 'B');
          }
        });
        E(v(0, 0, depth / 2), RYm90.clone(), [depth, 2 * rI * 1.05, 2 * rI * 1.05], 'C');
      } else { // other outlines (the shield): a plate and a pointed tip
        let x0 = 1e9, x1 = -1e9, y0 = 1e9, y1 = -1e9;
        pts.forEach((q) => { x0 = Math.min(x0, q.x); x1 = Math.max(x1, q.x); y0 = Math.min(y0, q.y); y1 = Math.max(y1, q.y); });
        E(v((x0 + x1) / 2, (y0 + y1) / 2 + (y1 - y0) * 0.06, depth / 2), I4(), [(x1 - x0) * 0.95, (y1 - y0) * 0.82, depth], 'B');
        E(v((x0 + x1) / 2, y0 + (y1 - y0) * 0.22, depth / 2), RZ(Math.PI / 4), [(x1 - x0) * 0.5, (x1 - x0) * 0.5, depth * 0.98], 'B');
      }
    });
  } else return null;
  return out;
}

const report = [];
for (let n = 1; n <= 20; n++) {
  const { object } = S.buildTier(n, cam);
  object.updateMatrixWorld(true);
  let hub = 1.16;
  object.traverse((o) => {
    if (o.isMesh && o.name === 'hub_ring') { const w = new THREE.Vector3(); o.getWorldPosition(w); hub = w.y; }
  });
  const rows = [];
  object.traverse((o) => {
    if (!o.isMesh || !o.visible || o.name === 'ceiling_mount') return; // the game draws the chain into the sky
    const P = new THREE.Vector3(), Q = new THREE.Quaternion(), Sc = new THREE.Vector3();
    o.matrixWorld.decompose(P, Q, Sc);
    const RQ = new THREE.Matrix4().makeRotationFromQuaternion(Q);
    const els = elements(o.geometry, Sc, P, new THREE.Vector3(0, 0, 1).applyMatrix4(RQ));
    if (!els) { console.warn('skipped', n, o.name, o.geometry.type); return; }
    const mi = matInfo(Array.isArray(o.material) ? o.material[0] : o.material);
    els.forEach((el) => {
      const wp = el.Lp.clone().multiply(Sc).applyMatrix4(RQ).add(P);
      const cols = [new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3()];
      el.LR.extractBasis(cols[0], cols[1], cols[2]);
      let size = el.size.map((s, i) => s * (Math.abs(cols[i].x) * Sc.x + Math.abs(cols[i].y) * Sc.y + Math.abs(cols[i].z) * Sc.z));
      if (el.shape === 'S') { const m = (size[0] + size[1] + size[2]) / 3; size = [m, m, m]; }
      const R = new THREE.Matrix4().multiplyMatrices(C, new THREE.Matrix4().multiplyMatrices(RQ, el.LR));
      const e = new THREE.Euler().setFromRotationMatrix(R, 'XYZ'); // same order as Roblox CFrame.Angles
      const pr = wp.clone(); pr.y -= hub; pr.applyMatrix4(C).multiplyScalar(K);
      const sz = size.map((s) => r3(Math.max(0.03, s * K))).join(', ');
      rows.push(`\t\t{ "${o.name}", "${el.shape}", { ${sz} }, { ${r3(pr.x)}, ${r3(pr.y)}, ${r3(pr.z)} }, ` +
        `{ ${r2(e.x * DEG)}, ${r2(e.y * DEG)}, ${r2(e.z * DEG)} }, "${mi.hex}", "${mi.mat}", ${r2(mi.tr)} },`);
    });
  });
  const [name, rar] = S.TIERS[n - 1];
  const head = `--!strict\n-- Generated from the Kick Sacks remodel (web/sacks.js): tier ${n} "${name}" (${rar}).\n` +
    `-- 1 m = ${K} studs; origin = the hub where the straps meet; front faces -Z. Do not edit by hand:\n` +
    `-- change the web model and re-run the port. Row: name, shape (B block, C cylinder, S ball), size,\n` +
    `-- position, rotation (degrees, XYZ), colour, material, transparency.\n`;
  const src = `${head}return {\n\thub = ${r3(hub)},\n\tparts = {\n${rows.join('\n')}\n\t},\n}\n`;
  const res = await fetch(`/save/Tier${String(n).padStart(2, '0')}.luau`, { method: 'POST', body: src });
  report.push(`${n}:${rows.length}${res.ok ? '' : '!'}`);
}
console.log(report.join(' '));
