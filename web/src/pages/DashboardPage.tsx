import { useEffect, useState } from 'react'
import {
  Droplets,
  CheckCircle2,
  AlertTriangle,
  CalendarDays,
  FolderKanban,
  ArrowRight,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import { getFuites } from '../api/fuiteApi'
import { getCampagnes } from '../api/campagneApi'
import { useProjetActif } from '../context/ProjetActifContext'
import { useNavigate } from 'react-router-dom'
import type { FuiteResponseDto } from '../types'

interface Stats {
  totalFuites: number
  fuitesResolues: number
  fuitesEnCours: number
  fuitesCritiques: number
  totalCampagnes: number
}

const STATUT_LABEL: Record<string, string> = {
  A_REPARER: 'À réparer',
  EN_COURS: 'En cours',
  REPAREE: 'Réparée',
  ANNULEE: 'Annulée',
}

/**
 * Dashboard — KPIs + aperçu des fuites récentes.
 * Les données sont filtrées par le projet actif (comme l'app mobile).
 */
export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [recentFuites, setRecentFuites] = useState<FuiteResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const { projetActif, loading: projetLoading } = useProjetActif()
  const navigate = useNavigate()

  useEffect(() => {
    if (projetLoading) return
    if (!projetActif) {
      setStats({ totalFuites: 0, fuitesResolues: 0, fuitesEnCours: 0, fuitesCritiques: 0, totalCampagnes: 0 })
      setRecentFuites([])
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
        const sorted = [...fuites].sort(
          (a, b) =>
            new Date(b.dateDetection ?? 0).getTime() -
            new Date(a.dateDetection ?? 0).getTime(),
        )
        setRecentFuites(sorted.slice(0, 6))
        setStats({
          totalFuites: fuites.length,
          fuitesResolues: fuites.filter((f) => f.statut === 'REPAREE').length,
          fuitesEnCours: fuites.filter(
            (f) => f.statut !== 'REPAREE' && f.statut !== 'ANNULEE',
          ).length,
          fuitesCritiques: fuites.filter((f) => f.pressionBar != null && f.pressionBar >= 8).length,
          totalCampagnes: campagnes.length,
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

  const cards = [
    {
      label: 'Total fuites',
      value: stats.totalFuites,
      icon: Droplets,
      color: 'text-[#00875a]',
      bg: 'bg-[#00875a]/10',
    },
    {
      label: 'Fuites réparées',
      value: stats.fuitesResolues,
      icon: CheckCircle2,
      color: 'text-emerald-600',
      bg: 'bg-emerald-50',
    },
    {
      label: 'Fuites en cours',
      value: stats.fuitesEnCours,
      icon: AlertTriangle,
      color: 'text-amber-600',
      bg: 'bg-amber-50',
    },
    {
      label: 'Fuites haute pression',
      value: stats.fuitesCritiques,
      icon: AlertTriangle,
      color: 'text-red-600',
      bg: 'bg-red-50',
    },
    {
      label: 'Campagnes',
      value: stats.totalCampagnes,
      icon: CalendarDays,
      color: 'text-sky-600',
      bg: 'bg-sky-50',
    },
    {
      label: 'Projet actif',
      value: projetActif?.nom ?? '—',
      icon: FolderKanban,
      color: 'text-indigo-600',
      bg: 'bg-indigo-50',
      isText: true,
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
        />

        {/* Cartes KPI */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
          {cards.map((card) => (
            <div
              key={card.label}
              className="bg-white rounded-2xl p-5 border border-[#e5e7eb] hover:shadow-lg hover:shadow-black/5 transition-all"
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-sm text-[#757575]">{card.label}</span>
                <div className={`w-9 h-9 rounded-xl ${card.bg} flex items-center justify-center`}>
                  <card.icon size={18} className={card.color} />
                </div>
              </div>
              <div
                className={`text-3xl font-bold tracking-tight text-[#111111] ${
                  card.isText ? '!text-lg !font-semibold truncate' : ''
                }`}
              >
                {card.value}
              </div>
            </div>
          ))}
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
