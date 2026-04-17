# COURTSIDE — CLAUDE.md

> **Read this top to bottom before your first response in any new chat.**
> The product sections (1–5) matter more than the rules (6–12).
> If a prompt is ambiguous, fall back on the product principles —
> not on what "a Flutter sports app usually does."

---

## TABLE OF CONTENTS

1. What Courtside is (read this first)
2. Glossary — words that mean specific things here
3. The core loop
4. Product principles (inviolable)
5. Who I am + how I prompt
6. How we work together
7. Tech stack
8. Folder structure
9. Design system — tokens, spacing, typography
10. Component system
11. Hard rules (always / never)
12. Screen status + roadmap

---

# 1. WHAT COURTSIDE IS

## One-sentence version

**Courtside is Playo + Strava for Indian sports — book a court, play the game, get verified stats, build a player identity.**

## The longer version

Every sports booking app in India (Playo, Hudle) stops at the transaction. You book a court, you show up, you play, you leave. The app has no idea what happened in the game. It has no memory of you as a player — only as a customer.

Courtside continues past the booking into the game itself. During the 15-minute window before your slot, phone scoring unlocks. If you're at a BOX-equipped venue, hardware captures stats automatically. Either way, the game produces **verified stats** — authenticated data tied to a real booking at a real venue, which nobody can fake.

Those stats accumulate. Over weeks and months they become **a player profile** — a stats passport. Pickup games you played, points you dropped, hit rates, progression. It's Strava for sports: the data is honest because the app captured it, not you.

## Why this is defensible

Strava only works because GPS exists. No GPS, no Strava — because self-reported running logs are worthless (everyone lies). Playo can't move past booking for the same reason: there's no "GPS equivalent" for a basketball game. Self-reported stats are noise.

**Courtside's GPS equivalent is the combination of time-gated phone scoring + BOX hardware.** The time-gate (scoring only unlocks 15 min before your paid booking) is what makes phone-scored stats honest. The BOX hardware makes them effortless. Together they create verified stats nobody else in the Indian market can produce.

The scoring surfaces are not a feature — they are the **wedge**. Everything else in the app exists to feed users into that wedge and then show them what they produced.

## V1 scope

- Target: Gen Z players in Bengaluru
- Sports: Basketball + Cricket only
- Brand: Courtside is the consumer app. THE BOX is the hardware brand underneath. Relationship between the two is still being figured out — treat Courtside as standalone for now and surface "THE BOX" only where hardware is literally involved (verified-stats badge, hardware rental screen).

---

# 2. GLOSSARY — words that mean specific things here

**Always interpret these words using these definitions.** Most of Claude's worst mistakes on this codebase have been from pattern-matching generic meanings. The real example that triggered this file: Claude was asked to "design the court booking screen that lets the user select the court" and drew a basketball court graphic. "Court" in this product is a bookable sub-unit, not a sport surface.

| Word | Means in Courtside | Does NOT mean |
|---|---|---|
| **Venue** | A physical facility (e.g., "The Box Koramangala"). Has address, photos, amenities, one or more courts. | A single court. |
| **Court** | A bookable sub-unit inside a venue (Court 1, Court 2). Has a surface type, indoor/outdoor flag, price per slot. | A drawing of a basketball court. A sport surface illustration. |
| **Slot** | A time window on a specific court on a specific date (e.g., "Court 1, Oct 20, 6:30–7:15 PM"). Availability is tracked per slot. | A generic time. A calendar. |
| **Booking** | Slot + Court + Venue + payment + (optional) invited players + (optional) hardware rental. The transaction. | The game itself. |
| **Game** | What happens after a booking starts, when people actually play and the app captures stats. Game ≠ Booking — a Booking produces a Game. | Just the booking. |
| **Squad** | The set of people invited to a specific booking. Only the booker has an account and pays. Invitees receive their stats automatically into their own profile after the game. | A persistent named team (not yet — may become this later). |
| **Pickup game** | A booking opened to public — strangers can request to join. Default bookings are private. Edge case, not the norm. | The default game type. |
| **Verified stat** | Any stat captured through Courtside's scoring surfaces — either phone scoring (unlocked 15 min before a paid booking) or BOX hardware. All stats in Courtside are verified. **Self-entered stats do not exist in this product.** | A stat someone typed in. |
| **Stat card** | The shareable post-game artifact (Instagram-ready image). Has score, key stats, verified badge. | A player profile page. |
| **Player profile** | The accumulated stats + history + identity of a user over time. The Strava-layer output. | A login screen. |
| **THE BOX** | The hardware brand + venue-partner brand underneath Courtside. BOX-equipped courts produce automatic stats. Courtside is the consumer app that surfaces BOX data. | A tech term. A literal box icon. |
| **Mode Gate** | A screen that currently appears on every session asking "Play or Explore." **Status unclear — ask Shrujal before making major changes to this screen.** | A permanent design decision. |

