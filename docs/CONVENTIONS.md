# Code Conventions

Agents and contributors must follow these conventions. They are not suggestions.

## File & Folder Naming

- **Files:** `snake_case.dart` — `product_list_screen.dart`, `auth_repository.dart`
- **Folders:** `snake_case` — `features/auth/`, `core/theme/`
- **One class per file.** File name matches class name in snake_case:
  - `class ProductRepository` lives in `product_repository.dart`
- **Exception:** Small, tightly-coupled classes (e.g. a sealed class hierarchy) may share a file.

## Dart Naming

| Construct | Convention | Example |
|-----------|-----------|---------|
| Class | `UpperCamelCase` | `ProductRepository` |
| Enum | `UpperCamelCase` | `OrderStatus` |
| Enum value | `lowerCamelCase` | `OrderStatus.pickedUp` |
| Variable / parameter | `lowerCamelCase` | `currentPrice` |
| Constant | `lowerCamelCase` (for `final`) or `SCREAMING_SNAKE` (for top-level `const`) | `final productList`, `const MAX_STOCK = 999` |
| Function / method | `lowerCamelCase` | `calculateDynamicPrice()` |
| Private | `_leadingUnderscore` | `_supabase`, `_parseResponse()` |

## Imports

Order imports in this order, separated by blank lines:

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party packages (alphabetical)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Project imports (relative paths, alphabetical)
import '../models/product.dart';
import '../providers/product_provider.dart';
```

Prefer `package:` imports for project files when the relative path is deep or ambiguous.

## Null Safety

- **Never** use `!` (null assertion) without a comment explaining why it's safe.
- Prefer `?? defaultValue` or `if (x != null) { ... }` over `x!`.
- If a variable is nullable only because it's late-initialized, consider `late` instead of `?`.

## Async Code

- Always `await` a `Future`. If you're fire-and-forgetting on purpose, prefix with `unawaited()` from `dart:async`.
- Prefer `async`/`await` over `.then()` chains.
- In repositories, catch specific exception types (`PostgrestException`, `AuthException`), not generic `Exception` or `dynamic`.

## Error Handling

1. **Repositories** throw typed exceptions from `core/errors/app_exception.dart`. Never return `null` to indicate failure.
2. **Providers** wrap repository calls in `AsyncValue` (via Riverpod's `FutureProvider` or explicit try/catch in notifiers).
3. **UI** reads `AsyncValue.when(data:, loading:, error:)` — never accesses `.value` without checking.

Forbidden:
```dart
// ❌ Swallowing errors
try { await repo.load(); } catch (_) {}

// ❌ Showing raw error to user
Text('Error: ${error.toString()}')

// ❌ Generic catch
try { ... } catch (e) { print(e); }
```

Required:
```dart
// ✅ Typed catch, re-throw as app exception
try {
  await _supabase.from('products').select();
} on PostgrestException catch (e) {
  throw NetworkException('Failed to load: ${e.message}');
}

// ✅ AsyncValue.when in UI
final asyncProducts = ref.watch(productListProvider);
return asyncProducts.when(
  data: (products) => ProductList(products),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => ErrorView(ErrorHandler.toUserMessage(e)),
);
```

## Widgets

- Prefer `const` constructors wherever possible.
- Extract repeated inline widgets into named widgets (not private methods). Named widgets are testable and composable; private methods that return `Widget` are not.
- Avoid deep widget trees in a single build method — extract when nesting exceeds ~4 levels.
- Use `StatelessWidget` unless local state is absolutely necessary.

## State Management (Riverpod)

- Use `ref.watch` in build methods for reactive reads.
- Use `ref.read` in callbacks (button presses) for one-shot reads.
- Use `ref.listen` for side effects (navigation, snackbars) in response to state changes.
- Prefer `@riverpod` code generation annotations over manual `Provider(...)` declarations when using Riverpod 2.x.
- Keep providers focused: one responsibility per provider.

## Hardcoding Rules

Never hardcode:
- **Colors** → use `AppColors` from `core/theme/app_colors.dart` or `Theme.of(context).colorScheme.*`
- **Text styles** → use `Theme.of(context).textTheme.*` or `AppTypography`
- **Spacing values** → use `AppSpacing` constants (`AppSpacing.sm = 8`, `AppSpacing.md = 16`, etc.)
- **Supabase credentials** → read from `.env` via `flutter_dotenv`
- **Business logic constants** (commission rate, dynamic pricing tiers, impact coefficients) → put in `core/config/constants.dart` with clear `TODO` comments for pending decisions
- **User-facing strings** → put in a central `AppStrings` class (prepares for future localization even if MVP is Turkish-only)

## Comments & Documentation

- **DartDoc (`///`)** on every public class, method, and complex function.
- **Inline comments (`//`)** only for non-obvious logic — not for restating what code does.
- **`TODO:` comments** for pending decisions, with owner or ticket reference:
  ```dart
  // TODO: Pending team decision on commission rate (10-15%).
  const commissionRate = 0.10;
  ```

## Git Commit Messages

Format:
```
<type>(<scope>): <short description>

<optional longer description>
```

Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`

Examples:
- `feat(auth): add KVKK consent flow`
- `fix(products): prevent duplicate reservations when stock hits 0`
- `refactor(orders): extract status transition logic to dedicated service`
- `docs(readme): update setup instructions for Windows`

**Commit small. One logical change per commit.** Don't bundle unrelated fixes.

## Testing Conventions

- Test files mirror source: `lib/features/auth/repositories/auth_repository.dart` → `test/features/auth/repositories/auth_repository_test.dart`
- Use `group()` for class, nested `group()` for method, `test()` for individual cases.
- Test names: `should <expected behavior> when <condition>` — e.g., `should throw NetworkException when Supabase returns 500`.

## Formatting

- Run `dart format .` before every commit. Use 2-space indentation (Dart default).
- Line length: 100 characters (Dart default 80 is too tight for modern screens).

## Forbidden Patterns

- **`print()` in production code** — use `dart:developer`'s `log()` or a proper logging package
- **`setState` in widgets that also use Riverpod** — pick one
- **Global mutable state** — no top-level `var` that gets mutated
- **`StatelessWidget` with `late` fields** — defeats the purpose of stateless
- **Magic numbers** — extract to named constants
- **Long parameter lists (>4)** — use a dedicated class or `copyWith` pattern
- **Excessive abbreviations** — `ProductRepo` is fine, `PrdRp` is not

## Language

- **Code (variables, functions, comments):** English only, always.
- **User-facing strings in the app:** Turkish (MVP is Turkish-first).
- **Documentation files (`.md`):** English.
- **Commit messages:** English.
