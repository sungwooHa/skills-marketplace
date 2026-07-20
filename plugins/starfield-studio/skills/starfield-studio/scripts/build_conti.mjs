#!/usr/bin/env node
// spec JSON → 자립형 콘티 HTML (엔진 템플릿에 spec 주입)
// 사용: node build_conti.mjs <spec.json> [out.html]
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const [specPath, outArg] = process.argv.slice(2);
if (!specPath) {
  console.error('사용법: node build_conti.mjs <spec.json> [out.html]');
  process.exit(1);
}

let spec;
try {
  spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
} catch (e) {
  console.error(`spec 읽기 실패 (${specPath}): ${e.message}`);
  process.exit(1);
}
if (!spec.name) {
  console.error('spec 에 "name" 이 필요합니다 (산출물 파일명의 기준).');
  process.exit(1);
}

const tplPath = fileURLToPath(new URL('../assets/engine_template.html', import.meta.url));
const tpl = fs.readFileSync(tplPath, 'utf8');
const marker = /\/\*__SPEC__\*\/[\s\S]*?\/\*__END_SPEC__\*\//;
if (!marker.test(tpl)) {
  console.error('엔진 템플릿에서 __SPEC__ 마커를 찾지 못했습니다.');
  process.exit(1);
}
const html = tpl.replace(marker, `/*__SPEC__*/${JSON.stringify(spec, null, 2)}/*__END_SPEC__*/`);

const out = outArg || path.join(path.dirname(specPath), `${spec.name}.conti.html`);
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, html);
console.log(`콘티 생성: ${out}`);
console.log(`브라우저 확인: open "${out}"`);
