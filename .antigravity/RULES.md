# Agent Rules

These are non-negotiable rules the agent must follow for every task in this project. Read this file at the start of every task.

## Document Precedence

When writing or modifying code, the agent MUST consult documentation in this order:

1. **`.antigravity/RULES.md`** (this file) — absolute rules
2. **`docs/CURRENT_SPRINT.md`** — what's in scope right now
3. **Task-specific docs:**
   - For UI work: `docs/UI_GUIDELINES.md` + `docs/FEATURE_SPECS.md`
   - For backend/data work: `docs/DATABASE_SCHEMA.md` + `docs/ARCHITECTURE.md`
   - For any new feature: `docs/PROJECT_CONTEXT.md` + `docs/FEATURE_SPECS.md`
4. **`docs/CONVENTIONS.md`** — style rules, always apply
5. **`docs/ARCHITECTURE.md`** — structural rules, always apply

If a task contradicts documentation, STOP and ask for clarification rather than guessing.

## Forbidden Actions

The agent must NEVER:

1. **Commit secrets to git.** No Supabase keys, no API tokens, no passwords in source files. All credentials go in `.env` (gitignored).
2. **Hardcode values that should be configurable.** Dynamic pricing tiers, commission rates, impact coefficients, etc. — put in `core/config/constants.dart` with `TODO` comments.
3. **Skip RLS policies.** Every new table must have RLS enabled and policies defined before use.
4. **Add a package without asking.** New dependencies must be approved. Justify why the existing stack can't solve the problem.
5. **Break the repository pattern.** No UI code calls Supabase directly. Ever.
6. **Mix state management.** If a feature uses Riverpod, don't add `setState` for the same state.
7. **Write code for features not in the current sprint.** Check `CURRENT_SPRINT.md`. Out-of-scope work creates bloat and bugs.
8. **Delete tests or documentation without explicit approval.**
9. **Use raw SQL in Flutter code.** All database access through Supabase SDK methods.
10. **Commit broken or unformatted code.** Run `dart format .` and `dart analyze` before committing.

## Required Actions

The agent MUST:

1. **Read documentation before coding.** Don't invent file structures or patterns when they're specified in `docs/`.
2. **Follow the feature-first folder structure** exactly as defined in `ARCHITECTURE.md`.
3. **Use typed exceptions** from `core/errors/app_exception.dart`. Never throw generic `Exception`.
4. **Write DartDoc comments** on all public APIs (classes, methods, non-trivial functions).
5. **Add `TODO` comments for pending team decisions** instead of guessing values.
6. **Verify builds after changes.** Run `flutter analyze` and `flutter test` before claiming done.
7. **Produce artifacts in Plan mode** for non-trivial tasks (new feature, refactor, architecture change). Fast mode is for small fixes only.
8. **Confirm destructive operations** (file deletion, schema migrations, force-pushing) before executing.
9. **Report partial failures explicitly.** Don't silently skip steps. If a test fails, say so.
10. **Keep commits small and focused.** One logical change per commit.

## When Uncertain

If the agent cannot confidently proceed, it must STOP and ask. Specifically stop when:

- Documentation is ambiguous or contradictory
- A task requires a decision not yet documented (e.g., specific pricing tier values)
- Multiple valid architectural approaches exist and the tradeoff is unclear
- A requested action contradicts a rule in this file
- A test failure suggests deeper design issues rather than a simple bug

Asking is cheap. Rewriting code is expensive.

## Documentation Update Rules

The agent keeps documentation in sync with code. Documentation drift is a bug.

### Files the agent MAY update

**`docs/CURRENT_SPRINT.md`** — After every completed task:
- Move the task from "In Progress" to "Done" with date stamp
- Add any new `TODO` items discovered during implementation
- Update the "Next Up" section with what should come next
- Note any blockers encountered

**`docs/FEATURE_SPECS.md`** — When a feature is implemented:
- Add or update the "Implementation Notes" subsection for that feature
- List the files created or modified
- Document edge cases handled
- Record decisions made during implementation (with rationale)
- Never modify the original spec (user stories, acceptance criteria) — only append implementation notes

