// Static preview of a .dc.html board: runs renderVals() with default props, expands sc-for/sc-if/{{holes}}.
// shortcut: no events/dc-import/state; good enough for screenshots, use the real canvas for interaction.
const fs = require('fs');
const [src, out] = process.argv.slice(2);
const html = fs.readFileSync(src, 'utf8');
const tpl = html.match(/<x-dc>([\s\S]*)<\/x-dc>/)[1];
const helmet = (tpl.match(/<helmet>([\s\S]*?)<\/helmet>/) || ['', ''])[1];
const body = tpl.replace(/<helmet>[\s\S]*?<\/helmet>/, '');
const scriptTag = html.match(/<script type="text\/x-dc"[^>]*data-props='([^']*)'[^>]*>([\s\S]*?)<\/script>/);
const decode = (s) => s.replace(/&#39;/g, "'").replace(/&amp;/g, '&');
const propsDecl = JSON.parse(decode(scriptTag[1]));
const props = {};
for (const [k, v] of Object.entries(propsDecl)) if (v && 'default' in v) props[k] = v.default;
class DCLogic { constructor() { this.props = props; this.state = {}; } setState() {} }
const Component = new Function('DCLogic', scriptTag[2] + '\nreturn Component;')(DCLogic);
const vals = new Component().renderVals();

const get = (scope, path) => path.trim().split('.').reduce((o, k) => (o == null ? undefined : o[k]), scope);
const holes = (s, scope) => s.replace(/\{\{\s*([^}]+?)\s*\}\}/g, (_, p) => {
  if (p === 'true' || p === 'false') return p;
  const v = get(scope, p); return v == null ? '' : String(v);
});
// find the matching close tag for a block element starting at idx
function block(s, tag, start) {
  const open = new RegExp(`<${tag}\\b|</${tag}>`, 'g'); open.lastIndex = start + 1; let depth = 1, m;
  while ((m = open.exec(s))) { depth += m[0].startsWith('</') ? -1 : 1; if (!depth) return m.index; }
  throw new Error('unclosed ' + tag);
}
function expand(s, scope) {
  let outStr = '', i = 0;
  const re = /<(sc-for|sc-if)\b([^>]*)>/g; let m;
  while ((m = re.exec(s))) {
    outStr += holes(s.slice(i, m.index), scope);
    const end = block(s, m[1], m.index);
    const inner = s.slice(m.index + m[0].length, end);
    const attr = (n) => (m[2].match(new RegExp(`${n}="\\{\\{\\s*([^}]+?)\\s*\\}\\}"`)) || [])[1];
    if (m[1] === 'sc-for') {
      const as = (m[2].match(/as="([^"]+)"/) || [])[1];
      (get(scope, attr('list')) || []).forEach((it, idx) => { outStr += expand(inner, { ...scope, [as]: it, $index: idx }); });
    } else if (get(scope, attr('value'))) outStr += expand(inner, scope);
    i = end + m[1].length + 3; re.lastIndex = i;
  }
  return outStr + holes(s.slice(i), scope);
}
const imgDir = process.env.IMG_DIR || '';
const page = `<!doctype html><html><head><meta charset="utf-8">${helmet}</head><body style="margin:0">${expand(body, vals)}</body></html>`;
fs.writeFileSync(out, page.replace(/IMG_([a-z0-9_]+)/g, (_, n) => `${imgDir.startsWith('.') ? '' : 'file://'}${imgDir}/${n}.png`));
