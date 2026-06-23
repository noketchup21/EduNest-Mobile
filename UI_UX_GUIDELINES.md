# EduNest UI/UX Guidelines

This is the living design and redesign reference for the EduNest mobile app. Use it when adding a screen, changing a flow, reviewing UI, or asking an AI coding tool such as Codex to redesign the app.

EduNest is not only an education app. It is a **trust-based tutoring marketplace** where parents/students compare tutors, book lessons, pay safely, communicate inside the platform, and follow learning progress. Tutors use the app to manage availability, lessons, materials, homework, attendance, wallet, reports, and payouts. Administrators use the app to verify quality, manage payouts, review reports, and keep the platform trustworthy.

The UI should feel:

- **Energetic but focused** — engaging enough to hold a student's attention, calm enough for a parent to trust
- **Visually breathing** — generous whitespace, clear hierarchy, nothing crammed
- **Scannable in 3 seconds** — the user's eye should land on the right thing immediately
- **Warm and distinctive** — not a generic blue corporate app
- **Modern** — rounded, layered, with color that has purpose
- **Mobile-first** — narrow phones, Vietnamese strings, text scaling
- **Suitable for parents, students, tutors, and admins**

This document should guide both human developers and AI coding agents. It should be followed before making any broad UI/UX overhaul.

---

## 1. Product and design intent

### 1.1 Product summary

EduNest helps:

- **Parents/students** find suitable tutors, book lessons, pay, communicate, submit homework, access materials, and track learning progress.
- **Tutors** create availability/courses, manage lessons, mark attendance, share materials, create homework, report progress, manage wallet balance, and request payouts.
- **Admins** manage users, tutor verification, bookings, payments, payouts, reports, and platform trust.

The product experience should balance two things:

1. **Marketplace conversion**: make it easy to discover tutors and book lessons.
2. **Education trust**: make parents feel safe and make tutors feel the platform is professional.

### 1.2 Core design principles

- **Make the next action obvious.** A user should never need to infer how to book, create availability, submit a document, mark attendance, request payout, or continue a lesson.
- **Prioritize trust before conversion.** Show tutor identity, verification, rating, price, schedule, refund/payment status, and lesson outcome before users confirm important actions.
- **Use marketplace clarity.** Tutor cards, tutor profiles, filters, sorting, booking details, and payment screens should be easy to compare and scan.
- **Prefer short, plain language.** Explain education terms and system statuses rather than using internal jargon.
- **Use progressive disclosure.** Show essential information first; keep advanced fields, rare actions, and destructive actions behind dialogs, bottom sheets, or detail screens.
- **Design for mobile first.** Support narrow Android phones, large phones, tablets, Vietnamese strings, and text scaling.
- **Preserve business logic.** UI redesign should not break API calls, auth state, routing, role protection, payment flow, or existing backend contracts.
- **Avoid decorative redesigns.** A redesign is successful only if users complete key tasks faster and with fewer mistakes.
- **Never overwhelm the user.** Each screen must answer one primary question.
  Show three to five pieces of information per card maximum. Use progressive
  disclosure — a summary card tapped opens a detail screen, not an expanded
  wall of text inline. If a list item needs more than two lines of text,
  move the overflow to a detail route.
- **Lead with visuals and status, not text.** An icon, a colored badge, and
  one bold label communicates faster than a paragraph. Replace text-heavy
  descriptions with icon + chip + short label wherever possible.
- **Use whitespace as a design element.** Crowded screens feel untrustworthy.
  Generous padding (20–24 on cards, 16–20 between sections) makes the app
  feel premium and easy to read.

### 1.3 Primary user jobs

#### Parent/student jobs

- Find a tutor for a subject or learning goal.
- Compare tutors by trust, subject, price, rating, teaching mode, and schedule.
- Book a lesson or course with confidence.
- Pay and understand payment status.
- View upcoming lessons.
- Chat with the tutor safely inside the app.
- Access homework/materials.
- Track learning progress and reports.

#### Tutor jobs

- Set up profile and verification.
- Create availability/course slots.
- Manage upcoming lessons.
- Mark attendance.
- Share materials and homework.
- Send reports or progress notes.
- Track wallet balance and payout status.
- Respond to parent/student messages.

#### Admin jobs

- Review tutor verification and evidence.
- Monitor bookings, payments, reports, users, and payouts.
- Approve/reject payouts with auditable context.
- Resolve reports and suspicious activity.
- Keep the marketplace trustworthy.

---

## 2. Reference products and UX inspiration

Use these products as **visual and UX pattern inspiration only**. Do not copy
layouts exactly, do not copy brand assets, and do not clone unique screens.
For each reference, only the listed patterns are relevant — ignore everything else.

---

### 2.1 Color, visual energy, and UI style references

These products share the indigo/violet + warm accent + emerald success palette
direction described in Section 5.1. Use them to understand how to make color
feel purposeful rather than decorative.

**Brilliant.org** — `brilliant.org`
- Deep indigo/navy background with vibrant orange accent CTAs.
- Cards that feel layered: dark surface, white text, colored icon containers.
- Progress indicators that feel rewarding, not clinical.
- Apply to: course hub header, lesson progress bar, metric cards.

**Linear.app** — `linear.app`
- Indigo primary with very clean whitespace. Status badges that are small,
  pill-shaped, and never noisy.
- Section headers with subtle icon + label. No visual clutter.
- Apply to: status badges, section headers, list item density, admin screens.

**Duolingo** — `duolingo.com`
- Vibrant greens, purples, and oranges used with clear semantic purpose.
- Every color means something: green = success/streak, orange = warning/pending.
- Large rounded buttons with subtle shadow. Never flat ghost buttons for primary CTAs.
- Friendly empty states with illustration + action. Never a blank list.
- Apply to: primary buttons, status colors, empty states, homework urgency badges.

**Notion** — `notion.so`
- Soft off-white/lavender scaffold with white cards floating above it.
- Section headers with small emoji or icon in a subtle container.
- Generous vertical spacing between sections (20–28 dp).
- Almost no hard dividers — breathing room does the separation instead.
- Apply to: scaffold background, card surfaces, section spacing, content grouping.

---

### 2.2 Course hub and learning screen references

These products handle the lesson + homework + materials screen pattern. Use them
to understand how to organize course content without overwhelming the user.

**Udemy** — `udemy.com` (mobile app, course player screen)
- Course screen uses tabs: Overview / Q&A / Announcements / Reviews.
- Lesson list grouped by section, with completion checkmark per lesson.
- Material type shown with a file icon (PDF → red, video → dark, link → blue).
- Collapsed sections by default — user expands what they need.
- Apply to: course hub tab structure, lesson grouping, materials file icons,
  collapsed past-lessons pattern.

**Coursera** — `coursera.org` (mobile app, course detail screen)
- Week-by-week or module grouping for lessons. Progress ring in header.
- Deadline shown with urgency (red if late, amber if soon).
- Clear "Resume" or "Start" CTA as the first visible action on the screen.
- Simple card: lesson title + duration + completion status. Nothing else.
- Apply to: lesson card design, progress header, deadline urgency, module grouping.

**Google Classroom** — `classroom.google.com` (mobile)
- Homework grouped into "Assigned", "Missing", "Done" — no flat chronological list.
- Assignment card: title + due date + class name. Three fields maximum.
- Status color is a small dot or label, never a large colored background.
- Materials organized into "Topics" the teacher creates, not a flat file dump.
- Apply to: homework tab grouping, assignment card simplicity, materials by topic.

**Khan Academy** — `khanacademy.org` (mobile)
- Mastery/progress shown as a ring or bar on the course card — visible immediately.
- Content organized into Units → Lessons → Exercises. No overloading one screen.
- Friendly, short labels: "Watch", "Practice", "Review" — not "Submit assignment
  for lesson ID 00423".
- Parent dashboard is separate from the student view and shows summary only.
- Apply to: progress visualization, label language, parent vs student view priority.

**Brilliant.org** — `brilliant.org` (mobile course screen)
- Each lesson is one card. Card shows: title, estimated time, locked/unlocked state.
- Lesson list is a clean vertical stack — no metadata beyond what is needed.
- Completed lessons get a checkmark and fade slightly — draws attention to the next one.
- Apply to: lesson card simplicity, completion state, attention direction to next lesson.

