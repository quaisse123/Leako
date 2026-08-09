import { request } from './request'
import { getAuthHeaders } from './jwtService'
import { ACTIVE_API_URL, API_TIMEOUT } from '../config/baseURL'
import type { AnalyseIAReponse } from '../types'

/**
 * Timeout dédié à l'analyse IA (ms).
 * L'analyse d'images par le modèle local Ollama (7B sur CPU) peut prendre
 * plusieurs minutes. Le timeout global de 30s ferait abandonner la requête
 * ("signal is aborted") avant la fin. On laisse 5 minutes.
 */
const ANALYSE_IA_TIMEOUT = 5 * 60 * 1000

/**
 * Service IA — correspond à analyse_ia_service.dart (mobile).
 *
 * Envoie le fuiteId au lieu des fichiers bruts — Spring Boot se charge
 * de charger les médias depuis le disque et d'appeler l'IA (Ollama local
 * d'abord, OpenRouter en fallback).
 */
export async function analyserParFuite(fuiteId: number): Promise<AnalyseIAReponse> {
  return request<AnalyseIAReponse>('/analyse-ia', {
    method: 'POST',
    body: JSON.stringify({ fuiteId }),
  }, ANALYSE_IA_TIMEOUT)
}

/**
 * Charge la dernière analyse IA persistée pour une fuite (si elle existe
 * et si les photos n'ont pas changé depuis l'analyse).
 *
 * Retourne `null` si aucune analyse à jour (204/404) ou en cas d'erreur.
 */
export async function getDerniereAnalyse(
  fuiteId: number,
): Promise<AnalyseIAReponse | null> {
  const authHeaders = getAuthHeaders()
  const controller = new AbortController()
  const timeoutId = setTimeout(() => controller.abort(), API_TIMEOUT)
  try {
    const response = await fetch(`${ACTIVE_API_URL}/analyse-ia/${fuiteId}`, {
      signal: controller.signal,
      headers: { ...authHeaders },
    })

    // 204 = aucune analyse à jour pour cette fuite
    if (response.status === 204 || response.status === 404) {
      console.debug(
        `[IA] getDerniereAnalyse fuite#${fuiteId} → ${response.status} (aucune analyse à jour)`,
      )
      return null
    }
    if (response.status !== 200) {
      console.debug(
        `[IA] getDerniereAnalyse fuite#${fuiteId} → statut inattendu ${response.status}`,
      )
      return null
    }

    const data = (await response.json()) as AnalyseIAReponse
    console.debug(
      `[IA] getDerniereAnalyse fuite#${fuiteId} → 200 OK, analyse persistée trouvée`,
    )
    return data
  } catch (err) {
    console.debug(`[IA] getDerniereAnalyse fuite#${fuiteId} → erreur:`, err)
    // Silencieux : l'absence d'analyse n'est pas une erreur bloquante.
    return null
  } finally {
    clearTimeout(timeoutId)
  }
}

/** Message user-friendly à partir d'un statut HTTP (identique au mobile). */
export function erreurDepuisStatut(statusCode: number): string {
  switch (statusCode) {
    case 400:
      return 'Requête invalide. Vérifie que les photos existent.'
    case 429:
      return 'Service IA surchargé. Attends quelques secondes et réessaie.'
    case 502:
      return "L'IA n'a pas pu analyser les fichiers."
    case 503:
      return 'Service IA indisponible. Vérifie ta connexion Internet.'
    case 504:
      return "L'analyse a pris trop de temps. Réessaie avec moins de photos."
    default:
      return `Erreur du serveur (${statusCode}). Réessaie dans un instant.`
  }
}
