/**
 * URL de base de l'API backend.
 * ─────────────────────────────────────────────
 * ✅ Production & Développement : chemin relatif `/api`.
 * Le proxy nginx (prod) ou Vite (dev) redirige `/api` → backend.
 * Évite le "mixed content" (page HTTPS → API HTTP bloquée par le navigateur).
 */
export const API_BASE_URL = '/api';

/**
 * ☑️ Local (développement) — via proxy Vite
 * (le proxy /api → http://84.235.230.47:8080 est configuré dans vite.config.ts)
 */
export const API_PROXY_URL = '/api';

/** URL de base utilisée par les requêtes (proxy en dev, direct en prod) */
export const ACTIVE_API_URL =
  import.meta.env.DEV ? API_PROXY_URL : API_BASE_URL;

/** Timeout standard pour les requêtes HTTP (ms). */
export const API_TIMEOUT = 30000;
