# My Expenses

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white)](https://dart.dev)

> Recommended order: backend first, then Flutter. That keeps API URLs, auth, and staged review flows aligned.

My Expenses is a Flutter-based personal finance tracker paired with a FastAPI backend. The app follows a local-first workflow: transactions update immediately in the UI, queued changes sync later, and staged PDF rows can be reviewed locally without losing edits when you leave and return to the screen.

## What’s In The Repo

| Path | Purpose |
|---|---|
| `my_expenses/` | Flutter client app |
| `My Expenses API/` | FastAPI backend, migrations, and backend tests |

## Current Product Areas

- Dashboard with monthly summary cards, quick add, PDF upload, staged review, budget visibility, and shortcuts to settings and sync.
- Transaction history with filtering, editing, deletion, and export actions.
- Analytics with income vs expense charts and category insights.
- Budget tracking with per-category limits and threshold warnings.
- Staged PDF review with type/category selection, accept/reject controls, and local persistence of user edits.
- Authentication, onboarding, currency selection, category management, and account settings.
- App lock, notifications, and a weekly digest service.
- Cross-platform Flutter support for Android, iOS, web, Windows, macOS, and Linux.

## Architecture At A Glance

### Flutter app structure

- `lib/core/` shared infrastructure such as API, auth, storage, notifications, security, theme, and constants.
- `lib/data/` repositories for transactions, budgets, and staged drafts.
- `lib/models/` application data models.
- `lib/pages/` UI screens.
- `lib/services/` background services such as health score and weekly digest.
- `lib/utils/` helper utilities.
- `lib/widgets/` reusable UI components.

### Runtime environments

| Environment | What it is | Needed for |
|---|---|---|
| Flutter SDK | The app runtime and build toolchain | Running the mobile/web/desktop client |
| Python 3.12 virtual environment (`My Expenses API/.venv`) | Isolated backend dependencies | Running and testing the FastAPI backend |

There is no separate Flutter virtual environment. Flutter uses the installed SDK directly, while the backend should be run inside its own Python virtual environment.

### Suggested local layout

```text
Expenses/
├── My Expenses API/
│   └── .venv/
└── my_expenses/
    └── .env.dev
```

## Setup Guide

### 1. Install prerequisites

- Flutter SDK 3.10.7 or newer
- Dart SDK included with Flutter
- Python 3.12 for the backend
- A backend API URL for the FastAPI service

### 2. Backend virtual environment

From `My Expenses API/`:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

If you are running tests, also install the test tools you need locally, for example `pytest`.

### 3. Flutter dependencies

From `my_expenses/`:

```bash
flutter pub get
```

## Environment Files

### Flutter app

The Flutter app reads environment values from these files in the project root:

- `.env.dev`
- `.env`
- `.env.example`

Set `API_URL` in the file you use locally.

```bash
API_URL=https://your-backend-link/api/v1
```

At runtime, the app tries `.env.dev` first, then `.env`, then `.env.example`.

### Quick start

| Step | Command |
|---|---|
| Activate backend env | `cd "My Expenses API"` then `.\.venv\Scripts\Activate.ps1` |
| Install backend deps | `pip install -r requirements.txt` |
| Start backend | `uvicorn main:app --reload --host 0.0.0.0 --port 8000` |
| Install Flutter deps | `cd my_expenses` then `flutter pub get` |
| Start Flutter app | `flutter run` |

### Backend API

The backend loads environment variables from a local `.env` file in `My Expenses API/`. The backend requires these values:

- `JWT_SECRET`
- `SUPABASE_URL`
- `SUPABASE_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `BREVO_API_KEY`
- `SENDER_EMAIL`

Optional values:

- `SENDER_NAME`
- `JWT_EXPIRE_MINUTES`
- `PORT`
- `MAX_UPLOAD_BYTES`
- `WEEKLY_DIGEST_CRON_TOKEN`

Example backend `.env`:

```bash
JWT_SECRET=your-very-long-secret
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-or-service-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
BREVO_API_KEY=your-brevo-api-key
SENDER_EMAIL=no-reply@example.com
SENDER_NAME=My Expenses
PORT=8000
```

## How To Run

### Run the backend

From `My Expenses API/` with the virtual environment activated:

```powershell
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

If you want a quick syntax check instead of a full test run:

```powershell
python -m compileall -q main.py pdf_parser.py core routes schemas services
```

### Run the Flutter app

From `my_expenses/`:

```bash
flutter run
```

Helpful commands:

```bash
flutter analyze
flutter test
flutter devices
```

### Build examples

```bash
flutter build apk --release --dart-define=API_URL=https://your-backend-link/api/v1
flutter build appbundle --release --dart-define=API_URL=https://your-backend-link/api/v1
flutter build ios --release
```

## Working Flow

1. Start the backend API inside its Python virtual environment.
2. Run the Flutter app with `flutter run`.
3. Add or edit transactions from the dashboard or history.
4. Upload a bank PDF and review staged rows.
5. Adjust type and category, mark rows accepted, and confirm them later.
6. Use budgets, analytics, and the weekly digest to monitor spending.

## Notes For Development

- Staged draft changes are cached locally so they survive screen changes and later confirmation.
- The app supports compile-time `API_URL` overrides for release builds.
- Generated code support is already included in `pubspec.yaml`.
- The backend uses rate limiting, CORS, auth, budget, onboarding, upload, feedback, debt, and settings routes.

## How To Make The Markdown Feel Professional

- Keep the top section short and outcome-focused, then move into setup and usage.
- Use tables for environments, commands, and dependencies so the file is scannable.
- Prefer plain section titles with a small amount of formatting instead of heavy emoji noise.
- Keep code blocks minimal and exact; put one command per line when possible.
- Add a short “working flow” section so new contributors understand the app lifecycle quickly.
- Use consistent terminology across the Flutter and backend docs so the repo feels unified.

## Contributing

```bash
flutter format .
flutter analyze
flutter test
```

If you add generated code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Support

For support and questions, email bheesettimanohar27@gmail.com.

**Last Updated:** April 17, 2026
**Current Version:** 1.0.0+1
