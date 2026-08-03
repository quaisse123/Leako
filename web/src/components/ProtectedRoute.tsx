import { Navigate } from 'react-router-dom'
import { isAuthenticated } from '../api/jwtService'
import type { ReactNode } from 'react'

interface ProtectedRouteProps {
  children: ReactNode
}

/**
 * Garde de route — redirige vers /login si l'utilisateur n'est pas authentifié.
 */
export default function ProtectedRoute({ children }: ProtectedRouteProps) {
  if (!isAuthenticated()) {
    return <Navigate to="/login" replace />
  }
  return <>{children}</>
}
