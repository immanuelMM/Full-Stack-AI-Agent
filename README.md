# Full Stack Agent

Claude Code subagents and agent-team settings for building web apps. Each app
lives in its own sibling folder next to this one (e.g. `../cafe-pos-system/`).

```
Agentic-fullstack-web-dev/
├── full-stack-agent/    ← this folder (agents + Claude settings only)
│   ├── CLAUDE.md        workflow, default tech stack, git + secrets rules
│   ├── .claude/agents/  research-planner, frontend-react-dev, backend-dotnet-dev,
│   │                    qa-automation, docs-writer, devops-engineer
│   ├── .claude/skills/  react-frontend-standards (backend uses ~/.claude/skills/dotnet-backend-standards)
│   ├── .claude/hooks/   verify-app.sh — build/lint quality gate when an agent finishes
│   ├── .claude/team-viz/ Agent Studio — live browser animation of the agents at work
│   ├── .claude/settings.json
│   └── docs/agent-teams.md
├── cafe-pos-system/     ← full stack app (backend/, frontend/, docs/, docs/plan/)
└── <new-app>/           ← every future app gets its own folder here
```

## Starting a new app

Run `research-planner` first. It always needs two answers:

1. What is the name of the app? (the folder name is the app name in lowercase-kebab-case)
2. Is this a static website or a full stack web app?

- **Full stack web app:** `<app>/backend/` (.NET 8 API), `<app>/frontend/` (React), `<app>/docs/`
- **Static website:** `<app>/site/`, `<app>/docs/` (no backend)

The plan is saved to `<app>/docs/plan/`. The other agents read it from there,
and every prompt to them must name the app they are working on. Each app is its
own git repo. See `CLAUDE.md` for the full workflow and default tech stack.

## Usage

Start Claude Code from this folder so the agents are picked up:

```
cd full-stack-agent
claude
```

`.claude/settings.json` adds `..` as a working directory, so the agents can read
and edit every app folder from here. See `docs/agent-teams.md` for running them
as an agent team.

## Agent Studio (live animation)

The first time an agent is dispatched in a session, a hook starts a small local
server and opens <http://localhost:4747> in your browser. The page shows the Lead
(Claude) handing tasks to each agent, what each agent is doing right now, the
Plan → Build → Test → Review → Docs → Deploy pipeline, and a live activity feed.

- Watch a sample run: <http://localhost:4747/?demo> (or press **Play demo**).
- Start it by hand: `node .claude/team-viz/server.js --open`
- Turn it off: set the environment variable `TEAM_VIZ=off`.
- Different port: set `TEAM_VIZ_PORT`.

It only listens on `127.0.0.1` and stops itself after 3 hours with no activity.