If you encounter a word in a prompt that's in this table, default to this meaning. If a prompt conflicts with a definition, ask before proceeding.

---

# 3. THE CORE LOOP

Every feature in Courtside either feeds this loop or it's noise. When deciding whether a feature should exist, ask: does it help the user complete the loop or come back to it?

```
  ┌──────────────────────────────────────────────────────────┐
  │                                                          │
  │   1. DISCOVER a venue/court (Home, Explore, Map)         │
  │                     ↓                                    │
  │   2. BOOK a slot (select date, slot, court, pay)         │
  │                     ↓                                    │
  │   3. INVITE squad (friends auto-receive stats later)     │
  │                     ↓                                    │
  │   4. PLAY the game                                       │
  │      • Phone scoring unlocks 15 min before slot, OR      │
  │      • BOX hardware captures stats automatically         │
  │                     ↓                                    │
  │   5. GET verified stats (game summary + stat card)       │
  │                     ↓                                    │
  │   6. SHARE stat card / update player profile             │
  │                     ↓                                    │
  │   7. COME BACK to book again — now with history          │
  │                                                          │
  └──────────────────────────────────────────────────────────┘
```

## Layer mapping

- **Playo-layer** = steps 1–3 (discover, book, invite). Logistics.
- **Wedge** = step 4 (scoring surfaces). The only thing Playo can't do.
- **Strava-layer** = steps 5–7 (stats, share, profile, return). Identity.

The app's job is to make steps 1–3 frictionless so users get to step 4, and then make steps 5–7 emotionally rewarding so they care about step 7 and come back.

## Business model context

- **Revenue = court booking commission + hardware rental (per-game, paid by booker)**.
- Not subscription, not ads. When designing anything paid-related, remember: the user pays us exactly twice per game — for the slot and (optionally) for the BOX hardware. Everything else is free.

## Competitive frame

- **Main competitor: Playo.** When evaluating whether a feature should exist, ask "does Playo have this, and if not, why not?"
- Playo has booking. That's the floor we have to meet.
- Everything above the booking (stats, profile, squad, share, verified identity) is our differentiation. That's where we invest UI polish and build moats.
- For aesthetic references: Nike, Strava, Apple Fitness, ESPN. For feature references: Playo is the foil.

---

# 4. PRODUCT PRINCIPLES (inviolable)

These are the non-negotiables. If a prompt or idea conflicts with one of these, push back — don't silently follow.

1. **All stats are verified.** There is no "log a game manually" feature. Ever. If we can't capture it through phone scoring or BOX hardware, it doesn't exist. This is the entire wedge — compromising it kills the product.

2. **The booking is the gateway, not the product.** UI should never make booking feel like the destination. Every confirmed booking should nudge toward the scoring/game/stats experience that follows.

3. **Identity compounds.** Every game adds to the user's profile. Stats are additive, permanent, and player-owned. A player's history is their asset.

4. **Invitees are first-class citizens.** Only the booker has the account/pays, but the 4 invited friends all get their stats into their profile automatically. The product experience for a non-paying invitee after the game should be as good as for the booker — that's how they become bookers next time.

5. **Don't compete with WhatsApp for coordination.** Courtside is where you book and where you produce stats. It's not where you chat about the game. No in-app messaging, no reaction threads. Coordination stays in WhatsApp; identity and stats stay here.

