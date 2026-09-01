# Lancer le projet en local

La pile complète : **PostgreSQL (Docker) → backend Node/Express → application Flutter**.

Racine du projet : `C:\Users\ULTRAPC\Desktop\hcp`

Prérequis déjà installés sur cette machine : Docker Desktop, Node.js 22, Flutter
(`C:\src\flutter\bin`). Si la commande `flutter` n'est pas reconnue, rouvrir le terminal.

Lancer chaque étape dans **son propre onglet de terminal** — les trois restent occupés.

---

## 1. PostgreSQL

```powershell
cd C:\Users\ULTRAPC\Desktop\hcp\backend
docker compose up -d
docker ps            # hcp_postgres doit être "healthy"
```

Base `hcp_survey` · utilisateur `hcp` · port `5432`.

Première installation seulement — crée le schéma et l'agent de test :

```powershell
npm run db:reset
```

## 2. Backend

```powershell
cd C:\Users\ULTRAPC\Desktop\hcp\backend
npm install          # première fois seulement
npm start            # ou: npm run dev  (rechargement automatique)
```

- API : **http://localhost:3000/api**
- Vérification : **http://localhost:3000/api/health** → `{"status":"ok"}`
- Outil d'administration : **http://localhost:3000/admin/**
- `http://localhost:3000` sans `/api` renvoie `{"error":"Not found"}` — c'est normal.

> Le serveur **refuse de démarrer** si `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `JWT_SECRET`
> ou `DATABASE_URL` manquent dans `backend/.env`. C'est volontaire : aucun mot de
> passe par défaut n'existe dans le code source. Partir de `.env.example`.

## 3. Application Flutter

```powershell
cd C:\Users\ULTRAPC\Desktop\hcp
flutter pub get                                            # première fois
dart run build_runner build --delete-conflicting-outputs   # après un changement de table Drift
flutter run -d web-server --web-port 5000
```

Ouvrir ensuite **http://localhost:5000** dans Edge — la commande n'ouvre pas de
navigateur toute seule. Si la page est blanche, attendre la fin de la compilation
puis **Ctrl + Maj + R**.

### Utiliser `web-server`, pas `-d edge`

Sur le web, la base locale Drift vit dans le stockage IndexedDB du navigateur.
`flutter run -d edge` ouvre un **profil Edge jetable à chaque lancement** : l'historique,
les réponses et la session sont perdus à chaque redémarrage. Avec `web-server` et
votre Edge habituel, les données survivent. Sur Android et Windows, la base est un
vrai fichier sur disque et persiste sans précaution.

---

## Identifiants

| Rôle | Où | Identifiant | Mot de passe |
|---|---|---|---|
| Enquêteur | app Flutter | `AG001` | `password123` |
| Administrateur | `/admin/` | valeur de `ADMIN_EMAIL` | valeur de `ADMIN_PASSWORD` |

Les identifiants admin viennent uniquement de `backend/.env` — les consulter avec :

```powershell
Get-Content C:\Users\ULTRAPC\Desktop\hcp\backend\.env | Select-String ADMIN_
```

---

## Tests

```powershell
cd C:\Users\ULTRAPC\Desktop\hcp
flutter test          # 26 tests
flutter analyze       # doit afficher "No issues found!"

cd backend
npm test              # 21 tests
node eval/run-eval.mjs        # note la génération IA sur 10
node eval/probe-models.mjs    # mesure quels modèles Gemini répondent
```

---

## Arrêter

```powershell
# App et backend : q dans leur terminal, ou Ctrl+C
cd C:\Users\ULTRAPC\Desktop\hcp\backend
docker compose stop        # garde les données
# docker compose down      # supprime le conteneur (le volume de données reste)
```

## Dépannage

| Symptôme | Cause probable |
|---|---|
| Le backend quitte avec « Missing required environment variable » | Une variable obligatoire manque dans `backend/.env` |
| `ECONNREFUSED` sur le port 5432 | Docker Desktop n'est pas démarré |
| Page blanche sur le port 5000 | Compilation en cours — attendre puis Ctrl+Maj+R |
| L'admin affiche un bandeau orange « sans IA » | Gemini n'a pas répondu — relancer, le quota gratuit se libère |
| 429 à la connexion | Limitation anti-force brute : 10 essais par minute |
| Émulateur Android | Utiliser `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api` |
