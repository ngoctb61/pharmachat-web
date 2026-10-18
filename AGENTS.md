# AGENTS.md

Instructions for AI coding agents other than Claude Code (Codex, Cursor, Copilot, Gemini CLI and similar). Claude Code reads `CLAUDE.md` and `.claude/` on its own and does not need this file.

**Read [`CLAUDE.md`](CLAUDE.md) first.** It is the single source of truth for what this repo is, the commands and the rules. This file only adds what Claude Code loads automatically and other agents do not.

## Rules you must load yourself

Claude Code applies these files automatically. Read them before working:

| File                        | When                                                                                             |
| --------------------------- | ------------------------------------------------------------------------------------------------ |
| `.claude/rules/workflow.md` | Always: Jira issue per change, backend dependencies, API contract, scope, branch naming, secrets |

`.claude/skills/*/SKILL.md` describe step-by-step procedures (`start-task`, `review-task`, `fix-review`). Follow the matching one by hand when doing that kind of work. Each task keeps its plan, decisions, summary and reviews in `ticketed/PHA-n/` on its branch; write the plan there and get the user's approval before changing code. `.claude/agents/*.md` describe the three review lenses (architecture, engineering, security).

## Guards that only exist for Claude Code

`.claude/settings.json` and its hooks enforce these for Claude sessions only. Nothing stops you, so follow them yourself:

- Never read, print or commit `.env` files. `VITE_*` variables end up in the public bundle, so they never hold secrets.
- Run `npm run format` (prettier) on files you change; CI fails on unformatted files.
- Do not change code in a task until the user has approved `ticketed/PHA-n/plan.md`.
- Never push to `master` and never force-push. Push a `feat/PHA-n-<scope>`, `fix/PHA-n-<scope>` or `chore/PHA-n-<scope>` branch and open a PR. Branch protection on GitHub also rejects these pushes.

## Business docs and tasks

Specs, the constitution, business decisions B-1..B-6 and tasks live on Atlassian (`pharmachat.atlassian.net`): Confluence space `SD` and Jira project `PHA` (frontend epics F0..F5, issues titled `FE-xx · ...`). Frontend decisions F-1..F-5 are in `docs/FRONTEND_REPO_PLAN.md`. `.mcp.json` registers the Atlassian MCP server (`https://mcp.atlassian.com/v2/mcp`) for Claude Code; configure the same server in your own agent to read them.
