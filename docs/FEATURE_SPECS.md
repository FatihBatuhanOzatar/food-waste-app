# Feature Specifications

## Auth (US-01, US-02, US-03)

### Files Created/Modified
- `lib/features/auth/models/app_user.dart`: Model representing the user.
- `lib/features/auth/repositories/auth_repository.dart`: Supabase interaction logic.
- `lib/features/auth/providers/auth_provider.dart`: State management providers for auth logic.
- `lib/features/auth/screens/login_screen.dart`: Login UI.
- `lib/features/auth/screens/register_screen.dart`: Registration UI with role segmentation.
- `lib/features/auth/screens/kvkk_consent_screen.dart`: Mandatory KVKK consent UI.
- `lib/features/auth/screens/home_placeholder_screen.dart`: Temporary post-login fallback UI.
- `lib/core/routing/app_router.dart`: Added routing guards for authenticated logic, KVKK redirection, and auth provider synchronization.
- `lib/core/widgets/app_button.dart` & `lib/core/widgets/app_text_field.dart`: Reusable UI elements for forms.
- `c:\Users\Batzatar\Desktop\foodwasteapp\.env`: Values filled for SUPABASE configuration.

### Implementation Details & Decisions Made
- All Supabase communications are isolated strictly within `auth_repository.dart`.
- Any non-MVP functionalities in screens, such as "Sign in with Google", show a snack bar without logic.
- Reusable UI elements like buttons and text fields abstracted to `core/widgets/`.
- During registration as a business, business-specific data points are collected locally but not stored in `businesses` table yet, adhering to the constraint of keeping this phase local.
- `KVKK` screening logic uses a flag `hasAcceptedKvkk` fetched from the `profiles` table to lock users into a redirect loop until accepted.
- Passwords and emails perform client-side format and length checking using Riverpod's native logic handling (or UI level checks).

### Edge Cases Handled
- Ensuring router blocks access to `home` if `kvkk_accepted_at` is null.
- Handling login while fetching profile row natively in `AuthRepository`.

### Future TODOs
- Add real legal text to `kvkk_consent_screen.dart`.
- Replace `home_placeholder_screen.dart` with the actual home screen when ready.
- Store business registration form data to `businesses` table upon feature addition.
- Enable Google Auth.
- Configure password reset.

## Home / Product List (Product Discovery)

### Files Created/Modified
- `lib/features/products/models/product.dart`: Full Product model with `fromJson` handling nested `businesses` JOIN.
- `lib/features/products/repositories/product_repository.dart`: Supabase queries with `select('*, businesses(name, latitude, longitude)')`.
- `lib/features/products/providers/product_list_provider.dart`: `productRepositoryProvider`, `productListProvider`, `selectedCategoryProvider`, `filteredProductListProvider`.
- `lib/features/products/providers/product_detail_provider.dart`: `productDetailProvider` (FutureProvider.family).
- `lib/features/products/screens/product_list_screen.dart`: Full home screen with greeting, search bar, category chips, Harita/Liste toggle, product list.
- `lib/features/products/screens/widgets/product_card.dart`: Reusable product card with countdown timer, price display, and action buttons.
- `lib/core/widgets/main_scaffold.dart`: Bottom navigation scaffold with 4 tabs (Keşfet, Siparişlerim, Etkim, Profil).
- `lib/core/routing/app_router.dart`: `/home` route now uses `MainScaffold` instead of `HomePlaceholderScreen`.

### Implementation Details & Decisions Made
- Supabase query JOINs products with businesses table to get business name and location in a single query.
- Category chips map Turkish labels to database values: Fırın→bread, Kafe→drink, Pastane→pastry,dessert (comma-separated), Sürpriz Kutu→surprise_box (filters by listing_type).
- Countdown timer updates every 60 seconds via `Timer.periodic`. Format: "Xs Ydk kaldı" / "Ydk kaldı" / "Süre doldu".
- Bottom nav uses `IndexedStack` to preserve tab state across switches.
- Custom bottom nav (not `BottomNavigationBar`) to match UI_GUIDELINES spec exactly — white bg, top border, terracotta active.
- All non-functional features (search, map, reserve, favorite) show Turkish SnackBar messages.
- Image placeholders use category-specific Material Icons on light terracotta background.

### Non-functional Placeholders (with SnackBars)
- Search bar → "Arama yakında eklenecek"
- Harita toggle → "Harita görünümü yakında eklenecek"
- Ayır button → "Rezervasyon yakında eklenecek"
- Heart/favorite → visual only, no action

### TODO Comments Added
- `product_card.dart`: Replace hardcoded "350m" with real distance calculation (Haversine).
- `product_card.dart`: Implement actual dynamic price tier countdown format.
- `product_detail_provider.dart`: Add live-updating dynamic price calculation.

