import { useEffect, useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import {
  ArrowLeft,
  Download,
  FileText,
  RefreshCw,
  AlertTriangle,
} from 'lucide-react'
import { getPdfUrl } from '../api/rapportApi'
import { getAuthHeaders } from '../api/jwtService'

/**
 * 📄 Page de visualisation du rapport PDF.
 * Équivalent web de pdf_viewer_page.dart :
 * télécharge les bytes du PDF depuis le backend, les affiche dans la
 * visionneuse native du navigateur (iframe via Blob URL), avec bouton
 * de téléchargement.
 */
export default function PdfViewerPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()

  const projetId = Number(searchParams.get('projetId') ?? 0)
  const periode = searchParams.get('periode') ?? 'ALL'
  const titre = searchParams.get('titre') ?? 'Rapport OCP'
  const metrics = (searchParams.get('metrics') ?? '')
    .split(',')
    .filter((m) => m.length > 0)

  const [pdfUrl, setPdfUrl] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const chargerPdf = async () => {
    setLoading(true)
    setError(null)
    try {
      const url = getPdfUrl({ projetId, periode, metrics })
      const response = await fetch(url, { headers: getAuthHeaders() })
      if (!response.ok) {
        throw new Error(`Erreur serveur (${response.status})`)
      }
      const blob = await response.blob()
      // Crée une URL objet pour afficher le PDF dans l'iframe
      const objectUrl = URL.createObjectURL(blob)
      setPdfUrl(objectUrl)
      setLoading(false)
    } catch (e) {
      setError(`Erreur de chargement : ${e instanceof Error ? e.message : String(e)}`)
      setLoading(false)
    }
  }

  useEffect(() => {
    if (projetId > 0) {
      chargerPdf()
    } else {
      setError('❌ Aucun projet sélectionné')
      setLoading(false)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projetId])

  const telechargerPdf = () => {
    if (!pdfUrl) return
    // Téléchargement direct via l'URL Blob (attribut download)
    const a = document.createElement('a')
    a.href = pdfUrl
    a.download = `rapport_ocp_${projetId}.pdf`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
  }

  return (
    <div className="min-h-screen bg-white flex flex-col">
      {/* ── Barre supérieure (équivalent AppBar mobile) ── */}
      <header className="flex items-center justify-between px-4 py-3 border-b border-black/10 bg-white">
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate(-1)}
            className="p-2 rounded-lg hover:bg-[#f5f5f5] transition-colors text-[#111111]"
            aria-label="Retour"
          >
            <ArrowLeft size={22} />
          </button>
          <h1 className="text-[18px] font-black text-[#111111] truncate">
            {titre}
          </h1>
        </div>
        {pdfUrl && (
          <button
            onClick={telechargerPdf}
            title="Télécharger le PDF"
            className="flex items-center gap-2 px-3 py-2 rounded-lg text-[#00875a] hover:bg-[#e8f5e9] transition-colors font-semibold text-sm"
          >
            <Download size={20} />
            <span className="hidden sm:inline">Télécharger</span>
          </button>
        )}
      </header>

      {/* ── Corps ── */}
      <div className="flex-1 flex flex-col">
        {loading ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-4">
            <div className="w-10 h-10 border-4 border-[#00875a] border-t-transparent rounded-full animate-spin" />
            <p className="text-[#757575] text-[15px]">Génération du rapport…</p>
          </div>
        ) : error ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-4 px-8 text-center">
            <AlertTriangle size={56} className="text-[#d32f2f]" />
            <p className="text-[#d32f2f] text-[15px]">{error}</p>
            <button
              onClick={chargerPdf}
              className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
            >
              <RefreshCw size={16} />
              Réessayer
            </button>
          </div>
        ) : pdfUrl ? (
          <div className="flex-1 flex flex-col">
            {/* Visionneuse PDF native du navigateur */}
            <iframe
              src={pdfUrl}
              title="Rapport PDF"
              className="flex-1 w-full border-0"
            />
            {/* Barre d'actions basse (équivalent boutons mobile) */}
            <div className="flex items-center justify-center gap-3 px-4 py-3 border-t border-black/10 bg-white">
              <button
                onClick={telechargerPdf}
                className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-bold hover:bg-[#005c3e] transition-colors"
              >
                <Download size={16} />
                Télécharger le PDF
              </button>
            </div>
          </div>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center gap-4">
            <FileText size={64} className="text-[#00875a]" />
            <p className="text-[18px] font-bold text-[#111111]">PDF prêt</p>
          </div>
        )}
      </div>
    </div>
  )
}
