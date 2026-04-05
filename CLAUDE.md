# COURTSIDE — CLAUDE.md

## Who I am, what we're building
I'm Shrujal. This is Courtside — a sports court booking app for India,
built under THE BOX brand. Think Playo meets Strava. Users book courts
AND track their verified athletic stats. Built for Bengaluru initially.

You are the lead engineer. I am the product owner and designer.

---

## How we work together

**Clear direct instruction → execute it.**
No caveats, no alternatives, no "are you sure". Just build it.
Only push back if it would actually break something — in that case,
one sentence: "This will crash because X. Want me to fix it?"

**Vague or "I don't know what I want" → give me options.**
2–3 concrete directions with your recommendation. One line tradeoff each.
Then wait for me to confirm before writing any code.

**Better design idea → show me first.**
You have creative freedom within the dark premium sports theme. If you
see a genuinely better approach than what I described, propose it with
a one-line reason. I'll confirm or reject. Don't silently build something
different from what I asked.

**Touching other files → ask first.**
"To make this work I also need to update router.dart — okay?"

**Something is broken → tell me directly.**
Don't bury it. One clear sentence upfront.

---

## Tech stack

| Layer | Tool | Notes |
|---|---|---|
| Framework | Flutter 3.41.6 + Dart 3.11.4 | Stable channel |
| State | flutter_riverpod ^2.6.1 | StateNotifier for complex state |
| Navigation | go_router ^17.1.0 | context.push / context.go only |
| Backend | supabase_flutter ^2.12.2 | Auth + DB + Realtime |
| Maps | google_maps_flutter | Dark JSON style loaded |
| Location | geolocator ^14.0.2 | GPS for user position |
| Fonts | google_fonts | SpaceGrotesk + Inter ONLY |
| Storage | hive_flutter | Preferences only |

---

## Folder structure

```
lib/
├── core/
│   ├── theme.dart            ← AppColors, AppTextStyles, AppGradients
│   ├── app_spacing.dart      ← AppSpacing, AppRadius, AppDuration, AppShadow
│   ├── constants.dart        ← AppRoutes, AppConstants
│   ├── router.dart           ← GoRouter (all routes live here)
│   └── app_transitions.dart  ← slideUpPage, fadeScalePage, bottomSheetPage
├── models/
│   └── fake_data.dart        ← ALL fake data until Supabase
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── home/                 ← home_screen.dart + widgets/
│   ├── sport/                ← sport_screen.dart
│   ├── venue/                ← venue_detail_screen.dart
│   ├── booking/              ← booking_screen.dart
│   ├── bookings/             ← my_bookings_screen.dart
│   ├── stats/                ← stats_screen.dart
│   ├── explore/              ← explore_screen.dart (stub)
│   ├── scoring/
│   │   ├── basketball/       ← basketball_scorer.dart
│   │   └── cricket/          ← cricket_scorer.dart
│   ├── auth/
│   ├── onboarding/
│   └── splash/
└── widgets/
    ├── common/app_shell.dart
    └── stat_share/stat_share_preview_screen.dart
```

---

## Design tokens — always use these

### Colors (AppColors in theme.dart)
```dart
// Backgrounds — 4-level dark hierarchy
AppColors.black        // 0xFF080A0F  scaffold
AppColors.surface      // 0xFF0F1117  cards
AppColors.surfaceHigh  // 0xFF161B24  elevated cards
AppColors.overlay      // 0xFF1E2535  modals, sheets

// Brand
AppColors.red          // 0xFFE8112D  primary CTA
AppColors.redDark      // 0xFFB50022  pressed state
AppColors.redMuted     // 0xFF3D000A  subtle tint

// Text
AppColors.textPrimaryDark    // 0xFFF8F9FA
AppColors.textSecondaryDark  // 0xFF6B7280
AppColors.textTertiaryDark   // 0xFF374151

// Sport accents
AppColors.basketball   // 0xFFFF6B35
AppColors.cricket      // 0xFF00C9A7
AppColors.badminton    // 0xFFFFC107
AppColors.football     // 0xFF4CAF50

// Semantic
AppColors.success / warning / error / info
```

### Spacing (AppSpacing + AppRadius in app_spacing.dart)
```dart
AppSpacing: xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32
AppRadius: sm=8, md=12, lg=16, xl=20, card=16, pill=100
AppDuration: fast=150ms, normal=250ms, slow=400ms, page=320ms
AppShadow: .cardElevated  .navBar  .fab
```

### Typography (AppTextStyles in theme.dart)
```dart
// Headings — SpaceGrotesk
AppTextStyles.displayXL/L/M/S(color)
AppTextStyles.headingL/M/S(color)

// Body — Inter
AppTextStyles.bodyL/M/S(color)
AppTextStyles.labelM/S(color)
AppTextStyles.overline(color)    // 10px uppercase, 1.4 tracking

// Scores — SpaceGrotesk + tabular figures
AppTextStyles.scoreXXL(color)   // 72px
AppTextStyles.statXL/L/M(color) // 42/32/24px
```

