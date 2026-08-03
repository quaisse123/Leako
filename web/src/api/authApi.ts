import { request } from './request'
import { setToken, setRefreshToken, setUser } from './jwtService'
import type {
  LoginRequestDto,
  LoginResponseDto,
  RegisterRequestDto,
  UtilisateurResponseDto,
} from '../types'

/** Connexion — retourne les tokens et stocke l'utilisateur. */
export async function login(payload: LoginRequestDto): Promise<LoginResponseDto> {
  const data = await request<LoginResponseDto>('/auth/login', {
    method: 'POST',
    body: JSON.stringify(payload),
  })

  if (data.accessToken) {
    setToken(data.accessToken)
    if (data.refreshToken) setRefreshToken(data.refreshToken)
    // Stocke l'utilisateur depuis les infos renvoyées par le backend
    setUser({
      id: Number(data.userId ?? 0),
      nom: data.userNom ?? '',
      prenom: '',
      email: data.userEmail ?? payload.email,
      role: undefined,
    })
  }

  return data
}

/** Inscription. */
export async function register(payload: RegisterRequestDto): Promise<UtilisateurResponseDto> {
  return request<UtilisateurResponseDto>('/auth/register', {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

/** Récupère le profil de l'utilisateur connecté. */
export async function getMe(): Promise<UtilisateurResponseDto> {
  return request<UtilisateurResponseDto>('/utilisateurs/me')
}
