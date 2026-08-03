import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Calendar,
  SlidersHorizontal,
  RefreshCw,
  BarChart3,
  ArrowLeftRight,
  PieChart,
  CheckCircle2,
  TrendingUp,
  Hash,
  PiggyBank,
  AlertTriangle,
  Donut,
  FileText,
  X,
} from 'lucide-react'
import Layout from '../components/Layout'
import { getRapport, getRapportByProjet } from '../api/rapportApi'
import { getUser } from '../api/jwtService'
import { useProjetActif } from '../context/ProjetActifContext'
import type {
  RapportResponseDto,
  FuiteResumeDto,
} from '../types'

/* ─── Constantes OCP (mêmes couleurs que le mobile) ─── */
const OCP_GREEN = '#00875a'
const OCP_GREY = '#757575'
const OCP_LIGHT_GREY = '#f5f5f5'
const RED = '#d32f2f'
const RED_BG = '#ffebee'
const GREEN_BG = '#e8f5e9'
const ORANGE = '#f57c00'
const ORANGE_BG = '#fff3e0'
const BLUE = '#1565c0'

/* ─── Périodes ─── */
const PERIODES = [
  { code: 'ALL', label: 'Tout' },
  { code: '1M', label: '1 mois' },
  { code: '3M', label: '3 mois' },
  { code: '6M', label: '6 mois' },
  { code: '1Y', label: '1 an' },
]

/* ─── Métriques ─── */
const TOUTES_LES_METRICS = [
  { id: 'top_priority', emoji: '💰', label: 'Pertes vs Économies' },
  { id: 'nb_campagnes', emoji: '📊', label: 'Nombre de fuites par campagne' },
  { id: 'pertes_campagnes', emoji: '💸', label: 'Pertes vs Économies par campagne' },
  { id: 'cout_statut', emoji: '📋', label: 'Coût par statut' },
  { id: 'taux_reparation', emoji: '✅', label: 'Taux de réparation' },
  { id: 'top5_actives', emoji: '🔴', label: 'Top 5 fuites actives' },
  { id: 'top5_reparees', emoji: '🟢', label: 'Top 5 fuites réparées' },
  { id: 'diagrammes', emoji: '🥧', label: 'Diagrammes circulaires' },
] as const

type MetricId = (typeof TOUTES_LES_METRICS)[number]['id']

/* ─── Palette du pie chart (identique mobile) ─── */
const PIE_PALETTE = [
  '#00875a', // OCP Green
  '#1565c0', // Blue
  '#d32f2f', // Red
  '#f57c00', // Orange
  '#7b1fa2', // Purple
  '#00838f', // Teal
  '#283593', // Indigo
  '#ad1457', // Pink
  '#4e342e', // Brown
  '#558b2f', // Light Green
]

/** Formatte un coût : 1 234 567 MAD (espace milliers, comme mobile). */
function formatCout(valeur: number): string {
  const intPart = Math.round(valeur).toString()
  const buffer: string[] = []
  for (let i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 === 0) buffer.push(' ')
    buffer.push(intPart[i])
  }
  return `${buffer.join('')} MAD`
}

/* ════════════════════════════════════════════════
   PAGE RAPPORTS & ANALYSES
   Réplique exacte de rapports_page.dart
   ════════════════════════════════════════════════ */