---

### 2.3 Tutor marketplace and booking references

Use these for tutor discovery, profile trust, booking flow, and payment status.

**Preply** — `preply.com` (mobile)
- Tutor card: avatar + name + flag + rating + price + subject + short bio line.
  Everything visible in one card, no tap needed to compare.
- Filters are a horizontal scrollable chip rail, always visible above the list.
- Tutor profile: sticky bottom bar with price + "Book trial" button. Never buried.
- Apply to: tutor card layout, filter chip rail, sticky booking CTA.

**AmazingTalker** — `amazingtalker.com` (mobile)
- Large avatar with a verified badge overlay. Trust is visual, not just text.
- Teaching style shown as short chips (Patient / Structured / Conversational).
- Price shown prominently in a colored pill — never hidden or small.
- Apply to: tutor avatar with badge overlay, teaching style chips, price prominence.

**Cambly** — `cambly.com` (mobile)
- Tutor discovery uses a card with a large photo, name, country flag, rating.
- "Book" button is always coral/orange — consistent accent color for conversion CTA.
- Lesson history screen is a simple date-grouped list. No clutter.
- Apply to: photo-forward tutor card, accent color on book CTA, lesson history layout.

**Outschool** — `outschool.com`
- Class cards show: class photo, title, teacher name, age range, price, schedule.
  All trust-relevant. Parent can decide without opening the class.
- "Enroll" button is large and sticky at the bottom of every class detail page.
- Parent-side dashboard separates "Upcoming classes" from "Past classes" clearly.
- Apply to: parent-friendly class/booking cards, sticky enroll CTA, upcoming vs past.

---

### 2.4 Payment and status transparency references

**Grab** — `grab.com` (mobile app)
- Ride/order status is communicated through a timeline: Confirmed → In progress →
  Done. User always knows where they are.
- Payment amount shown large and bold. No ambiguity.
- Receipt screen is clean: item, amount, payment method, timestamp. That is all.
- Apply to: booking/payment status timeline, payment confirmation screen, receipt layout.

**Shopee** — `shopee.vn` (mobile)
- Order status tabs: To Pay / To Ship / To Receive / Completed / Cancelled.
  Direct mapping to EduNest booking tabs.
- Each order card: product thumbnail + name + price + status chip + one action button.
- Apply to: booking list tab structure, booking card layout, status chip + one action.

---

### 2.5 Admin and management screen references

**Linear.app** — `linear.app`
- Issue list: status dot + title + assignee avatar + priority label. Four fields, nothing more.
- Filters always visible at top as chips, not buried in a modal.
- Approve/reject actions are clear buttons, never ambiguous icons.
- Apply to: admin payout list, admin verification list, tutor management list.

**Notion** — `notion.so` (database table view)
- Each row is one decision. Status, name, date — scannable in half a second.
- Empty state is friendly: "No items yet. Click to add."
- Apply to: admin table views, report list, verification queue.

---

### 2.6 What not to copy

Do not copy:
- Exact screen layouts, spacing values, or animation styles from any listed product.
- Brand colors, logos, iconography, or illustrations.
- Manipulative dark patterns (countdown timers, false scarcity, hidden unsubscribe).
- UI that only works in English or on large Western phone sizes.
- Designs that require specific OS features not available on older Android versions.

EduNest should feel like its own product — a Vietnamese-first tutoring marketplace
with the polish and clarity of the apps above, not a clone of any of them.

---

## 3. Source of truth in the Flutter project

| Concern | Current source |
| --- | --- |
| Light and dark themes | `lib/theme/app_theme.dart` |
| Application routing and role access | `lib/router/app_router.dart` |
| English/Vietnamese UI text | `lib/l10n/app_strings.dart` |
| Shared feedback | `lib/widgets/error_banner.dart`, `SnackBar` |
| Reusable controls | `lib/widgets/app_ui.dart`, `app_button.dart`, `bank_bin_field.dart`, `money_text.dart`, `user_avatar.dart` |
| Screen-level patterns | `lib/screens/` |
| Role-based state/providers | Existing providers/services in `lib/providers/`, `lib/services/`, or current project structure |
| API models | Existing model files; do not rename fields unless backend contracts change |

When the same pattern appears on three or more screens, promote it to a themed component or shared widget instead of copying styling.

AI agents must inspect these files before making broad changes:

1. `lib/theme/app_theme.dart`
2. `lib/router/app_router.dart`
3. `lib/l10n/app_strings.dart`
4. `lib/widgets/`
5. The target screen folder under `lib/screens/`
6. Any related provider/service/model files

Do not redesign a screen in isolation if it depends on shared navigation, role access, localization, or API state.

---

## 4. AI redesign rules for Codex and coding agents

This section is specifically for AI tools that modify the Flutter codebase.

### 4.1 Required behavior

Before changing code, the AI agent must:

1. Inspect the current project structure.
2. Identify the affected role: parent/student, tutor, admin, or shared.
3. Identify the job to be done.
4. Check existing theme/widgets/localization.
5. State a short implementation plan.
6. Make the smallest safe set of changes that creates a clear design improvement.
7. Preserve API calls and business logic.
8. Run formatting and static analysis when possible.
9. Summarize changed files and known limitations.

### 4.2 Do not break these things

Do not break:

- Authentication flow
- Role-based routing
- API request/response models
- Payment flow
- PayOS/VietQR status display
- Booking status logic
- Tutor wallet and payout logic
- Existing localization structure
- Existing dark mode support
- Existing provider/service state updates
- Existing back navigation
- Existing required form validation

### 4.3 Safe refactoring rules

Allowed:

- Extract repeated UI into reusable widgets.
- Improve theme styles.
- Replace hardcoded colors with semantic theme colors.
- Add loading, empty, error, disabled, and success states.
- Improve scroll behavior and overflow handling.
- Improve microcopy through `AppStrings`.
- Add helper widgets for cards, chips, status badges, section headers, empty states, and CTA areas.
- Reorganize UI-only code if imports and routes remain correct.

Avoid unless explicitly requested:

- Rewriting the whole app architecture.
- Renaming routes.
- Renaming API models.
- Changing backend contract fields.
- Adding large new packages.
- Replacing state management.
- Replacing navigation framework.
- Mixing UI redesign with unrelated backend changes.

### 4.4 Output expected from Codex after redesign

After implementing changes, Codex should provide:

- Summary of UI/UX changes.
- Files modified.
- New shared components introduced.
- Screens redesigned.
- Known limitations.
- Commands run, such as `dart format` and `flutter analyze`.
- Any errors that could not be fixed.

---

## 5. Visual foundations

### 5.1 Color

#### New color palette — required overhaul

The current palette (`#2563EB` corporate blue, `#D97706` amber) must be replaced
with a richer, more distinctive identity. The new system uses indigo-violet as the
primary brand color and warm coral-orange as the attention accent. This combination
is widely used in modern edtech and feels both trustworthy and energetic.

**Required seed colors for `app_theme.dart`:**

| Role | Light mode | Dark mode seed |
|------|-----------|----------------|
| Primary | `#4F46E5` (indigo-violet) | `#818CF8` |
| Secondary / accent | `#F97316` (warm coral-orange) | `#FB923C` |
| Tertiary / learning | `#0EA5E9` (sky blue) | `#38BDF8` |
| Success / verified | `#10B981` (emerald) | `#34D399` |
| Warning / pending | `#F59E0B` (amber) | `#FCD34D` |
| Error | `#EF4444` | `#FCA5A5` |
| Scaffold background | `#F5F3FF` (soft lavender tint) | `#0F0E17` |
| Card surface | `#FFFFFF` | `#1C1B2E` |
| Section divider | `#EDE9FE` | `#2D2B45` |

Generate the `ColorScheme` using `ColorScheme.fromSeed(seedColor: Color(0xFF4F46E5))`
then override specific roles with the values above using `copyWith`.

**Semantic meaning — required:**

