import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react'
import type { ReactNode } from 'react'
import { getProjets } from '../api/projetApi'
import { getUser } from '../api/jwtService'
import type { ProjetResponseDto } from '../types'

interface ProjetActifContextValue {
  projets: ProjetResponseDto[]
  projetActif: ProjetResponseDto | null
  loading: boolean
  setProjetActif: (projet: ProjetResponseDto | null) => void
  reload: () => Promise<void>
}

const ProjetActifContext = createContext<ProjetActifContextValue | null>(null)

const STORAGE_KEY = 'leaks_survey_projet_actif'

/**
 * Contexte « projet actif » — équivalent du drawer de l'app mobile.
 * Charge les projets de l'utilisateur, sélectionne automatiquement le
 * premier (ou le dernier choisi), et expose tout aux pages filles.
 */
export function ProjetActifProvider({ children }: { children: ReactNode }) {
  const [projets, setProjets] = useState<ProjetResponseDto[]>([])
  const [projetActif, setProjetActifState] = useState<ProjetResponseDto | null>(null)
  const [loading, setLoading] = useState(true)

  const userId = getUser()?.id ?? 0

  const reload = useCallback(async () => {
    if (!userId) return
    try {
      setLoading(true)
      const data = await getProjets()
      setProjets(data)

      // Projet mémorisé dans localStorage
      const stored = Number(localStorage.getItem(STORAGE_KEY) ?? '0')
      const storedProjet = data.find((p) => p.id === stored) ?? null

      // Conserver le projet actif s'il existe encore, sinon premier projet
      setProjetActifState((prev) => {
        if (prev && data.some((p) => p.id === prev.id)) return prev
        return storedProjet ?? data[0] ?? null
      })
    } catch (err) {
      console.error('Erreur chargement projets:', err)
    } finally {
      setLoading(false)
    }
  }, [userId])

  useEffect(() => {
    void reload()
  }, [reload])

  const setProjetActif = useCallback((projet: ProjetResponseDto | null) => {
    setProjetActifState(projet)
    if (projet) {
      localStorage.setItem(STORAGE_KEY, String(projet.id))
    } else {
      localStorage.removeItem(STORAGE_KEY)
    }
  }, [])

  const value = useMemo(
    () => ({ projets, projetActif, loading, setProjetActif, reload }),
    [projets, projetActif, loading, setProjetActif, reload],
  )

  return <ProjetActifContext.Provider value={value}>{children}</ProjetActifContext.Provider>
}

/** Hook d'accès au contexte projet actif. */
export function useProjetActif(): ProjetActifContextValue {
  const ctx = useContext(ProjetActifContext)
  if (!ctx) {
    throw new Error('useProjetActif doit être utilisé dans un ProjetActifProvider')
  }
  return ctx
}
