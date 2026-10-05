# Trip Planner: a travel planner with Plan B and disruption replanning

**Name:** Daniel Hu
**UMID:** 41313424

My personal planning tool is a small travel planner written in [Jac](https://www.jaseci.org/).
You enter your trip and the hotels, flights, and activities you are considering, and the
planner keeps track of the budget, checks your must-have requirements, flags risky bookings,
suggests a Plan B, and repairs the plan when something goes wrong (for example, a cancelled
flight). It has four parts that share one backend: a **server**, a **web app**, a **mobile app**,
and a **CLI**.

This is a demo. Nothing is really booked, and there are no outside APIs or API keys. All
hotel, flight, and activity data is typed in by you (or loaded from the sample trip).

## Features

1. **Trip profile**: destination, dates, total budget, contingency percent (default 10%),
   number of travelers, and hard requirements: kids, pet, accessibility, and dietary needs.
2. **Manual item entry**: hotels, flights, and activities with cost, taxes/fees,
   pet / kid / accessible / dietary flags (`yes` / `no` / `unknown`), refund policy
   (`refundable` / `partial` / `non-refundable` / `unknown`), an optional cancellation
   deadline, and a **fixed** flag ("keep this no matter what"). An item can be part of the
   plan or saved as an **option** for backups to choose from.
3. **Budget ledger**: the contingency is set aside first, then the planned items (plus any
   money already lost to refund rules) are compared with what is left. Shows remaining
   budget, percent used, and an over/under status.
4. **Hard-filter validation**: each planned item gets `pass`, `fail`, or `unresolved`.
   An `unknown` flag is reported as **unresolved**; it is never silently accepted.
5. **Rule-based risk flags**: non-refundable item, unknown refund policy, free cancellation
   ending within 7 days, and budget more than 90% used. Each flag names the item and the reason.
6. **Plan B suggestions**: for every flagged or unresolved item, the planner picks the
   cheapest other entered option of the same type that passes all hard filters.
   A suggestion you reject is not suggested again.
7. **Simulated disruption and replan**: mark a planned item as disrupted. The planner finds
   a replacement, then checks the downstream items (planned items on the same day or later).
   Items that now happen before you arrive get a replacement too. **Fixed items are never
   swapped**; a conflict with a fixed item is reported instead.
8. **Comparison** for every proposal: cash needed now, refund loss (from the old item's
   refund policy, or "unknown"), and the projected trip total. The original payment is
   counted only once.
9. **Traveler control**: accept or reject each proposal. Reject changes nothing. Accept
   updates only the stored trip.
10. **Sample trip**: one command or button loads a ready-made Lisbon trip for a quick demo.

## Prerequisites

- **Jac 0.37** (I used `jac 0.37.23`). Jac is now a single native binary. Install it with:

  ```bash
  curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jac/main/scripts/install.sh | bash
  ```

  This puts `jac` in `~/.local/bin` (add that folder to your `PATH` if needed). Check with `jac --version`.
- **Linux or macOS.** The Jac binary does not support Windows yet. On Windows, use
  **WSL** (Ubuntu) and run every command below inside the WSL terminal. I built and tested
  the project this way, with the repo in my Windows folder (`/mnt/c/...`).
- Note: `pip install jaclang` gives a much older Jac (0.16) that cannot run this project.
- Nothing else. Jac brings its own Python, Bun/Vite, and an embedded Postgres database.
  No API keys or `.env` file are needed.

## Run the server and web app

From the repository root:

```bash
jac run
```

Then open **http://localhost:8000**. The very first start takes a few minutes, because Jac
installs the web dependencies and compiles everything. Later starts are faster.

`jac run` starts the default app (`web`), and the `planner` service app (the server) runs
inside the same process. Data is stored in Jac's embedded Postgres database (under
`~/.cache/jac/pg`), so it survives restarts. To start over, load the sample trip again or
create a new trip; both replace the current one.

## Run the CLI

