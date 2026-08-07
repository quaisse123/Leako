import { useEffect, useState } from 'react'
import {
  TrendingUp,
  PiggyBank,
  ArrowRight,
  Bell,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import DonutChart from '../components/DonutChart'
import { getFuites } from '../api/fuiteApi'
import { getCampagnes } from '../api/campagneApi'
import { getMesInvitations } from '../api/projetApi'
import { useProjetActif } from '../context/ProjetActifContext'
import { useNavigate } from 'react-router-dom'
import type { FuiteResponseDto, InvitationResponseDto, CampagneResponseDto } from '../types'

interface Stats {
  totalFuites: number
  fuitesResolues: number
  fuitesEnCours: number
  fuitesCritiques: number
  totalCampagnes: number
  // ── Métriques mobiles ──
  sommeActives: number // coût annuel estimé des fuites A_REPARER + EN_COURS
  sommeReparees: number // coût annuel estimé des fuites REPAREE
  nbrActives: number // A_REPARER + EN_COURS
}

const STATUT_LABEL: Record<string, string> = {
  A_REPARER: 'À réparer',
  EN_COURS: 'En cours',
  REPAREE: 'Réparée',
  ANNULEE: 'Annulée',
}

/** Formate un coût à la manière du mobile : "628 kDH" / "1,10 M DH". */
function formatCout(valeur: number): string {
  if (valeur < 1000) return `${Math.round(valeur)} DH`
  if (valeur < 1_000_000) {
    const milliers = Math.round(valeur / 1000).toLocaleString('fr-FR')
    return `${milliers} kDH`
  }
  if (valeur < 1_000_000_000) {
    return `${(valeur / 1_000_000).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} M DH`
  }
  return `${(valeur / 1_000_000_000).toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} Md DH`
}

/**
 * Dashboard — KPIs + aperçu des fuites récentes.
 * Les données sont filtrées par le projet actif (comme l'app mobile).
 */
export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [recentFuites, setRecentFuites] = useState<FuiteResponseDto[]>([])
  const [allFuites, setAllFuites] = useState<FuiteResponseDto[]>([])
  const [campagnes, setCampagnes] = useState<CampagneResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const [invitations, setInvitations] = useState<InvitationResponseDto[]>([])
  const { projetActif, loading: projetLoading } = useProjetActif()
  const navigate = useNavigate()

  // Charger les invitations en attente (badge cloche)
  useEffect(() => {
    getMesInvitations()
      .then((invs) =>
        setInvitations(invs.filter((i) => i.statut === 'INVITE')),
      )
      .catch(() => setInvitations([]))
  }, [])

  useEffect(() => {
    if (projetLoading) return
    if (!projetActif) {
      setStats({ totalFuites: 0, fuitesResolues: 0, fuitesEnCours: 0, fuitesCritiques: 0, totalCampagnes: 0, sommeActives: 0, sommeReparees: 0, nbrActives: 0 })
      setRecentFuites([])
      setAllFuites([])
      setCampagnes([])
      setLoading(false)
      return
    }
    const load = async () => {
      setLoading(true)
      try {
        const [fuites, campagnes] = await Promise.all([
          getFuites({ projetId: projetActif.id }),
          getCampagnes(projetActif.id),
        ])
        setAllFuites(fuites)
        setCampagnes(campagnes)
        const sorted = [...fuites].sort(
          (a, b) =>
            new Date(b.dateDetection ?? 0).getTime() -
            new Date(a.dateDetection ?? 0).getTime(),
        )
        setRecentFuites(sorted.slice(0, 6))
        const actives = fuites.filter(
          (f) => f.statut === 'A_REPARER' || f.statut === 'EN_COURS',
        )
        const reparees = fuites.filter((f) => f.statut === 'REPAREE')
        setStats({
          totalFuites: fuites.length,
          fuitesResolues: reparees.length,
          fuitesEnCours: fuites.filter(
            (f) => f.statut !== 'REPAREE' && f.statut !== 'ANNULEE',
          ).length,
          fuitesCritiques: fuites.filter((f) => f.pressionBar != null && f.pressionBar >= 8).length,
          totalCampagnes: campagnes.length,
          sommeActives: actives.reduce((s, f) => s + (f.coutAnnuelEstime ?? 0), 0),
          sommeReparees: reparees.reduce((s, f) => s + (f.coutAnnuelEstime ?? 0), 0),
          nbrActives: actives.length,
        })
      } catch (err) {
        console.error('Erreur chargement dashboard:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [projetActif, projetLoading])

  if (loading || !stats) {
    return (
      <Layout>
        <LoadingSpinner />
      </Layout>
    )
  }

  const annee = new Date().getFullYear()

  // ── Taux de réparation ──
  const tauxReparation =
    stats.totalFuites > 0
      ? Math.round((stats.fuitesResolues / stats.totalFuites) * 100)
      : 0

  // ── Compteurs par statut (sous-titre carte 1) ──
  const aReparer = allFuites.filter((f) => f.statut === 'A_REPARER').length
  const enCours = allFuites.filter((f) => f.statut === 'EN_COURS').length

  // ── Pertes par campagne (coût des fuites actives) ──
  // On itère sur TOUTES les campagnes (même celles sans fuite active) pour
  // que chaque campagne apparaisse dans le graphique.
  const fuitesActives = allFuites.filter(
    (f) => f.statut === 'A_REPARER' || f.statut === 'EN_COURS',
  )
  const pertesParCampagne = new Map<string, number>()
  for (const f of fuitesActives) {
    const id = f.campagneId
    const nom = f.campagneNom || 'Sans campagne'
    // On somme par campagneId si dispo, sinon par nom
    const cle = id != null ? `id:${id}` : `nom:${nom}`
    pertesParCampagne.set(cle, (pertesParCampagne.get(cle) ?? 0) + (f.coutAnnuelEstime ?? 0))
  }
  // Inclure toutes les campagnes (y compris celles à 0 perte)
  const campagneNoms = new Map<number, string>()
  for (const c of campagnes) {
    campagneNoms.set(c.id, c.nom)
  }
  for (const c of campagnes) {
    const cle = `id:${c.id}`
    if (!pertesParCampagne.has(cle)) {
      pertesParCampagne.set(cle, 0)
    }
  }
  // Construire les segments dans l'ordre des campagnes
  const campagneSegments = campagnes.map((c, i) => {
    const montant = pertesParCampagne.get(`id:${c.id}`) ?? 0
    return {
      label: c.nom,
      value: montant,
      color: ['#00875a', '#f59e0b', '#3b82f6', '#ef4444', '#8b5cf6', '#06b6d4'][
        i % 6
      ],
    }
  })
  const totalPertes = campagneSegments.reduce((s, seg) => s + seg.value, 0)

  const cards = [
    {
      label: `Coût fuites actives (${annee})`,
      value: formatCout(stats.sommeActives),
      subtitle: `${aReparer} à réparer · ${enCours} en cours`,
      icon: TrendingUp,
      color: 'text-[#D32F2F]',
      bg: 'bg-[#FFEBEE]',
    },
    {
      label: `Économisé (${annee})`,
      value: formatCout(stats.sommeReparees),
      subtitle: `${stats.fuitesResolues} fuites réparées`,
      icon: PiggyBank,
      color: 'text-[#00875a]',
      bg: 'bg-[#00875a]/10',
    },
  ]

  return (
    <Layout>
      <div className="p-6 max-w-7xl mx-auto">
        <PageHeader
          title="Dashboard"
          subtitle={
            projetActif
              ? `Vue d'ensemble — ${projetActif.nom}`
              : 'Sélectionnez un projet pour voir ses données'
          }
          actions={
            invitations.length > 0 ? (
              <button
                onClick={() => navigate('/projets')}
                title={`${invitations.length} invitation(s) en attente`}
                className="relative flex items-center justify-center w-10 h-10 rounded-xl border border-[#e5e7eb] bg-white text-[#757575] hover:bg-[#f5f5f5] hover:text-[#00875a] transition-colors"
              >
                <Bell size={20} />
                <span className="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-red-500 text-white text-[11px] font-bold flex items-center justify-center">
                  {invitations.length}
                </span>
              </button>
            ) : undefined
          }
        />

        {/* Row 1 — Coût fuites actives + Économisé (50/50) */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-8">
          {cards.map((card) => (
            <div
              key={card.label}
              className="bg-white rounded-2xl p-5 border border-[#e5e7eb] hover:shadow-lg hover:shadow-black/5 transition-all"
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-sm text-[#757575] font-medium truncate">{card.label}</span>
                <div className={`w-9 h-9 rounded-full ${card.bg} flex items-center justify-center shrink-0 ml-2`}>
                  <card.icon size={18} className={card.color} />
                </div>
              </div>
              <div className="text-3xl font-bold tracking-tight text-[#111111]">
                {card.value}
              </div>
              <div className="mt-1 text-sm text-[#9ca3af]">
                {card.subtitle}
              </div>
            </div>
          ))}
        </div>

        {/* Row 2 — Pertes par campagne (2 colonnes) | Taux de réparation (1 colonne) */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-8">
          {/* Pertes par campagne — étalée sur 2 colonnes */}
          <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb] hover:shadow-lg hover:shadow-black/5 transition-all lg:col-span-2">
            <h2 className="font-semibold text-[#111111] mb-4">
              Pertes par campagne
            </h2>
            {campagneSegments.length === 0 ? (
              <p className="text-sm text-[#9ca3af] py-8 text-center">
                Aucune campagne pour ce projet
              </p>
            ) : (
              <div className="flex items-center gap-8">
                <DonutChart
                  size={180}
                  thickness={18}
                  segments={campagneSegments}
                  center={
                    <div className="text-center">
                      <div className="text-2xl font-bold text-[#111111]">
                        {formatCout(totalPertes)}
                      </div>
                      <div className="text-xs text-[#9ca3af]">pertes actives</div>
                    </div>
                  }
                />
                <div className="space-y-2 text-sm flex-1 min-w-0">
                  {campagneSegments.map((seg) => (
                    <div
                      key={seg.label}
                      className="flex items-center gap-2"
                    >
                      <span
                        className="w-3 h-3 rounded-full shrink-0"
                        style={{ backgroundColor: seg.color }}
                      />
                      <span className="text-[#757575] truncate flex-1">
                        {seg.label}
                      </span>
                      <span className="font-semibold text-[#111111]">
                        {formatCout(seg.value)}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Taux de réparation — 1 colonne */}
          <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]">
            <h2 className="font-semibold text-[#111111] mb-4">
              Taux de réparation
            </h2>
            <div className="flex items-center gap-6">
              <DonutChart
                size={150}
                thickness={16}
                segments={[
                  {
                    value: tauxReparation,
                    color: tauxReparation >= 50 ? '#00875a' : '#f59e0b',
                  },
                ]}
                center={
                  <div className="text-center">
                    <div className="text-3xl font-bold text-[#111111]">
                      {tauxReparation}%
                    </div>
                    <div className="text-xs text-[#9ca3af]">
                      {stats.fuitesResolues}/{stats.totalFuites} réparées
                    </div>
                  </div>
                }
              />
              <div className="space-y-3 text-sm">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#00875a]" />
                  <span className="text-[#757575]">
                    {stats.fuitesResolues} réparée(s)
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#f59e0b]" />
                  <span className="text-[#757575]">
                    {stats.nbrActives} Actifs
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Fuites récentes */}
        <div className="bg-white rounded-2xl p-5 border border-[#e5e7eb]">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-[#111111]">Fuites récentes</h2>
            <button
              onClick={() => navigate('/fuites')}
              className="flex items-center gap-1 text-sm text-[#00875a] hover:text-[#005c3e] transition-colors"
            >
              Tout voir <ArrowRight size={14} />
            </button>
          </div>

          {recentFuites.length === 0 ? (
            <p className="text-sm text-[#9ca3af] py-8 text-center">
              Aucune fuite enregistrée pour ce projet
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-[#9ca3af] border-b border-[#e5e7eb]">
                    <th className="py-2 pr-4 font-medium">Tag</th>
                    <th className="py-2 pr-4 font-medium">Zone</th>
                    <th className="py-2 pr-4 font-medium">Statut</th>
                    <th className="py-2 pr-4 font-medium">Coût annuel</th>
                    <th className="py-2 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {recentFuites.map((fuite) => (
                    <tr
                      key={fuite.id}
                      className="border-b border-[#e5e7eb]/50 last:border-0 hover:bg-[#f5f5f5] cursor-pointer transition-colors"
                      onClick={() => navigate(`/fuites/${fuite.id}`)}
                    >
                      <td className="py-3 pr-4 font-medium text-[#00875a]">
                        {fuite.numeroTag ?? '—'}
                      </td>
                      <td className="py-3 pr-4 text-[#757575] max-w-xs truncate">
                        {fuite.zone || fuite.description || '—'}
                      </td>
                      <td className="py-3 pr-4">
                        <Badge
                          color={
                            fuite.statut === 'REPAREE'
                              ? 'green'
                              : fuite.statut === 'A_REPARER'
                                ? 'red'
                                : fuite.statut === 'EN_COURS'
                                  ? 'yellow'
                                  : 'gray'
                          }
                        >
                          {STATUT_LABEL[fuite.statut ?? ''] ?? fuite.statut ?? '—'}
                        </Badge>
                      </td>
                      <td className="py-3 pr-4 text-[#757575]">
                        {fuite.coutAnnuelEstime != null
                          ? `${fuite.coutAnnuelEstime.toLocaleString('fr-FR')} DH`
                          : '—'}
                      </td>
                      <td className="py-3 text-[#9ca3af]">
                        {fuite.dateDetection
                          ? new Date(fuite.dateDetection).toLocaleDateString('fr-FR')
                          : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </Layout>
  )
}
