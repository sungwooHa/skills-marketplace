#!/usr/bin/env node
// 콘티 HTML → 프레임 PNG → GIF/MP4. 의존성 0 (Node 22+ 내장 WebSocket/fetch + 로컬 Chrome + ffmpeg).
// 사용: node render.mjs <conti.html> [--out <dir>] [--formats gif,mp4] [--gif-width N] [--keep-frames]
import { spawn, spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

// ---- 인자 ----
const args = process.argv.slice(2);
const contiPath = args.find((a) => !a.startsWith('--'));
function flag(name, def) {
  const i = args.indexOf(`--${name}`);
  if (i === -1) return def;
  const v = args[i + 1];
  return v && !v.startsWith('--') ? v : true;
}
if (!contiPath || !fs.existsSync(contiPath)) {
  console.error('사용법: node render.mjs <conti.html> [--out dir] [--formats gif,mp4] [--gif-width N] [--keep-frames]');
  process.exit(1);
}
const outDir = flag('out', path.dirname(path.resolve(contiPath)));
const formats = String(flag('formats', 'gif,mp4')).split(',').map((s) => s.trim());
const gifWidth = flag('gif-width', null);
const keepFrames = args.includes('--keep-frames');
// --split "6,12" : 연속 시뮬레이션을 초 단위 컷 지점에서 잘라 씬별 파일(_p1,_p2,…)로 산출.
// 컷 앞뒤가 연속 프레임이라 씬 간 이음매가 없다 (심리스 장면 전환용).
const splitArg = flag('split', null);

// ---- Chrome 탐색 ----
function findChrome() {
  const cands = [process.env.CHROME_BIN, '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'];
  const pw = path.join(os.homedir(), 'Library/Caches/ms-playwright');
  if (fs.existsSync(pw)) {
    for (const d of fs.readdirSync(pw).filter((n) => n.startsWith('chromium_headless_shell')).sort().reverse()) {
      cands.push(path.join(pw, d, 'chrome-mac', 'headless_shell'));
    }
  }
  const hit = cands.find((p) => p && fs.existsSync(p));
  if (!hit) {
    console.error('Chrome/Chromium 을 찾지 못했습니다. CHROME_BIN 환경변수로 지정하세요.');
    process.exit(1);
  }
  return hit;
}

// ---- CDP 클라이언트 (browser endpoint, flat session) ----
class CDP {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.onmessage = (e) => {
      const m = JSON.parse(typeof e.data === 'string' ? e.data : e.data.toString());
      if (m.id && this.pending.has(m.id)) {
        const { resolve, reject } = this.pending.get(m.id);
        this.pending.delete(m.id);
        m.error ? reject(new Error(m.error.message)) : resolve(m.result);
      }
    };
  }
  send(method, params = {}, sessionId) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    });
  }
}
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  const chrome = findChrome();
  const udd = fs.mkdtempSync(path.join(os.tmpdir(), 'sf-chrome-'));
  const proc = spawn(chrome, [
    '--headless=new', '--remote-debugging-port=0', `--user-data-dir=${udd}`,
    '--no-first-run', '--no-default-browser-check', '--hide-scrollbars', '--mute-audio',
    'about:blank'
  ], { stdio: ['ignore', 'ignore', 'pipe'] });

  const wsUrl = await new Promise((resolve, reject) => {
    let buf = '';
    const to = setTimeout(() => reject(new Error('Chrome DevTools 기동 대기 시간 초과')), 20000);
    proc.stderr.on('data', (d) => {
      buf += d.toString();
      const m = buf.match(/DevTools listening on (ws:\/\/\S+)/);
      if (m) { clearTimeout(to); resolve(m[1]); }
    });
    proc.on('exit', () => reject(new Error('Chrome 이 예기치 않게 종료됨')));
  });

  const ws = new WebSocket(wsUrl);
  await new Promise((r, j) => { ws.onopen = r; ws.onerror = j; });
  const cdp = new CDP(ws);

  const fileUrl = pathToFileURL(path.resolve(contiPath)).href + '#render';
  const { targetId } = await cdp.send('Target.createTarget', { url: fileUrl });
  const { sessionId } = await cdp.send('Target.attachToTarget', { targetId, flatten: true });

  async function evalJs(expr) {
    const r = await cdp.send('Runtime.evaluate', { expression: expr, returnByValue: true }, sessionId);
    if (r.exceptionDetails) throw new Error(`페이지 오류: ${r.exceptionDetails.text} ${r.exceptionDetails.exception?.description || ''}`);
    return r.result.value;
  }

  // 엔진 로드 대기
  let info = null;
  for (let i = 0; i < 50; i++) {
    try {
      info = await evalJs('window.__getRenderInfo ? __getRenderInfo() : null');
      if (info) break;
    } catch { /* 로딩 중 — 재시도 */ }
    await sleep(200);
  }
  if (!info) throw new Error('엔진이 로드되지 않았습니다 (__getRenderInfo 없음). 콘티 HTML 을 확인하세요.');
  console.log(`장면: ${info.name} · ${info.width}×${info.height} · ${info.fps}fps · ${info.duration}s (${info.frames}프레임) · ${info.loop ? 'loop' : 'once'}`);

  // 프레임 캡처
  const framesDir = fs.mkdtempSync(path.join(os.tmpdir(), 'sf-frames-'));
  const t0 = Date.now();
  for (let i = 0; i < info.frames; i++) {
    const dataUrl = await evalJs(`__renderFrame(${i})`);
    fs.writeFileSync(path.join(framesDir, `f_${String(i).padStart(5, '0')}.png`), Buffer.from(dataUrl.slice('data:image/png;base64,'.length), 'base64'));
    if ((i + 1) % 30 === 0 || i === info.frames - 1) {
      console.log(`  프레임 ${i + 1}/${info.frames} (${((Date.now() - t0) / 1000).toFixed(1)}s)`);
    }
  }
  const exited = new Promise((r) => proc.once('exit', r));
  proc.kill();
  await Promise.race([exited, sleep(3000)]);
  fs.rmSync(udd, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });

  // 조립
  fs.mkdirSync(outDir, { recursive: true });
  const loopTag = info.loop ? 'loop' : 'once';
  const outputs = [];
  const pattern = path.join(framesDir, 'f_%05d.png');

  function inputArgs(start, n) {
    const a = ['-framerate', String(info.fps), '-start_number', String(start), '-i', pattern];
    return n != null ? [...a, '-frames:v', String(n)] : a;
  }
  function makeGif(start, n, base) {
    const gw = gifWidth ? parseInt(gifWidth, 10) : info.width;
    const scale = gifWidth ? `scale=${gw}:-1:flags=lanczos,` : '';
    // GIF 전용 경량화: --gif-fps(프레임 솎기) · --gif-colors(팔레트 축소). 렌더 원본에는 영향 없음.
    const gifFps = flag('gif-fps', null);
    const fpsFilter = gifFps ? `fps=${parseInt(gifFps, 10)},` : '';
    const colors = parseInt(flag('gif-colors', '256'), 10);
    // 디더링: bayer(기본, 그라데이션 유리) | none(어두운 배경·점 위주 콘텐츠에서 크기 대폭 절감)
    const dither = flag('gif-dither', 'bayer') === 'none' ? 'none' : 'bayer:bayer_scale=5';
    const gifPath = path.join(outDir, `${base}_${gw}_${loopTag}.gif`);
    run('ffmpeg', ['-y', ...inputArgs(start, n),
      '-filter_complex', `[0:v]${fpsFilter}${scale}split[a][b];[a]palettegen=stats_mode=diff:max_colors=${colors}[p];[b][p]paletteuse=dither=${dither}:diff_mode=rectangle`,
      '-loop', info.loop ? '0' : '-1', gifPath]);
    outputs.push(gifPath);
  }
  function makeMp4(start, n, base) {
    const mp4Path = path.join(outDir, `${base}_master.mp4`);
    run('ffmpeg', ['-y', ...inputArgs(start, n), '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '18', '-movflags', '+faststart', mp4Path]);
    outputs.push(mp4Path);
  }

  const cuts = splitArg
    ? String(splitArg).split(',').map(Number).filter((s) => s > 0 && s < info.duration).sort((a, b) => a - b)
    : [];
  if (cuts.length) {
    const bounds = [0, ...cuts.map((s) => Math.round(s * info.fps)), info.frames];
    for (let si = 0; si + 1 < bounds.length; si++) {
      const base = `${info.name}_p${si + 1}`;
      const start = bounds[si], n = bounds[si + 1] - bounds[si];
      if (formats.includes('gif')) makeGif(start, n, base);
      if (formats.includes('mp4')) makeMp4(start, n, base);
    }
    if (formats.includes('mp4')) makeMp4(0, null, info.name); // 전체 마스터 (이음매 검수용)
  } else {
    if (formats.includes('gif')) makeGif(0, null, info.name);
    if (formats.includes('mp4')) makeMp4(0, null, info.name);
  }
  if (keepFrames || formats.includes('frames')) {
    console.log(`프레임 보존: ${framesDir}`);
  } else {
    fs.rmSync(framesDir, { recursive: true, force: true });
  }

  for (const o of outputs) {
    console.log(`산출: ${o} (${(fs.statSync(o).size / 1024 / 1024).toFixed(2)} MB)`);
  }
  ws.close();
  process.exit(0);
}

function run(cmd, argv) {
  const r = spawnSync(cmd, argv, { stdio: ['ignore', 'ignore', 'pipe'] });
  if (r.status !== 0) {
    console.error(`${cmd} 실패:\n${r.stderr?.toString().slice(-2000)}`);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(`렌더 실패: ${e.message}`);
  process.exit(1);
});
