import { requestMultipart, request } from './request'
import { getAuthHeaders } from './jwtService'
import { ACTIVE_API_URL } from '../config/baseURL'
import type { PhotoResponseDto } from '../types'

/**
 * Upload une photo/vidéo pour une fuite.
 * Endpoint backend : POST /api/photos/upload (multipart).
 */
export async function uploadPhoto(
  fuiteId: number,
  file: File,
  datePrise?: string,
): Promise<PhotoResponseDto> {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('fuiteId', String(fuiteId))
  if (datePrise) formData.append('datePrise', datePrise)
  return requestMultipart<PhotoResponseDto>('/photos/upload', formData)
}

/**
 * Upload une photo/vidéo avec suivi de progression (XHR).
 * `onProgress` reçoit un nombre entre 0 et 1.
 * Même logique que le mobile (photo_api.dart) : comptage des octets envoyés.
 */
export async function uploadPhotoWithProgress(
  fuiteId: number,
  file: File,
  onProgress: (progress: number) => void,
  datePrise?: string,
): Promise<PhotoResponseDto> {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('fuiteId', String(fuiteId))
  if (datePrise) formData.append('datePrise', datePrise)

  return new Promise<PhotoResponseDto>((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('POST', `${ACTIVE_API_URL}/photos/upload`)
    const headers = getAuthHeaders()
    if (headers.Authorization) {
      xhr.setRequestHeader('Authorization', headers.Authorization)
    }
    xhr.timeout = 15 * 60 * 1000 // 15 min pour les vidéos volumineuses (comme le mobile)

    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable && e.total > 0) {
        onProgress(Math.min(1, e.loaded / e.total))
      }
    }

    xhr.onload = () => {
      try {
        const data = JSON.parse(xhr.responseText) as PhotoResponseDto
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve(data)
        } else {
          const msg =
            (data as unknown as { message?: string; error?: string })?.message ||
            (data as unknown as { error?: string })?.error ||
            `Request failed with status ${xhr.status}`
          reject(new Error(msg))
        }
      } catch {
        reject(new Error('Réponse invalide du serveur'))
      }
    }

    xhr.onerror = () => reject(new Error('Erreur réseau lors de l\'upload'))
    xhr.ontimeout = () => reject(new Error("L'upload a dépassé le délai (15 min)"))
    xhr.send(formData)
  })
}

/** Liste les photos d'une fuite (limit optionnelle, comme le mobile). */
export async function getPhotosByFuite(
  fuiteId: number,
  limit?: number,
): Promise<PhotoResponseDto[]> {
  const qs = limit && limit > 0 ? `&limit=${limit}` : ''
  return request<PhotoResponseDto[]>(`/photos?fuiteId=${fuiteId}${qs}`)
}

/** Récupère une photo par ID. */
export async function getPhotoById(id: number): Promise<PhotoResponseDto> {
  return request<PhotoResponseDto>(`/photos/${id}`)
}

/** Supprime une photo. */
export async function deletePhoto(photoId: number): Promise<void> {
  await request<unknown>(`/photos/${photoId}`, { method: 'DELETE' })
}
