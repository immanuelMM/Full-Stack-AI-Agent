#!/usr/bin/env node
// Claude Code hook: forwards agent events to the Agent Studio animation server (server.js).
// On the first agent dispatch it starts the server and opens the browser.
// It never blocks Claude: it prints nothing and always exits 0. Set TEAM_VIZ=off to disable.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = Number(process.env.TEAM_VIZ_PORT) || 4747;
const DISPATCH_TOOLS = new Set(['Agent', 'Task']);

if (process.env.TEAM_VIZ === 'off') process.exit(0);
setTimeout(() => process.exit(0), 4500).unref();

let raw = '';
process.stdin.on('data', (d) => (raw += d));
process.stdin.on('end', () => main().catch(() => {}).finally(() => process.exit(0)));

const short = (s, n) => {
  if (!s) return '';
  s = String(s).replace(/\s+/g, ' ').trim();
  return s.length > n ? s.slice(0, n - 1) + '…' : s;
};
const base = (p) => (p ? path.basename(String(p)) : '');

function describe(tool, input) {
  switch (tool) {
    case 'Read': return `Reading ${base(input.file_path)}`;
    case 'Edit': case 'MultiEdit': return `Editing ${base(input.file_path)}`;
    case 'Write': return `Writing ${base(input.file_path)}`;
    case 'NotebookEdit': return `Editing ${base(input.notebook_path)}`;
    case 'Bash': case 'PowerShell': return `Running: ${short(input.description || input.command, 70)}`;
    case 'Grep': return `Searching for "${short(input.pattern, 40)}"`;
    case 'Glob': return `Finding ${short(input.pattern, 50)}`;
    case 'WebSearch': return `Researching "${short(input.query, 60)}"`;
    case 'WebFetch': try { return `Reading ${new URL(input.url).host}`; } catch { return 'Reading a web page'; }
    case 'Agent': case 'Task': return short(input.description || input.prompt, 80);
    case 'Skill': return `Using skill ${input.skill}`;
    case 'TodoWrite': case 'TaskCreate': case 'TaskUpdate': return 'Updating the task list';
    case 'SendMessage': return `Messaging ${input.to || 'a teammate'}`;
    default: return tool || '';
  }
}

// Which app folder (sibling of full-stack-agent/) this event touches, if any.
function detectApp(e) {
  try {
    const workspace = path.dirname(process.env.CLAUDE_PROJECT_DIR || e.cwd || process.cwd());
    const apps = fs.readdirSync(workspace, { withFileTypes: true })
      .filter((d) => d.isDirectory() && d.name !== 'full-stack-agent' && !d.name.startsWith('.'))
      .map((d) => d.name);
    const text = JSON.stringify(e.tool_input || {}) + ' ' + (e.prompt || '') + ' ' + (e.cwd || '');
    return apps.find((a) => text.includes(a)) || '';
  } catch { return ''; }
}

function summarize(e) {
  const input = e.tool_input || {};
  const isFile = ['Read', 'Edit', 'MultiEdit', 'Write'].includes(e.tool_name);
  return {
    t: Date.now(),
    event: e.hook_event_name,
    session: e.session_id,
    agentId: e.agent_id || '',
    agentType: e.agent_type || '',
    tool: e.tool_name || '',
    text: e.tool_name ? describe(e.tool_name, input) : '',
    file: isFile ? base(input.file_path) : '',
    target: DISPATCH_TOOLS.has(e.tool_name) ? input.subagent_type || 'general-purpose' : '',
    background: !!input.run_in_background,
    skill: input.skill || '',
    app: detectApp(e),
    prompt: short(e.prompt, 160),
    message: short(e.last_assistant_message, 160),
    task: short(e.task_subject || e.task_description, 100),
  };
}

function post(evt, timeoutMs) {
  return new Promise((resolve) => {
    const body = JSON.stringify(evt);
    const req = http.request(
      { host: '127.0.0.1', port: PORT, path: '/event', method: 'POST', timeout: timeoutMs,
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) } },
      (res) => { res.resume(); resolve(res.statusCode < 300); });
    req.on('error', () => resolve(false));
    req.on('timeout', () => { req.destroy(); resolve(false); });
    req.end(body);
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  const evt = summarize(JSON.parse(raw || '{}'));
  if (await post(evt, 400)) return;

  // Server not running: only start it (and open the browser) when an agent is dispatched.
  const startsTeam = (evt.event === 'PreToolUse' && evt.target) || evt.event === 'SubagentStart';
  if (!startsTeam) return;
  spawn(process.execPath, [path.join(__dirname, 'server.js'), '--open'],
    { detached: true, stdio: 'ignore', windowsHide: true }).unref();
  for (let i = 0; i < 20; i++) {
    await sleep(150);
    if (await post(evt, 400)) return;
  }
}
