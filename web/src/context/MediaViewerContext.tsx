import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { X } from 'lucide-react'

export type MediaType = 'image' | 'video'

interface MediaViewerState {
  openMedia: (url: string, type?: MediaType) => void
  closeMedia: () => void
}

const MediaViewerContext = createContext<MediaViewerState | null>(null)

/** Récupère le contexte du visionneuse média centralisée. */
export function useMediaViewer(): MediaViewerState {
  const ctx = useContext(MediaViewerContext)
  if (!ctx) {
    throw new Error('useMediaViewer doit être utilisé dans <MediaViewerProvider>')
  }
  return ctx
}

/** Détecte si un chemin est une vidéo (mêmes extensions que le mobile). */
export function isVideoPath(path?: string): boolean {
  if (!path) return false
  const ext = path.split('?')[0].split('.').pop()?.toLowerCase() ?? ''
  return ['mp4', 'mov', 'avi', 'mkv', 'webm'].includes(ext)
}

/**
 * Visionneuse média centralisée — reproduit le comportement mobile :
 * - Image  → dialog plein écran (fond noir, ✕, clic extérieur / Échap pour fermer)
 * - Vidéo  → lecteur plein écran avec contrôles
 *
 * S'ouvre PAR-DESSUS le contenu sans ouvrir un nouvel onglet.
 */
export function MediaViewerProvider({ children }: { children: ReactNode }) {
  const [media, setMedia] = useState<{ url: string; type: MediaType } | null>(null)

  const closeMedia = useCallback(() => setMedia(null), [])

  const openMedia = useCallback((url: string, type?: MediaType) => {
    if (!url) return
    setMedia({ url, type: type ?? (isVideoPath(url) ? 'video' : 'image') })
  }, [])

  // Fermer avec Échap
  useEffect(() => {
    if (!media) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeMedia()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [media, closeMedia])

  // Verrouiller le scroll du body quand le modal est ouvert
  useEffect(() => {
    if (!media) return
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.body.style.overflow = prev
    }
  }, [media])

  const value = useMemo(() => ({ openMedia, closeMedia }), [openMedia, closeMedia])

  return (
    <MediaViewerContext.Provider value={value}>
      {children}

      {/* ─── Modal plein écran ─── */}
      {media && (
        <div
          className="fixed inset-0 z-[100] bg-black/90 flex items-center justify-center p-4"
          onClick={closeMedia}
        >
          {/* Bouton fermer */}
          <button
            onClick={closeMedia}
            className="absolute top-4 right-4 z-10 w-10 h-10 rounded-full bg-black/50 text-white flex items-center justify-center hover:bg-black/70 transition-colors"
            title="Fermer (Échap)"
            aria-label="Fermer"
          >
            <X size={22} />
          </button>

          {media.type === 'video' ? (
            // eslint-disable-next-line jsx-a11y/media-has-caption
            <video
              src={media.url}
              controls
              autoPlay
              playsInline
              className="max-w-full max-h-full rounded-xl shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            />
          ) : (
            <img
              src={media.url}
              alt="Média"
              className="max-w-full max-h-full object-contain rounded-xl shadow-2xl"
              onClick={(e) => e.stopPropagation()}
            />
          )}
        </div>
      )}
    </MediaViewerContext.Provider>
  )
}
