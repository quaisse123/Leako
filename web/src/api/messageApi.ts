import { request, requestMultipart } from './request'
import type {
  FuiteMessageRequestDto,
  FuiteMessageResponseDto,
} from '../types'

/** Récupère tous les messages d'une fuite. */
export async function getMessagesByFuite(fuiteId: number): Promise<FuiteMessageResponseDto[]> {
  return request<FuiteMessageResponseDto[]>(`/fuites/${fuiteId}/messages`)
}

/** Crée un message texte pour une fuite. */
export async function createTextMessage(payload: FuiteMessageRequestDto): Promise<FuiteMessageResponseDto> {
  return request<FuiteMessageResponseDto>(`/fuites/${payload.fuiteId}/messages`, {
    method: 'POST',
    body: JSON.stringify({
      utilisateurId: payload.utilisateurId,
      contenuTexte: payload.contenuTexte,
      fuiteId: payload.fuiteId,
    }),
  })
}

/** Crée un message avec fichier audio pour une fuite. */
export async function createAudioMessage(payload: {
  fuiteId: number
  utilisateurId: number
  contenuTexte?: string
  audioFile: File
  dureeAudioSecondes?: number
}): Promise<FuiteMessageResponseDto> {
  const formData = new FormData()
  formData.append('utilisateurId', String(payload.utilisateurId))
  formData.append('fuiteId', String(payload.fuiteId))
  if (payload.contenuTexte) formData.append('contenuTexte', payload.contenuTexte)
  if (payload.dureeAudioSecondes != null) {
    formData.append('dureeAudioSecondes', String(payload.dureeAudioSecondes))
  }
  formData.append('audio', payload.audioFile)

  return requestMultipart<FuiteMessageResponseDto>(
    `/fuites/${payload.fuiteId}/messages/with-audio`,
    formData,
  )
}

/** Supprime un message. */
export async function deleteMessage(fuiteId: number, messageId: number): Promise<void> {
  await request<unknown>(`/fuites/${fuiteId}/messages/${messageId}`, { method: 'DELETE' })
}