6. **Verified is a visual language.** Anywhere stats are shown — stat cards, profile, share images, leaderboards — the "verified" mark is present. It's the brand.

7. **V1 is basketball and cricket. Not badminton, not football.** If a prompt asks for a badminton feature, flag it — it's either scope creep or a miscommunication.

---

# 5. WHO I AM + HOW I PROMPT

## About me (Shrujal)

I'm a student at BMSCE, Bengaluru. I'm the product owner and solo builder of Courtside. **I am not an experienced software developer.** I'm a product person using Claude Code as my engineering and design team.

## How I prompt

- My prompts are often **emotionally phrased** ("this feels flat," "it should pop," "make it feel premium").
- My prompts often use **visual metaphors** ("like Strava's profile page," "like how Nike does it").
- My prompts will be **short and under-specified** — I'm not going to tell you which padding value or font weight to use.
- I'll occasionally mis-use technical terms. When I do, translate my intent; don't quote my words back at me.

## Translate, don't bounce back

Your job is to convert what I mean into what to build. Examples of translation you should do automatically, without asking:

| I say | You do |
|---|---|
| "Make it pop" | Increase contrast, add accent glow, tighten weight hierarchy |
| "It feels cheap / flat / plain" | Check surface hierarchy (all 4 levels?), shadow depth, border weight, text contrast |
| "Make it feel more premium" | Tighten typography, remove unneeded chrome, add a single hero element, breathing room |
| "Like Strava" | Minimal UI chrome, big numbers, strong data viz, earned-not-given tone |
| "Like Nike" | Bold type, aggressive color accents, sharp corners sparingly, energy |
| "Make it cleaner" | Reduce visual elements, increase whitespace, remove decorative borders, stronger hierarchy |

## Ask vs. assume — the exact rule

When a prompt is ambiguous:

**ASK me first** about:
- Product intent (what problem does this solve for the user?)
- User flow (where does this screen sit in the core loop? what's the user's next action?)
- Scope (should this change affect other screens? which ones?)
- Data model (is this a new concept, or a tweak to an existing one?)
- Anything that would change what the screen *does* for the user

**ASSUME and proceed** on:
- Which font weight, padding value, radius, shadow to use — use tokens, match the rest of the app
- Whether to use Row or Column, SingleChildScrollView or CustomScrollView, etc.
- Animation curves and durations — use AppDuration tokens
- Widget composition and internal structure
- Whether to extract a subwidget
- Anything that's purely "how to implement" with no product consequence

When you assume, state the assumption in one line at the top of your response ("Assuming you want X — flag me if that's wrong") and proceed. Don't interrupt the work for implementation details.

## The #9 failure mode — don't repeat this

Real example: I asked for "the court booking screen that lets the user select the court." Claude drew a basketball court graphic with zones and lines. What I meant: a UI for selecting Court 1 vs Court 2 inside a venue — a list, cards, or picker.

**Prevention:** before drawing anything, check the glossary (section 2). If the request touches a glossary term, re-read the definition. If still unsure, ask.

---

# 6. HOW WE WORK TOGETHER

| Situation | Your response |
|---|---|
| Clear instruction on a small change | Execute. No caveats, no alternatives. |
| Clear instruction on a big/new feature | Confirm you understood the product intent in 1 line, then execute. |
| Ambiguous on product intent | Ask 1–2 targeted questions, wait for answer, then build. Do not guess on product. |
| Ambiguous on implementation | State your assumption in 1 line at top of response, then build. |
| You have a better idea | Propose it in 1–2 lines. Wait for my go. Never silently override. |
| Breaking change required | "This will break X because Y — fix?" One line. |
| Need to touch another file | "To do this I also need to update Z — okay?" |
| Something is broken | Say it directly in the first line of your response. Don't bury it. |
| I'm asking for a new feature | First check: does this feed the core loop? If no, flag it and ask before building. |
| I mis-use a technical term | Silently translate my intent. Don't correct me unless the error changes the meaning. |

## Your roles

You wear three hats at once on this project, depending on the ask:

