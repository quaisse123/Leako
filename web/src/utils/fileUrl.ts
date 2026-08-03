import { API_BASE_URL } from '../config/baseURL'

/**
 * Construit l'URL complète d'un fichier uploadé (photo/audio).
 * Même logique que `_photoUrl` dans l'app mobile Flutter.
 * Ex: "/uploads/photos/xxx.jpg" → "http://84.235.230.47:8080/uploads/photos/xxx.jpg"
 */
export function fileUrl(path?: string): string {
  if (!path) return ''
  if (path.startsWith('http://') || path.startsWith('https://')) return path
  let base = API_BASE_URL // ex: http://84.235.230.47:8080/api
  if (base.endsWith('/api')) base = base.substring(0, base.length - 4)
  if (!base.endsWith('/')) base = `${base}/`
  if (path.startsWith('/')) path = path.substring(1)
  return `${base}${path}`
}
