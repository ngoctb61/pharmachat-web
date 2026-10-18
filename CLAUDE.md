# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

React SPA for PharmaChat, an AI sales and support chatbot for a Vietnamese pharma company. Sales staff use the inbox to watch AI conversations and take them over (business decision B-1); admins manage the knowledge base, AI config, Meta connection and users. The Go backend is `ngoctb61/pharmachat-backend`. User-facing strings are Vietnamese without diacritics.

`docs/FRONTEND_REPO_PLAN.md` is the plan: stack, API contract, deployment, tasks FE-00..FE-21 and the settled decisions F-1..F-5. Business docs and SPECs are on Confluence space `SD`; tasks are in Jira project `PHA` (phase epics F0..F5, issues titled `FE-xx · ...`). Branches, commits and PRs reference the `PHA-n` key.

## Commands

Node 24 is required (`.nvmrc`); `jsdom` refuses Node 25.

```bash
npm ci
npm run dev                      # :3000, proxies /api and /ws to PHARMACHAT_API_URL (default http://localhost:8080)
npm run typecheck                # tsc -b
npm run lint                     # eslint + prettier --check
npm test                         # vitest run (jsdom)
npx vitest run src/App.test.tsx  # one file; add -t "<name>" for one test
npm run build
```

CI (`.github/workflows/ci.yml`) runs lint, typecheck, test and build as separate jobs on the Node version in `.nvmrc`.

## Rules

- Dependencies are pinned to exact versions (`.npmrc` sets `save-exact`). Pick versions released at least two weeks ago. TypeScript stays on 6.0.x until `typescript-eslint` supports 7.
- API types and the client will be generated from `contract/openapi.yaml`, a pinned copy of the backend's `api/openapi.yaml` (FE-03). Never hand-write request or response types.
- The access token lives in memory only, never in `localStorage`; the refresh token is an httpOnly cookie set by the backend. WebSocket auth uses a one-time ticket from `POST /api/ws/ticket` (F-5).
- Never log or persist phone numbers, emails, message content or tokens on the client.
- Never push to `master` or force-push; open a PR from `feat/PHA-n-<scope>`, `fix/PHA-n-<scope>` or `chore/PHA-n-<scope>`. The repo is public; branch protection on `master` requires a PR, the four CI checks and an up-to-date branch, and blocks force-pushes.

## Shared Claude Code setup (`.claude/`)

- `rules/workflow.md` always applies: Jira issue per change, backend dependencies, API contract, branches, commits, secrets.
- `skills/`: `/start-task PHA-n` (or `FE-xx`), `/review-task`, `/fix-review`.
- `agents/`: three personas. `aarch` (software architect) writes the plan; `aeng` (principal engineer) is the role the main session takes to implement; `asec` (security engineer). All three review as read-only subagents.
- `settings.json`: allowlists routine npm/git/gh commands and denies reading `.env` files. Hooks run prettier after edits (`hooks/prettier.sh`, a no-op until `npm ci`), block force-pushes and pushes to `master` (`hooks/guard-push.sh`), and gate code edits on plan approval (below).
- Personal overrides go in `.claude/settings.local.json` (gitignored). `.mcp.json` registers the Atlassian MCP server for Jira and Confluence; each person signs in once with `/mcp`.

### Task flow

Each task runs in its own git worktree `.claude/worktrees/PHA-n` (gitignored) on branch `feat/PHA-n-<scope>`, with its own `npm ci`. Its working docs go in `ticketed/PHA-n/` and are committed with the branch: `plan.md`, optional `decision-NN-<slug>.md`, `summary.md`, `review-<YYYYMMDD-HHMM>.md`.

1. `/start-task PHA-n`: creates the worktree, `aarch` writes `plan.md`, the session stops.
2. The user types `approve`. `hooks/plan-approve.sh` writes `ticketed/PHA-n/.approved` (the plan's SHA-256). `hooks/plan-gate.sh` blocks Write/Edit of files outside `ticketed/` in that worktree until then, and again if the plan changes after approval.
3. The session implements as `aeng`, writes `summary.md` and points the user to review.
4. `/review-task`, in the same session or (to keep the implementation context out of it) a new one opened in the worktree: `aarch`, `aeng` and `asec` review the diff in parallel; findings are verified, graded Blocker / Major / Minor / Nit / Question and written to `review-*.md` with a decision box each.
5. The user marks decisions; `/fix-review` in the implement session fixes the ones marked "sửa" and appends to `summary.md`.

A task blocked by an unfinished `GO-xx` issue is built against MSW mocks first and only moves to Done after it has run against the real backend.