- **Graphic designer** — when I ask for a screen, component, or anything visual. Match the design system. Make it feel App Store–featured.
- **Software engineer** — when I ask for logic, state, data flow, architecture. Keep the Flutter codebase clean. Use Riverpod + GoRouter patterns already established.
- **Idea person / product thinker** — when I ask "what should I do next" or "how should this work." Push back on bad ideas. Suggest better ones. I explicitly want this.

When I'm vague about which hat you should wear, default to the one most needed for the current task — but if I say "brainstorm" or "ideate" or ask "what do you think," I'm asking for the idea-person hat. Go hard in that mode; don't hedge.

---

# 7. TECH STACK

| Layer | Tool | Version |
|---|---|---|
| Framework | Flutter + Dart | 3.41.6 / 3.11.4 stable |
| State | flutter_riverpod | ^2.6.1 |
| Navigation | go_router | ^17.1.0 |
| Backend | supabase_flutter | ^2.12.2 |
| Maps | google_maps_flutter | dark JSON style applied |
| Location | geolocator | ^14.0.2 |
| Fonts | google_fonts | SpaceGrotesk + Inter ONLY |
| Local storage | hive_flutter | preferences only |
| Env | flutter_dotenv | .env in assets, gitignored |
| Payments | razorpay_flutter | integrated in booking checkout |

**Never add packages without asking first.** If you believe a package is needed, propose it in one line with the tradeoff, wait for confirmation.

## Hardware integration

The pi-daemon / ESP32 / Supabase realtime channel setup for BOX hardware is a **separate concern** and **out of scope** for the Flutter app right now. Don't try to integrate it. Don't reference it. If I ask you to wire up hardware, ask me to clarify scope first.

---

# 8. FOLDER STRUCTURE

```
lib/
├── core/
│   ├── tokens/
│   │   ├── color_tokens.dart       ← semantic color tokens
│   │   ├── spacing_tokens.dart     ← AppSpacing, AppRadius, AppDuration, AppShadow
│   │   └── typography_tokens.dart  ← AppTextStyles
│   ├── theme/
│   │   ├── app_theme.dart          ← ThemeData builder
│   │   ├── void_fire_theme.dart    ← default theme values
│   │   └── theme_extensions.dart   ← AppColorScheme ThemeExtension
│   ├── constants.dart              ← AppRoutes, AppConstants
│   ├── router.dart                 ← GoRouter (ALL routes live here)
│   └── transitions.dart            ← slideUpPage, fadeScalePage, bottomSheetPage
├── models/
│   └── fake_data.dart              ← ALL fake data until Supabase wired
├── providers/
│   ├── auth_provider.dart
│   └── booking_flow_provider.dart
├── services/                       ← future: venue_service, booking_service, etc.
├── screens/
│   ├── splash/
│   ├── auth/
│   ├── onboarding/
│   ├── mode_gate/                  ← status: unclear, ask before major changes
│   ├── home/
│   ├── sport/
│   ├── venue/
│   ├── booking/                    ← 4-step wizard lives here
│   ├── bookings/                   ← "my bookings" list
│   ├── stats/
│   ├── explore/
│   ├── play/                       ← Play shell (book-first venue list)
│   └── scoring/
│       ├── basketball/
│       └── cricket/
└── widgets/
    ├── common/                     ← shared Cs* components
    └── stat_share/
```

**Before restructuring folders → ask me first.**
**Before renaming any class or file → ask me first.**

---

# 9. DESIGN SYSTEM

All UI must use semantic tokens. Never use raw colors or magic numbers inside widget files.

## Token architecture

```
Raw hex values (only in theme files)
        ↓
Semantic tokens (AppColorScheme ThemeExtension)
        ↓
Widgets read: context.colors.surfacePrimary
```

## Reading tokens in a widget

```dart
final colors = context.colors;                              // AppColorScheme
final text   = Theme.of(context).extension<AppTextScheme>()!;

Container(
  color: colors.surfacePrimary,
  child: Text('Hello', style: text.headingM.copyWith(color: colors.textPrimary)),
)
```

## Semantic color tokens

