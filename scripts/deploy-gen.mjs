// Bundle site/ into a single Pages _worker.js and emit deploy.js for Cloudflare MCP `execute`.
// Usage: node scripts/deploy-gen.mjs [project] [out]
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, '..');
const site = path.join(root, 'site') + path.sep;
const project = process.argv[2] || 'macos-tcc-preflight';
const out = process.argv[3] || (await import('os')).tmpdir() + '/macos-tcc-preflight-deploy.js';
const ct = {
  html: 'text/html; charset=utf-8',
  css: 'text/css; charset=utf-8',
  js: 'text/javascript; charset=utf-8',
  svg: 'image/svg+xml',
  png: 'image/png',
  jpg: 'image/jpeg',
  md: 'text/markdown; charset=utf-8',
};
const F = {}, R = {};
(function walk(d) {
  for (const n of fs.readdirSync(d)) {
    const p = path.join(d, n);
    if (fs.statSync(p).isDirectory()) {
      walk(p);
      continue;
    }
    let u = '/' + path.relative(site, p).split(path.sep).join('/');
    F[u] = [ct[n.split('.').pop()] || 'application/octet-stream', fs.readFileSync(p).toString('base64')];
    if (n === 'index.html') {
      const dir = u.slice(0, -'index.html'.length);
      F[dir] = F[u];
      if (dir !== '/') R[dir.slice(0, -1)] = dir;
    }
  }
})(site);
const worker = `const F=${JSON.stringify(F)};const R=${JSON.stringify(R)};const C={};function get(p){if(!C[p]){const [t,b]=F[p];const s=atob(b);const u=new Uint8Array(s.length);for(let i=0;i<s.length;i++)u[i]=s.charCodeAt(i);C[p]=[t,u]}return C[p]}
export default{async fetch(req,env){const url=new URL(req.url);const p=url.pathname;if(R[p])return Response.redirect(url.origin+R[p]+url.search,301);if(!F[p])return new Response('not found',{status:404,headers:{'content-type':'text/plain'}});const [t,u]=get(p);return new Response(req.method==='HEAD'?null:u,{headers:{'content-type':t,'content-length':String(u.length),'cache-control':p.endsWith('/')||p.endsWith('.html')?'public, max-age=60':'public, max-age=3600','x-content-type-options':'nosniff'}})}}`;
const code = `async () => {
const name=${JSON.stringify(project)};
let pr=await cloudflare.request({method:'GET',path:\`/accounts/\${accountId}/pages/projects/\${name}\`}).catch(e=>({success:false,err:String(e)}));
let created=false;
if(!pr.success){pr=await cloudflare.request({method:'POST',path:\`/accounts/\${accountId}/pages/projects\`,body:{name,production_branch:'main'}});created=true;if(!pr.success)return {stage:'create',errs:pr.errors}}
const w=${JSON.stringify(worker)};
const b='----macosTccPreflight';
const body=['--'+b,'Content-Disposition: form-data; name="manifest"','','{}','--'+b,'Content-Disposition: form-data; name="branch"','','main','--'+b,'Content-Disposition: form-data; name="_worker.js"; filename="_worker.js"','Content-Type: application/javascript+module','',w,'--'+b+'--',''].join('\\r\\n');
const d=await cloudflare.request({method:'POST',path:\`/accounts/\${accountId}/pages/projects/\${name}/deployments\`,body,contentType:'multipart/form-data; boundary='+b,rawBody:true});
return {created,subdomain:pr.result?.subdomain,ok:d.success,url:d.result?.url,id:d.result?.id,stage:d.result?.latest_stage,errs:d.errors};
}`;
fs.writeFileSync(out, code);
console.log(out, code.length, 'bytes;', Object.keys(F).length, 'routes');
