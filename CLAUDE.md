# COURTSIDE — CLAUDE.md (v3 — PRODUCTION FRONTEND)

## Who I am, what we're building

I'm Shrujal. This is **Courtside** — a sports court booking + verified player
stats app for India, built under THE BOX brand.
Positioning: "Playo books you a court. Courtside makes you a player."
Target: Gen Z, Bengaluru. V1 sports: basketball + cricket only.

You are the **lead frontend architect + design systems engineer**.
I am the product owner.

We are building a **production-quality, premium dark sports app** —
not a prototype. Every screen must feel like it belongs on the App Store
featured row.

Emotional target: **Aggressive/Competitive + Premium/Aspirational.**
References: Nike App, Strava, Apple Fitness, ESPN.

---

## How we work together

| Situation | Your response |
|---|---|
| Clear instruction | Execute. No caveats, no alternatives. |
| Vague / open-ended | 2–3 concrete directions + your recommendation + one-line tradeoff. Wait for confirmation before coding. |
| You have a better idea | Propose in one line. Wait for my go. Never silently override. |
| Breaking change | "This will break X because Y. Fix?" — one line only. |
| Need to touch another file | "To make this work I also need to update Z — okay?" |
| Something is broken | Say it directly in the first line. Don't bury it. |

---

## Tech stack

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

**Never add packages without asking first.**

---

## Folder structure

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
│   │   └── theme_extensions.dart  ← AppColorScheme ThemeExtension
│   ├── constants.dart              ← AppRoutes, AppConstants
│   ├── router.dart                 ← GoRouter (ALL routes live here)
│   └── transitions.dart           ← slideUpPage, fadeScalePage, bottomSheetPage
├── models/
│   └── fake_data.dart              ← ALL fake data until Supabase wired
├── providers/
│   └── auth_provider.dart
├── services/
│   └── (future: venue_service, booking_service, etc.)
├── screens/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   ├── sport/
│   │   └── sport_screen.dart
│   ├── venue/
│   │   └── venue_detail_screen.dart
│   ├── booking/
│   │   └── booking_screen.dart
│   ├── bookings/
│   │   └── my_bookings_screen.dart
│   ├── stats/
│   │   └── stats_screen.dart
│   ├── explore/
│   │   └── explore_screen.dart
│   ├── scoring/
│   │   ├── basketball/
│   │   │   ├── basketball_scorer.dart
│   │   │   ├── basketball_setup_screen.dart
│   │   │   ├── basketball_players_screen.dart
│   │   │   ├── basketball_mode_screen.dart
│   │   │   └── models/basketball_models.dart
│   │   └── cricket/
│   │       └── cricket_scorer.dart
│   ├── auth/
│   ├── onboarding/
│   └── splash/
└── widgets/
    ├── common/
    │   ├── app_shell.dart
    │   ├── cs_button.dart          ← primary/secondary/ghost variants
    │   ├── cs_card.dart            ← base card with elevation system
    │   ├── cs_chip.dart            ← filter + sport chips
    │   ├── cs_bottom_sheet.dart    ← standard sheet wrapper
    │   └── cs_shimmer.dart         ← loading skeleton
    └── stat_share/
        ├── stat_share_card.dart
        └── stat_share_preview_screen.dart
```

**Before restructuring folders → ask me first.**
**Before renaming any class or file → ask me first.**

---

## DESIGN TOKEN SYSTEM

This is the most important section. All UI must use semantic tokens.
Never use raw colors or magic numbers anywhere in widget files.

### Architecture

```
Raw hex values (primitives — only in theme files)
        ↓
Semantic tokens (AppColorScheme ThemeExtension)
        ↓
Widget reads: context.colors.backgroundPrimary
```

### How to read tokens in any widget

```dart
final colors = Theme.of(context).extension<AppColorScheme>()!;
final text   = Theme.of(context).extension<AppTextScheme>()!;