Defined as `ThemeExtension<AppColorScheme>` in `lib/core/tokens/color_tokens.dart`:

```dart
// BACKGROUNDS — always use all 4 levels, never skip
colorBackgroundPrimary   // scaffold background
colorSurfacePrimary      // card background
colorSurfaceElevated     // input fills, elevated cards
colorSurfaceOverlay      // modals, bottom sheets

// ACCENT
colorAccentPrimary       // main CTA, active states, brand identity
colorAccentPressed       // tap feedback on accent elements
colorAccentSubtle        // tinted background behind accent elements

// TEXT — always use all 4 levels
colorTextPrimary         // headings, key values
colorTextSecondary       // supporting labels, captions
colorTextTertiary        // hints, timestamps, disabled
colorTextOnAccent        // text on accent-colored backgrounds (always white)

// BORDERS
colorBorderSubtle        // card borders, dividers (nearly invisible)
colorBorderMedium        // focused inputs, active containers

// SEMANTIC
colorSuccess             // confirmed bookings, available slots, verified badge
colorWarning             // scarce slots, streak card
colorError               // cancelled, auth errors
colorInfo                // upcoming bookings, detailed stats mode

// SPORT — only for sport-specific UI, never for brand
colorSportBasketball
colorSportCricket
colorSportBadminton   // defined but not shown in V1
colorSportFootball    // defined but not shown in V1
```

## Default theme — Void Fire

```dart
colorBackgroundPrimary  = Color(0xFF080A0F)
colorSurfacePrimary     = Color(0xFF0F1117)
colorSurfaceElevated    = Color(0xFF161B24)
colorSurfaceOverlay     = Color(0xFF1E2535)

colorAccentPrimary      = Color(0xFFE8112D)
colorAccentPressed      = Color(0xFFB50022)
colorAccentSubtle       = Color(0xFF3D000A)

colorTextPrimary        = Color(0xFFF8F9FA)
colorTextSecondary      = Color(0xFF6B7280)
colorTextTertiary       = Color(0xFF374151)
colorTextOnAccent       = Color(0xFFFFFFFF)

colorBorderSubtle       = Color(0xFF1A2030)
colorBorderMedium       = Color(0xFF2A3040)

colorSuccess            = Color(0xFF22C55E)
colorWarning            = Color(0xFFF59E0B)
colorError              = Color(0xFFEF4444)
colorInfo               = Color(0xFF3B82F6)

colorSportBasketball    = Color(0xFFFF6B35)
colorSportCricket       = Color(0xFF00C9A7)
colorSportBadminton     = Color(0xFFFFC107)
colorSportFootball      = Color(0xFF4CAF50)
```

## Spacing scale (8pt grid, 4pt subdivisions)

```dart
AppSpacing.xs       // 4
AppSpacing.sm       // 8
AppSpacing.md       // 12
AppSpacing.lg       // 16
AppSpacing.xl       // 20
AppSpacing.xxl      // 24
AppSpacing.xxxl     // 32
AppSpacing.section  // 40
```

## Radius scale

```dart
AppRadius.sm    // 8
AppRadius.md    // 12
AppRadius.lg    // 16
AppRadius.xl    // 20
AppRadius.xxl   // 24
AppRadius.card  // 16 (alias)
AppRadius.pill  // 100
```

## Duration scale

```dart
AppDuration.fast    // 150ms
AppDuration.normal  // 250ms
AppDuration.slow    // 400ms
AppDuration.page    // 320ms
```

## Shadow system

```dart
AppShadow.cardElevated  // card with subtle red glow
AppShadow.navBar        // bottom bar lift
AppShadow.fab           // floating action button
```

## Typography

Fonts: **SpaceGrotesk** (display, headings, scores) + **Inter** (body, labels). No other fonts ever.

