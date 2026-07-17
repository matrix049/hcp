# How to run the HCP project locally

Full stack = **PostgreSQL (Docker) → Node/Express backend → Flutter app**.
Run every command in a **PowerShell terminal on this Windows machine**
(the integrated terminal in VS Code / Kiro works, or a standalone PowerShell window —
it makes no difference, they're the same machine).

Prerequisites (already installed on this machine):
Docker Desktop, Node.js, Flutter SDK (`C:\flutter\bin` on PATH — restart the terminal if `flutter` isn't recognized).

---

## 1. PostgreSQL (Docker) — start first

```powershell
cd C:\Users\semla\OneDrive\Desktop\hcp\backend
docker compose up -d
```

Check it's healthy:

```powershell
docker ps            # hcp_postgres should be "healthy"
```

- User `hcp` · Password `hcp_dev_password` · DB `hcp_survey` · port `5432`
- One-time (already done): create schema + seed a test agent → `npm run db:reset`

## 2. Backend API (Node/Express)

```powershell
cd C:\Users\semla\OneDrive\Desktop\hcp\backend
npm install          # first time only
npm run dev          # auto-reload, or: npm start
```

- Base URL: **http://localhost:3000/api**
- Health check: **http://localhost:3000/api/health** → `{"status":"ok"}`
- NOTE: `http://localhost:3000` (root) returns `{"error":"Not found"}` — that is normal,
  the API only answers under `/api/...`.

## 3. Flutter app (web / Edge)

```powershell
cd C:\Users\semla\OneDrive\Desktop\hcp
flutter pub get                                             # first time only
dart run build_runner build --delete-conflicting-outputs   # first time / after model changes
flutter run -d web-server --web-port 5000
```

- Then **open http://localhost:5000 in your own Edge** (it does NOT auto-open a browser).
- If the page is blank, wait for the build to finish, then hard-refresh: **Ctrl + Shift + R**

### IMPORTANT — use `web-server`, not `-d edge`, so local data persists
On the web target the app's local SQLite DB (Drift) lives in the **browser's IndexedDB storage**.
`flutter run -d edge` launches a **fresh throwaway Edge profile every run**, so your local
history/responses (and your login) reset each time. Running `-d web-server` and opening the app
in **your normal Edge** keeps that storage, so responses and history **survive restarts**.
(On Android/Windows the local DB is a real file on disk and persists automatically.)

### Test login
- Matricule: **AG001**
- Password: **password123**

---

## Stopping

```powershell
# App / backend: press  q  in their terminal (or Ctrl+C)
# Postgres:
cd C:\Users\semla\OneDrive\Desktop\hcp\backend
docker compose stop        # keep data, stop container
# docker compose down      # remove container (data volume is kept)
```

## Tips
- Run each of the 3 pieces in its **own terminal tab** (they stay running / occupied).
- Other Flutter targets: `flutter run -d chrome` (needs Chrome) or `-d windows`
  (needs the Visual Studio "Desktop development with C++" workload).
- Android emulator would use API base `http://10.0.2.2:3000/api` instead of `localhost`.
