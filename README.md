# HCP Survey App

Offline-first, cross-platform survey application for **Haut Commissariat au Plan (HCP)** field agents.
Built with Flutter using **Clean Architecture** + **Feature-First** organization.

> Status: **Step 1 — project skeleton.** Feature logic is implemented incrementally, with review between each step.

---

## Architecture at a glance

```
presentation  ->  domain  <-  data
   (Riverpod)     (rules)    (Drift + Dio)
```

- **domain** — pure Dart: entities, abstract repository contracts, use cases. No Flutter/Dio/SQLite imports.
- **data** — implements domain contracts; owns offline/online logic (SQLite + REST).
- **presentation** — Flutter UI + Riverpod state.

**Golden rule (offline-first):** the UI always reads from the **local SQLite database** (single source of truth). A background **Sync Engine** drains a change queue to the REST API whenever connectivity returns.

## Tech decisions

| Concern | Choice |
|---|---|
| State management | flutter_riverpod |
| Local DB | drift (SQLite), reactive + type-safe |
| Networking | dio |
| Secure token storage | flutter_secure_storage |
| Connectivity | connectivity_plus |
| Routing | go_router |
| Models | freezed + json_serializable |
| Errors | dartz `Either<Failure, T>` |

## Directory layout

```
lib/
├── core/          shared: db, network, sync engine, router, theme, di, errors
├── features/      auth · profile · surveys · questionnaire · history · sync
│   └── <feature>/ { data / domain / presentation }
└── ai/            PHASE 2 — abstract AI interfaces only (no implementation yet)
assets/surveys/    survey definitions (JSON) — questionnaires are generated dynamically
```

## Authentication

- Agents sign in with **matricule + password** (the citizen/respondent is **not** an app user).
- **First login must be online** (validated by the server). On success the JWT, the
  agent profile, and a **salted SHA-256 hash** of the password are cached in secure storage.
- Afterwards the agent can **log in offline** on the same device: the entered password is
  re-hashed and compared locally. Wrong credentials never pass offline.
- The `AuthRepository` decides online vs offline; the UI only sees `AgentUser` or `Failure`.
- Kept lean per project rules: **no use-case layer** (controller → repository directly) and
  **no `go_router` yet** (a simple `AuthGate` switches login ↔ home).

The **User** entity = the HCP agent only: `id, matricule, firstName, lastName, role, region, phone?`.

## Dynamic questionnaires

Surveys are **never hardcoded**. A survey JSON (see `assets/surveys/sample_household_survey.json`)
is parsed into domain models and rendered by a `QuestionWidgetFactory` that maps each
`question.type` (`text`, `number`, `single_choice`, `multi_choice`, `boolean`, `date`, `gps`, …)
to a widget. New question types = one new case, zero screen changes.

## Getting started (once Flutter is installed)

```bash
# 1. Generate platform folders (android/ios/web/windows) into this project
flutter create .

# 2. Install dependencies
flutter pub get

# 3. Run code generation (freezed / json_serializable / drift)
dart run build_runner build --delete-conflicting-outputs

# 4. Run
flutter run
```

## Roadmap (step-by-step, reviewed between each)

1. ✅ Project skeleton (folders, pubspec, sample survey)
2. ✅ Core layer: errors, Dio client, Drift DB, secure storage, connectivity, DI
3. ✅ Auth feature — matricule + password, online-first, offline re-login
   - ✅ Backend (`backend/`): Node/Express + PostgreSQL, `POST /api/auth/login` verified end-to-end
4. ✅ Surveys: list + download (backend endpoints verified; offline-first, downloads cache to Drift)
5. ✅ Dynamic questionnaire engine — central-switch factory (text, number, radio, checkbox, dropdown, date), conditional visibility, validation
6. ✅ Local answer storage + edit-before-sync — responses auto-saved to Drift as drafts, resumable/editable, finalize → `pending` (DB-tested)
7. ✅ Sync engine + sync status UI — auto-sync (start/reconnect/finalize) + manual; idempotent upload; retries; badge indicator (DB-tested)
8. ✅ Survey history + profile — cross-survey response list (status + tap to edit) and agent profile with sign-out
9. ⬜ (Phase 2) AI integration behind existing interfaces
