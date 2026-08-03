/**
 * Service JWT — gestion du token d'authentification.
 * Style : inspiré du repo PM-B-frontend (jwtService).
 */

const TOKEN_KEY = 'leaks_survey_token';
const REFRESH_TOKEN_KEY = 'leaks_survey_refresh_token';
const USER_KEY = 'leaks_survey_user';

export interface StoredUser {
  id: number;
  nom: string;
  prenom: string;
  email: string;
  role?: string;
}

/** Enregistre le token JWT. */
export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

/** Récupère le token JWT. */
export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

/** Enregistre le refresh token. */
export function setRefreshToken(token: string): void {
  localStorage.setItem(REFRESH_TOKEN_KEY, token);
}

/** Récupère le refresh token. */
export function getRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

/** Supprime les tokens (déconnexion). */
export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

/** Enregistre l'utilisateur connecté. */
export function setUser(user: StoredUser): void {
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

/** Récupère l'utilisateur connecté. */
export function getUser(): StoredUser | null {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredUser;
  } catch {
    return null;
  }
}

/** En-têtes d'authentification à joindre aux requêtes. */
export function getAuthHeaders(): Record<string, string> {
  const token = getToken();
  if (!token) return {};
  return { Authorization: `Bearer ${token}` };
}

/** Décode le payload du JWT (sans vérification de signature — lecture seule). */
export function decodeToken(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = parts[1];
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized.padEnd(normalized.length + ((4 - normalized.length % 4) % 4), '=');
    return JSON.parse(atob(padded)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/** Vérifie si le token est présent et non expiré. */
export function isAuthenticated(): boolean {
  const token = getToken();
  if (!token) return false;
  const payload = decodeToken(token);
  if (!payload) return false;
  const exp = payload.exp as number | undefined;
  if (!exp) return true;
  return Date.now() < exp * 1000;
}

/** Vérifie la validité du token auprès du backend (/api/jwt/ping). */
export async function isTokenValidOnServer(): Promise<boolean> {
  const token = getToken();
  if (!token) return false;
  try {
    const response = await fetch('/api/jwt/ping', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Rafraîchit les tokens via le refresh token (/api/jwt/refresh).
 * Retourne true si le refresh a réussi.
 */
export async function refreshTokens(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;
  try {
    const response = await fetch('/api/jwt/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
    if (!response.ok) return false;
    const data = (await response.json()) as { accessToken?: string; refreshToken?: string };
    if (data.accessToken) {
      setToken(data.accessToken);
      if (data.refreshToken) setRefreshToken(data.refreshToken);
      return true;
    }
    return false;
  } catch {
    return false;
  }
}

/**
 * Récupère un token valide : si le token actuel est expiré ou rejeté,
 * tente un refresh automatique. Sinon retourne null (déconnecté).
 */
export async function getValidAccessToken(): Promise<string | null> {
  if (isAuthenticated()) return getToken();
  const refreshed = await refreshTokens();
  return refreshed ? getToken() : null;
}
