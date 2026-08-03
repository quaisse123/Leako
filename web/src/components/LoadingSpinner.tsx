import { Loader2 } from 'lucide-react'

/**
 * Spinner de chargement centré.
 */
export default function LoadingSpinner() {
  return (
    <div className="flex items-center justify-center py-16">
      <Loader2 size={32} className="animate-spin text-[#00875a]" />
    </div>
  )
}