Keep `jac run` running, and in a second terminal (from the repo root):

```bash
jac run cli -- --help
jac run cli -- seed                     # load the sample Lisbon trip
jac run cli -- status                   # profile, ledger, and items with their checks
jac run cli -- risks                    # risk flags and pending proposals
jac run cli -- disrupt 1                # simulate a disruption on item #1
jac run cli -- accept 4                 # accept proposal #4
jac run cli -- reject 6                 # reject proposal #6 (nothing changes)

jac run cli -- init "Rome, Italy" --start 2026-06-01 --end 2026-06-05 --budget 2000 \
    --kids --diet "vegetarian, nut allergy"
jac run cli -- add-item hotel "Hotel Roma" --date 2026-06-01 --cost 500 --taxes 50 \
    --kid-ok yes --diet-ok yes --refund refundable --deadline 2026-05-20
jac run cli -- add-item hotel "Backup Inn" --date 2026-06-01 --cost 400 \
    --kid-ok yes --diet-ok yes --refund refundable --option
```

Everything after `--` goes to the CLI. Item and proposal numbers are the `#` numbers shown in
the output. By default the CLI talks to `http://localhost:8000/api/planner`; use
`--server URL` (or the `TRIP_SERVER` environment variable) to point it somewhere else.
If the server is not running, the CLI says so instead of crashing.

## Run the mobile app

The mobile app is a React Native (Jac "mobUI") app. It has a trip summary, the proposals
with Accept / Reject, risks, a "Simulate disruption" button on each planned item, and a
quick-add form.

**Easiest: in a browser (no phone needed).** Keep `jac run` running, and in another terminal:

```bash
jac build mobile --platform web       # first time only: compiles the mobile app
jac run --dev --platform web mobile
```

(The build step is needed once on a fresh checkout. Without it, the dev preview shows a
blank page and logs `Failed to resolve import '/mobile/compiled/_entry.js'`.)

Open the `App:` URL it prints (usually **http://localhost:8003** when the web app is already
on 8000). Use a narrow browser window or the browser's phone view. This is the way I tested it.

**On a real phone (optional, not fully tested by me):** `jac run --dev mobile` sets up an
Expo project the first time and shows a QR code to open in the Expo Go app (the phone must be
on the same Wi-Fi). `jac build mobile --platform android` builds an APK, but it needs the
Android SDK (Jac offers to install it).

How it connects: in dev mode, Jac starts a small API process next to the mobile app that runs
the **same planner server code against the same project database**, so the phone shows and
changes the same trip as the web app and the CLI. You can check this: accept a proposal on
the phone, then run `jac run cli -- status`.

## How the four parts fit together

```
            web/ (browser)      mobile/ (phone UI)      cli/ (terminal)
                    \                  |                  /
                     \                 |                 /
                 def:pub calls (Jac turns these into HTTP / bridge calls)
                                       |
                          core/server.jac  (the "planner" service app)
                          stores one Trip node in the database
                                       |
        core/budget  core/validate  core/risk  core/backup  core/replan  core/compare
                       (pure planning logic, plus tests)
```

- `jac.toml` declares four apps: `web` (default), `mobile`, `cli`, and `planner` (a service).
- **All planning logic lives in `core/`**, one small module per job. The clients never
  compute money or rules themselves; they only call the server and show the result.
- **`core/server.jac`** is the only place that reads or writes data. Every endpoint
  (`get_trip`, `init_trip`, `add_item`, `seed_trip`, `disrupt_item`, `accept_proposal`,
  `reject_proposal`) returns the same `TripView` object, so all three clients show exactly
  the same ledger, checks, risks, and proposals.
- In the web and mobile apps, importing a server function and `await`ing it makes an HTTP
  call. In the CLI the same import becomes a "bridge" call to the running server.
- There are no accounts: public (`def:pub`) calls share one guest graph, so there is one trip.

What I think makes it stand out:

