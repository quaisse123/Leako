import { useEffect, useState } from 'react'
import { ImageOff, Play } from 'lucide-react'
import { getPhotosByFuite } from '../api/photoApi'
import { fileUrl } from '../utils/fileUrl'
import { useMediaViewer } from '../context/MediaViewerContext'
import type { PhotoResponseDto } from '../types'

const VID_EXT = ['mp4', 'mov', 'avi', 'mkv', 'webm']

/** Miniature unique avec shimmer pendant le chargement. */
function Thumb({ src, isVideo }: { src: string; isVideo: boolean }) {
  const [loaded, setLoaded] = useState(false)
  const [failed, setFailed] = useState(false)
  const empty = !src

  return (
    <span
      className={`absolute inset-0 flex items-center justify-center rounded-lg overflow-hidden ${
        !loaded && !empty ? 'bg-[#f5f5f5] animate-pulse' : ''
      }`}
    >
      {failed || empty ? (
        <ImageOff size={18} className="text-[#9ca3af]" />
      ) : (
        <img
          src={src}
          alt=""
          loading="lazy"
          onLoad={() => setLoaded(true)}
          onError={() => setFailed(true)}
          className={`w-full h-full object-cover transition-opacity ${
            loaded ? 'opacity-100' : 'opacity-0'
          }`}
        />
      )}
      {isVideo && loaded && !failed && !empty && (
        <span className="absolute inset-0 flex items-center justify-center bg-black/30">
          <Play size={18} className="text-white" fill="white" />
        </span>
      )}
    </span>
  )
}

/**
 * Rangée de miniatures des photos d'une fuite — reproduit _FuiteCardPhotos (mobile).
 * Affiche jusqu'à 4 miniatures + badge "+N", avec shimmer pendant le chargement.
 */
export default function PhotosRow({ fuiteId }: { fuiteId: number }) {
  const [photos, setPhotos] = useState<PhotoResponseDto[] | null>(null)
  const { openMedia } = useMediaViewer()

  useEffect(() => {
    let cancelled = false
    setPhotos(null)
    getPhotosByFuite(fuiteId, 5)
      .then((data) => {
        if (!cancelled) setPhotos(data)
      })
      .catch(() => {
        if (!cancelled) setPhotos([])
      })
    return () => {
      cancelled = true
    }
  }, [fuiteId])

  // Shimmer de chargement (comme ShimmerPlaceholder mobile)
  if (photos === null) {
    return (
      <div className="flex items-center gap-1.5 py-2">
        {[0, 1, 2, 3].map((i) => (
          <div
            key={i}
            className="w-14 h-14 rounded-lg bg-[#f5f5f5] animate-pulse"
          />
        ))}
      </div>
    )
  }

  if (photos.length === 0) return null

  const display = photos.slice(0, 4)
  const extra = photos.length - 4

  return (
    <div className="flex items-center gap-1.5 py-2">
      {display.map((p) => {
        const ext = (p.cheminFichier ?? '').split('.').pop()?.toLowerCase() ?? ''
        const isVideo = VID_EXT.includes(ext)
        return (
          <button
            key={p.id}
            type="button"
            onClick={(e) => {
              e.stopPropagation()
              openMedia(fileUrl(p.cheminFichier), isVideo ? 'video' : 'image')
            }}
            className="relative block w-14 h-14 rounded-lg border border-[#e5e7eb] bg-white overflow-hidden cursor-pointer hover:opacity-90 transition-opacity"
            title={p.cheminFichier}
          >
            <Thumb src={fileUrl(p.thumbnailUrl ?? p.cheminFichier)} isVideo={isVideo} />
          </button>
        )
      })}
      {extra > 0 && (
        <div className="w-14 h-14 rounded-lg bg-[#f5f5f5] border border-[#e5e7eb] flex items-center justify-center text-sm font-bold text-[#757575]">
          +{extra}
        </div>
      )}
    </div>
  )
}
