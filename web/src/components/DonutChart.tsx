import type { ReactNode } from 'react'

interface DonutSegment {
  value: number
  color: string
  label?: string
}

interface DonutChartProps {
  /** Segments du donut. Pour un simple pourcentage, passer un seul segment (valeur = % sur 100). */
  segments: DonutSegment[]
  /** Taille du cercle en pixels. */
  size?: number
  /** Épaisseur de l'anneau. */
  thickness?: number
  /** Contenu central (ex: pourcentage). */
  center?: ReactNode
}

/**
 * DonutChart — cercle de progression en SVG pur (sans dépendance).
 * - Un seul segment → cercle de progression (ex: taux de réparation, valeur = % sur 100).
 * - Plusieurs segments → répartition (ex: fuites par campagne).
 */
export default function DonutChart({
  segments,
  size = 160,
  thickness = 18,
  center,
}: DonutChartProps) {
  const radius = (size - thickness) / 2
  const circumference = 2 * Math.PI * radius

  // Un seul segment = pourcentage absolu sur 100
  const isSingle = segments.length <= 1
  const total = isSingle
    ? 100
    : segments.reduce((sum, s) => sum + s.value, 0)

  // Accumulateur pour positionner chaque segment
  let offset = 0

  return (
    <div className="relative inline-flex items-center justify-center">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        {/* Fond de l'anneau */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="#f0f0f0"
          strokeWidth={thickness}
        />
        {total > 0 &&
          segments.map((seg, i) => {
            const value = isSingle ? seg.value : seg.value
            const fraction = value / total
            const dash = fraction * circumference
            const rotation = (offset / total) * 360
            offset += isSingle ? 100 : seg.value
            return (
              <circle
                key={i}
                cx={size / 2}
                cy={size / 2}
                r={radius}
                fill="none"
                stroke={seg.color}
                strokeWidth={thickness}
                strokeLinecap="round"
                strokeDasharray={`${dash} ${circumference - dash}`}
                transform={`rotate(${rotation} ${size / 2} ${size / 2})`}
              />
            )
          })}
      </svg>
      {center && (
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {center}
        </div>
      )}
    </div>
  )
}
