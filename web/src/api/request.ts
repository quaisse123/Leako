import { ACTIVE_API_URL, API_TIMEOUT } from '../config/baseURL'
import { getAuthHeaders, refreshTokens } from './jwtService'

/**
 * Helper `request<T>` — style inspiré du repo PM-B-frontend.
 * Utilise fetch + getAuthHeaders() pour injecter le token JWT.
 * Si la réponse est 401, tente un refresh automatique puis rejoue la requête.
 *
 * @param timeoutMs Timeout optionnel (ms). Par défaut API_TIMEOUT (30s).
 *                  Certaines opérations longues (analyse IA) ont besoin de plus.
 */
export async function request<T>(
  path: string,
  init?: RequestInit,
  timeoutMs: number = API_TIMEOUT,
): Promise<T> {
  const authHeaders = getAuthHeaders()

  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs)

  try {
    const response = await fetch(`${ACTIVE_API_URL}${path}`, {
      ...init,
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders,
        ...(init?.headers ?? {}),
      },
    })

    const contentType = response.headers.get('content-type') || ''
    let data: unknown = null
    if (contentType.includes('application/json')) {
      data = await response.json()
    } else if (contentType.includes('text/')) {
      // Certains endpoints backend retournent une String brute (ex: /fuites/prochain-tag)
      data = await response.text()
    }

    if (!response.ok) {
      // Token expiré ou invalide → tente un refresh automatique (sauf sur /auth et /jwt)
      const isAuthEndpoint =
        path.startsWith('/auth/') || path.startsWith('/jwt/')
      if (response.status === 401 && !isAuthEndpoint) {
        const refreshed = await refreshTokens()
        if (refreshed) {
          // Rejoue la requête avec le nouveau token
          return request<T>(path, init, timeoutMs)
        }
      }
      const message =
        (data as { message?: string; error?: string })?.message ||
        (data as { error?: string })?.error ||
        `Request failed with status ${response.status}`
      throw new Error(message)
    }

    return data as T
  } finally {
    clearTimeout(timeoutId)
  }
}

/**
 * Helper pour les requêtes multipart (upload photo/audio).
 */
export async function requestMultipart<T>(
  path: string,
  formData: FormData,
  method: 'POST' | 'PUT' = 'POST',
): Promise<T> {
  const authHeaders = getAuthHeaders()

  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT)

  try {
    const response = await fetch(`${ACTIVE_API_URL}${path}`, {
      method,
      signal: controller.signal,
      headers: {
        ...authHeaders,
      },
      body: formData,
    })

    const contentType = response.headers.get('content-type') || ''
    let data: unknown = null
    if (contentType.includes('application/json')) {
      data = await response.json()
    } else if (contentType.includes('text/')) {
      // Certains endpoints backend retournent une String brute (ex: /fuites/prochain-tag)
      data = await response.text()
    }

    if (!response.ok) {
      const message =
        (data as { message?: string; error?: string })?.message ||
        (data as { error?: string })?.error ||
        `Request failed with status ${response.status}`
      throw new Error(message)
    }

    return data as T
  } finally {
    clearTimeout(timeoutId)
  }
}

/**
 * Aide à normaliser les réponses qui peuvent être soit un tableau,
 * soit un objet avec une liste imbriquée (content/items/data).
 */
export function asArray<T>(value: unknown): T[] {
  if (Array.isArray(value)) return value as T[]
  if (value && typeof value === 'object') {
    const record = value as Record<string, unknown>
    const nested = record.content ?? record.items ?? record.data
    if (Array.isArray(nested)) return nested as T[]
  }
  return []
}
