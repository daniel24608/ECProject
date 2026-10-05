# AGENTS.md

Project guide for any coding agent working in this repository.

## Project summary

A **very basic travel planner demo** written in **Jac**. It is the course "personal planning tool" project, themed as a travel planner. It must have four parts that share one backend:

1. **Server**: planning logic and persistent data
2. **Web frontend**: browser UI
3. **Mobile app**: phone UI using the same backend
4. **CLI**: terminal commands using the same backend

This is a simple demo, not the full product. Working end to end beats feature count. All hotel, flight, and activity data is **entered by the user** (web form, mobile form, or CLI). Do not call real external APIs (Expedia, Google Places, Yelp, OpenWeather). No API keys should be needed to run the project.

## Hard rules (read first)

### No AI attribution anywhere

- **No credit to Claude, Anthropic, or any AI tool anywhere in this project.**
- Git commits: no `Co-Authored-By:` trailers, no "Generated with ..." lines, no mention of AI tools in subject or body.
- Do not mention AI tooling in the README, code comments, docstrings, file headers, commit messages, branch names, or any generated file.
- Before the first commit, create `.claude/settings.json` with this content and add `.claude/` and `CLAUDE.md` to `.gitignore`:
  ```json
  {
    "includeCoAuthoredBy": false,
    "attribution": { "commit": "", "pr": "" }
  }
  ```
- Before finishing, run `git log --format=%B | grep -i -E "claude|anthropic|co-authored|generated with"` and `grep -ri -E "claude|anthropic" . --exclude-dir=.git --exclude-dir=.claude --exclude=AGENTS.md`. Both must return nothing. Fix any hit (rewrite history if needed, since the repo is not yet shared).
- Commits are written as plain, human-style messages in imperative mood, for example `Add trip profile model` or `Add CLI add-item command`.

### Keep it simple

- Do not add features that are not listed under "Scope". When unsure, choose the simpler option.
- Never invent Jac syntax. When unsure, check the example workspace (`jac create --awesome`), the Jac docs, and the Day Planner guide. Run the code to confirm.
- Persistence must survive restarts (use the same persistence pattern as the example workspace).

## Scope

### Must have (the demo)

1. **Trip profile intake** (structured form, no LLM required): destination, start date, end date, total budget, contingency percent (default 10), travelers, and hard requirements: traveling with kids (yes/no), traveling with pet (yes/no), dietary needs (free text list), accessibility needs (yes/no).
2. **Manual item entry** for hotels, flights, and activities. Each item has: type, name, city, date, cost, taxes/fees, pet friendly (yes/no/unknown), kid friendly (yes/no/unknown), accessible (yes/no/unknown), refund policy (refundable / partial / non-refundable / unknown), cancellation deadline (optional), and `fixed` flag (traveler wants to keep it).
3. **Budget ledger**: sum of selected items plus taxes/fees, compared with budget minus contingency. Show remaining budget and an over/under status.
4. **Hard-filter validation** (plain code, no LLM): flag any selected item that fails a mandatory requirement (pet, kids, accessibility, dietary). Items with `unknown` eligibility are reported as **unresolved**, never silently accepted.
5. **Rule-based risk flags**: non-refundable item, unknown refund policy, cancellation deadline within 7 days, budget over 90% used. Each flag names the affected item and the reason. Leave unknown refund terms as unknown.
6. **Backup (Plan B) suggestion**: for each flagged item, pick the cheapest other entered item of the same type that passes the hard filters. Show it as a suggestion only (not a booking), with its estimated cost.
7. **Simulated disruption and replan**: user marks an item as disrupted (for example flight cancelled). The system lists downstream items on later dates in the same trip that depend on it, proposes a replacement from the entered options that passes hard filters, and keeps `fixed` items untouched.
8. **Simple comparison**: for each proposed backup or repair, show cash needed now, refund loss (from the refund policy, unknown if unknown), and projected total trip cost. No double counting of the original payment.
9. **Traveler control**: accept or reject a proposal. Reject changes nothing. Accept updates only the stored trip data (simulated).

### Nice to have (only if everything above works)

- A seed command that loads a sample trip so the demo is instant.
- Optional LLM free-text profile parsing behind an off-by-default flag. The app must run fully without it.

### Out of scope

Real booking, real pricing APIs, live monitoring, cross-trip memory, ads or sponsorships, user accounts or passwords.

## Architecture

Put all planning logic in one shared core so the server, web, mobile, and CLI never duplicate logic. Follow the layout of the example workspace. Suggested structure (adjust to match the example):

```
README.md
AGENTS.md
jac.toml
core/        # models + planning logic (budget, validate, risk, backup, replan, compare)
web/         # browser UI
mobile/      # mobile app
cli/         # terminal commands
```

Suggested core modules, one responsibility each:

- `models`: Trip, Profile, Item
- `budget`: ledger totals and remaining budget
- `validate`: hard-filter checks (pass / fail / unresolved)
- `risk`: rule-based risk flags
- `backup`: Plan B suggestions
- `replan`: dependency lookup and repair proposal
- `compare`: cash now, refund loss, projected total

Interfaces:

- **Web**: full workflow: profile form, add items, see ledger, validation, risks, backups, simulate disruption, review and accept or reject.
- **Mobile**: view trip summary, view risks and backups, simulate a disruption, accept or reject a proposal, add a quick item.
- **CLI**: for example `trip init`, `trip add-item`, `trip status`, `trip risks`, `trip disrupt <item>`, `trip accept`, `trip reject`, `trip seed`. Use the CLI pattern from the example workspace.

All three clients talk to the same server and the same stored data.

## Code style

The author is a student who must understand and explain every line. Write code that is easy to read.

- Use explicit, simple code: clear loops and named intermediate variables over clever one-liners and dense comprehensions.
- Descriptive names, for example `remaining_budget`, not `rb`.
- Short functions that do one thing, each with a one or two line comment saying what it does and why.
- Money is stored as numbers in one currency (USD). Round only when displaying.
- Dates use one format (`YYYY-MM-DD`).
- Handle bad input with a clear message rather than crashing (for example a missing trip, a negative cost, or an end date before the start date).

## Testing and verification

- Add a small set of tests for the pure logic in `core/` (budget, validate, risk, backup, replan, compare), following whatever test approach Jac supports. Keep them few and readable.
- Before finishing, from a **fresh clone**, follow the README exactly and confirm:
  1. `jac run` starts the server and web app from the repo root.
  2. The web flow works end to end.
  3. The mobile app connects to the same backend and works.
  4. The CLI commands work against the same server and data.
- Fix problems found. Do not claim something works without running it.

## README requirements (root `README.md`)

Must include:

1. Name and UMID (leave clearly marked placeholders for the author to fill in)
2. Brief description and main features
3. Setup and run instructions with prerequisites and configuration (start with `jac run`)
4. How to launch and use the mobile app and the CLI, including any platform setup
5. Short explanation of how the four components fit together and what makes the project stand out
6. Sample demo walkthrough (seed data, then the disruption and replan flow)

Write the README in the author's voice as a student project. Do not mention AI tools.

## Definition of done

- All four components work against one backend and one data store.
- `jac run` from the repo root starts the web app and server.
- README is complete and verified from a fresh checkout.
- The attribution checks in "No AI attribution anywhere" return nothing.
- Working tree is clean and commits are small, human-style, and readable.