- It does more than a to-do list: it **reasons about the plan**. It finds what depends on a
  disrupted booking, repairs only the affected part, and leaves your fixed items alone.
- It is **honest about uncertainty**. Unknown eligibility is "unresolved", and unknown refund
  terms stay "unknown" in the comparison instead of being guessed.
- **Money math avoids double counting**. A swap's projected total removes the old payment
  once and adds back only the part you cannot get refunded.
- One shared core, four clients, one data store, and readable tests for the logic.

## Demo walkthrough (about 3 minutes)

1. Start the server: `jac run`, then open http://localhost:8000.
2. Click **Load sample trip** (or `jac run cli -- seed`). This is a Lisbon trip for 2 people
   with kids and a vegetarian diet, a $4000 budget, and 10% contingency.
   - Ledger: $2160 spent of $3600 usable (60%).
   - Risk flags: the TAP flight is **non-refundable**, the Alfama hotel's free cancellation
     **ends in 3 days**, and the Sintra tour has an **unknown refund policy**. The Sintra tour
     is also **unresolved** because its kid-friendliness is unknown.
   - Three **Plan B** proposals appear, each with cash now, refund loss, and projected total.
     The Sintra backup shows "refund loss unknown".
3. In the itinerary, click **Simulate disruption** on item #1 (the TAP flight), or run
   `jac run cli -- disrupt 1`. The planner proposes:
   - **Repair**: replace the TAP flight with the United flight that arrives the **next day**.
   - **Repair**: the Alfama hotel night is now before you arrive, so swap it for the Baixa
     Budget Inn starting the next day.
   - The **Oceanarium tickets are fixed** and still fit, so they are kept. The replan notes
     explain each decision.
4. **Accept** the flight repair. The flight is swapped, and the ledger now includes the $1220
   lost on the non-refundable ticket. The trip goes over 90% of the budget, so a new
   "budget is 90.3% used" risk flag appears.
5. **Reject** the hotel repair. Nothing changes and the original hotel stays.
6. Open the mobile app (`jac run --dev --platform web mobile`) or run `jac run cli -- status`:
   both show the same updated trip. Add an item from the phone's quick-add form and refresh
   the web page to see it there too.

## Tests

```bash
jac test
```

This runs the tests in `core/*.test.jac` for the budget ledger, validation, risk flags, backup
choice, replanning, the comparison math, and the display helpers. They use plain objects, so
they do not need the server or the database.

## Project layout

```
jac.toml             apps (web, mobile, cli, planner), settings
core/models.jac      Profile, Item, Proposal
core/views.jac       TripView / ProposalView: what every endpoint returns
core/budget.jac      ledger totals and remaining budget
core/validate.jac    hard-filter checks (pass / fail / unresolved)
core/risk.jac        rule-based risk flags
core/backup.jac      Plan B choice
core/replan.jac      downstream items and repair plan
core/compare.jac     cash now, refund loss, projected total
core/format.jac      money / percent text for the clients
core/server.jac      the planner service: storage, endpoints, sample trip
web/                 browser UI (main.jac, components/, styles.css)
mobile/              phone UI (main.jac, TripScreen.jac, theme.jac)
cli/                 terminal commands (main.jac, show.jac)
```

## Known limitations and choices

- One trip at a time and no user accounts (out of scope for this demo).
- "Downstream" means planned items on the same day or later. There is no real dependency
  graph between bookings; that keeps the rule easy to explain.
- Refund loss uses a simple rule: refundable 0%, partial 50%, non-refundable 100%.
- The dietary check uses one "fits dietary needs" flag per item rather than matching
  each diet separately.
- The mobile quick-add form only sets type, name, date, and cost; the eligibility flags
  start as `unknown` (so the item shows up as unresolved). Use the web form or the CLI for
  full details.
- I disabled Jac's automatic native compilation (`[placement] default = "server"` in
  `jac.toml`) because one logic module crashed when compiled natively; as normal server
  code it works fine.
