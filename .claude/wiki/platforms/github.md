# GitHub

- Owner account `immanuelMM`; repos: `immanuelMM/Cafe_POs` (cafe-pos-system), `immanuelMM/IMMAN_HRIS`
  (`git@github.com:immanuelMM/IMMAN_HRIS.git`). beth-online-shop has no remote yet (2026-10-30).
- **The user's SSH key is rejected for this machine's agents:** the user runs git network commands (`push`, `fetch`,
  PR merges) themselves — ask them, e.g. `! git -C ../<app> push -u origin <branch>`.
- Always ask before push, force-push or history rewrites.
- `gh` is not installed: look up action versions with
  `curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest`.
- `/security-review` needs an `origin` remote; without one run a read-only review agent over `git diff <base>..HEAD`.
- Push early once a remote exists so CI runs on GitHub; anything a platform reads from the repo (`render.yaml`) must be
  pushed before dashboard steps. See [CI](../features/github-actions-ci.md).