### Future TODOs
- Implement real search functionality.
- Implement map view (Google Maps integration).
- Add reservation flow from "Ayır" button.
- Real distance calculation using user's GPS location.
- Dynamic pricing recalculation based on time tiers.
- Product image loading from Supabase storage.

## Product Detail & Reservation Flow

### Files Created/Modified
- `lib/features/orders/models/order.dart` & `order_status.dart`: Enum and Model mapping to Supabase structure with JOIN capabilities.
- `lib/features/orders/repositories/order_repository.dart`: DB ops for creating/canceling reservations and updating statuses while keeping stock in sync.
- `lib/features/orders/providers/order_provider.dart`: `orderRepositoryProvider`, `userOrdersProvider` and `orderActionProvider`.
- `lib/features/products/screens/product_detail_screen.dart`: Complete detail view with info matching UI_GUIDELINES and confirmation bottom sheet.
- `lib/features/orders/screens/my_orders_screen.dart`: View for user's past/active orders with pull-to-refresh.
- `lib/features/products/screens/widgets/product_card.dart`: Tap handler added.
- `lib/core/widgets/main_scaffold.dart`: Added `MyOrdersScreen` to the second tab.
- `lib/core/routing/app_router.dart`: Added route path `/product/:id`.

### Implementation Details & Decisions Made
- `OrderStatus` explicitly parses db snake_case enum values and provides Turkish translations.
- `OrderRepository.createReservation` handles inventory decrement concurrently. Transaction limitations noted in TODO.
- The `OrderNotifier` manages creating/canceling orders and triggers invalidation on `userOrdersProvider` and `productListProvider` since stock availability changes.
- In `ProductDetailScreen`, `use_build_context_synchronously` is handled by checking `sheetContext.mounted` to pop sheets safely after async work.
- Tapping a product card delegates to GoRouter.

### TODO Comments Added
- `order_repository.dart`: Note about lacking full transactional safety leading to race conditions on the last stock.
- `product_detail_screen.dart`: Placeholder for actual distance calculation logic.

## Business Panel (US-11 to US-18)

### Files Created/Modified
- `lib/features/businesses/models/business.dart`: `Business` model mapping to `businesses` table.
- `lib/features/businesses/repositories/business_repository.dart`: DB ops for business profiles and dashboard stats.
- `lib/features/profile/repositories/impact_repository.dart`: DB ops for `impact_logs`.
- `lib/features/products/repositories/product_repository.dart`: Added `getBusinessProducts`, `createProduct`, `updateProduct`, `deleteProduct`.
- `lib/features/orders/providers/order_provider.dart`: Added `businessOrdersProvider`.
- `lib/features/products/providers/product_list_provider.dart`: Added `businessProductsProvider`.
- `lib/features/businesses/providers/business_provider.dart`: `myBusinessProvider`, `dashboardStatsProvider`, `BusinessNotifier`.
- `lib/core/widgets/business_scaffold.dart`: Parallel to `MainScaffold` but for business role (Panel, Ürünlerim, Siparişler, Profil).
- `lib/features/businesses/screens/business_dashboard_screen.dart`: Dashboard with metrics and active products.
- `lib/features/businesses/screens/business_orders_screen.dart`: Order management with tabbed filtering by status.
- `lib/features/businesses/screens/business_setup_screen.dart`: Business setup and onboarding form.
- `lib/features/businesses/screens/product_create_screen.dart`: Form to create/edit products.
- `lib/core/routing/app_router.dart`: Added business routes and role checking to protect business/customer domains.
- `lib/core/routing/route_names.dart`: Added new business route keys.

### Implementation Details & Decisions Made
- Routing explicitly checks `user.role` to redirect users out of `/business` and businesses out of `/home`.
- On entering `/business`, if `myBusinessProvider` returns `null`, the router redirects to `/business/setup`.
- Dashboard stats aggregate data natively from Supabase queries in `business_repository.dart`.
- Business Orders separates lists into Tabs (`Bekleyen`, `Onaylanan`, `Tamamlanan`, `Tümü`) and filters memory-side using `businessOrdersProvider`.
- Upon successful order pickup, an impact log is recorded using `ImpactRepository.createImpactLog`.
- Shared `BusinessDashboardScreen` UI handles the `Ürünlerim` independent tab through the `productsOnly=true` layout variation.

### Edge Cases Handled
- Validated that `pickupEnd` must be chronologically after `pickupStart` in `product_create_screen`.
- Implemented `AutoDispose` logic securely within providers, avoiding state retention across unintended sessions.

### Future TODOs
- Replace hardcoded coordinate creation in `BusinessSetupScreen` with real map point integration.
- Implement storage interaction for `ProductCreateScreen` image attachments.
- Pending final formula variables team vote for environmental impact coefficients used in `ImpactRepository`.
