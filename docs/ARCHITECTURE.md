# Architecture

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile framework | Flutter 3.38+ (stable) | Cross-platform (iOS + Android + Web) with single codebase. Team is new to mobile — Flutter's hot reload and widget model flatten the learning curve. |
| Language | Dart 3.10+ | Required by Flutter. Strong null safety catches entire class of runtime bugs. |
| Backend / Database | Supabase (Postgres + Auth + Storage + Edge Functions + Realtime) | BaaS with generous free tier. Replaces ~5 separate services (Auth, Postgres, file storage, serverless functions, realtime subscriptions). Row-Level Security eliminates most backend boilerplate. |
| State management | Riverpod 2.x | Compile-time safe, testable, scales well, strong AI agent support (well-documented). Chosen over Provider (legacy) and Bloc (overkill for project size). |
| Routing | go_router | Official Flutter routing package. Type-safe deep links, auth-aware redirects, web URL support. |
| Maps | Google Maps (google_maps_flutter) | Free tier sufficient for MVP. Alternative (Mapbox) adds complexity without clear benefit at our scale. |
| HTTP / Network | Supabase Flutter SDK handles all network calls | Direct SDK integration; no need for separate `dio` or `http` packages in MVP. |

## Core Architectural Principles

### 1. Feature-First Folder Structure
Every feature owns its own models, repositories, providers, and screens. Features do not reach into each other's internals — they communicate through shared models and public provider APIs only.

### 2. Repository Pattern (Mandatory)
No UI code talks to Supabase directly. All database access goes through a repository class. This is non-negotiable because:
- UI stays readable and testable
- Backend changes (e.g. Supabase query optimization) don't leak into UI
- Repositories can be mocked in tests without touching real database

### 3. Riverpod for All State
No `setState`, no `ChangeNotifier`, no `InheritedWidget`. All app state lives in Riverpod providers. This includes local UI state that spans multiple widgets.

