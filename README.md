# Food Waste App

A mobile marketplace connecting university-area bakeries and cafes with nearby users (primarily students) to reduce food waste by selling end-of-day surplus at a discount.

**Status:** MVP in development (6-week timeline, course project at Istanbul University).

## Tech Stack

- **Mobile:** Flutter 3.38+ / Dart 3.10+
- **State management:** Riverpod 2.x
- **Routing:** go_router
- **Backend:** Supabase (Postgres + Auth + Storage + Edge Functions)
- **Maps:** Google Maps (google_maps_flutter)
- **Design:** Google Stitch → Figma → Flutter

## Project Documentation

All architectural and product decisions are documented. Read these before contributing:

| File | Purpose |
|------|---------|
| [`docs/PROJECT_CONTEXT.md`](docs/PROJECT_CONTEXT.md) | What the project is, why, for whom, scope |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Tech stack, folder structure, patterns |
| [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) | Supabase tables, RLS policies, migrations |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | Code style, naming, formatting rules |
| [`.antigravity/RULES.md`](.antigravity/RULES.md) | Non-negotiable rules for AI agents |

Additional docs will be added as the project progresses:
- `docs/UI_GUIDELINES.md` (after first Stitch designs)
- `docs/FEATURE_SPECS.md` (per-feature detailed specs)
- `docs/CURRENT_SPRINT.md` (active sprint plan)

## Setup

### Prerequisites
- Flutter SDK 3.38+ ([install](https://docs.flutter.dev/get-started/install))
- Android Studio with Android SDK (for Android builds)
- A Supabase project ([create one](https://supabase.com))

### Configuration

1. Copy `.env.example` to `.env`:
   ```
   cp .env.example .env
   ```

2. Fill in your Supabase credentials in `.env`:
   ```
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Apply database migrations to your Supabase project:
   - Run the SQL files in `supabase/migrations/` in order via the Supabase SQL editor.

### Running

```
flutter run           # Runs on connected device or emulator
flutter run -d chrome # Runs in web browser for quick testing
```

## Development Workflow

The team uses:
- **Scrumban** methodology, 1-week sprints
- **Jira** for task tracking
- **GitHub** for version control, branch protection on `main`
- **Antigravity (with Claude Sonnet 4.6)** for AI-assisted coding

## Contributing

1. Read `docs/PROJECT_CONTEXT.md` and `docs/ARCHITECTURE.md` first.
2. Create a feature branch from `main`: `git checkout -b feat/your-feature`.
3. Follow all rules in `docs/CONVENTIONS.md`.
4. Ensure `flutter analyze` and `flutter test` pass before opening a PR.
5. Small, focused commits. See `CONVENTIONS.md` for commit message format.

## License

Private / academic use only (for now).
