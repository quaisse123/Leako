/**
 * Utilitaires de formatage de dates pour le backend.
 *
 * Le backend Spring Boot attend les dates au format
 * `yyyy-MM-ddTHH:mm:ss.000000` (avec microsecondes), comme l'envoie
 * l'app mobile Flutter (`'${date}.000000'`).
 */

/**
 * Convertit une valeur `datetime-local` (yyyy-MM-ddTHH:mm) en format
 * backend (yyyy-MM-ddTHH:mm:ss.000000).
 */
export function toBackendDate(datetimeLocal: string): string {
  if (!datetimeLocal) return ''
  // datetime-local donne "yyyy-MM-ddTHH:mm" → ajoute ":00.000000"
  return `${datetimeLocal}:00.000000`
}

/**
 * Convertit une date ISO (ex: "2026-07-21T10:00:00.000000") en valeur
 * `datetime-local` (yyyy-MM-ddTHH:mm) pour les champs de formulaire.
 */
export function toDatetimeLocal(iso?: string): string {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ''
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}