Exception: ephemeral widget-local state (e.g. a text field's current value before submit) may use `StatefulWidget` + `setState`.

### 4. Thin UI Widgets
Screens and widgets should contain layout, styling, and event handlers only. Business logic lives in providers and repositories. If a widget has a function over ~20 lines of logic, extract it.

### 5. Single Source of Truth
For any piece of data, there is one provider that owns it. Other providers derive from it. No duplication of state.

## Folder Structure

```
lib/
├── main.dart
├── app.dart                      # App root widget, theme, routing setup
│
├── core/                         # Shared, cross-feature code
│   ├── supabase_client.dart      # Supabase singleton initialization
│   ├── config/
│   │   ├── env.dart              # Env variable reader (from .env)
│   │   └── constants.dart        # App-wide constants
│   ├── theme/
│   │   ├── app_theme.dart        # ThemeData configuration
│   │   ├── app_colors.dart       # Color palette (terracotta, etc.)
│   │   ├── app_typography.dart   # Text styles
│   │   └── app_spacing.dart      # Spacing scale
│   ├── routing/
│   │   ├── app_router.dart       # GoRouter configuration
│   │   └── route_names.dart      # Route name constants
│   ├── errors/
│   │   ├── app_exception.dart    # Custom exception types
│   │   └── error_handler.dart    # Centralized error-to-message mapping
│   └── widgets/                  # Truly shared widgets (primary button, loading indicator)
│
├── features/                     # One folder per feature
│   ├── auth/
│   │   ├── models/
│   │   │   └── app_user.dart
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── kvkk_consent_screen.dart
│   │
│   ├── products/
│   │   ├── models/
│   │   │   └── product.dart
│   │   ├── repositories/
│   │   │   └── product_repository.dart
│   │   ├── providers/
│   │   │   ├── product_list_provider.dart
│   │   │   └── product_detail_provider.dart
│   │   └── screens/
│   │       ├── product_list_screen.dart
│   │       ├── product_detail_screen.dart
│   │       └── widgets/
│   │           └── product_card.dart
│   │
│   ├── orders/
│   │   ├── models/
│   │   │   ├── order.dart
│   │   │   └── order_status.dart   # Enum: pending, confirmed, pickedUp, cancelled
│   │   ├── repositories/
│   │   │   └── order_repository.dart
│   │   ├── providers/
│   │   │   └── order_provider.dart
│   │   └── screens/
│   │       ├── reservation_screen.dart
│   │       └── my_orders_screen.dart
│   │
│   ├── businesses/
│   │   ├── models/
│   │   │   └── business.dart
│   │   ├── repositories/
│   │   │   └── business_repository.dart
│   │   ├── providers/
│   │   │   └── business_provider.dart
│   │   └── screens/
│   │       ├── business_dashboard_screen.dart
│   │       ├── product_create_screen.dart
│   │       └── business_orders_screen.dart
│   │
│   ├── map/
│   │   └── screens/
│   │       └── map_screen.dart
│   │
│   └── profile/
│       ├── providers/
│       │   └── impact_provider.dart
│       └── screens/
│           ├── profile_screen.dart
│           └── impact_dashboard_screen.dart
│
└── shared/                       # Cross-feature pure utilities (formatters, validators)
    ├── formatters/
    │   └── price_formatter.dart
    └── validators/
        └── email_validator.dart
```

## Data Flow

```
┌──────────┐     reads/writes     ┌──────────────┐      calls       ┌────────────┐
│  Screen  │ ───────────────────▶ │   Provider   │ ───────────────▶ │ Repository │
│ (Widget) │                      │  (Riverpod)  │                  │   (class)  │
└──────────┘ ◀──────────────────  └──────────────┘ ◀─────────────── └────────────┘
             reactive rebuilds                      returns Model         │
                                                                          │ queries
                                                                          ▼
                                                                    ┌──────────┐
                                                                    │ Supabase │
                                                                    └──────────┘
```

**Rules:**
- Screen only depends on providers (via `ref.watch`)
- Provider only depends on other providers or repositories
- Repository only depends on Supabase SDK and models
- Repository NEVER returns raw Supabase types — always converts to domain models
- Model classes are pure Dart (no dependencies on Flutter, Supabase, or Riverpod)

## Model Layer Rules

Every model class lives in `features/<feature>/models/` and must have:

1. `fromJson(Map<String, dynamic>)` factory — parses from Supabase response
2. `toJson()` method — serializes to Supabase insert/update format
3. `copyWith(...)` method — creates modified copy for state updates
4. Immutable fields (all `final`)
5. Equality via `operator ==` and `hashCode` (use `equatable` package if simpler)

Models are pure data. No business logic, no async methods. Business logic belongs in providers.

## Repository Layer Rules

Every repository class:

1. Takes `SupabaseClient` as a constructor dependency (never imports the global singleton directly)
2. Returns `Future<T>` or `Stream<T>` — never void unless genuinely fire-and-forget
3. Throws domain-specific exceptions (`AuthException`, `NetworkException`) instead of raw `PostgrestException`
4. Does NOT cache results — caching is the provider's job
5. Does NOT make UI decisions (showing snackbars, navigating) — returns data, throws exceptions

Example repository skeleton (do not treat as final code — see CONVENTIONS.md for style):

```dart
class ProductRepository {
  ProductRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<List<Product>> getActiveProducts({double? userLat, double? userLng}) async {
    try {
      final data = await _supabase
        .from('products')
        .select('*, businesses(name, location)')
        .eq('status', 'active')
        .gt('stock', 0)
        .order('created_at', ascending: false);
      return data.map((json) => Product.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw NetworkException('Failed to load products: ${e.message}');
    }
  }
}
```

## Provider Layer Rules

Use Riverpod's new syntax (`@riverpod` annotation with code generation) where it reduces boilerplate. Otherwise use manual `Provider`, `StateProvider`, `FutureProvider`, `StreamProvider`, `NotifierProvider`.

- **Read-only data** → `FutureProvider` or `StreamProvider`
- **Mutable app state** → `NotifierProvider`
- **Derived values** → `Provider` with `ref.watch` dependencies
- **Repositories** → `Provider` (they're stateless, just inject them)

Providers should be named by what they expose, not by technical type:
- `currentUserProvider` (not `authNotifierProvider`)
- `productListProvider` (not `productFutureProvider`)

## Authentication Flow

1. App launch → `main.dart` initializes Supabase → runs app
2. `app.dart` watches `authStateProvider` (Stream from `Supabase.instance.client.auth.onAuthStateChange`)
3. `GoRouter` redirect logic:
   - Unauthenticated user → `/login`
   - Authenticated user → last intended route or `/home`
4. Login/register calls `AuthRepository.signIn()` / `signUp()` → auth state updates automatically via Supabase listener → router redirects

## Error Handling

Three layers:

1. **Repository** throws typed exceptions (`AuthException`, `NetworkException`, `ValidationException`)
2. **Provider** catches exceptions, exposes them via `AsyncValue.error` (or equivalent state)
3. **UI** reads `AsyncValue` and displays appropriate message via centralized `ErrorHandler`

Never show raw exception messages to users. `ErrorHandler.toUserMessage(exception)` returns localized, friendly text.

## Environment Configuration

Environment-specific values (Supabase URL, anon key) live in `.env` file at project root:

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

Read via `flutter_dotenv` package. `.env` is gitignored. A `.env.example` file (committed) shows required variables with placeholder values.

**Never hardcode credentials in source code. Ever.**

## Testing Strategy (MVP-scope)

- **Unit tests:** Model serialization, validators, pure business logic in providers
- **Repository tests:** Use `supabase_flutter` in-memory fakes
- **Widget tests:** Deferred for MVP — focus on manual testing first

Test files mirror source structure: `test/features/auth/repositories/auth_repository_test.dart`

## What NOT to Do

- **No global singletons** except the Supabase client (and even that is injected into repositories, not imported everywhere)
- **No logic in `build` methods** beyond reading providers and building widgets
- **No mixed state management** (no `setState` in widgets that also use Riverpod for the same state)
- **No hardcoded strings in UI** for things that might need translation later (use a central `Strings` class or constants file)
- **No inline colors or text styles** — always use theme (`Theme.of(context).colorScheme.primary`) or constants from `app_colors.dart`
- **No deep folder nesting** beyond `features/<feature>/<layer>/<file>.dart`