**`docs/DATABASE_SCHEMA.md`** — When a schema migration is applied:
- Reflect the schema change in the relevant table section
- Add a changelog entry at the bottom noting migration number and date
- If a new table is added, add its full definition including RLS policies

**`docs/UI_GUIDELINES.md`** — When a reusable UI pattern emerges:
- Add the component example with code snippet
- Document the Flutter widget equivalent of Stitch/Figma designs
- Never remove existing patterns without explicit approval

### Files the agent MUST NOT update

**`docs/PROJECT_CONTEXT.md`** — Product vision. Only the human project lead changes this.

**`docs/ARCHITECTURE.md`** — Architectural decisions. If the agent believes architecture must change, it STOPS and asks.

**`docs/CONVENTIONS.md`** — Code style. Changes affect the entire team; human decides.

**`.antigravity/RULES.md`** — The agent cannot relax its own constraints. Ever.

**`README.md`** — Only updated when setup instructions genuinely change, and only with human approval.

### Documentation update protocol

When the agent updates documentation:

1. Make the documentation change as part of the same logical work unit
2. Commit docs separately from code: `docs(<scope>): <description>`
   - Example: `docs(sprint): move US-07 reservation flow to done`
   - Example: `docs(schema): add profiles.kvkk_accepted_at column`
3. In the task artifact, explicitly list which docs were updated under a "Documentation Updates" section
4. If documentation update would contradict something in the same doc, STOP and ask

### Documentation integrity check

Before marking a task done, verify:

- [ ] Any new table/column changes reflected in `DATABASE_SCHEMA.md`
- [ ] Completed tasks moved to "Done" in `CURRENT_SPRINT.md`
- [ ] New UI patterns documented in `UI_GUIDELINES.md` (if applicable)
- [ ] Implementation notes appended to `FEATURE_SPECS.md` for completed features
- [ ] No unauthorized edits to forbidden files (see above)

## Quality Gates (Before Marking a Task Done)

The agent must verify:

- [ ] `flutter analyze` passes with zero warnings
- [ ] `flutter test` passes (if tests exist for the modified code)
- [ ] `dart format .` applied
- [ ] No new hardcoded values (colors, strings, magic numbers)
- [ ] No new direct Supabase calls outside repositories
- [ ] All new public APIs have DartDoc comments
- [ ] `.env` file not modified (unless adding a new required variable, in which case `.env.example` is also updated)
- [ ] Git working tree is clean (all intended changes staged, no accidental modifications)

## Project-Specific Gotchas

1. **KVKK compliance is mandatory.** Any screen that collects or displays personal data must respect the user's consent state. Block unauthorized access at the UI layer AND the RLS layer.
2. **Payment is offline.** The MVP does NOT process payments. Anywhere payment logic seems needed, confirm this is actually a UI affordance (e.g., showing "pay at business") — not real payment code.
3. **Turkish is the UI language.** All user-facing strings should be Turkish. Code, comments, and docs remain English.
4. **Dynamic pricing updates must be reliable.** If using client-side calculation, ensure it survives app close/reopen. If server-side, use Supabase realtime subscriptions, not polling.
5. **Terracotta, not green.** The brand deliberately avoids green. Use `AppColors.primary` (terracotta) — never import green colors directly.
6. **Reservation != purchase.** Reservations can be cancelled by either party before pickup. Code must handle cancellation flows gracefully at every state transition.

## Agent Mode Guidance

- **Plan mode** for: new features, schema changes, refactors, architecture decisions
- **Fast mode** for: typos, small UI tweaks, adding a constant, renaming a variable
- **Review-driven mode** for: auth flow changes, payment-adjacent code, anything touching KVKK consent

## Feedback Loop

After completing a task, the agent should produce an artifact that includes:

1. What was done (file list)
2. What was NOT done and why (deferred decisions, blocked items)
3. Any new `TODO` comments added
4. Recommendations for the next task

This artifact is what the human reviews. Raw tool calls are not review material.