Container(
  color: colors.surfacePrimary,
  child: Text('Hello', style: text.headingM.copyWith(color: colors.textPrimary)),
)
```

### Semantic color token names

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
colorAccentSubtle        // tinted background (alpha fill behind accent)

// TEXT — always use all 4 levels
colorTextPrimary         // headings, key values
colorTextSecondary       // supporting labels, captions
colorTextTertiary        // hints, timestamps, disabled
colorTextOnAccent        // text that sits ON the accent color (always white)

// BORDERS
colorBorderSubtle        // card borders, dividers (nearly invisible)
colorBorderMedium        // focused inputs, active containers

// SEMANTIC
colorSuccess             // confirmed bookings, available slots
colorWarning             // scarce slots, streak card
colorError               // cancelled, auth errors
colorInfo                // upcoming bookings, detailed stats mode

// SPORT — only for sport-specific UI elements, never for brand
colorSportBasketball
colorSportCricket
colorSportBadminton
colorSportFootball
```

### Default theme: Void Fire (values for void_fire_theme.dart)

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

### Forbidden in widget files

```dart
// ❌ raw hex
color: const Color(0xFF0F1117)

// ❌ AppColors.* direct (only valid inside theme files)
color: AppColors.surface

// ❌ Material defaults
color: Colors.red, Colors.white, Colors.black

// ❌ deprecated
color: someColor.withOpacity(0.5)  → use .withValues(alpha: 0.5)
```

---

## SPACING + LAYOUT TOKENS

### Spacing scale (8pt grid, 4pt subdivisions)

```dart
class AppSpacing {
  static const double xs      = 4;
  static const double sm      = 8;
  static const double md      = 12;
  static const double lg      = 16;
  static const double xl      = 20;
  static const double xxl     = 24;
  static const double xxxl    = 32;
  static const double section = 40;
}
```

### Radius scale

```dart
class AppRadius {
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double card = 16;
  static const double pill = 100;
}
```

### Duration scale

```dart
class AppDuration {
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 400);
  static const Duration page   = Duration(milliseconds: 320);
}
```

### Shadow system

```dart
class AppShadow {
  static List<BoxShadow> get cardElevated => [
    BoxShadow(color: Color(0xFF000000), blurRadius: 20,
              offset: Offset(0, 8), spreadRadius: -4),
    BoxShadow(color: Color(0x1AE8112D), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static List<BoxShadow> get navBar => [
    BoxShadow(color: Color(0xCC000000), blurRadius: 32, offset: Offset(0, -4)),
  ];
  static List<BoxShadow> get fab => [
    BoxShadow(color: Color(0x99E8112D), blurRadius: 20,
              offset: Offset(0, 4), spreadRadius: -4),
  ];
}
```

---

## TYPOGRAPHY TOKENS

Font families: **SpaceGrotesk** (display, headings, scores) + **Inter** (body, labels).
No other fonts ever.

```dart
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
overline    10px  w700  tracking:1.4  (section headers)

// Scores — SpaceGrotesk, MUST use tabular figures
scoreXXL    72px  w800  tracking:-3.0  FontFeature.tabularFigures()
statXL      42px  w800  tracking:-1.7  FontFeature.tabularFigures()
statL       32px  w800  tracking:-1.0  FontFeature.tabularFigures()
statM       24px  w800  tracking:-0.8  FontFeature.tabularFigures()
```

All score and stat styles must include `fontFeatures: [FontFeature.tabularFigures()]`
— prevents score display from shifting width during live updates.

---

## COMPONENT SYSTEM

Every shared component lives in `lib/widgets/common/`.
If a widget appears in 2+ places → extract it immediately.

### CsButton

```dart
CsButton.primary(label: 'Book Now', onTap: () {})      // accentPrimary bg
CsButton.secondary(label: 'Cancel', onTap: () {})      // surfaceElevated bg
CsButton.ghost(label: 'See all', onTap: () {})         // no bg, no border
CsButton.destructive(label: 'Remove', onTap: () {})    // colorError
CsButton.primary(label: 'Saving...', isLoading: true)  // spinner state
```

