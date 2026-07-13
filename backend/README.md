# HCP Survey — Backend

Node.js + Express + PostgreSQL REST API for the HCP Survey app.

## Stack
- Express (ESM), PostgreSQL 16 (via Docker), `pg`, `bcryptjs`, `jsonwebtoken`.
- Layered, feature-first: `modules/<feature>/{routes,controller,service}` + `config`, `db`, `middleware`, `utils`.

## Run locally

```bash
# 1. Start PostgreSQL (Docker)
docker compose up -d

# 2. Install dependencies
npm install

# 3. Create schema + seed a test agent
npm run db:reset

# 4. Start the API
npm run dev        # or: npm start
```

API base: `http://localhost:3000/api`

## Endpoints
| Method | Path              | Body                     | Notes                    |
|--------|-------------------|--------------------------|--------------------------|
| GET    | `/api/health`     | —                        | Liveness check           |
| POST   | `/api/auth/login` | `{ matricule, password }`| 200 → tokens + user, 401 |

### Test credentials (from seed)
- **Matricule:** `AG001`
- **Password:** `password123`

### Login response shape (matches Flutter `AgentUserModel`)
```json
{
  "accessToken": "…",
  "refreshToken": "…",
  "user": {
    "id": "uuid", "matricule": "AG001",
    "firstName": "Youssef", "lastName": "Alaoui",
    "role": "agent", "region": "Rabat-Salé-Kénitra", "phone": "+212600000000"
  }
}
```