export default function RapportsPage() {
  const [periode, setPeriode] = useState('ALL')
  const [metricsVisibles, setMetricsVisibles] = useState<Set<MetricId>>(
    () => new Set(TOUTES_LES_METRICS.map((m) => m.id)),
  )
  const [rapport, setRapport] = useState<RapportResponseDto | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showMetrics, setShowMetrics] = useState(false)

  const { projetActif, loading: projetLoading } = useProjetActif()
  const user = getUser()
  const navigate = useNavigate()

  const projetId = projetActif?.id ?? null
  const utilisateurId = user?.id ?? 0

  const chargerRapport = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = projetId != null
        ? await getRapportByProjet({ projetId, periode })
        : await getRapport({ utilisateurId, periode })
      setRapport(data)
    } catch (e) {
      setError(`Erreur : ${e instanceof Error ? e.message : String(e)}`)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (!projetLoading) {
      void chargerRapport()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projetLoading, projetId, periode])

  const toggleMetric = (id: MetricId) => {
    setMetricsVisibles((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const changerPeriode = (code: string) => {
    if (periode !== code) {
      setPeriode(code)
    }
  }

  const downloadPdf = () => {
    if (projetId == null) {
      setError('❌ Aucun projet sélectionné')
      return
    }
    const metrics = Array.from(metricsVisibles)
    const titre = `Rapport OCP - ${rapport?.periodeLibelle ?? ''}`
    navigate(
      `/rapports/pdf?projetId=${projetId}&periode=${periode}&titre=${encodeURIComponent(titre)}&metrics=${metrics.join(',')}`,
    )
  }

  return (
    <Layout>
      <div className="p-6 max-w-4xl mx-auto">
        <div className="flex items-center justify-between gap-4 mb-4">
          <h1 className="text-2xl font-black tracking-tight text-[#111111]">
            Rapports & Analyses
          </h1>
          <button
            onClick={() => setShowMetrics(true)}
            title="Métriques à afficher"
            className="p-2.5 rounded-xl hover:bg-[#f5f5f5] transition-colors text-[#111111]"
          >
            <SlidersHorizontal size={20} />
          </button>
        </div>

        {/* ── Barre de période ── */}
        <div className="flex items-center gap-3 px-1 py-3 overflow-x-auto">
          <Calendar size={18} className="text-[#00875a] flex-shrink-0" />
          <div className="flex gap-2 flex-shrink-0">
            {PERIODES.map((p) => {
              const selected = periode === p.code
              return (
                <button
                  key={p.code}
                  onClick={() => changerPeriode(p.code)}
                  className={`px-3.5 py-1.5 rounded-full text-[13px] transition-colors ${
                    selected
                      ? 'bg-[#00875a] text-white font-bold'
                      : 'bg-[#f5f5f5] text-[#757575] hover:bg-[#e0e0e0]'
                  }`}
                >
                  {p.label}
                </button>
              )
            })}
          </div>
        </div>
        <div className="border-t border-black/10" />

        {/* ── Contenu ── */}
        <div className="mt-4">
          {loading ? (
            <Shimmer />
          ) : error ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <AlertTriangle size={48} className="text-[#d32f2f] mb-3" />
              <p className="text-[#d32f2f]">{error}</p>
              <button
                onClick={() => void chargerRapport()}
                className="mt-4 flex items-center gap-2 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
              >
                <RefreshCw size={16} />
                Réessayer
              </button>
            </div>
          ) : !rapport ? (
            <div className="py-16 text-center text-[#757575]">
              Aucune donnée disponible
            </div>
          ) : (
            <div className="space-y-4 pb-16">
              {/* En-tête période */}
              <div className="flex items-center gap-2 mb-2">
                <span className="px-2.5 py-1 rounded-full bg-[#00875a]/10 text-[#005c3e] font-bold text-[13px]">
                  {rapport.periodeLibelle ?? ''}
                </span>
                <span className="text-[12px] text-[#757575]">
                  {rapport.dateDebut ?? ''} → {rapport.dateFin ?? ''}
                </span>
              </div>

              {/* TOP PRIORITY */}
              {metricsVisibles.has('top_priority') && (
                <div className="grid grid-cols-2 gap-3">
                  <MetricCard
                    icon={<AlertTriangle size={18} />}
                    title="Coût fuites actives"
                    value={formatCout(rapport.coutFuitesActives ?? 0)}
                    accentColor={RED}
                    bgColor={RED_BG}
                  />
                  <MetricCard
                    icon={<PiggyBank size={18} />}
                    title="Économies réalisées"
                    value={formatCout(rapport.economiesRealisees ?? 0)}
                    accentColor={OCP_GREEN}
                    bgColor={GREEN_BG}
                  />
                </div>
              )}

              {/* Nombre de fuites par campagne */}
              {metricsVisibles.has('nb_campagnes') && (
                <SectionCard
                  icon={<BarChart3 size={18} />}
                  title="Nombre de fuites par campagne"
                >
                  <MapList
                    map={rapport.fuitesParCampagne ?? {}}
                    suffixe=" fuite(s)"
                  />
                </SectionCard>
              )}

              {/* Pertes vs Économies par campagne */}
              {metricsVisibles.has('pertes_campagnes') && (
                <PertesVsEconomies rapport={rapport} />
              )}

              {/* Coût par statut */}
              {metricsVisibles.has('cout_statut') && (
                <CoutParStatut rapport={rapport} />
              )}

              {/* Taux de réparation */}
              {metricsVisibles.has('taux_reparation') && (
                <TauxReparation rapport={rapport} />
              )}

              {/* Top 5 fuites actives */}
              {metricsVisibles.has('top5_actives') && (
                <Top5Liste
                  titre="🔴 Top 5 fuites actives les plus coûteuses"
                  liste={rapport.top5Actives ?? []}
                  accentColor={RED}
                />
              )}

              {/* Top 5 fuites réparées */}
              {metricsVisibles.has('top5_reparees') && (
                <Top5Liste
                  titre="🟢 Top 5 fuites réparées les plus coûteuses"
                  liste={rapport.top5Reparees ?? []}
                  accentColor={OCP_GREEN}
                />
              )}

              {/* Diagrammes circulaires */}
              {metricsVisibles.has('diagrammes') && (
                <DiagrammesCirculaires rapport={rapport} />
              )}

              {/* Bouton PDF */}
              <button
                onClick={downloadPdf}
                className="w-full flex items-center justify-center gap-2 px-4 py-3.5 rounded-xl bg-[#005c3e] text-white text-[15px] font-bold hover:bg-[#00472f] transition-colors"
              >
                <FileText size={18} />
                Visualiser le rapport PDF
              </button>
            </div>
          )}
        </div>
      </div>

      {/* ── Popup métriques ── */}
      {showMetrics && (
        <MetricsPopup
          metricsVisibles={metricsVisibles}
          onToggle={toggleMetric}
          onClose={() => setShowMetrics(false)}
        />
      )}
    </Layout>
  )
}

/* ════════════════════════════════════════════════
   SOUS-COMPOSANTS
   ════════════════════════════════════════════════ */

function MetricCard({
  icon,
  title,
  value,
  accentColor,
  bgColor,
}: {
  icon: React.ReactNode
  title: string
  value: string
  accentColor: string
  bgColor: string
}) {
  return (
    <div className="bg-white border border-black/10 rounded-2xl p-4 shadow-sm">
      <div className="flex items-center justify-between gap-2 mb-2">
        <span
          className="text-[11px] font-bold text-[#757575] truncate"
          style={{ maxWidth: '80%' }}
        >
          {title}
        </span>
        <span
          className="p-1.5 rounded-full flex-shrink-0"
          style={{ backgroundColor: bgColor, color: accentColor }}
        >
          {icon}
        </span>
      </div>
      <p className="text-[22px] font-black text-[#111111]">{value}</p>
      <p className="text-[11px] text-[#757575]/70">MAD/an</p>
    </div>
  )
}

function SectionCard({
  icon,
  title,
  children,
}: {
  icon: React.ReactNode
  title: string
  children: React.ReactNode
}) {
  return (
    <div className="bg-white border border-black/10 rounded-2xl p-4 shadow-sm">
      <div className="flex items-center gap-2 mb-3">
        <span className="text-[#00875a]">{icon}</span>
        <h3 className="text-[15px] font-black text-[#111111]">{title}</h3>
      </div>
      {children}
    </div>
  )
}

function MapList({ map, suffixe = '' }: { map: Record<string, number>; suffixe?: string }) {
  const entries = Object.entries(map ?? {})
  if (entries.length === 0) {
    return <p className="text-[13px] text-[#757575]">Aucune donnée</p>
  }
  const total = entries.reduce((acc, [, v]) => acc + v, 0)
  return (
    <div className="space-y-2">
      {entries.map(([key, value]) => {
        const ratio = total > 0 ? value / total : 0
        return (
          <div key={key}>
            <div className="flex justify-between items-center gap-2">
              <span className="text-[13px] text-[#111111] truncate">{key}</span>
              <span className="text-[13px] font-bold text-[#111111]">{value}{suffixe}</span>
            </div>
            <div className="mt-1 h-1.5 rounded bg-[#f5f5f5] overflow-hidden">
              <div
                className="h-full rounded bg-[#00875a]"
                style={{ width: `${Math.min(ratio * 100, 100)}%` }}
              />
            </div>
          </div>
        )
      })}
    </div>
  )
}

function PertesVsEconomies({ rapport }: { rapport: RapportResponseDto }) {
  const campagnes = Object.keys(rapport.fuitesParCampagne ?? {})
  return (
    <SectionCard
      icon={<ArrowLeftRight size={18} />}
      title="Pertes vs Économies par campagne"
    >
      {campagnes.length === 0 ? (
        <p className="text-[13px] text-[#757575]">Aucune donnée</p>
      ) : (
        <div className="space-y-3">
          {campagnes.map((nom) => {
            const pertes = rapport.pertesParCampagne?.[nom] ?? 0
            const economies = rapport.economiesParCampagne?.[nom] ?? 0
            return (
              <div key={nom}>
                <p className="text-[13px] font-bold text-[#111111] mb-1">{nom}</p>
                <div className="grid grid-cols-2 gap-3">
                  <MiniBar label="Pertes" value={pertes} color={RED} />
                  <MiniBar label="Économies" value={economies} color={OCP_GREEN} />
                </div>
              </div>
            )
          })}
        </div>
      )}
    </SectionCard>
  )
}

function MiniBar({
  label,
  value,
  color,
}: {
  label: string
  value: number
  color: string
}) {
  return (
    <div>
      <p className="text-[12px] font-semibold" style={{ color }}>
        {label} : {formatCout(value)}
      </p>
      <div className="mt-1 h-2 rounded bg-[#f5f5f5] overflow-hidden">
        <div
          className="h-full rounded"
          style={{ backgroundColor: color, width: value > 0 ? '100%' : '0%' }}
        />
      </div>
    </div>
  )
}

const STATUT_LABELS: Record<string, string> = {
  A_REPARER: 'À réparer',
  EN_COURS: 'En cours',
  REPAREE: 'Réparée',
  ANNULEE: 'Annulée',
}

const STATUT_COLORS: Record<string, string> = {
  A_REPARER: RED,
  EN_COURS: ORANGE,
  REPAREE: OCP_GREEN,
  ANNULEE: OCP_GREY,
}

function CoutParStatut({ rapport }: { rapport: RapportResponseDto }) {
  const entries = Object.entries(rapport.coutParStatut ?? {})
  const total = entries.reduce((acc, [, v]) => acc + v, 0)
  return (
    <SectionCard
      icon={<PieChart size={18} />}
      title="Coût total par statut"
    >
      {entries.length === 0 ? (
        <p className="text-[13px] text-[#757575]">Aucune donnée</p>
      ) : (
        <div className="space-y-2.5">
          {entries.map(([key, value]) => {
            const ratio = total > 0 ? value / total : 0
            const label = STATUT_LABELS[key] ?? key
            const color = STATUT_COLORS[key] ?? OCP_GREY
            return (
              <div key={key} className="flex items-center gap-2">
                <span
                  className="w-2.5 h-2.5 rounded-full flex-shrink-0"
                  style={{ backgroundColor: color }}
                />
                <span className="text-[13px] text-[#111111] w-[90px] flex-shrink-0">{label}</span>
                <div className="flex-1 h-2 rounded bg-[#f5f5f5] overflow-hidden">
                  <div
                    className="h-full rounded"
                    style={{ backgroundColor: color, width: `${Math.min(ratio * 100, 100)}%` }}
                  />
                </div>
                <span className="text-[13px] font-bold text-[#111111] w-[100px] text-right flex-shrink-0">
                  {formatCout(value)}
                </span>
              </div>
            )
          })}
        </div>
      )}
    </SectionCard>
  )
}

function TauxReparation({ rapport }: { rapport: RapportResponseDto }) {
  const tauxGlobal = rapport.tauxReparationGlobal ?? 0
  const totalFuites = rapport.totalFuites ?? 0
  const nbReparees = rapport.top5Reparees?.length ?? 0
  const parCampagne = Object.entries(rapport.tauxReparationParCampagne ?? {})

  return (
    <SectionCard
      icon={<CheckCircle2 size={18} />}
      title="Taux de réparation"
    >
      {/* Taux global — anneau circulaire */}
      <div className="flex items-center gap-4">
        <div
          className="relative w-20 h-20 rounded-full flex items-center justify-center"
          style={{
            background: `conic-gradient(${tauxGlobal >= 50 ? OCP_GREEN : ORANGE} ${tauxGlobal * 3.6}deg, ${OCP_LIGHT_GREY} 0deg)`,
          }}
        >
          <div className="absolute inset-1.5 rounded-full bg-white" />
          <span className="relative text-[18px] font-black text-[#111111]">
            {tauxGlobal.toFixed(0)}%
          </span>
        </div>
        <div>
          <p className="text-[14px] font-bold text-[#111111]">Global</p>
          <p className="text-[12px] text-[#757575]">
            {totalFuites} fuites · {nbReparees} réparées
          </p>
        </div>
      </div>

      {parCampagne.length > 0 && (
        <>
          <div className="border-t border-black/10 my-4" />
          <div className="space-y-2">
            {parCampagne.map(([key, value]) => (
              <div key={key} className="flex items-center gap-2">
                <span className="flex-1 text-[13px] text-[#111111] truncate">{key}</span>
                <span
                  className="px-2 py-0.5 rounded-full text-[12px] font-bold"
                  style={{
                    backgroundColor: value >= 50 ? GREEN_BG : ORANGE_BG,
                    color: value >= 50 ? OCP_GREEN : ORANGE,
                  }}
                >
                  {value.toFixed(0)}%
                </span>
              </div>
            ))}
          </div>
        </>
      )}
    </SectionCard>
  )
}

function Top5Liste({
  titre,
  liste,
  accentColor,
}: {
  titre: string
  liste: FuiteResumeDto[]
  accentColor: string
}) {
  return (
    <div className="bg-white border border-black/10 rounded-2xl p-4 shadow-sm">
      <h3 className="text-[15px] font-black text-[#111111] mb-3">{titre}</h3>
      {liste.length === 0 ? (
        <p className="text-[13px] text-[#757575]">Aucune fuite</p>
      ) : (
        <div className="space-y-2">
          {liste.map((f, i) => (
            <div key={f.id} className="flex items-center gap-2.5">
              <span
                className="w-6 h-6 rounded-md flex items-center justify-center text-[12px] font-bold"
                style={{ backgroundColor: `${accentColor}1a`, color: accentColor }}
              >
                {i + 1}
              </span>
              <div className="flex-1 min-w-0">
                <p className="text-[13px] font-bold text-[#111111] truncate">
                  {f.numeroTag ?? 'Sans tag'}
                </p>
                <p className="text-[11px] text-[#757575] truncate">{f.campagneNom}</p>
              </div>
              <span
                className="text-[14px] font-black flex-shrink-0"
                style={{ color: accentColor }}
              >
                {formatCout(f.coutAnnuelEstime ?? 0)}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function DiagrammesCirculaires({ rapport }: { rapport: RapportResponseDto }) {
  return (
    <SectionCard
      icon={<Donut size={18} />}
      title="Répartition par campagne"
    >
      <DiagrammeRow
        icon={<Hash size={16} />}
        label="Nombre de fuites"
        data={rapport.repartitionNbrCampagnes ?? {}}
        color={BLUE}
      />
      <div className="my-4 border-t border-black/10" />
      <DiagrammeRow
        icon={<TrendingUp size={16} />}
        label="Pertes estimées (MAD)"
        data={rapport.repartitionPertesCampagnes ?? {}}
        color={RED}
      />
      <div className="my-4 border-t border-black/10" />
      <DiagrammeRow
        icon={<PiggyBank size={16} />}
        label="Économies (MAD)"
        data={rapport.repartitionEconomiesCampagnes ?? {}}
        color={OCP_GREEN}
      />
    </SectionCard>
  )
}

function DiagrammeRow({
  icon,
  label,
  data,
  color,
}: {
  icon: React.ReactNode
  label: string
  data: Record<string, number>
  color: string
}) {
  const total = useMemo(
    () => Object.values(data ?? {}).reduce((acc, v) => acc + v, 0),
    [data],
  )
  if (total === 0) return null

  return (
    <div>
      <div className="flex items-center gap-1.5 mb-3">
        <span style={{ color }}>{icon}</span>
        <span className="text-[13px] font-bold text-[#111111]">{label}</span>
      </div>
      <PieChartWidget data={data} />
      <div className="border-t border-black/10 my-4" />
    </div>
  )
}

/* ─── Pie Chart (donut) — réplique de pie_chart_widget.dart ─── */
function PieChartWidget({ data }: { data: Record<string, number> }) {
  const total = useMemo(
    () => Object.values(data ?? {}).reduce((acc, v) => acc + v, 0),
    [data],
  )
  const entries = useMemo(
    () =>
      Object.entries(data ?? {})
        .filter(([, v]) => v > 0)
        .sort((a, b) => b[1] - a[1]),
    [data],
  )
  if (total === 0) return null

  return (
    <div className="flex items-center gap-5">
      {/* Camembert */}
      <DonutChart entries={entries} total={total} />
      {/* Légende */}
      <div className="flex-1 space-y-1.5">
        {entries.map(([key, value], i) => {
          const ratio = (value / total) * 100
          const color = PIE_PALETTE[i % PIE_PALETTE.length]
          return (
            <div key={key} className="flex items-center gap-2">
              <span
                className="w-3 h-3 rounded-full flex-shrink-0"
                style={{ backgroundColor: color }}
              />
              <span className="flex-1 text-[12px] text-[#111111] truncate">{key}</span>
              <span className="text-[12px] font-bold" style={{ color }}>
                {ratio.toFixed(1)}%
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}

function DonutChart({
  entries,
  total,
}: {
  entries: [string, number][]
  total: number
}) {
  let acc = 0
  const segments = entries.map(([, value], i) => {
    const start = (acc / total) * 360
    acc += value
    const sweep = (value / total) * 360
    const color = PIE_PALETTE[i % PIE_PALETTE.length]
    return { start, sweep, color }
  })

  return (
    <div
      className="relative w-[160px] h-[160px] rounded-full flex-shrink-0"
      style={{
        background: `conic-gradient(${segments
          .map(
            (s) =>
              `${s.color} ${s.start + 0.5}deg ${s.start + s.sweep - 0.5}deg`,
          )
          .join(', ')})`,
      }}
    >
      <div className="absolute inset-[28%] rounded-full bg-white" />
    </div>
  )
}

/* ─── Shimmer (squelette de chargement, comme mobile) ─── */
function Shimmer() {
  return (
    <div className="space-y-4">
      <div className="h-[60px] rounded-xl bg-[#f5f5f5] animate-pulse" />
      <div className="grid grid-cols-2 gap-3">
        <div className="h-[80px] rounded-xl bg-[#f5f5f5] animate-pulse" />
        <div className="h-[80px] rounded-xl bg-[#f5f5f5] animate-pulse" />
      </div>
      <div className="h-[100px] rounded-xl bg-[#f5f5f5] animate-pulse" />
      <div className="h-[80px] rounded-xl bg-[#f5f5f5] animate-pulse" />
      <div className="h-[120px] rounded-xl bg-[#f5f5f5] animate-pulse" />
      <div className="h-[80px] rounded-xl bg-[#f5f5f5] animate-pulse" />
      <div className="h-[100px] rounded-xl bg-[#f5f5f5] animate-pulse" />
    </div>
  )
}

/* ─── Popup métriques (équivalent PopupMenuButton mobile) ─── */
function MetricsPopup({
  metricsVisibles,
  onToggle,
  onClose,
}: {
  metricsVisibles: Set<MetricId>
  onToggle: (id: MetricId) => void
  onClose: () => void
}) {
  return (
    <div
      className="fixed inset-0 z-50 bg-black/40 flex items-end sm:items-center justify-center"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-xl max-h-[80vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-[#e5e7eb] sticky top-0 bg-white">
          <h2 className="text-[15px] font-bold text-[#111111]">
            Métriques à inclure
          </h2>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-[#757575] hover:bg-[#f5f5f5] transition-colors"
            aria-label="Fermer"
          >
            <X size={18} />
          </button>
        </div>
        <div className="p-3">
          {TOUTES_LES_METRICS.map((m) => {
            const checked = metricsVisibles.has(m.id)
            return (
              <button
                key={m.id}
                onClick={() => onToggle(m.id)}
                className="flex items-center gap-3 w-full px-2 py-2.5 rounded-xl hover:bg-[#f5f5f5] transition-colors text-left"
              >
                <span
                  className={`w-5 h-5 rounded-md border flex items-center justify-center flex-shrink-0 transition-colors ${
                    checked
                      ? 'bg-[#00875a] border-[#00875a] text-white'
                      : 'border-[#9ca3af]'
                  }`}
                >
                  {checked && (
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M20 6L9 17l-5-5" />
                    </svg>
                  )}
                </span>
                <span className="text-[14px] text-[#111111]">
                  {m.emoji} {m.label}
                </span>
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