| Color | Meaning | Where to use |
|-------|---------|-------------|
| Indigo primary | Main action, selection, active nav, key links | Primary buttons, selected tabs, FAB |
| Coral-orange | Pending, attention-needed, CTA highlight | Pending badges, "Book now" accent, notification dots |
| Emerald green | Completed, verified, success, active | Completed badges, verified tutor chip, success states |
| Sky blue tertiary | Learning progress, materials, info | Material cards, progress bars, info chips |
| Amber | Warning, due-soon, reversible states | Homework due, payment pending, expiry |
| Soft lavender `#F5F3FF` | Page background | Scaffold background only |
| White card | Grouped content | All cards, list items, bottom sheets |

**Rules — all required:**

- Never communicate status with color alone. Always pair color with a label and icon.
- Never hard-code `Color(0xFF...)` in screen files. Use only `Theme.of(context).colorScheme.*`
  or a `ThemeExtension`.
- The soft lavender scaffold (`#F5F3FF`) must appear on all main screens so white
  cards float visually above the background — this single change makes the app feel
  layered and modern.
- Primary CTA buttons must use the filled indigo style with a `BoxShadow`:
  `BoxShadow(color: Color(0xFF4F46E5).withOpacity(0.30), blurRadius:12, offset:Offset(0,4))`
- Coral-orange is an accent only. Never use it as the primary button color or for
  large backgrounds.
- Dark mode: scaffold `#0F0E17`, cards `#1C1B2E`, all text via `onSurface` and
  `onSurfaceVariant`. No white hard-codes in dark mode.

**Gradient — allowed zones only:**

Soft linear gradient is allowed in these areas only:
- Tutor profile header hero
- Course/booking header hero card
- Home welcome banner
- Stat/metric cards (very subtle — same hue, 5% lightness shift)

Format: `LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight)`

Do not apply gradients to list items, bottom sheets, or form fields.

### 5.1.1 Visual energy and attention targeting

The palette should feel energetic but not stressful. Educational apps that retain
users (Duolingo, Khan Academy, Photomath) use high-contrast primary actions,
warm accent pops, and clear visual hierarchy — not flat grey monotony.

Codex must apply these rules:

- **Primary CTAs must pop.** Use a filled button with the indigo-violet primary,
  generous horizontal padding (24–32), height 52–56 dp, radius 28 (pill-adjacent).
  Add a subtle drop shadow: `BoxShadow(color: primary.withOpacity(0.30),
  blurRadius: 12, offset: Offset(0, 4))`. Never use a flat outline-only primary CTA
  on a card unless it is genuinely secondary.
- **Accent colors must earn attention.** Coral/amber for pending and action-required.
  Emerald for success, verified, completed. Indigo or sky blue as a learning/progress
  accent. These should show up on badges, progress indicators, and section headers —
  not just error states.
- **Gradient is allowed for hero areas only.** Tutor profile header, home hero
  banner, and feature card headers may use a soft linear gradient from primary to a
  10–15% lighter/darker variant. Do not apply gradients to body cards or list items.
- **Surface contrast must guide the eye.** Page background: `#F5F3FF` (soft lavender
  tint). Cards: pure `surface` (white in light mode). Use `elevation: 2`
  with a shadow rather than a border for marketplace-style listing cards. Reserve flat
  borderless cards for internal grouped content.
- **Status colors must be distinct and saturated enough to read at a glance.**
  Upcoming → blue chip. Pending → amber chip. Completed → teal chip. Cancelled →
  grey chip. Each with a small 8×8 dot or icon prefix, not color alone.

### 5.2 Typography

The system uses the platform font with this fallback chain:

`Roboto, Noto Sans, Arial, Segoe UI, sans-serif`

Noto Sans helps Vietnamese render reliably.

Use the Material text theme before setting a custom size.

Recommended hierarchy:

| Purpose | Text style |
| --- | --- |
| Screen title | `headlineSmall` or `titleLarge`, bold |
| Section title | `titleMedium`, semibold/bold |
| Card title | `titleMedium`, semibold/bold |
| Primary body | `bodyMedium` |
| Secondary/helper text | `bodySmall` with lower emphasis |
| Price or key metric | `titleMedium` or `titleLarge`, bold |
| Status badge | `labelMedium` |
| Tiny metadata | `labelSmall` only when still readable |

Rules:

- Use bold to establish hierarchy, not decoration.
- Avoid more than two emphasis levels in one card.
- Long dynamic text must use `Expanded`, wrapping, `maxLines`, or `TextOverflow.ellipsis`.
- Never rely on a fixed-width `Row` for dynamic Vietnamese text.
- Do not hard-limit card height around text.
- Ensure text scaling does not cause overflow.

### 5.3 Spacing, shape, and elevation

Use the 4-point rhythm:

`4, 8, 12, 16, 20, 24, 32, 48`

Recommended values:

| Element | Value |
| --- | --- |
| Screen horizontal padding | 16 |
| Standard content gap | 12 or 16 |
| Card inner padding | 16 |
| Feature card padding | 20 or 24 |
| Field radius | 16 |
| Button radius | 16 |
| Standard card radius | 20 |
| Feature/listing card radius | 24 |
| Bottom sheet radius | 24 top corners |
| Avatar small | 32–40 |
| Avatar standard | 48–64 |
| Touch target | About 48 × 48 dp |

Cards have two deliberate tiers:

- **Marketplace cards** (tutor/course discovery, featured availability, metric cards): `AppSurfaceCard(kind: AppSurfaceCardKind.marketplace)` with elevation 2 and a soft shadow.
- **Content cards** (forms, grouped detail, internal settings): default `AppSurfaceCard` with a flat semantic border and no elevation.

Hero areas must use `AppHeroCard` and are the only card type allowed to use a soft blue-to-teal gradient.

Avoid arbitrary dimensions. If a new radius, spacing value, or repeated visual rule is needed, add it to a shared token/helper first.

### 5.4 Icons and imagery

- Prefer rounded Material icons.
- Use icons to reinforce labels, not replace them.
- Icon-only buttons require tooltip and semantic label.
- Avatar images must have a fallback initial or neutral placeholder.
- Avoid decorative imagery that competes with booking, verification, payment, or lesson status.
- Empty-state illustrations should be friendly but lightweight.
- Avoid using stock-like tutor images unless the app supports real profile images.


### 5.5 Buttons — clarity and hierarchy

Codex must apply a strict three-tier button system:

| Tier | Use | Style |
|------|-----|-------|
| Primary | Main task CTA per screen | Filled, primary color, height 52–56, radius 28, shadow |
| Secondary | Alternative or supporting action | Outlined or tonal, same radius, no shadow |
| Tertiary | Low-priority / destructive / cancel | Text button or ghost, muted color |

Rules:
- Only one primary button per screen section.
- Primary button must always have a label. Never icon-only for a primary CTA.
- Disabled state must clearly look disabled (opacity 0.38) — do not hide disabled buttons.
- Loading state: replace label with `SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2, color: onPrimary))`.
- Buttons inside cards should be `FilledButton.tonal` (secondary tier), not flat text.
- FABs are allowed for single-dominant actions (e.g. "Create availability", "New booking").

### 5.6 Icons — expressive, consistent, readable

- Icon size: 20 in list items, 24 in app bars and cards, 28–32 for feature/hero icons.
- Use `Icons.rounded` variants only (no sharp or outlined mix).
- Every status must have an icon paired with a label:
  - Upcoming: `schedule` (blue)
  - Completed: `check_circle_rounded` (teal)
  - Pending: `hourglass_top_rounded` (amber)
  - Cancelled: `cancel_rounded` (grey)
  - Verified: `verified_rounded` (teal)
  - Action required: `warning_amber_rounded` (orange)
- Section header icons: use a small filled icon in primary or teal inside a
  `Container(padding:6, decoration:BoxDecoration(color:primary.withOpacity(0.10),
  borderRadius:BorderRadius.circular(8)))`. This anchors each section visually.
- Avoid mixing icon styles within the same screen.

### 5.7 Lists and list items — scannable, dense but breathable

Every list item must have a clear visual anchor (leading icon, avatar, or status dot)
so the eye has an entry point. Rules:

- Leading element: always present. Avatar for people, icon in colored container for
  subjects/categories, status dot or badge for action lists.