### Page transitions (app_transitions.dart)
```dart
slideUpPage(child, key)      // sport, venue screens
fadeScalePage(child, key)    // scoring screens
bottomSheetPage(child, key)  // booking, share screens
```
Use in `pageBuilder:` in router.dart, not `builder:`.

---

## Hard rules — always

```dart
// ✅ withValues — never withOpacity (deprecated)
color: AppColors.red.withValues(alpha: 0.15)

// ✅ GoRouter — never Navigator
context.push('/venue/$id')
context.go(AppRoutes.home)
context.pop()

// ✅ AppColors constants — never hardcode hex in widgets
AppColors.red                    // ✅
const Color(0xFFE8112D)          // ❌

// ✅ Design tokens — never magic numbers
padding: EdgeInsets.all(AppSpacing.lg)   // ✅
padding: EdgeInsets.all(16)              // ❌

// ✅ Safe area — always on full-screen scaffolds
SizedBox(height: MediaQuery.of(context).padding.top)

// ✅ Bottom padding — always at end of scrollable content
SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.xl)

// ✅ Mounted check — always before AnimationController use
if (!mounted) return;
_controller.forward();

// ✅ const — use everywhere possible
const SizedBox(height: 12)   // ✅
SizedBox(height: 12)         // ❌
```

## Hard rules — never
- `setState` for business logic — only local UI state (tabs, toggles)
- `StatefulWidget` when `ConsumerStatefulWidget` fits better
- Business logic inside `build()` methods
- Widget tree nesting beyond 3 levels without extracting a widget class
- `Colors.*` Material defaults — always `AppColors.*`
- `TextStyle()` directly — always `AppTextStyles.*` or `GoogleFonts.*`
- Importing one screen into another — always navigate via routes
- `print()` statements in code
- Adding packages without asking me first
- Restructuring folders without asking
- Silently renaming classes or files

---

## Riverpod patterns
```dart
// Simple
final myProvider = Provider<T>((ref) => value);

// Async (Supabase later)
final venuesProvider = FutureProvider<List<Venue>>((ref) async {
  return FakeData.venues; // replace with Supabase call
});

// Mutable state
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial());
}
final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (_) => MyNotifier(),
);

// In widget
class MyScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
    final notifier = ref.read(myProvider.notifier);
  }
}
```

---

## Current screen status

| Screen | Route | Status |
|---|---|---|
| Splash | / | ✅ |
| Landing | /landing | ✅ |
| Login | /login | ✅ |
| Phone auth | /phone-auth | ✅ |
| Onboarding | /onboarding | ✅ |
| Home | /home | ✅ Live Now + Map + Chips + Courts + Activity + Promos |
| Sport | /sport/:id | ✅ |
| Venue detail | /venue/:id | ✅ |
| Booking | /book/:id | ✅ slot picker |
| My bookings | /bookings | ✅ |
| Stats | /stats | ✅ profile banner + win ring + share |
| Stat share | /stats/share | ✅ |
| Basketball scorer | /score/basketball | ✅ |
| Cricket scorer | /score/cricket | ✅ |
| Explore | /explore | 🔲 stub |
| Player profile | /player/:id | 🔲 |
| Squad | /squad | 🔲 |
| Pickup create | /pickup/new | 🔲 |

---

## Data layer
All screens use `FakeData` from `lib/models/fake_data.dart`.
This is intentional — full UI first, Supabase in one pass later.

When replacing fake data:
1. Create provider in `lib/providers/`
2. Replace `FakeData.X` with `ref.watch(xProvider)`
3. Add loading + error states
4. Remove entry from `fake_data.dart`

Do NOT wire Supabase screen by screen. Do it all together.

---

## Prompting tips for Shrujal

**Be specific about which file and which widget:**
> "In `sport_screen.dart`, the Book button inside `_VenueCard` goes nowhere.
> Wire it to `context.push(AppRoutes.bookCourt(venue.id))`"

**Reference existing patterns when you want consistency:**
> "Build the PickupGameCard using the same card style as `_CourtCard`
> in `home_screen.dart` — same shadow, radius, structure"

**Scope the change:**
> "Only touch `basketball_scorer.dart`. Don't change anything else."

**When you want ideas, say so explicitly:**
> "I want something on the stats screen that makes people want to share it.
> I don't know what — give me 3 ideas."

**Paste errors, don't describe them:**
Don't type "there's a red error". Paste the full terminal output or
the exact VS Code error message. That's 10x faster.

**Ask for a plan before a big feature:**
> "Before writing code — read home_screen.dart and tell me how you'd
> add a horizontal pickup games section below the map. Plan only, no code."

**For UI feeling, describe the experience not the widgets:**
> "The booking confirmation feels plain. Make it feel like a moment —
> something that feels rewarding. You decide how."

**When something works and you want to improve it:**
> "The sport chip row works but feels flat. Make it feel more alive —
> within the existing theme, your call on how."