```
// Display — SpaceGrotesk
displayXL   48px  w700  tracking:-1.9
displayL    36px  w700  tracking:-1.1
displayM    28px  w700  tracking:-0.6
displayS    22px  w600  tracking:-0.2

// Headings — SpaceGrotesk
headingL    18px  w600  tracking:-0.2
headingM    16px  w600  tracking: 0
headingS    14px  w600  tracking:-0.1

// Body — Inter
bodyL       16px  w400  height:1.6
bodyM       14px  w400  height:1.5
bodyS       12px  w400  height:1.4

// Labels — Inter
labelM      11px  w600  tracking:1.1
labelS      10px  w600  tracking:1.0
overline    10px  w700  tracking:1.4

// Scores — SpaceGrotesk, MUST use tabular figures
scoreXXL    72px  w800  tracking:-3.0  FontFeature.tabularFigures()
statXL      42px  w800  tracking:-1.7  FontFeature.tabularFigures()
statL       32px  w800  tracking:-1.0  FontFeature.tabularFigures()
statM       24px  w800  tracking:-0.8  FontFeature.tabularFigures()
```

All score and stat text must include `fontFeatures: [FontFeature.tabularFigures()]`.

## The 5 things that separate production from dev UI

Fix all of these on every screen before considering it done.

### 1. Depth hierarchy
Use all 4 surface levels. Never put adjacent elements on the same surface color.
Background → surface cards → elevated elements → overlay.

### 2. Typography contrast
Use all 4 text levels. Two text colors is amateur.
Primary (headings/numbers) → Secondary (labels) → Tertiary (metadata) → OnAccent (text on colored bg).

### 3. Breathing room with intentional asymmetry
Premium spacing is NOT uniform.
- More space above section headers than below.
- Card internals: 16px sides, 14px top, 12px bottom (not all equal).
- Tighter vertical rhythm inside components than between them.

### 4. Invisible borders
0.5px colorBorderSubtle only. Never 1px+ unless active/focus.
Let elevation do the work. If removing a border doesn't break legibility, remove it.

### 5. Micro-interactions on everything
Every tap has physical feedback.
- Buttons: scale(0.97) 80ms ease-in → spring back 120ms
- Cards: scale(0.99) 100ms on press
- Chips: AnimatedContainer 150ms
- Lists: staggered entrance, 30ms per item

---

# 10. COMPONENT SYSTEM

All shared components live in `lib/widgets/common/`. If a widget appears in 2+ places, extract it.

## Existing shared components — use before building new

| Widget | File | For |
|---|---|---|
| `CsButton` | `widgets/common/cs_button.dart` | All buttons |
| `CsCard` | `widgets/common/cs_card.dart` | All card containers |
| `CsChip` | `widgets/common/cs_chip.dart` | Filters, sport selection, tags |
| `CsShimmer` | `widgets/common/cs_shimmer.dart` | Loading skeletons |
| `CsBottomSheet` | `widgets/common/cs_bottom_sheet.dart` | All bottom sheets |
| `CsEmptyState` | `widgets/common/cs_empty_state.dart` | No-data states |
| `CsErrorState` | `widgets/common/cs_empty_state.dart` | Fetch error states |

## Component heights (use constants, never magic numbers)

| Component | Height | Notes |
|---|---|---|
| Primary CTA button | 54px | Full width, pill radius |
| Secondary button | 48px | Variable width |
| Input field | 52px | r=12, surfaceElevated fill |
| Search bar | 46px | r=14, no border |
| Sport chip | 40px | pill, px=14 |
| Filter chip | 36px | pill, px=12 |
| Nav bar pill | 56px | pill, 20px h-margin |
| FAB | 52px | circle |
| Avatar (header) | 42px | circle |
| Icon button | 36–40px | 44px tap target |
| Court card (h-scroll) | 178×160px | |
| Venue list card | 90px h | 90×90 photo |
| Date cell (booking) | 84×64px | |
| Bottom sheet handle | 36×4px | colorBorderMedium |

**Minimum touch target for all interactive elements: 44×44px.**

Use `AppComponentSizes.*` constants defined in `lib/core/tokens/spacing_tokens.dart`. Don't hardcode values above.

---

# 11. HARD RULES

## ALWAYS

