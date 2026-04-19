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