Sizes: primary=54px, secondary/ghost=48px. Radius: pill for standalone, lg for inline.
Disabled: 50% opacity. Pressed: scale(0.96) + accentPressed color.

### CsCard

```dart
CsCard(elevation: CardElevation.base,    child: ...)  // surfacePrimary
CsCard(elevation: CardElevation.raised,  child: ...)  // surfaceElevated + shadow
CsCard(elevation: CardElevation.overlay, child: ...)  // surfaceOverlay
```

Always: 0.5px colorBorderSubtle border. Always: AppRadius.card radius.

### CsChip

```dart
CsChip(label: 'Basketball', isActive: true, sport: Sport.basketball)
CsChip(label: 'All', isActive: false)
```

Height: 36–40px. Radius: pill.
Active: accentSubtle bg + accentPrimary border + accentPrimary text.
Sport active: sportColor.withValues(alpha:0.14) bg + sportColor border.
Inactive: surfaceElevated bg + borderSubtle.

---

## COMPONENT SIZE REFERENCE

| Component | Height | Notes |
|---|---|---|
| Primary CTA button | 54px | Full width, pill radius |
| Secondary button | 48px | Variable width |
| Input field | 52px | r=12, surfaceElevated fill |
| Search bar | 46px | r=14, no border |
| Sport chip | 40px | r=pill, px=14 |
| Filter chip | 36px | r=pill, px=12 |
| Nav bar pill | 56px | r=pill, 20px h-margin |
| FAB | 52px | circle |
| Avatar (header) | 42px | circle |
| Icon button | 36–40px | circle container, 44px tap target |
| Court card (h-scroll) | 178×160px | |
| Venue list card | 90px h | 90×90px photo |
| Date cell (booking) | 84×64px | |
| Bottom sheet handle | 36×4px | centered, colorBorderMedium |

Minimum touch target for all interactive elements: **44×44px**.

---

## 5 THINGS THAT SEPARATE PRODUCTION FROM DEVELOPMENT UI

Fix all of these on every screen before considering it done:

### 1. Depth hierarchy
Use all 4 surface levels. Never put adjacent elements on the same surface color.
Background → surface cards → elevated elements → overlay.
This creates the depth that makes dark UIs feel premium, not flat.

### 2. Typography contrast
Use all 4 text levels. Two text colors is amateur.
Primary: headings, key numbers.
Secondary: supporting info.
Tertiary: timestamps, metadata, hints.
OnAccent: text on colored backgrounds.

### 3. Breathing room (deliberate asymmetry)
Premium spacing is NOT uniform. Use:
- More space above section headers than below
- Card internals: 16px sides, 14px top, 12px bottom (not all equal)
- Tighter vertical rhythm inside components than between them

### 4. Invisible borders
0.5px colorBorderSubtle only — barely visible at first glance.
Never 1px+ unless it is an active/focus state.
Elevation and background difference does the heavy lifting.
If removing a border doesn't break legibility → remove it.

### 5. Micro-interactions on everything
Every tap needs physical feedback:
- Buttons: scale(0.97) 80ms ease-in → spring back 120ms
- Cards: scale(0.99) 100ms on press
- Chips: AnimatedContainer 150ms for state change
- Lists: staggered entrance, 30ms delay per item

---

## HARD RULES

### ALWAYS

```dart
// Use withValues — withOpacity is deprecated
color: colors.accentPrimary.withValues(alpha: 0.15)  // ✅
color: AppColors.red.withOpacity(0.15)               // ❌

// GoRouter only
context.push('/venue/$id')    // ✅
Navigator.push(...)           // ❌

// Semantic tokens in widgets
colors.surfacePrimary         // ✅
AppColors.surface             // ❌ (only valid inside theme definition files)
const Color(0xFF0F1117)       // ❌

// Design tokens — no magic numbers
EdgeInsets.all(AppSpacing.lg)     // ✅
EdgeInsets.all(16)                // ❌

// Safe area on all full-screen scaffolds
SizedBox(height: MediaQuery.of(context).padding.top)
SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xl)

// Mounted check before AnimationController
if (!mounted) return;
_controller.forward();

// const everywhere possible
const SizedBox(height: 12)    // ✅

// Tabular figures on all score/stat text
fontFeatures: [FontFeature.tabularFigures()]
```

