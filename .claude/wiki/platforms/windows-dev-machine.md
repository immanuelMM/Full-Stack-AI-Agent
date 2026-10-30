# Windows 11 + Git Bash dev machine

- **Low RAM:** run heavy suites (Testcontainers, Playwright, Docker builds) one at a time, never while another agent
  runs its suites; a failure seen only under load is re-run once on a quiet machine before calling it flaky.
- **260-char paths:** clone, build and create worktrees in short temp paths (`$TEMP/<short>`), not the scratchpad.
- **Bash heredocs** with quotes/apostrophes fail ("unexpected EOF") or silently write nothing/truncate: write files with
  the Write/Edit tools; keep scripts in the scratchpad. Check written files exist.
- Editing C# string escapes (`"\n"`) with sed/Python one-liners consumes the backslash: use Edit.
- If Glob/Grep fail with `uv_spawn`, read `<app>/.git/index` for tracked paths, or use `git ls-files`.
- Stop servers by PID or listening port, never by command-line pattern (`*port*` once killed the agent's own shell).
- `core.autocrlf=true`: set Prettier `"endOfLine": "auto"` before `prettier --write` on an existing repo.
- **npm 10 `edgesOut` error** ("Cannot read properties of null (reading 'edgesOut')") when installing test deps:
  commit `.npmrc` with `legacy-peer-deps=true` (and add `@testing-library/dom` explicitly) so local installs and CI
  `npm ci` agree. (IMMAN_HRIS plan prefers fixing peers / Node 22 over hiding conflicts — check the app's choice.)
- Local Node may be 20.x while CI/Docker use 22: don't commit anything that only works on one.
- `gh` is not installed (see [GitHub](github.md)).
- Ports in use by dev databases: 5432 (IMMAN_HRIS), 5433 (cafe-pos), 5434 (beth); pick free ones for new apps and E2E stacks (15xxx).

## Python
- Python from Git Bash reads/writes cp1252 by default: edit scripts touching non-ASCII (`₱`) use
  `io.open(path, encoding='utf-8')`, or they crash halfway with some files already edited.
- `python` is Python 3.12; `python3` is the Microsoft Store stub and fails. Scripts and skills (ui-ux-pro-max) must call `python`.
