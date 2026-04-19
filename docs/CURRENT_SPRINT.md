# Current Sprint

## Sprint 1 — Project Foundation (Week 1)

### ✅ Done

| Task | Completed | Notes |
|------|-----------|-------|
| Flutter project scaffold | 2026-04-16 | Full skeleton: packages, folder structure, core files, `flutter analyze` clean |
| Auth feature implementation | 2026-04-19 | Login, register, KVKK consent screens; `AuthRepository`; Providers and GoRouter logic. |
| Home / Product List screen | 2026-04-19 | Product model, ProductRepository (Supabase JOIN with businesses), providers (list + filter), ProductCard widget, ProductListScreen with category chips, MainScaffold with 4-tab bottom nav, router updated. |
| Product detail & reservation | 2026-04-19 | Order model & OrderStatus enum, `OrderRepository` with stock decrement logic, `orderProvider`s, `ProductDetailScreen` (hero, reserve button, confirmation sheet), `MyOrdersScreen` integrated to `MainScaffold`, `/product/:id` route added. |
| Business Panel | 2026-04-19 | `Business` model, `BusinessRepository`, Riverpod providers. `BusinessScaffold`, `BusinessDashboardScreen`, `BusinessOrdersScreen`, `ProductCreateScreen`, `BusinessSetupScreen`. Auth-aware routing for role='business'. `ImpactRepository` implemented for pickup tracking. |

**Scaffold deliverables:**
- `flutter create` with Android/iOS/Web platforms (`com.foodwasteapp`)
- `pubspec.yaml` — all packages pinned (Riverpod 2.x, GoRouter 14.x, Supabase Flutter 2.x, Freezed, etc.)
- Folder structure matching `docs/ARCHITECTURE.md` exactly
- Core files fully implemented:
  - `lib/main.dart` — env load → Supabase init → ProviderScope → App
  - `lib/app.dart` — MaterialApp.router + AppTheme
  - `lib/core/supabase_client.dart` — Supabase initializer
  - `lib/core/config/env.dart` — type-safe .env reader
  - `lib/core/config/constants.dart` — app constants with TODO markers
  - `lib/core/theme/` — AppColors, AppSpacing, AppTypography, AppTheme
  - `lib/core/routing/` — RouteNames, AppRouter (placeholder route)
  - `lib/core/errors/` — AppException sealed hierarchy, ErrorHandler (Turkish messages)
  - `lib/shared/formatters/price_formatter.dart` — Turkish lira formatter
  - `lib/shared/validators/email_validator.dart` — email validator
- 28 feature placeholder files created across auth, products, orders, businesses, map, profile
- `analysis_options.yaml` — strict lints + custom_lint plugin
- `.gitignore` — .env and legacy files appended
- `.env` — empty values file (gitignored)

### 🚧 In Progress

_Nothing currently in progress._

### 📋 Next Up

> **Recommended next task: Database Schema Migration (Sprint 1, Week 2)**

1. **Database schema migration** — Create `profiles`, `businesses`, `products`, `orders` tables in Supabase with RLS policies (update `docs/DATABASE_SCHEMA.md`).

### 🚫 Blockers

- `.env` values empty — developer must fill in `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_MAPS_API_KEY` before the app can run against a real backend.
- Supabase project not yet created — needed before auth sprint begins.

### 📝 Open Decisions (from PROJECT_CONTEXT.md)

| Decision | Status |
|----------|--------|
| Brand name | Pending |
| Dynamic pricing tiers (30%/50%/70% at 3h/2h/1h) | Pending team vote |
| Dynamic pricing trigger (auto vs business override) | Pending decision |
| Commission rate (10–15%) | Pending decision |
| Impact coefficients (0.8 kg/order, 2.5 kg CO₂) | Pending decision |

### 🆕 TODO Items Discovered During Scaffold

- `lib/core/config/constants.dart` — 4 TODO markers for pending team decisions
- `lib/core/routing/app_router.dart` — full auth-aware routing deferred to auth sprint
- `lib/core/widgets/` — folder created but no shared widgets implemented yet (first candidate: `PrimaryButton`, `LoadingIndicator`)
- `analysis_options.yaml` — `custom_lint` runs via `dart run custom_lint`; riverpod_lint rules active but require running codegen first
