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
- Never push to `master` or force-push; open a PR from `feat/PHA-n-<scope>`, `fix/PHA-n-<scope>` or `chore/<scope>`. The repo is public; branch protection on `master` requires a PR and blocks force-pushes.
