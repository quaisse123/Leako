import {
  AlertTriangle,
  CheckCircle2,
  Cloud,
  Droplets,
  HelpCircle,
  Image as ImageIcon,
  Ruler,
  Signal,
  SignalHigh,
  SignalLow,
  SignalMedium,
  Sparkles,
  XCircle,
} from 'lucide-react'
import type { AnalyseIAReponse } from '../types'

/** Icône + couleur selon le type de fuite (équivalent du switch mobile). */
function typeIcone(type: string): { icon: React.ReactNode; color: string } {
  switch (type) {
    case 'liquide':
      return { icon: <Droplets size={20} />, color: '#1565C0' }
    case 'vapeur':
      return { icon: <Cloud size={20} />, color: '#78909C' }
    case 'mixte':
      return { icon: <Droplets size={20} />, color: '#6A1B9A' }
    default:
      return { icon: <HelpCircle size={20} />, color: '#9ca3af' }
  }
}

/** Icône + couleur selon l'intensité (équivalent du switch mobile). */
function intensiteIcone(intensite: string): { icon: React.ReactNode; color: string } {
  switch (intensite) {
    case 'faible':
      return { icon: <SignalLow size={20} />, color: '#F9A825' }
    case 'moyenne':
      return { icon: <SignalMedium size={20} />, color: '#EF6C00' }
    case 'forte':
      return { icon: <SignalHigh size={20} />, color: '#D32F2F' }
    default:
      return { icon: <Signal size={20} />, color: '#9ca3af' }
  }
}

/** Petit encart d'info (équivalent _iaInfoChip du mobile). */
function IaInfoChip({
  icon,
  label,
  subtitle,
  color,
}: {
  icon: React.ReactNode
  label: string
  subtitle: string
  color: string
}) {
  return (
    <div
      className="flex-1 rounded-[10px] p-2.5 flex flex-col items-center gap-1 min-w-0"
      style={{ backgroundColor: `${color}14` }}
    >
      <span style={{ color }}>{icon}</span>
      <span
        className="text-[13px] font-bold text-center truncate w-full"
        style={{ color }}
      >
        {label}
      </span>
      <span className="text-[10px]" style={{ color: `${color}B3` }}>
        {subtitle}
      </span>
    </div>
  )
}

/**
 * Carte de prédiction IA (équivalent _buildCartePredictionIA du mobile).
 */
export default function CartePredictionIA({ reponse }: { reponse: AnalyseIAReponse }) {
  const r = reponse.resume
  const confiancePourcent = Math.round(r.confianceMoyenne * 100)

  const type = typeIcone(r.typeFuite)
  const intensite = intensiteIcone(r.intensite)

  const fuiteVisible = reponse.resultats.filter((x) => x.fuiteVisible).length
  const ignorees = reponse.resultats.length - fuiteVisible

  const confianceCouleur =
    confiancePourcent >= 70 ? '#00875A' : confiancePourcent >= 40 ? '#F9A825' : '#D32F2F'

  return (
    <div
      className="w-full rounded-[14px] border p-4"
      style={{
        backgroundColor: '#7B1FA20F',
        borderColor: '#7B1FA240',
      }}
    >
      {/* ── En-tête ── */}
      <div className="flex items-center">
        <div
          className="p-1.5 rounded-lg"
          style={{ backgroundColor: '#7B1FA21F' }}
        >
          <Sparkles size={16} className="text-[#7B1FA2]" />
        </div>
        <span className="ml-2.5 text-[15px] font-extrabold text-[#7B1FA2]">Analyse IA</span>
        <div className="ml-auto flex items-center gap-1 rounded-full px-2 py-0.5" style={{ backgroundColor: '#00875A1A' }}>
          <CheckCircle2 size={12} className="text-[#00875A]" />
          <span className="text-[11px] font-bold text-[#00875A]">Utilisé</span>
        </div>
      </div>

      <div className="h-3.5" />

      {/* ── Grille d'infos ── */}
      <div className="flex gap-2">
        <IaInfoChip icon={type.icon} label={r.typeFuite} subtitle="Type" color={type.color} />
        <IaInfoChip icon={intensite.icon} label={r.intensite} subtitle="Intensité" color={intensite.color} />
        <IaInfoChip
          icon={<Ruler size={20} />}
          label={`${r.diametreMoyenMm.toFixed(1)} mm`}
          subtitle="Diamètre"
          color="#00875A"
        />
      </div>

      <div className="h-3.5" />

      {/* ── Barre de confiance ── */}
      <div>
        <div className="flex items-center justify-between">
          <span className="text-xs text-[#757575]">Confiance</span>
          <span className="text-[13px] font-bold text-[#7B1FA2]">{confiancePourcent}%</span>
        </div>
        <div className="mt-1.5 h-2 rounded overflow-hidden" style={{ backgroundColor: '#7B1FA21F' }}>
          <div
            className="h-full rounded"
            style={{
              width: `${Math.min(100, Math.max(0, confiancePourcent))}%`,
              backgroundColor: confianceCouleur,
            }}
          />
        </div>
      </div>

      <div className="h-3" />

      {/* ── Nombre de médias analysés ── */}
      <div className="flex items-center text-xs text-[#757575]">
        <ImageIcon size={14} className="text-[#9e9e9e]" />
        <span className="ml-1.5">{reponse.resultats.length} analysé(s)</span>
        <CheckCircle2 size={14} className="ml-3 text-[#00875A]" />
        <span className="ml-1 text-[#00875A] font-semibold">{fuiteVisible} fuite(s)</span>
        <XCircle size={14} className="ml-3 text-[#bdbdbd]" />
        <span className="ml-1 text-[#9e9e9e]">{ignorees} ignorée(s)</span>
        {reponse.warnings && reponse.warnings.length > 0 && (
          <>
            <AlertTriangle size={14} className="ml-3 text-[#fb923c]" />
            <span className="ml-1 text-[11px] text-[#ea580c] truncate max-w-[120px]">
              {reponse.warnings[0]}
            </span>
          </>
        )}
      </div>
    </div>
  )
}