### NEVER

- `setState` for business logic — only local UI state (tab index, toggle, focus)
- `StatefulWidget` when `ConsumerStatefulWidget` is appropriate
- Business logic inside `build()` methods
- Widget nesting beyond 3 levels without extracting a named class
- `Colors.*` Material defaults in any widget
- Raw `TextStyle(...)` in widgets — always use typography tokens
- One screen importing another screen — always navigate via routes
- `print()` statements left in code
- `withOpacity()` — deprecated
- Packages added without asking first
- Folders restructured without asking first
- Files or classes renamed without asking first
- Rebuilding full screen when only partial state changed — use `select()`

---

## RIVERPOD PATTERNS

```dart
// Simple sync
final myProvider = Provider<T>((ref) => value);

// Async data (FakeData now → swap to Supabase in one pass)
final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  return FakeData.venues;
});

// Mutable game state
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial());
  void update() => state = state.copyWith(...);
}
final myNotifierProvider = StateNotifierProvider<MyNotifier, MyState>(
  (_) => MyNotifier(),
);

// In widget
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final data    = ref.watch(myProvider);
    final notifier = ref.read(myNotifierProvider.notifier);
  }
}

// Avoid full rebuild — use select()
final name = ref.watch(profileProvider.select((p) => p.name));
```

---

## PAGE TRANSITIONS

```dart
// In pageBuilder: in router.dart — never in builder:
slideUpPage(child, key)      // sport, venue, scoring setup screens
fadeScalePage(child, key)    // scoring game screens  
bottomSheetPage(child, key)  // booking sheet, share preview

// Shell routes: NoTransitionPage — instant tab switch
```

---

## ANIMATION STANDARDS

```dart
// Page entrance:       320ms easeOutCubic
// Chip state change:   150ms linear (AnimatedContainer)
// Card press:          scale(0.97) 80ms ease-in → spring back 120ms
// Win rate ring:       400ms easeOutCubic, reset + forward on sport change
// List stagger:        30ms delay per item, fade + slide from y+0.04
// Modal entrance:      280ms easeOutCubic from bottom
// FAB appear:          spring physics, overshoot 1.05 → settle 1.0
// Score number change: no number animation — flash the container border instead
```

Never exceed 300ms for micro-interactions.
Never animate layout properties rapidly during scroll (layout thrashing).

---

## SCREEN STATUS

| Screen | Route | Status |
|---|---|---|
| Splash | / | ✅ custom animation |
| Landing | /landing | ✅ |
| Login | /login | ✅ |
| Phone auth | /phone-auth | ✅ |
| Onboarding | /onboarding | ✅ |
| Home | /home | ✅ Live Now + Map + Chips + Courts + Feed |
| Sport | /sport/:id | ✅ |
| Venue detail | /venue/:id | ✅ |
| Booking | /book/:id | ✅ slot picker |
| My bookings | /bookings | ✅ |
| Stats | /stats | ✅ ring + share |
| Stat share | /stats/share | ✅ |
| Basketball scorer | /score/basketball | ✅ full scorer |
| Cricket scorer | /score/cricket | ✅ |
| Explore | /explore | 🔲 stub |
| Player profile | /player/:id | 🔲 |
| Squad | /squad | 🔲 |
| Pickup create | /pickup/new | 🔲 |

---

## DATA LAYER

All screens use `FakeData` from `lib/models/fake_data.dart`.
This is intentional — full UI first, Supabase in one pass.

Supabase migration (when ready, all at once):
1. Create provider in `lib/providers/`
2. Replace `FakeData.X` calls with `ref.watch(xProvider)`
3. Add loading shimmer + error state to every screen
4. Remove entry from `fake_data.dart`

Do NOT wire Supabase screen by screen. Do it all at once.

---

## THEMING SYSTEM

