# OCP Leaks Survey — Frontend Web (React)

Application web React pour la détection de fuites industrielles (OCP).
Elle consomme l'API Spring Boot : `http://84.235.230.47:8080/api`.

## 🚀 Démarrage

```bash
npm install
npm run dev
```

Le serveur de dev tourne sur `http://localhost:5173`.
En mode dev, les requêtes `/api/*` sont proxifiées vers le backend via `vite.config.ts`.

## 📦 Build de production

```bash
npm run build
npm run preview
```

## 🐳 Docker

```bash
docker build -t leaks-survey-web .
docker run -p 80:80 leaks-survey-web
```

## 🗂️ Structure

```
src/
├── api/          → Couche API par entité (authApi, fuiteApi, ...)
├── components/   → Composants partagés (Layout, ProtectedRoute, Badge...)
├── config/       → Configuration (baseURL)
├── pages/        → Pages (LoginPage, DashboardPage, FuitesPage...)
├── types/        → DTOs TypeScript (correspondance backend)
├── App.tsx       → Routes
└── main.tsx      → Point d'entrée
```

## ✅ Phases

Voir `PLAN_REACT_WEB.md` pour le plan détaillé par phases.
