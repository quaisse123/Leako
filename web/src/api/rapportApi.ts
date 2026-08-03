import { request } from './request'
import { ACTIVE_API_URL } from '../config/baseURL'
import type { RapportResponseDto } from '../types'

/**
 * API Rapports & Analyses — correspondance exacte avec le mobile (rapport_api.dart).
 * Endpoints backend : /rapports, /rapports/projet, /rapports/projet/pdf.
 */

/** Génère le rapport complet pour un utilisateur sur une période donnée. */
export async function getRapport(params: {
  utilisateurId: number
  periode?: string
}): Promise<RapportResponseDto> {
  const query = new URLSearchParams()
  query.set('utilisateurId', String(params.utilisateurId))
  if (params.periode) query.set('periode', params.periode)
  return request<RapportResponseDto>(`/rapports?${query.toString()}`)
}

/** Génère le rapport centralisé pour un projet (tous les membres voient les mêmes données). */
export async function getRapportByProjet(params: {
  projetId: number
  periode?: string
}): Promise<RapportResponseDto> {
  const query = new URLSearchParams()
  query.set('projetId', String(params.projetId))
  if (params.periode) query.set('periode', params.periode)
  return request<RapportResponseDto>(`/rapports/projet?${query.toString()}`)
}

/** Construit le paramètre query "&metrics=id1,id2" (vide si null ou vide). */
function metricsParam(metrics?: string[]): string {
  if (!metrics || metrics.length === 0) return ''
  return `&metrics=${metrics.join(',')}`
}

/** URL directe du PDF backend (affichage inline ou téléchargement). */
export function getPdfUrl(params: {
  projetId: number
  periode?: string
  metrics?: string[]
  inline?: boolean
}): string {
  const periode = params.periode ?? 'ALL'
  const inline = params.inline ? '&inline=true' : ''
  return `${ACTIVE_API_URL}/rapports/projet/pdf?projetId=${params.projetId}&periode=${periode}${metricsParam(params.metrics)}${inline}`
}