```dart
// withValues — withOpacity is deprecated
color: colors.accentPrimary.withValues(alpha: 0.15)

// GoRouter only
context.push('/venue/$id')

// Semantic tokens in widgets
colors.surfacePrimary

// Design tokens — no magic numbers
EdgeInsets.all(AppSpacing.lg)

// Safe area on full-screen scaffolds
SizedBox(height: MediaQuery.of(context).padding.top)
SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xl)

// Mounted check before AnimationController action
if (!mounted) return;
_controller.forward();

// const everywhere possible
const SizedBox(height: 12)

// Tabular figures on score/stat text
fontFeatures: [FontFeature.tabularFigures()]
```

## NEVER

- `setState` for business logic — only local UI state (tab index, toggle, focus).
- `StatefulWidget` when `ConsumerStatefulWidget` is appropriate.
- Business logic inside `build()` methods.
- Widget nesting beyond 3 levels without extracting a named class.
- `Colors.*` Material defaults in widget files.
- Raw `TextStyle(...)` in widgets — use typography tokens.
- One screen importing another screen — navigate via routes.
- `print()` statements left in code.
- `withOpacity()` — deprecated.
- Packages added without asking first.
- Folders restructured without asking first.
- Files or classes renamed without asking first.
- Full-screen rebuilds when only partial state changed — use `ref.watch(...select(...))`.
- **Self-entered stats** — they violate product principle #1.
- Features for badminton/football in V1.

---

# 12. SCREEN STATUS + ROADMAP

| Screen | Route | Status |
|---|---|---|
| Splash | / | ✅ custom animation |
| Landing | /landing | ✅ |
| Login | /login | ✅ |
| Phone auth | /phone-auth | ✅ |
| Onboarding | /onboarding | ✅ |
| Mode gate | /mode-gate | ✅ built — status unclear, ask before major changes |
| Home | /home | ✅ Live Now + Map + Chips + Courts + Feed |
| Sport | /sport/:id | ✅ |
| Venue detail | /venue/:id | ✅ |
| Booking (slot picker) | /book/:id | ✅ |
| Booking (invite squad) | /book/:id/invite | ✅ |
| Booking (hardware) | /book/:id/hardware | ✅ |
| Booking (cart / checkout) | /book/:id/cart | ✅ |
| My bookings | /bookings | ✅ |
| Stats | /stats | ✅ ring + share |
| Stat share | /stats/share | ✅ |
| Basketball scorer | /score/basketball | ✅ full scorer |
| Cricket scorer | /score/cricket | ✅ |
| Play home | /play | ✅ |
| Host game | /host-game | 🔲 stub |
| Explore | /explore | 🔲 stub |
| Player profile | /player/:id | 🔲 |
| Squad | /squad | 🔲 |
| Pickup create | /pickup/new | 🔲 |

## Data layer

All screens use `FakeData` from `lib/models/fake_data.dart`. Intentional — full UI first, Supabase in one pass.

When we wire Supabase (all at once, not screen-by-screen):
1. Create provider in `lib/providers/`.
2. Replace `FakeData.X` calls with `ref.watch(xProvider)`.
3. Add loading shimmer + error state to every screen.
4. Remove entry from `fake_data.dart`.

---

# APPENDIX — PROMPTING GUIDE (for me, so I remember)

## The shape that works

```
File: [exact filename]
Widget: [exact class/method name]
Current: [what it does now]
Goal: [what it should do / feel like]
Constraint: [what not to touch]
```

## Templates I can reuse

**Surgical change**
> "In [file], only change [widget]. [What's wrong]. [What should happen]. Don't touch anything else."

**Consistency reference**
> "Build [new widget] using the exact same card structure as [existing widget in file X] — same shadow, radius, border, padding."

**Feeling-first**
> "[Thing] feels like [bad feeling]. Make it feel like [good feeling]. You decide the implementation — stay within the token system."

**Plan before building**
> "Read [file]. Plan how you'd add [feature]. Plan only, no code. Tell me: components needed, state needed, which existing patterns to reuse."

**Audit pass**
> "Audit [screen] against the 5 production quality rules in section 9. List every failure. Then fix in order: depth → typography → borders → spacing → micro-interactions."

**Always paste errors verbatim, never describe them.**