- Title: `titleMedium`, semibold. One line max with ellipsis.
- Subtitle: `bodySmall`, `onSurfaceVariant`. Up to two lines.
- Trailing: status badge OR price OR chevron. Never both a badge and a long label.
- Divider: use `Divider(height:1, indent:72)` (aligned to leading element end) rather
  than card-per-item for dense lists. Use card-per-item only for marketplace discovery
  lists where each item needs more visual weight.
- Section grouping: use sticky or non-sticky section headers with the `AppSectionHeader`
  widget between groups (e.g. Today / This week / Past).
- Empty list items: never show placeholder dashes or empty strings — use the `AppEmptyState`.
- Long lists (>10 items): add search or filter at the top.

### 5.8 Information density — anti-overwhelm rules

These rules are mandatory on every screen redesign.

**Card content limit:**
- Maximum 5 data points visible per card without expanding.
- A "data point" is: label, value, badge, icon-label pair, or chip.
- If a card needs more, move secondary data to a detail route or collapsible section.

**Screen content limit:**
- Maximum 3 distinct sections visible above the fold.
- Each section should answer one question (e.g. "What do I do next?", "What is my
  progress?", "Who is my tutor?").
- Sections below the fold are acceptable — the user can scroll, but must not feel
  bombarded when the screen first opens.

**Text rules:**
- No paragraph text on list items. Use one bold title + one short subtitle maximum.
- No inline instructions longer than one line. Move multi-step instructions to a
  tooltip, info sheet, or onboarding card.
- Status descriptions must be one to four words: "Due tomorrow", "Paid", "Needs review",
  "Completed", not a full sentence.

**Visual chunking:**
- Group related information inside one card. Separate unrelated information with a
  section header and whitespace (minimum 20 dp gap between sections).
- Never show two forms or two lists stacked without a header separating them.
- Use `SizedBox(height: 20)` or `SizedBox(height: 24)` between all major sections —
  not `Divider` lines between sections (dividers are for list items only).

**Progressive disclosure pattern — required for complex screens:**

---

## 6. Design system components

Create or standardize these shared components when redesigning.

### 6.1 App card

Use for grouped content.

Requirements:

- Rounded radius 20 or 24.
- Padding 16.
- Theme surface color.
- Border using `outlineVariant` or subtle shadow.
- Optional leading icon/avatar.
- Optional header, body, footer.

Do not nest more than two card levels.

**Implementation:** use `AppSurfaceCard` in `lib/widgets/app_ui.dart` for new grouped surfaces. It supports semantic surfaces, border, padding, radius, and optional tap feedback.

Shared spacing, radius, and shadow values live in `EduNestThemeTokens`, registered as a `ThemeExtension` by `AppTheme`. Read tokens with `Theme.of(context).extension<EduNestThemeTokens>()`; do not create new repeated spacing or shadow literals.

### 6.2 Section header

Use to separate content groups.

Should support:

- Title
- Optional subtitle
- Optional trailing action such as "View all"

**Implementation:** use `AppSectionHeader` for the common icon + title + optional subtitle/action pattern.

Use an `AppHeroCard` only for a page-level focus moment (home, tutor profile, payment/wallet summary). Do not apply a gradient to ordinary list rows.

### 6.3 Status badge

Use for booking, payment, lesson, verification, payout, homework, and report statuses.

Must include:

- Text label
- Semantic color
- Optional icon
- Consistent shape and padding

Status labels must be user-friendly. Examples:

- Pending payment
- Paid
- Upcoming
- Completed
- Cancelled
- Verification needed
- Payout requested
- Under review
- Action required

Avoid raw backend enum names unless no better label exists.

**Implementation:** use `AppStatusBadge` and `AppStatusTone`. Do not make a one-off colored `Container` for a new status.

### 6.4 Metadata chip

Use for small scannable details:

- Subject
- Mode
- Schedule
- Level
- Location
- Duration
- Lesson count
- Price range

Rules:

- Use `Wrap`, not fixed rows.
- Keep chip text short.
- Do not repeat information already shown directly above.

**Implementation:** use `AppMetaChip`; use `AppRating` for the compact rating/new-tutor treatment.

### 6.5 Tutor card

Tutor cards are the most important marketplace component.

A tutor card should include:

1. Avatar/photo.
2. Name.
3. Verification or trust marker where available.
4. Rating/review count if available.
5. Main subject(s).
6. Short teaching summary or experience.
7. Price.
8. Next available time or schedule hint.
9. Teaching mode: online/offline/hybrid.
10. Primary CTA: "View profile" or "Book lesson".

Avoid:

- Large paragraphs.
- Multiple competing CTAs.
- Raw tutor IDs.
- Too many badges.
- Hidden price.
- Hidden availability.

Recommended hierarchy:

```text
[Avatar] Tutor name        [Verified]
Subject • Level
⭐ 4.8 (32 reviews) • Online • Available this week
Short one-line teaching promise
₫250,000 / lesson              [View profile]
```

### 6.6 Tutor profile header

A tutor profile should quickly answer:

- Who is this tutor?
- What do they teach?
- Why should I trust them?
- How much does it cost?
- When can I book?
- What should I do next?

Required sections:

1. Header: avatar, name, verification, rating, primary subject.
2. Key facts: price, mode, level, schedule.
3. Bio/teaching style.
4. Experience/credentials.
5. Reviews or feedback.
6. Availability slots.
7. Booking CTA.
8. Safe in-app contact option, if allowed.

Use a sticky or bottom CTA when booking is the main goal.

### 6.7 Empty state

Every major list must have an empty state.

Empty state includes:

- Icon or small illustration.
- Clear title.
- Helpful explanation.
- Next action button if useful.

**Implementation:** use `AppEmptyState` for a friendly icon, title, explanation, and optional action. Use `AppLoadingState` for loading content that has no data to preserve.

### 6.11 Dashboard metric card

Use a small metric card only when it answers an immediate decision: number of active courses, upcoming lessons, pending payouts, or similar actionable information. Do not create metrics just to fill visual space.

**Implementation:** use `AppMetricCard` in a bounded grid (normally two columns on phones). Keep labels short and ensure values are secondary to the user’s next action.

Examples:

- "No bookings yet" → "Find a tutor and book your first lesson."
- "No availability created" → "Create availability so parents can book you."
- "No payout requests" → "Completed lesson earnings will appear here."
- "No homework assigned" → "Your tutor has not assigned homework yet."

### 6.8 Error state

Use `ErrorBanner` for page/API errors.

Rules:

- Explain what went wrong in user language.
- Avoid raw backend exception text when possible.
- Provide retry if useful.
- Preserve existing content when refresh fails.
- Show field-level errors near the relevant field.

### 6.9 Loading state

Use:

- Page-level spinner only when no data exists yet.
- Skeleton or placeholder cards for marketplace lists if possible.
- Inline spinner inside submitting buttons.
- Pull-to-refresh for refreshable lists.

Do not show blank white screens.

### 6.10 Confirmation dialog

Use for:

- Payment confirmation.
- Booking cancellation.
- Payout request.
- Admin payout approval/rejection.
- Tutor verification approval/rejection.
- Deleting/removing content.
- Reporting users/content.
- Any hard-to-reverse action.

The dialog must state:

- Entity affected.
- Consequence.
- Amount/status if financial.
- Primary confirmation action.
- Safe cancel action.

---

## 7. Layout and navigation

### 7.1 App structure

Primary signed-in areas live in the `MainShell`.

Typical primary areas:

- Home
- Explore/tutors
- Bookings
- Lessons
- Homework
- Materials
- Chat
- Wallet for tutors
- Reports where relevant
- Profile

Role-specific and task-focused flows should open as separate routes.

Rules:

- Keep primary destinations in shell navigation.
- Use push routes for focused task/detail pages.
- Detail pages must preserve a clear back path.
- Route-level role protection is required for tutor/admin-only features in `app_router.dart`.
- Hiding a button is not access control.
- Avoid deep navigation for high-frequency actions.

### 7.2 Screen anatomy

Use this order whenever it fits the task:

1. App bar: concise title and only high-value actions.
2. Page context: optional summary, filter, or status banner.
3. Primary content: list, form, detail, or dashboard cards.
4. Primary action: visible without ambiguity.
5. Feedback: inline validation, error banner, success SnackBar.

For long pages:

- Use `SafeArea`.
- Use scrollable content.
- Avoid fixed heights.
- Use `SliverAppBar`, `CustomScrollView`, `ListView`, or `SingleChildScrollView` carefully.
- Do not put unbounded `ListView` inside `Column` without constraints.
- Avoid nested scroll views unless necessary.

### 7.3 Responsive behavior

Must work on:

- Small Android phones.
- Large phones.
- Tablets.
- English.
- Vietnamese.
- Light mode.
- Dark mode.
- Text scaling.

Rules:

- Use `LayoutBuilder` for adaptive arrangements.
- Use `Wrap` for chips, quick actions, stats, and tags.
- Use `Expanded`/`Flexible` for dynamic text inside rows.
- Use `maxLines` and ellipsis only where truncation is acceptable.
- Allow important educational/payment information to wrap.
- Never use hardcoded heights that can cause overflow.
- Avoid horizontal scrolling except for intentional chip/filter rails.

---

## 8. Screen and flow guidelines

### 8.1 Parent/student home

Purpose:

Help the user understand what to do next.

Priority order:

1. Upcoming lesson or next action.
2. Current booking/payment status.
3. Homework/materials due.
4. Tutor recommendations or continue discovery.
5. Learning progress/reports.
6. Recent messages.

Good home sections:

- "Next lesson"
- "Continue learning"
- "Homework due"
- "Recommended tutors"
- "Recent messages"
- "Learning progress"

Avoid:

- Showing every feature equally.
- Admin-like metric dashboards for learners.
- Empty dashboards with no guidance.

### 8.2 Tutor discovery / explore

Purpose:

Help parents/students find a suitable tutor quickly.

Required features:

- Search by subject/tutor name.
- Filters for subject, price, mode, level, rating, and availability where data exists.
- Sort options such as best match, price, rating, newest, or availability where supported.
- Tutor cards optimized for scanning.
- Empty state with filter reset.
- Loading and error states.

Discovery page hierarchy:

1. Search field.
2. Filter chips.
3. Optional recommendation banner.
4. Tutor list.
5. Clear empty/error state.

Avoid:

- Burying filters in unclear menus.
- Showing raw technical fields.
- Hiding price or schedule.
- Making the first screen only a generic course list if the user goal is tutor discovery.

### 8.3 Tutor detail

Purpose:

Build enough trust for booking.

Required content:

- Tutor identity and avatar.
- Verification/trust marker if available.
- Rating/reviews if available.
- Subjects and levels.
- Bio/teaching style.
- Teaching mode.
- Price.
- Availability/schedule.
- Experience/credentials if available.
- Reviews/feedback if available.
- Clear booking CTA.
- Safe chat/contact CTA if allowed.

Recommended sections:

1. Profile header.
2. Quick trust facts.
3. About this tutor.
4. Subjects and teaching style.
5. Availability.
6. Reviews.
7. Booking/payment reminder.

The primary CTA should be clear: "Book lesson" or "Choose time".

### 8.4 Booking flow

Purpose:

Complete booking with minimal uncertainty.

Recommended flow:

1. Select tutor/course/availability.
2. Select time or slot.
3. Review booking details.
4. Confirm and pay.
5. Show payment/booking status.

Booking review must show:

- Tutor name.
- Subject/course.
- Date/time.
- Mode/location.
- Price.
- Payment status or next payment step.
- Cancellation/reschedule note if supported.
- What happens after payment.

Rules:

- Do not surprise users with price later.
- Avoid multi-page forms unless needed.
- Use a bottom CTA for the final action.
- Disable the confirmation button while submitting.
- Show success/failure clearly.

### 8.5 Payment flow

Purpose:

Make users feel safe when paying.

Must show:

- Amount.
- Provider/method.
- Booking/course.
- Tutor.
- Payment status.
- Next step.
- Retry or contact support when failed/expired.

Rules:

- Do not show raw provider data unless it helps the user.
- Explain pending payments.
- Show a receipt-like summary after payment.
- Use warning styles for pending/expired, not error unless the payment failed.
- Financial actions require confirmation.

### 8.6 Bookings

Purpose:

Let users track booking status and continue the right next step.

Group or filter by:

- Upcoming
- Pending payment
- Completed
- Cancelled

Booking card should include:

- Subject/course.
- Tutor or learner name depending on role.
- Time/date.
- Status badge.
- Price/payment state.
- Next action: pay, view detail, join lesson, message, cancel, review.

### 8.7 Lessons

Purpose:

Help users prepare for and complete lessons.

Lesson card should include:

- Subject/course.
- Tutor/learner name.
- Date/time.
- Lesson status.
- Mode/location.
- Attendance state where relevant.
- Notes/materials/homework indicator.
- Main action: view, join, complete, mark attendance.

Tutor lesson screen should prioritize:

- Today's lessons.
- Pending attendance.
- Lessons needing notes/report.
- Completed lesson history.

Parent/student lesson screen should prioritize:

- Upcoming lessons.
- Preparation materials.
- Homework due.
- Completed lessons and feedback.

### 8.8 Homework and materials

Purpose:

Make study tasks clear.

Recommended statuses:

- Assigned
- Due soon
- Submitted
- Reviewed
- Completed
- Missing/late

Homework card should show:

- Title.
- Course/subject.
- Due date.
- Status.
- Tutor feedback if reviewed.
- CTA: submit, view feedback, open material.

Materials card should show:

- Title.
- File type.
- Course/subject.
- Upload date.
- Download/open action.

### 8.8b Course hub screen — Lessons, Homework, Materials

This is the central learning screen for a student/parent after booking a course.
It must feel like a clean learning dashboard, not a list of records.

**Purpose:** Let the student understand their course progress, what to do next,
and access all course content in one place without feeling overwhelmed.

**Screen structure — top to bottom:**

┌─────────────────────────────────────┐

│  COURSE HEADER CARD (gradient)      │

│  Subject name + Tutor avatar + name │

│  Progress bar  ██████░░░░  6/10 lessons │

│  Mode chip • Level chip             │

└─────────────────────────────────────┘
[Lessons]   [Homework]   [Materials]   ← Tab bar
┌─────────────────────────────────────┐

│  NEXT LESSON  (highlighted card)    │

│  📅 Thu, 26 Jun  •  9:00 AM        │

│  Status: Upcoming  [Join / View]    │

└─────────────────────────────────────┘
Past lessons (collapsed list, tap to expand)

**Header card rules:**
- Gradient background (indigo to violet, see Section 5.1).
- Course subject as `headlineSmall`, white text.
- Tutor avatar (40 dp) + tutor name in a row.
- Progress bar using `LinearProgressIndicator` with emerald fill.
- `X of Y lessons completed` as a concise label next to the bar.
- Mode and level as small white/translucent chips.
- No more than these 5 elements in the header. Nothing else.

**Tab bar (Lessons / Homework / Materials):**
- Use `TabBar` with `indicator: BoxDecoration(borderRadius, color: primary)`.
- Active tab: white label on indigo pill. Inactive: `onSurfaceVariant`.
- Each tab holds its own scrollable list. Do not put all three in one scrollable page.

---

**LESSONS TAB:**

Show in order:
1. "Next lesson" highlighted card (if one exists).
2. "Upcoming" lessons list.
3. "Past lessons" in a collapsible section (collapsed by default).

Lesson card must show (maximum):
- Date + time (prominent, bold).
- Status badge (Upcoming / Completed / Cancelled).
- Duration chip.
- One action button (Join / View notes / Rate).

Do NOT show: lesson ID, booking ID, attendance code, or raw API fields.

Empty state: "No upcoming lessons. Your tutor will create lessons after booking."

---

**HOMEWORK TAB:**

Group by status using section headers:
── DUE SOON ──────────────────────────

[ Homework card ]

[ Homework card ]
── SUBMITTED ─────────────────────────

[ Homework card ]
── COMPLETED ─────────────────────────

(collapsed by default, show count)

Homework card must show (maximum):
- Title (bold, one line, ellipsis).
- Due date with urgency color (red if < 24h, amber if < 3 days, normal if more).
- Status badge.
- One action: Submit / View feedback / Resubmit.

Do NOT show: homework ID, lesson reference ID, created-at timestamp, or tutor notes
inline (move notes to the detail screen).

Urgency badge rule:
- Due today: `!` icon + red badge "Due today"
- Due in 1–2 days: amber badge "Due in X days"
- Due in 3+ days: neutral label, no badge color

Empty state per group: hide the section header entirely if that group has no items.
Show "No homework yet. Your tutor will assign homework for each lesson." only when
all three groups are empty.

---

**MATERIALS TAB:**

Do not use a plain list of filenames. Group by type or lesson:
── LESSON 3 — Introduction to Algebra ──

📄 Worksheet 1.pdf          [Open]

🎬 Intro video link         [Watch]
── LESSON 2 ──────────────────────────

📄 Notes.pdf                [Open]

Material card must show (maximum):
- File type icon (colored: PDF → coral, video → indigo, image → teal, link → sky blue).
- File name (one line, ellipsis).
- Upload date (small, muted).
- [Open] or [Download] button (text button, not full-width).

Do NOT show: file size in MB, server path, UUID, or uploader ID.

Empty state: "No materials yet. Your tutor will share study materials here."

---

**Anti-overwhelm rules specific to this screen:**
- The default view when entering the course hub must show the header + next lesson
  only. Everything else is a tap away via tabs.
- Never auto-expand all past lessons. Collapsed by default with a "Show X past lessons"
  button.
- Never show all homeworks in a flat list. Always group by status.
- Never put lesson + homework + materials all on one scrollable page. They must be
  in separate tabs.

**Current implementation:** `lib/screens/course/course_hub_screen.dart` is the
course-first entry point at `/course-hub`. It reuses `AppDataProvider`'s existing
lesson, homework, material, and availability loading methods; it does not change
models, services, or API contracts. The legacy `/lessons`, `/homework`, and
`/materials` routes remain available for their existing detail and management flows.

### 8.9 Chat

Purpose:

Support safe communication without encouraging off-platform transactions.

Chat list card should show:

- Avatar.
- Name.
- Role/context.
- Last message.
- Time.
- Unread indicator.
- Related booking/course if available.

Conversation screen should include:

- Clear header with person/context.
- Message bubbles.
- Timestamp grouping when useful.
- Safe messaging notice if needed.
- Input field with send button.
- Attachment support only if implemented.

Rules:

- Avoid exposing phone/email prompts if the business model requires in-app booking.
- Consider safety copy before booking.
- Empty chat should suggest a relevant first message.

### 8.10 Tutor dashboard

Purpose:

Help tutors complete work and understand earnings.

Priority order:

1. Next lesson.
2. Pending actions: attendance, homework, reports, verification.
3. Availability/course management.
4. Wallet summary.
5. Messages.
6. Performance/reviews.

Good sections:

- "Today"
- "Pending tasks"
- "Availability"
- "Earnings"
- "Recent messages"
- "Teaching resources"

Avoid:

- Admin-like clutter.
- Too many metrics without action.
- Hiding payout status.

### 8.11 Tutor availability/course creation

Purpose:

Help tutors create bookable slots without mistakes.

Form should explain:

- Subject.
- Level.
- Mode.
- Start/end time.
- Course start/end date.
- Slots.
- Price.
- Location/online details if relevant.
- Visibility/status.

Rules:

- Use date/time pickers.
- Validate start < end.
- Validate slot >= 1.
- Validate price >= 0.
- Show consequences before publishing.
- Preserve form data after errors.
- Show a preview card before final creation if possible.

### 8.12 Attendance

Purpose:

Let tutors quickly mark lesson attendance.

Attendance UI should show:

- Lesson.
- Learner/student.
- Time.
- Attendance options.
- Optional note.
- Submit button.
- Previous attendance state if already marked.

Use confirmation for changes that affect wallet/payment/reporting.

### 8.13 Tutor wallet and payout

Purpose:

Make money status transparent and trustworthy.

Wallet screen should show:

- Available balance.
- Pending balance if used.
- Recent transactions.
- Payout status.
- Request payout CTA.
- Bank/account setup status if needed.

Payout detail should show:

- Amount.
- Status.
- Requested date.
- Paid date if available.
- Bank info summary.
- Admin note/rejection reason if available.
- Clear next step.

Rules:

- Use `MoneyText` or shared formatting.
- Do not hide fees if they exist.
- Financial actions need confirmation.
- Admin payout actions must be auditable.

### 8.14 Reports and learning progress

Purpose:

Make progress understandable.

Report card should show:

- Learner/student.
- Subject/course.
- Date/period.
- Status.
- Main outcome.
- CTA: view report.

Report detail should show:

- Summary.
- Strengths.
- Areas to improve.
- Attendance/lesson context.
- Homework/material context if available.
- Tutor recommendations.
- Parent-friendly language.

Avoid technical grading language unless required.

### 8.15 Admin dashboard

Purpose:

Help admins make accurate decisions.

Priority sections:

- Pending tutor verification.
- Pending payouts.
- New reports.
- Payment/booking issues.
- User growth or platform metrics.
- Risk/flagged activity.

Admin cards should include:

- Metric number.
- Label.
- Trend/context if available.
- CTA when action is needed.

Use mobile-friendly tables/lists:

- Status chips.
- Search/filter.
- Compact row layout.
- Detail route for full context.
- Clear approve/reject actions.

### 8.16 Admin payout management

Purpose:

Support safe financial decisions.

Payout list should show:

- Tutor.
- Amount.
- Status.
- Requested date.
- Bank readiness.
- CTA: review.

Payout detail must show:

- Tutor identity.
- Wallet/transaction context.
- Requested amount.
- Bank account summary.
- Status history.
- Admin note field if rejecting.
- Approve/reject confirmation.

---

## 9. Content and localization

The app supports English and Vietnamese through `AppStrings`.

Every new user-facing string must be added to localization and rendered through the existing localization pattern such as `context.l10n`, `t.text(...)`, or the current project convention.

Never hard-code a new visible string into a screen unless the project currently has no localization pattern for that specific area and the change is temporary.

### 9.1 Writing rules

- Use direct verbs: "Create availability", "Book lesson", "Request payout".
- Use sentence case except proper names.
- Be specific about limits: "Up to 3 images", "Maximum file size: 2 MB".
- Use one term consistently.
- Avoid backend terms such as `availabilityId`, `bookingId`, `studentid`, `orderCode`, or raw enum names in normal user screens.
- Explain what the user can do next.
- Keep labels short for mobile.

### 9.2 Preferred terms

Use these terms consistently:

| Concept | Preferred user-facing term |
| --- | --- |
| Tutor | Tutor |
| Parent/student user | Learner or student, depending on context |
| Availability | Availability or time slot |
| Booking | Booking |
| Lesson | Lesson |
| Payment | Payment |
| Wallet | Wallet |
| Payout | Payout |
| Report | Progress report |
| Material | Material |
| Homework | Homework |
| Verification | Verification |

For admin/debug screens, technical IDs may be shown only if useful.

### 9.3 Vietnamese support

Vietnamese can be longer than English.

Rules:

- Do not concatenate grammar-dependent fragments such as `'$count lessons'`.
- Use localized helper functions for plural/count phrases.
- Allow labels and cards to grow vertically.
- Avoid small fixed-width buttons with long labels.
- Test narrow screens with Vietnamese strings.

---

## 10. Accessibility and inclusive design

- Maintain strong contrast using `ColorScheme` roles.
- Do not use light gray text for essential information.
- Interactive targets should be around 48 × 48 dp or have enough padding.
- Every icon-only control needs a tooltip.
- Use semantic labels for custom tappable widgets.
- Support text scaling.
- Avoid hard-limiting heights around text.
- Prefer `Wrap` over fixed-width rows for chips and tags.
- Do not use color, position, or icon alone to convey status.
- Use readable language for students and parents.
- Do not assume technical knowledge.
- Do not make payment or cancellation consequences unclear.
- Avoid stressful or blaming language in error states.

---

## 11. State, feedback, and safety rules

### 11.1 Required states for major screens

Every major screen must represent:

- Loading
- Empty
- Error
- Success feedback
- Disabled/submitting state
- Refresh state if applicable

### 11.2 Loading

Use:

- `CircularProgressIndicator` only when no data exists.
- Skeleton cards/placeholders for marketplace lists where practical.
- Inline spinner inside buttons during submit.
- Pull-to-refresh for refreshable lists.

Avoid:

- Blank pages.
- Infinite spinners without context.
- Removing existing content during background refresh.

### 11.3 Empty

An empty state must answer:

1. What is empty?
2. Why might it be empty?
3. What can the user do next?

### 11.4 Error

Error states must:

- Explain the problem in user language.
- Avoid raw server messages if unsafe or confusing.
- Offer retry if useful.
- Preserve entered form data.
- Show field-level errors near fields when practical.

### 11.5 Success

Use concise SnackBars or confirmation screens.

Examples:

- "Booking created. Continue to payment."
- "Attendance saved."
- "Payout request sent."
- "Availability published."

### 11.6 Safety and trust

Use confirmation for:

- Payment.
- Booking cancellation.
- Payout request.
- Admin payout approval/rejection.
- Tutor verification approval/rejection.
- Report resolution.
- Deleting/removing data.
- Any destructive or financial action.

Always show amount and consequence for financial actions.

---

## 12. Role-specific UX priorities

### 12.1 Learners / parents / students

Prioritize:

- Discovery.
- Trust.
- Booking confidence.
- Clear payment status.
- Upcoming lessons.
- Homework/material access.
- Progress visibility.
- Safe communication.

Important design question:

"Can the parent decide whether to book this tutor without needing to guess price, schedule, teaching mode, or credibility?"

### 12.2 Tutors

Prioritize:

- Task completion.
- Verification progress.
- Availability setup.
- Lesson management.
- Attendance.
- Materials/homework.
- Reports.
- Wallet/payout transparency.
- Message response.

Important design question:

"Can the tutor see what needs action today within 10 seconds?"

### 12.3 Administrators

Prioritize:

- Accurate decisions.
- Auditable context.
- Risk visibility.
- Clear financial actions.
- Tutor verification evidence.
- Report and payout status.

Important design question:

"Can the admin approve, reject, or investigate with enough context and without guessing?"

---

## 13. Design anti-patterns to avoid

Avoid:

- Beautiful screens that hide the primary action.
- Dashboards with too many equal-weight cards.
- Tutor cards without price or availability.
- Booking flows that reveal the amount too late.
- Payment screens without next-step explanation.
- Raw backend enum/status labels.
- Technical IDs in normal user screens.
- Multiple primary buttons in the same section.
- Nested cards inside nested cards inside nested cards.
- Horizontal overflow.
- Fixed heights around dynamic text.
- Icon-only actions without tooltip.
- Empty pages without guidance.
- Error messages that only say "Something went wrong".
- Hardcoded strings outside localization.
- Hardcoded colors outside theme.
- Screens that only work in English.
- Screens that only work in light mode.
- Changing backend logic while doing a visual redesign.

---

## 14. Redesign workflow

Before changing UI/UX:

1. Identify the user role.
2. Identify the job to be done.
3. Identify the current route and affected files.
4. Inspect shared theme/widgets/localization.
5. State the current UX problem.
6. Define success measure.
7. Sketch information hierarchy.
8. Reuse semantic theme tokens and localized strings.
9. Implement reusable components first.
10. Migrate high-traffic screens one by one.
11. Test loading, empty, error, success, disabled, long text, Vietnamese, dark mode, and narrow screen.
12. Check route authorization and API behavior.
13. Run `dart format`.
14. Run `flutter analyze` if possible.
15. Summarize changes.

For broad redesigns, change foundations first:

1. Theme tokens.
2. Shared components.
3. Navigation clarity.
4. Parent/student discovery and booking.
5. Tutor lesson/wallet flows.
6. Admin payout/report flows.
7. Polish states and microcopy.

Do not mix a broad visual redesign with unrelated backend behavior changes unless the flow requires it.

---

## 15. UI review checklist

Before merging a UI change, confirm:

- [ ] The screen has one obvious primary action.
- [ ] The page works in English and Vietnamese.
- [ ] Long names and labels do not overflow.
- [ ] Loading state exists.
- [ ] Empty state exists.
- [ ] Error state exists.
- [ ] Disabled/submitting state exists for async actions.
- [ ] Success feedback exists after important actions.
- [ ] Colors come from the theme or have a documented semantic purpose.
- [ ] Forms have useful validation and preserve entered data after errors.
- [ ] Important status is conveyed by text as well as color/icon.
- [ ] Tap targets, tooltips, and text scaling have been considered.
- [ ] Role restrictions are enforced in routing/API, not only hidden in UI.
- [ ] The implementation follows shared patterns or deliberately updates them.
- [ ] Financial actions show amount, status, and consequence.
- [ ] Booking actions show tutor, subject, time, mode, price, and next step.
- [ ] Tutor/admin actions show enough context for safe decisions.
- [ ] No new hardcoded user-facing strings were added outside localization.
- [ ] No avoidable RenderFlex overflow is introduced.
- [ ] Dark mode still looks readable.
- [ ] `dart format` was run.
- [ ] `flutter analyze` was run or any unresolved issue was documented.

---

## 16. Recommended next design-system improvements

These are safe improvements to make incrementally when redesign work begins:

1. Extract shared spacing, radius, status colors, and card/section styles into theme extensions or common widgets.
2. Create one reusable empty-state component.
3. Create one reusable loading-content/skeleton pattern.
4. Standardize status badges across bookings, lessons, reports, payments, verification, and payouts.
5. Standardize metadata chips across tutors, courses, availability, and lessons.
6. Create a reusable tutor card.
7. Create a reusable booking card.
8. Create a reusable lesson card.
9. Create a reusable payout/status card.
10. Create a reusable dashboard metric card.
11. Replace remaining direct `Colors.*` and deprecated opacity calls with semantic theme colors.
12. Add widget/golden tests for narrow-screen, Vietnamese, and dark-mode states.
13. Add a UI review checklist to pull requests.
14. Create sample mock data for key empty/loading/error states.
15. Add screenshot comparison for redesigned high-traffic flows.

---

## 17. Suggested Codex prompt for using this file

Use this prompt when asking Codex to overhaul UI/UX:

```text
Read UI_UX_GUIDELINES.md fully before touching any code. Sections to prioritize:
- Section 2: visual and UX references per screen type
- Section 5.1: new color palette (indigo-violet + coral-orange + emerald)
- Section 5.5–5.7: buttons, icons, lists
- Section 5.8: anti-overwhelm and information density rules
- Section 8.8b: course hub screen (Lessons / Homework / Materials)
- Section 4: what you must never break

You are a senior Flutter UI/UX engineer. Redesign EduNest to feel like a modern,
trustworthy tutoring marketplace — visually interesting, easy to navigate, and
never overwhelming. Every screen should answer one question and make the next
action obvious within 3 seconds of opening.

---

STEP 0 — Read before touching any code:
1. Inspect full project structure.
2. Read lib/theme/app_theme.dart, lib/router/app_router.dart,
   lib/l10n/app_strings.dart, lib/widgets/, and all relevant screen,
   provider, service, and model files.
3. For each major screen, identify:
   - The current visual problem (clutter, no hierarchy, flat color, missing states).
   - The reference product from Section 2 most relevant to fixing it.
   - The specific pattern to borrow (e.g. "Coursera collapsed module grouping
     for the lesson list", "Google Classroom status grouping for homework tab").
4. Write a short implementation plan per phase before writing code.

---

PHASE 1 — Color scheme overhaul (do this first, nothing else runs without it):

Update lib/theme/app_theme.dart:
- ColorScheme.fromSeed(seedColor: Color(0xFF4F46E5)) as the base.
- Override scaffold background: Color(0xFFF5F3FF) light / Color(0xFF0F0E17) dark.
- Override card surface: Colors.white light / Color(0xFF1C1B2E) dark.
- Override secondary: Color(0xFFF97316) coral-orange.
- Override tertiary: Color(0xFF0EA5E9) sky blue.
- Add ThemeExtension with: successColor (0xFF10B981), warningColor (0xFFF59E0B),
  sectionDivider (0xFFEDE9FE).
- Add shared BoxShadow token: BoxShadow(color: Color(0xFF4F46E5).withOpacity(0.28),
  blurRadius:12, offset:Offset(0,4)).
- Update ElevatedButton, FilledButton, OutlinedButton themes to use new colorScheme.
- Verify dark mode is readable.

Visual reference: Brilliant.org (dark layered cards + vibrant accent),
Duolingo (saturated semantic status colors), Notion (lavender scaffold + white cards).

---

PHASE 2 — Shared component overhaul:

Update all widgets in lib/widgets/ to remove clutter and apply new palette.

AppSurfaceCard:
- Marketplace cards: elevation 2 + BoxShadow token, radius 20.
- Content/grouped cards: elevation 0, border Color(0xFFEDE9FE), radius 20.
- Inner padding 16. Never nest more than two card levels.

AppStatusBadge:
- Pill shape, padding horizontal 10 vertical 4.
- Always icon (16dp) + label. Never color alone.
- Upcoming → indigo. Completed → emerald. Pending → amber.
  Cancelled → grey. Due soon → coral-orange. Verified → emerald.
- Reference: Linear.app status pills, Duolingo semantic color use.

AppSectionHeader:
- Leading icon in 32dp rounded container (primary.withOpacity(0.12)).
- Title bodyLarge bold. Optional "View all" text button trailing.
- Always SizedBox(height:12) after before content.
- Reference: Notion section headers, Linear issue grouping headers.

AppEmptyState:
- Icon 48dp muted, title titleMedium bold, subtitle bodySmall muted,
  optional FilledButton.tonal action.
- Reference: Duolingo friendly empty states, Google Classroom empty assignment list.

AppLoadingState:
- Shimmer skeleton shaped like the card it replaces. Never a bare spinner.

AppMetaChip:
- Icon + short label. Wrap layout. Max 3–4 visible before Wrap breaks to next line.

---

PHASE 3 — Course hub screen (highest priority screen, redesign in full):

Redesign the course/lesson screen according to Section 8.8b.

Reference products for this screen:
- Udemy mobile: tab structure (Lessons / Q&A / Materials), collapsed sections,
  file type icons.
- Coursera mobile: progress ring in header, deadline urgency, "Resume" as first CTA.
- Google Classroom mobile: homework grouped by Assigned / Missing / Done,
  assignment card with max 3 fields.
- Khan Academy mobile: progress bar on course card, short action labels
  (Watch / Practice / Review), parent summary separate from student view.
- Brilliant.org mobile: lesson card simplicity, completion checkmark + fade,
  attention drawn to next unlocked lesson.

Required outcome:
- Gradient header card: subject, tutor avatar + name, progress bar, mode/level chips.
  Maximum 5 elements. Gradient from Section 5.1.
- TabBar: Lessons / Homework / Materials. Indigo pill indicator.
- Lessons tab: next lesson highlighted card first, upcoming list, past collapsed
  by default with "Show X past lessons" button.
- Homework tab: grouped sections — Due soon / Submitted / Completed.
  Due date urgency color (red < 24h, amber < 3 days). Collapsed completed by default.
- Materials tab: grouped by lesson/topic. File type icon colored by type
  (PDF coral, video indigo, image teal, link sky blue).
- Every tab: loading skeleton, empty state, error state.
- No IDs, no raw timestamps, no API field names visible to the user.
- Maximum 5 data points per card. Overflow goes to detail screen.

---

PHASE 4 — Redesign all other high-traffic screens:

Apply Section 5.8 anti-overwhelm rules to every screen below.
For each screen, check Section 2 for the most relevant reference product and pattern.

Parent/student screens:

Home screen:
- Hero greeting card with student name + next lesson summary.
- Maximum 3 sections above the fold: Next lesson / Homework due / Recommended tutors.
- No equal-weight dashboard grid. One section leads, others support.
- Reference: Khan Academy home (progress-first), Outschool home (upcoming classes first).

Tutor discovery:
- Sticky search bar + horizontal filter chip rail always visible.
- Tutor card: avatar, name, verified badge overlay, rating, subject chips,
  price pill, teaching mode, one CTA. Maximum 6 data points.
- Empty state with filter reset action.
- Reference: Preply filter chip rail + tutor card layout,
  AmazingTalker verified badge overlay + price pill,
  Cambly photo-forward card + coral book CTA.

Tutor detail:
- Gradient profile header: avatar, name, verified badge, rating, primary subject.
- Trust row: price chip, mode chip, level chip, availability hint.
- Sections separated by 24dp gap, no hard dividers between sections.
- Sticky bottom bar: price + "Book lesson" FilledButton with shadow.
- Reference: Preply sticky booking CTA, AmazingTalker teaching style chips,
  Outschool sticky enroll button.

Booking flow:
- Step indicator at top (1 Select → 2 Review → 3 Pay).
- Review card: tutor, subject, date/time, mode, price. Five fields, nothing else.
- Single primary CTA at bottom. Disabled while submitting.
- Reference: Grab booking confirmation clarity, Shopee order review simplicity.

Payment screen:
- Amount large and bold at top.
- Status timeline: Pending → Processing → Confirmed.
- Payment method display. Next step copy below.
- Reference: Grab payment receipt, Shopee order status timeline.

Bookings list:
- Tabs: Upcoming / Pending / Completed / Cancelled.
- Booking card: tutor avatar + name, subject, date, status badge, one action button.
- Reference: Shopee order status tabs (To Pay / To Ship / Completed / Cancelled).

Chat list:
- Avatar + name + last message snippet (one line ellipsis) + time + unread dot.
- Nothing else on the list item.

Tutor screens:

Tutor dashboard:
- "Today" section first: lessons today, pending attendance, pending homework review.
- Pending task count badge on each section header.
- Wallet summary card: balance bold, payout status badge, request payout CTA.
- Maximum 3 sections above fold.
- Reference: Linear.app pending task grouping, Notion section-per-priority layout.

Lesson list (tutor):
- Grouped: Today / Upcoming / Past. Past collapsed by default.
- Lesson card: student name, subject, time, attendance status badge, one action.
- Reference: Coursera week-grouped lesson list, Udemy completion state per lesson.

Wallet screen:
- Balance as hero number (headlineLarge, bold, indigo).
- Payout status badge directly below balance.
- Request payout FilledButton with shadow.
- Transaction list below, date-grouped.
- Nothing else above the fold.

Admin screens:

Admin dashboard:
- 2-column metric card grid. Each card: number (large bold) + label + pending badge
  if action needed + tap to go to list.
- Reference: Linear.app issue count cards, Notion database summary view.

Admin payout list:
- Status chip + tutor name + amount + requested date + Review button.
  Four fields per row. Nothing else.
- Reference: Linear.app issue row (status dot + title + assignee + priority).

Admin verification list:
- Same pattern: status chip + tutor name + submitted date + Review button.

---

PHASE 5 — Polish every screen:

- Every major screen must have: loading skeleton, empty state, error state,
  disabled/submitting state, success SnackBar.
- Replace every Colors.* hard-code with colorScheme token or ThemeExtension value.
- Replace every hard-coded user-facing string with AppStrings localization entry.
- Verify no RenderFlex overflow on narrow screen (360dp width) with Vietnamese text.
- Verify dark mode contrast on every changed screen.
- Run dart format.
- Run flutter analyze. Fix all errors. Document any that cannot be fixed.

---

Do not stop at suggestions. Modify actual code files.

After completing all phases, provide:
- All files modified.
- New shared widgets introduced.
- Screens redesigned.
- Color tokens changed.
- Reference products applied per screen.
- Known limitations or deferred items.
- Output of dart format and flutter analyze.
```

---

## 18. Definition of a successful redesign

A successful EduNest redesign should make these statements true:

- A parent can understand the best next action within 5 seconds of opening the app.
- A parent can compare tutors without opening every profile.
- A tutor profile clearly explains credibility, subject, price, schedule, and booking action.
- A booking review clearly shows tutor, subject, time, mode, price, and next step.
- A payment screen clearly shows amount, status, and consequence.
- A tutor can see today's lesson and pending tasks quickly.
- A tutor can understand wallet and payout status without guessing.
- An admin can review payout/report/verification items with enough context.
- Every major screen has loading, empty, error, disabled, and success states.
- The app works on narrow phones with Vietnamese text.
- The app looks consistent in light and dark mode.
- The app feels like one product, not a collection of unrelated screens.