```
AppColorScheme (ThemeExtension)
    ← VoidFireTheme   (active default — dark premium)
    ← CarbonVoltTheme (future — electric yellow-green)
    ← SportTheme.basketball / .cricket (future — sport-specific)
```

Rules for adding new themes:
- New theme = new file in `lib/core/theme/`
- New theme only changes token values — never widget structure
- Widgets NEVER check which theme is active — they only read tokens
- Runtime switching via `themeModeProvider` (Riverpod NotifierProvider)

---

## PROMPTING GUIDE

### The most effective prompt structure

```
File: [exact filename]
Widget: [exact class or method name]
Current: [what it does / looks like now]
Goal: [what it should do / feel like]
Constraint: [what not to touch]
```

### Patterns that work

**Surgical change:**
> "In home_screen.dart, only change _CourtsNearYouSection.
> Cards feel flat — apply cardElevated shadow and surfaceElevated bg.
> Don't touch anything else."

**Consistency reference:**
> "Build _PickupGameCard using the exact same card structure as
> _CourtCard in home_screen.dart — same shadow, radius, border, padding."

**Feeling-first:**
> "The booking confirmation dialog feels like a form submission.
> Make it feel like a moment that rewards the user.
> You decide the implementation — stay within the token system."

**Plan before large feature:**
> "Read stats_screen.dart. Plan how you'd add a career timeline
> horizontal section below the stat grid.
> Plan only — no code. Tell me: components needed, state needed,
> which existing patterns to reuse."

**Improving without breaking:**
> "The sport chip row works but feels static.
> Make it more alive within the token system. Your call on how."

**Always paste errors — never describe them:**
> Paste full terminal output or VS Code error verbatim.
> Never write "there's a red underline" or "it crashes somewhere."

**Explicit scope:**
> "Only touch basketball_scorer.dart.
> Do not change basketball_models.dart or router.dart."

**When you want options:**
> "Don't code yet — give me 3 directions for [feature],
> your recommendation, and one-line tradeoff for each."

### Prompts for frontend quality upgrades

**Full screen audit:**
> "Audit [screen].dart against the 5 production quality rules in CLAUDE.md.
> List every failure. Then fix them in order:
> surface hierarchy → typography levels → border weight → spacing rhythm → micro-interactions."

**Component extraction:**
> "Find every widget in [screen].dart used in 2+ places or reusable cross-screen.
> List them. Then extract the top 3 into lib/widgets/common/ with correct token usage."

**Animation pass:**
> "Add micro-interactions to [screen].dart:
> 1. Card press feedback (scale 0.97, 80ms)
> 2. List stagger entrance (30ms per item)
> 3. Chip state change (AnimatedContainer 150ms)
> Use AppDuration tokens only."

**Depth pass:**
> "[Screen] feels flat — everything is on the same layer.
> Apply the 4-level surface hierarchy from CLAUDE.md.
> Background → surface cards → elevated elements → overlay.
> Only change background colors and shadows — no layout changes."

**Typography pass:**
> "[Screen] uses only 2 text colors. Apply all 4 levels from the token system.
> Primary for headings and key numbers.
> Secondary for labels and supporting info.
> Tertiary for timestamps, metadata, hints.
> No layout changes — text styles only."

---

## THE PRODUCTION TEST

Every screen must pass this before it is done:

> "Does this look like it was designed by a team at a funded startup,
> or does it look like a Flutter tutorial?"

Signs it is NOT done:
- All text is the same weight and color
- Cards have no depth or shadow  
- Buttons have no tap feedback
- Spacing is uniform everywhere (no intentional asymmetry)
- Animations are plain opacity fades with no staging
- Section headers are plain Text widgets, not designed elements
- The accent color appears on everything instead of sparingly

Signs it IS done:
- Screenshot of any screen looks App Store–ready
- Every tap has a physical response
- Text hierarchy guides the eye without effort
- Dark surfaces have visible depth — multiple distinct layers
- The accent color is used intentionally and sparingly
- It feels like a sports product, not a form-based utility app
- A non-developer looking at it says "this looks real"