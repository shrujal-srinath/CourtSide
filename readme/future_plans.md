# COURTSIDE — FUTURE PLANS

> **AI-context document. Read at the start of every session.**
> This is a living roadmap file, separate from `CLAUDE.md`. `CLAUDE.md` is the
> stable authority on spec, tokens, glossary, and hard rules — never contradict
> it. **This file is where product direction and the roadmap evolve.** When the
> two disagree on *direction* (not rules), this file is newer; flag the conflict
> to Shrujal rather than silently picking one.

---

## HOW TO USE THIS FILE (for Claude)

- Read **Where we are now** first — treat it as ground truth for the app's
  current shape. For deep detail (tokens, components, glossary, rules) defer to
  `CLAUDE.md`; don't duplicate it here.
- When Shrujal discusses a new feature or shift, check **New directions** — if
  it's there, build on the existing entry; if not, propose adding it.
- A direction only belongs in **New directions** if it feeds the core loop
  (discover → book → invite → play → stats → share → return). If it doesn't,
  say so before adding it.
- When a direction is **locked or killed**, append a row to **Decisions log**
  with the date (absolute, e.g. 2026-06-24) and move it out of "under
  consideration."
- Keep entries terse and factual. This file is optimized for fast AI ingestion,
  not for reading like a pitch.

---

## WHERE WE ARE NOW

**What Courtside is:** Playo + Strava for Indian sports — book a court, play the
game, get verified stats, build a player identity. The booking is the gateway;
the verified-stats wedge + player identity are the moat.

**The wedge (why it's defensible):** stats are *verified* — captured via
time-gated phone scoring (unlocks 15 min before a paid booking) or BOX hardware.
No self-entered stats exist in the product, ever. That honesty is the whole
differentiator vs. Playo.

**Core loop:**
`discover → book slot → invite squad → PLAY (scoring) → verified stats → share / profile → come back`
- Playo-layer = discover/book/invite (logistics, table stakes).
- Wedge = the scoring surfaces (the thing Playo can't do).
- Strava-layer = stats/share/profile/return (identity, where polish goes).

**V1 scope:** Gen Z players in Bengaluru. Basketball + cricket only. Courtside =
consumer app; THE BOX = hardware brand surfaced only where hardware is literally
involved.

**Business model:** booking commission + per-game hardware rental (paid by
booker). Not subscription, not ads. User pays at most twice per game.

**Build status (high level — see `CLAUDE.md` §12 for the full table):**
- ✅ Shipped: splash, auth, onboarding, Mode Gate (the landing page), Home,
  Sport, Venue detail, full booking wizard (slot → invite → hardware → cart),
  My Bookings, Stats + Stat Share, basketball scorer, cricket scorer, Play home.
- 🔲 Stub / not built: Host game, Explore, Player profile, Squad, Pickup create.
- **Data layer:** still `FakeData` (`lib/models/fake_data.dart`). Supabase to be
  wired in one pass, not screen-by-screen. (Note: a phone-game → verified-stat
  path via `courtside_games` + `submit_game_result` RPC exists; Stats screen
  still reads FakeData.)

---

## NEW DIRECTIONS UNDER CONSIDERATION

> Entry shape: **Name** — what it is (1–2 lines) · why it serves the core loop ·
> status (`exploring` / `decided` / `parked` / `killed`). Keep it tight.

_(empty — to fill in together)_

---

## IDEA PARKING LOT

> Raw, unfiltered ideas. No commitment, no ordering. Promote to "New directions"
> when one earns a real look.

_(empty)_

---

## DECISIONS LOG

> Append when a direction is locked or killed. Newest at the bottom.

| date | decision | why | impact |
|------|----------|-----|--------|
| | | | |

---

## NEXT UP

> The immediate next moves — the short list of what we're actually doing now.

_(empty)_
