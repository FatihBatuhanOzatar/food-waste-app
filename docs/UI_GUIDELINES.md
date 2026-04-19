# UI Guidelines

Design system derived from the approved Stitch mockups (see `docs/designs/` for reference screenshots). Every screen the agent builds must follow these rules.

## Design Reference Files

Screenshots of approved designs live in `docs/designs/`:
- `login.png` — Login screen
- `register.png` — Registration screen (user + business toggle)
- `kvkk_consent.png` — KVKK privacy consent screen
- `home_explore.png` — Home/explore screen (user side)
- `business_dashboard.png` — Business owner dashboard

When implementing a screen, the agent MUST open the corresponding design file and match it visually.

## Color System

### Brand Colors (defined in `core/theme/app_colors.dart`)

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#C1440E` | Buttons, active nav tabs, price highlights, toggle active state, links |
| `onPrimary` | `#FFFFFF` | Text on primary-colored surfaces |
| `background` | `#F5F0EB` | Page background (warm beige) |
| `surface` | `#FFFFFF` | Card backgrounds, input field backgrounds |
| `onBackground` | `#2C1A0E` | Primary text color (dark brown) |
| `onSurface` | `#2C1A0E` | Text on white cards |
| `secondary` | `#E8A090` | Light terracotta for subtle accents, disabled states |
| `outline` | `#D6CFC4` | Input field borders, dividers |
| `surfaceVariant` | `#F0E8E0` | Category chip unselected background, subtle contrast areas |
| `error` | `#B91C1C` | Error messages, destructive actions |
| `semanticGreen` | `#059669` | "Aktif" status badge, impact metrics, positive states |
| `semanticAmber` | `#D97706` | Countdown timer badge, "Acil" urgency indicator |
| `semanticRed` | `#DC2626` | "Tükendi" badge, order rejection |

