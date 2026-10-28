#!/usr/bin/env node
// Agent Studio server: receives hook events (POST /event) and streams them to the browser (GET /events, SSE).
// Run manually with `node .claude/team-viz/server.js --open`; hook.js starts it automatically.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = Number(process.env.TEAM_VIZ_PORT) || 4747;
const URL = `http://localhost:${PORT}/`;
const OPEN = process.argv.includes('--open');
const IDLE_EXIT_MS = 3 * 60 * 60 * 1000; // stop after 3h with no events and no open page
const MAX_HISTORY = 1000;

const history = [];
const clients = new Set();
let lastActivity = Date.now();
let lastOpened = OPEN ? Date.now() : 0;

function openBrowser() {
  const [cmd, args] =
    process.platform === 'win32' ? ['rundll32', ['url.dll,FileProtocolHandler', URL]]
    : process.platform === 'darwin' ? ['open', [URL]]
    : ['xdg-open', [URL]];
  spawn(cmd, args, { detached: true, stdio: 'ignore', windowsHide: true }).unref();
}

function broadcast(evt) {
  const line = `data: ${JSON.stringify(evt)}\n\n`;
  for (const res of clients) res.write(line);
}

const server = http.createServer((req, res) => {
  const url = req.url.split('?')[0];

  if (req.method === 'GET' && (url === '/' || url === '/index.html')) {
    fs.readFile(path.join(__dirname, 'index.html'), (err, html) => {
      if (err) { res.writeHead(500); return res.end('index.html missing'); }
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' });
      res.end(html);
    });
    return;
  }

  if (req.method === 'GET' && url === '/events') {
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
    res.write('retry: 2000\n\n');
    for (const evt of history) res.write(`data: ${JSON.stringify({ ...evt, replay: true })}\n\n`);
    clients.add(res);
    req.on('close', () => clients.delete(res));
    return;
  }

  if (req.method === 'POST' && (url === '/event' || url === '/reset')) {
    let body = '';
    req.on('data', (d) => { body += d; if (body.length > 65536) req.destroy(); });
    req.on('end', () => {
      lastActivity = Date.now();
      if (url === '/reset') {
        history.length = 0;
        broadcast({ event: 'Reset', t: Date.now() });
      } else {
        try {
          const evt = JSON.parse(body);
          history.push(evt);
          if (history.length > MAX_HISTORY) history.splice(0, history.length - MAX_HISTORY);
          broadcast(evt);
          // An agent was dispatched but no page is watching — open one (at most every 30s).
          const dispatched = (evt.event === 'PreToolUse' && evt.target) || evt.event === 'SubagentStart';
          if (dispatched && clients.size === 0 && Date.now() - lastOpened > 30000) {
            lastOpened = Date.now();
            openBrowser();
          }
        } catch { res.writeHead(400); return res.end(); }
      }
      res.writeHead(204);
      res.end();
    });
    return;
  }

  if (req.method === 'GET' && url === '/health') { res.writeHead(200); return res.end('ok'); }
  res.writeHead(404);
  res.end();
});

server.on('error', (err) => {
  // Already running (e.g. started by another hook call) — just open the page if asked.
  if (err.code === 'EADDRINUSE') { if (OPEN) openBrowser(); process.exit(0); }
  throw err;
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Agent Studio running at ${URL}`);
  if (OPEN) openBrowser();
});

setInterval(() => {
  for (const res of clients) res.write(': ping\n\n');
  if (clients.size === 0 && Date.now() - lastActivity > IDLE_EXIT_MS) process.exit(0);
}, 20000);