### Color Rules
- **Never use green as a primary or accent color.** Green is reserved exclusively for status badges ("Aktif") and impact metrics.
- **Terracotta (#C1440E) is the only primary accent.** If something needs emphasis, it's terracotta.
- **Dark brown (#2C1A0E) is the text color**, not black (#000000). Pure black is too harsh against beige.
- **Beige (#F5F0EB) is the page background**, not white. White is for cards and input fields only.

## Typography

### Scale (using system font / default Flutter font)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineLarge` | 28px | Bold (700) | Screen titles ("Hesap Oluştur") |
| `headlineMedium` | 24px | Bold (700) | Section headers ("Merhaba, Ahmet Usta") |
| `titleLarge` | 20px | SemiBold (600) | Card titles, product names |
| `titleMedium` | 16px | SemiBold (600) | Subsection headers, button text |
| `bodyLarge` | 16px | Regular (400) | Primary body text, input field text |
| `bodyMedium` | 14px | Regular (400) | Secondary text, descriptions |
| `bodySmall` | 12px | Regular (400) | Captions, timestamps, helper text |
| `labelLarge` | 14px | Medium (500) | Button labels, chip labels |
| `labelSmall` | 11px | Medium (500) | Badges, status tags |

### Typography Rules
- All text color is `onBackground` (#2C1A0E) unless on a colored surface.
- Prices use `titleLarge` in `primary` color. Original (crossed out) prices use `bodyMedium` with `decoration: TextDecoration.lineThrough` in gray.
- Turkish characters (ı, ğ, ş, ç, ö, ü, İ) must render correctly — test with sample strings.

## Spacing

8-point grid system (defined in `core/theme/app_spacing.dart`):

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4px | Tight gaps (between icon and label in a badge) |
| `sm` | 8px | Between related elements (checkbox and its label) |
| `md` | 16px | Standard spacing (between cards, between form fields) |
| `lg` | 24px | Section spacing (between section title and content) |
| `xl` | 32px | Major section breaks |
| `xxl` | 48px | Top padding on screens, large decorative spacing |

### Spacing Rules
- Screen horizontal padding: `md` (16px) on both sides.
- Card internal padding: `md` (16px).
- Between form fields: `md` (16px).
- Between a section header and its content: `sm` (8px).
- Bottom navigation bar height: 64px with `sm` (8px) internal padding.

## Component Patterns

### Buttons

**Primary Button** (e.g., "Giriş Yap", "Kayıt Ol", "Rezerve Et"):
- Full width (`double.infinity`)
- Height: 52px
- Background: `primary` (#C1440E)
- Text: `onPrimary`, `labelLarge` (14px medium)
- Border radius: 12px
- No shadow/elevation (flat design)

**Outlined Button** (e.g., "Google ile Giriş Yap"):
- Full width
- Height: 52px
- Background: transparent
- Border: 1px `outline` (#D6CFC4)
- Text: `onBackground`, `labelLarge`
- Border radius: 12px

**Disabled Button** (e.g., "Devam Et" before KVKK checkboxes):
- Same dimensions as primary
- Background: `secondary` (#E8A090) at 50% opacity or `surfaceVariant`
- Text: gray

**Text Button / Link** (e.g., "Şifremi Unuttum", "Kayıt Ol"):
- No background, no border
- Text: `primary` (#C1440E), `bodyMedium`
- Underline: none (color alone indicates tappability)

### Input Fields

- Background: `surface` (#FFFFFF)
- Border: 1px `outline` (#D6CFC4), radius 12px
- Focus border: 1.5px `primary` (#C1440E)
- Height: 52px
- Padding: horizontal `md` (16px)
- Label: above the field, `bodyMedium`, `onBackground`
- Hint text: `bodyLarge`, gray (#9E9E9E)
- Prefix icon: left-aligned, 20px, gray
- Suffix icon (e.g., password visibility toggle): right-aligned, 20px, gray

### Cards

**Product Card** (home screen listing):
- Background: `surface` (#FFFFFF)
- Border radius: 12px
- Subtle shadow: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2))`
- Image: left side, square (80x80), radius 8px, `BoxFit.cover`
- Padding: `md` (16px)
- Content: product name (titleMedium), business name + distance (bodySmall, gray), price row, countdown badge

**Summary Card** (business dashboard):
- Background: `surface` (#FFFFFF) or `primary` for highlighted card
- Border radius: 12px
- Icon: top-left, 24px, colored circle background
- Value: `headlineMedium` (24px bold)
- Label: `bodySmall` (12px)
- When highlighted (e.g., "Bekleyen Siparişler" with pending orders): `primary` background, white text

### Category Chips

- Unselected: background `surfaceVariant`, text `onBackground`, radius 20px (pill shape)
- Selected: background `primary`, text `onPrimary`, radius 20px
- Height: 36px
- Horizontal padding: `md` (16px)
- Horizontal gap between chips: `sm` (8px)
- Horizontal scroll, no wrap

### Status Badges

- "Aktif": background `semanticGreen` at 15% opacity, text `semanticGreen`, `labelSmall`
- "Tükendi": background gray at 15% opacity, text gray
- "Acil": background `semanticAmber` at 15% opacity, text `semanticAmber`
- "Sürpriz Kutu" / "Menü": background `primary` at 10% opacity, text `primary`
- Border radius: 6px
- Padding: horizontal 8px, vertical 4px

### Countdown Badge

- Background: `semanticAmber` at 10% opacity
- Text: `semanticAmber`, `bodySmall`
- Icon: clock icon, 14px, `semanticAmber`
- Border radius: 8px
- Format: "1s 23dk sonra ₺12'ye düşecek"

### Bottom Navigation Bar

- Background: `surface` (#FFFFFF)
- Height: 64px
- Items: 4 tabs
- Active: `primary` color icon + label, filled circle behind icon (or dot indicator)
- Inactive: gray icon + label
- Label: `labelSmall` (11px)
- No shadow from below — use top border: 0.5px `outline`

**User app tabs:** Keşfet, Siparişlerim, Etkim, Profil
**Business app tabs:** Panel, Ürünlerim, Siparişler, Profil

### Toggle / Segmented Control

- Used on register screen ("Kullanıcı" / "İşletme")
- Background: `surfaceVariant`
- Selected segment: `primary` background, `onPrimary` text
- Unselected segment: transparent, `onBackground` text
- Border radius: 12px (outer), 10px (inner segments)
- Height: 44px

### Checkbox

- Unchecked: 20x20, border 1.5px `outline`, radius 4px, transparent fill
- Checked: `primary` fill, white checkmark, radius 4px

### Divider with Text

- Used on login ("veya")
- Thin line (0.5px, `outline`) with centered text (`bodySmall`, gray)
- Horizontal padding: `md` (16px) between line ends and text

## Screen Layout Template

Every screen should follow this general structure:

```dart
Scaffold(
  backgroundColor: AppColors.background,  // #F5F0EB beige
  appBar: ...,  // or custom top bar
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),  // 16px
      child: Column / SingleChildScrollView(
        children: [
          // Content
        ],
      ),
    ),
  ),
  bottomNavigationBar: ...,  // only on main screens, not auth flow
)
```

### Auth screens (login, register, KVKK):
- No bottom navigation bar
- No app bar (custom back arrow where needed)
- Vertically centered or top-aligned with generous top padding
- Keyboard-aware (use `SingleChildScrollView` to prevent overflow when keyboard opens)

### Main app screens (home, orders, profile):
- Bottom navigation bar present
- Custom top bar (not standard AppBar) with greeting or title
- Content scrollable

### Business screens (dashboard, products, orders):
- Bottom navigation bar present (different tabs than user)
- Business name in top bar
- Dashboard-style layout with summary cards

## Responsive Behavior

- Design for 375px width (iPhone SE) as minimum
- Cards and inputs are full-width (minus 32px total horizontal padding)
- Images in cards are fixed size (80x80 in lists, full-width in detail)
- Bottom sheet modals (for confirmations) span full width with 16px padding

## Animation & Transitions

- Page transitions: default Material fade/slide (GoRouter handles this)
- Button press: subtle scale down (0.98) with 100ms duration
- Card tap: subtle opacity change (0.7) on press
- Countdown timer: text updates every second, no visual animation (just text change)
- Loading states: `CircularProgressIndicator` in `primary` color, centered
- Skeleton screens: gray shimmer placeholders while data loads (use `shimmer` package if needed)

## Accessibility

- All tappable elements: minimum 44x44px hit area
- Color contrast: dark brown on beige passes WCAG AA (ratio > 4.5:1)
- Images: `Semantics` label on all product images
- Form fields: `labelText` always present (not just hint)
- Error messages: red text below the field, not just border color change

## What NOT to Do

- No gradients anywhere (flat surfaces only)
- No drop shadows heavier than the card shadow defined above
- No rounded corners over 16px (except pill-shaped chips at 20px)
- No pure black (#000000) text — always dark brown (#2C1A0E)
- No pure white (#FFFFFF) backgrounds on screens — always beige (#F5F0EB), white is for cards only
- No green accent usage outside status badges and impact metrics
- No custom fonts in MVP — system font only
- No hero images or splash illustrations — clean typographic layout
