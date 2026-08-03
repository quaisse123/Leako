import { useEffect, useMemo, useState } from 'react'
import {
  Plus,
  Droplets,
  Search,
  X,
  Filter,
  ArrowUpDown,
  RefreshCw,
  Check,
  CheckSquare,
  Square,
  Trash2,
  Repeat,
  Tag,
  Calendar,
  ChevronDown,
  AlertCircle,
  Wrench,
  CheckCircle2,
  Ban,
  HelpCircle,
  Wallet,
  MessageCircle,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import FuiteChatModal from '../components/FuiteChatModal'
import {
  getFuites,
  getFuiteById,
  updateFuite,
  deleteFuite,
} from '../api/fuiteApi'
import { useProjetActif } from '../context/ProjetActifContext'
import { useNavigate } from 'react-router-dom'
import type { FuiteResponseDto, StatutFuite } from '../types'

const STATUT_LABEL: Record<string, string> = {
  A_REPARER: 'À réparer',
  EN_COURS: 'En cours',
  REPAREE: 'Réparée',
  ANNULEE: 'Annulée',
}

const STATUTS: { key: StatutFuite; label: string }[] = [
  { key: 'A_REPARER', label: 'À réparer' },
  { key: 'EN_COURS', label: 'En cours' },
  { key: 'REPAREE', label: 'Réparée' },
  { key: 'ANNULEE', label: 'Annulée' },
]

const STATUT_ICON: Record<string, typeof AlertCircle> = {
  A_REPARER: AlertCircle,
  EN_COURS: Wrench,
  REPAREE: CheckCircle2,
  ANNULEE: Ban,
}

const STATUT_HEX: Record<string, string> = {
  A_REPARER: '#D32F2F',
  EN_COURS: '#E65100',
  REPAREE: '#00875A',
  ANNULEE: '#757575',
}

type SortKey = 'cout' | 'date' | 'statut' | 'campagne'

const SORT_OPTIONS: { key: SortKey; label: string }[] = [
  { key: 'cout', label: 'Coût' },
  { key: 'date', label: 'Date' },
  { key: 'statut', label: 'Statut' },
  { key: 'campagne', label: 'Campagne' },
]

function formatDateTime(iso?: string): string {
  if (!iso) return '—'
  try {
    const d = new Date(iso.replace(' ', 'T'))
    const date = `${String(d.getDate()).padStart(2, '0')}/${String(
      d.getMonth() + 1,
    ).padStart(2, '0')}/${d.getFullYear()}`
    const hasTime = iso.includes('T') || iso.includes(' ') || d.getHours() !== 0 || d.getMinutes() !== 0
    return hasTime
      ? `${date} - ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`
      : date
  } catch {
    return iso
  }
}

function formatCout(value?: number): string {
  if (value == null || value <= 0) return ''
  return `${value.toLocaleString('fr-FR')} MAD/an`
}

function perteColor(value?: number): string {
  if (value == null || value <= 0) return '#00875A'
  if (value > 50000) return '#C62828'
  if (value > 20000) return '#E65100'
  return '#00875A'
}

/**
 * Liste des fuites — recherche, filtres, tris, sélection multiple.
 * Reproduit fidèlement le comportement de l'app mobile (fuites_page.dart).
 */
export default function FuitesPage() {
  const [fuites, setFuites] = useState<FuiteResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const { projetActif, loading: projetLoading } = useProjetActif()
  const navigate = useNavigate()

  // Recherche & filtres
  const [searchQuery, setSearchQuery] = useState('')
  const [statutFilter, setStatutFilter] = useState('TOUS')
  const [sortBy, setSortBy] = useState<SortKey>('cout')

  // Sélection multiple
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set())
  const [selectionMode, setSelectionMode] = useState(false)

  // Chat
  const [chatFuite, setChatFuite] = useState<FuiteResponseDto | null>(null)

  const loadFuites = async () => {
    if (!projetActif) return
    setLoading(true)
    try {
      const data = await getFuites({ projetId: projetActif.id })
      setFuites(data)
    } catch (err) {
      console.error('Erreur chargement fuites:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (projetLoading) return
    if (!projetActif) {
      setFuites([])
      setLoading(false)
      return
    }
    void loadFuites()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projetActif, projetLoading])

  // ─── Filtrage & tri (même logique que le mobile) ───────────────
  const filteredFuites = useMemo(() => {
    let result = [...fuites]

    // Filtre par statut
    if (statutFilter === 'ACTIVES') {
      result = result.filter(
        (f) => f.statut === 'A_REPARER' || f.statut === 'EN_COURS',
      )
    } else if (statutFilter !== 'TOUS') {
      result = result.filter((f) => f.statut === statutFilter)
    }

    // Recherche textuelle
    const q = searchQuery.trim().toLowerCase()
    if (q) {
      result = result.filter((f) => {
        const tag = (f.numeroTag ?? '').toLowerCase()
        const zone = (f.zone ?? '').toLowerCase()
        const desc = (f.description ?? '').toLowerCase()
        const campagne = (f.campagneNom ?? '').toLowerCase()
        const typeVapeur = (f.typeVapeur ?? '').replace(/_/g, ' ').toLowerCase()
        return (
          tag.includes(q) ||
          zone.includes(q) ||
          desc.includes(q) ||
          campagne.includes(q) ||
          typeVapeur.includes(q)
        )
      })
    }

    // Tri
    switch (sortBy) {
      case 'statut':
        result.sort((a, b) => (a.statut ?? '').localeCompare(b.statut ?? ''))
        break
      case 'campagne':
        result.sort((a, b) => (a.campagneNom ?? '').localeCompare(b.campagneNom ?? ''))
        break
      case 'date':
        result.sort((a, b) => {
          const dateA = a.dateDetection ? new Date(a.dateDetection).getTime() : 0
          const dateB = b.dateDetection ? new Date(b.dateDetection).getTime() : 0
          return dateB - dateA
        })
        break
      default: // cout — plus coûteux en premier
        result.sort((a, b) => (b.coutAnnuelEstime ?? 0) - (a.coutAnnuelEstime ?? 0))
    }

    return result
  }, [fuites, statutFilter, searchQuery, sortBy])

  // ─── Sélection multiple ────────────────────────────────────────
  const toggleSelection = (id: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) {
        next.delete(id)
        if (next.size === 0) setSelectionMode(false)
      } else {
        next.add(id)
        setSelectionMode(true)
      }
      return next
    })
  }

  const selectAll = () => {
    if (selectedIds.size === filteredFuites.length) {
      setSelectedIds(new Set())
      setSelectionMode(false)
    } else {
      setSelectedIds(new Set(filteredFuites.map((f) => f.id)))
      setSelectionMode(true)
    }
  }

  const clearSelection = () => {
    setSelectedIds(new Set())
    setSelectionMode(false)
  }

  const supprimerSelection = async () => {
    if (selectedIds.size === 0) return
    const count = selectedIds.size
    if (!window.confirm(`${count} fuite(s) seront définitivement supprimées.`)) return
    const ids = [...selectedIds]
    clearSelection()
    try {
      for (const id of ids) {
        await deleteFuite(id)
      }
      await loadFuites()
      alert(`${count} fuite(s) supprimée(s) ✓`)
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const changerStatutSelection = async (nouveauStatut: StatutFuite) => {
    if (selectedIds.size === 0) return
    const ids = [...selectedIds]
    clearSelection()
    try {
      for (const id of ids) {
        const fuite = await getFuiteById(id)
        await updateFuite(id, {
          numeroTag: fuite.numeroTag,
          statut: nouveauStatut,
          dateDetection: fuite.dateDetection ?? '',
          pressionBar: fuite.pressionBar,
          diametreOrifice: fuite.diametreOrifice,
          typeVapeur: fuite.typeVapeur,
          gpsLatitude: fuite.gpsLatitude,
          gpsLongitude: fuite.gpsLongitude,
          zone: fuite.zone,
          description: fuite.description,
          coutAnnuelEstime: fuite.coutAnnuelEstime,
          campagneId: fuite.campagneId ?? 0,
        })
      }
      await loadFuites()
      alert(`${ids.length} fuite(s) mise(s) à jour ✓`)
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const changerStatutFuite = async (fuite: FuiteResponseDto, nouveauStatut: StatutFuite) => {
    if (nouveauStatut === fuite.statut) return
    try {
      await updateFuite(fuite.id, {
        numeroTag: fuite.numeroTag,
        statut: nouveauStatut,
        dateDetection: fuite.dateDetection ?? '',
        pressionBar: fuite.pressionBar,
        diametreOrifice: fuite.diametreOrifice,
        typeVapeur: fuite.typeVapeur,
        gpsLatitude: fuite.gpsLatitude,
        gpsLongitude: fuite.gpsLongitude,
        zone: fuite.zone,
        description: fuite.description,
        coutAnnuelEstime: fuite.coutAnnuelEstime,
        campagneId: fuite.campagneId ?? 0,
      })
      await loadFuites()
      alert('Statut mis à jour ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const allSelected = filteredFuites.length > 0 && selectedIds.size === filteredFuites.length

  return (
    <Layout>
      <div className="p-6 max-w-7xl mx-auto">
        <PageHeader
          title="Fuites"
          subtitle={
            projetActif
              ? `${filteredFuites.length} fuite${filteredFuites.length > 1 ? 's' : ''} — ${projetActif.nom}`
              : 'Sélectionnez un projet pour voir ses fuites'
          }
          actions={
            !selectionMode ? (
              <div className="flex items-center gap-2">
                {/* Filtre statut */}
                <div className="relative">
                  <button
                    onClick={() => document.getElementById('fuites-statut-menu')?.classList.toggle('hidden')}
                    className={`flex items-center gap-2 px-3 py-2.5 rounded-xl border text-sm font-medium transition-colors ${
                      statutFilter !== 'TOUS'
                        ? 'border-[#00875a] text-[#00875a] bg-[#00875a]/5'
                        : 'border-[#e5e7eb] text-[#757575] bg-white hover:bg-[#f5f5f5]'
                    }`}
                  >
                    <Filter size={16} />
                    {statutFilter === 'TOUS'
                      ? 'Tous'
                      : statutFilter === 'ACTIVES'
                        ? 'Actives'
                        : STATUT_LABEL[statutFilter]}
                    <ChevronDown size={14} />
                  </button>
                  <div
                    id="fuites-statut-menu"
                    className="hidden absolute right-0 mt-2 w-52 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                  >
                    <button
                      onClick={() => {
                        setStatutFilter('TOUS')
                        document.getElementById('fuites-statut-menu')?.classList.add('hidden')
                      }}
                      className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                        statutFilter === 'TOUS' ? 'font-bold text-[#00875a]' : 'text-[#111111]'
                      }`}
                    >
                      <span className="w-4">{statutFilter === 'TOUS' && <Check size={16} />}</span>
                      Tous
                    </button>
                    <button
                      onClick={() => {
                        setStatutFilter('ACTIVES')
                        document.getElementById('fuites-statut-menu')?.classList.add('hidden')
                      }}
                      className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                        statutFilter === 'ACTIVES' ? 'font-bold text-[#00875a]' : 'text-[#111111]'
                      }`}
                    >
                      <span className="w-4">{statutFilter === 'ACTIVES' && <Check size={16} />}</span>
                      Actives
                    </button>
                    {STATUTS.map((s) => {
                      const isActive = statutFilter === s.key
                      const Icon = STATUT_ICON[s.key]
                      return (
                        <button
                          key={s.key}
                          onClick={() => {
                            setStatutFilter(s.key)
                            document.getElementById('fuites-statut-menu')?.classList.add('hidden')
                          }}
                          className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                            isActive ? 'font-bold' : 'text-[#111111]'
                          }`}
                          style={isActive ? { color: STATUT_HEX[s.key] } : undefined}
                        >
                          <span className="w-4">{isActive && <Check size={16} />}</span>
                          <Icon size={16} style={{ color: STATUT_HEX[s.key] }} />
                          {s.label}
                        </button>
                      )
                    })}
                  </div>
                </div>

                {/* Tri */}
                <div className="relative">
                  <button
                    onClick={() => document.getElementById('fuites-sort-menu')?.classList.toggle('hidden')}
                    className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
                  >
                    <ArrowUpDown size={16} />
                    {SORT_OPTIONS.find((o) => o.key === sortBy)?.label}
                    <ChevronDown size={14} />
                  </button>
                  <div
                    id="fuites-sort-menu"
                    className="hidden absolute right-0 mt-2 w-44 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                  >
                    {SORT_OPTIONS.map((o) => (
                      <button
                        key={o.key}
                        onClick={() => {
                          setSortBy(o.key)
                          document.getElementById('fuites-sort-menu')?.classList.add('hidden')
                        }}
                        className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                          sortBy === o.key ? 'font-bold text-[#00875a]' : 'text-[#111111]'
                        }`}
                      >
                        <span className="w-4">{sortBy === o.key && <Check size={16} />}</span>
                        {o.label}
                      </button>
                    ))}
                  </div>
                </div>

                <button
                  onClick={() => void loadFuites()}
                  className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
                  title="Rafraîchir"
                >
                  <RefreshCw size={16} />
                </button>

                <button
                  onClick={() => {
                    setSelectionMode(true)
                    setSelectedIds(new Set())
                  }}
                  className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
                  title="Sélection multiple"
                >
                  <CheckSquare size={16} />
                  Sélectionner
                </button>

                <button
                  onClick={() => navigate('/fuites/nouvelle')}
                  className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
                >
                  <Plus size={16} />
                  Nouvelle fuite
                </button>
              </div>
            ) : (
              <button
                onClick={clearSelection}
                className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
              >
                <X size={16} />
                Annuler la sélection
              </button>
            )
          }
        />

        {/* Barre de sélection */}
        {selectionMode && (
          <div className="flex items-center gap-3 px-4 py-2.5 bg-[#E8F5E9] rounded-xl mb-4">
            <span className="font-black text-[#00875a]">{selectedIds.size}</span>
            <span className="font-semibold text-[#00875a] text-sm">sélectionnée(s)</span>
            <div className="flex-1" />
            <button
              onClick={selectAll}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#00875a]/10 text-[#00875a] text-xs font-semibold hover:bg-[#00875a]/20 transition-colors"
            >
              {allSelected ? <Square size={14} /> : <CheckSquare size={14} />}
              {allSelected ? 'Tout désél.' : 'Tout sél.'}
            </button>
            {selectedIds.size > 0 && (
              <>
                <div className="h-5 w-px bg-[#00875a]/30" />
                {/* Changer statut */}
                <div className="relative">
                  <button
                    onClick={() => document.getElementById('fuites-bulk-statut')?.classList.toggle('hidden')}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1565C0]/10 text-[#1565C0] hover:bg-[#1565C0]/20 transition-colors"
                    title="Changer le statut"
                  >
                    <Repeat size={16} />
                  </button>
                  <div
                    id="fuites-bulk-statut"
                    className="hidden absolute right-0 mt-2 w-44 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                  >
                    {STATUTS.map((s) => {
                      const Icon = STATUT_ICON[s.key]
                      return (
                        <button
                          key={s.key}
                          onClick={() => {
                            document.getElementById('fuites-bulk-statut')?.classList.add('hidden')
                            void changerStatutSelection(s.key)
                          }}
                          className="w-full flex items-center gap-2 px-4 py-2 text-sm text-[#111111] hover:bg-[#f5f5f5]"
                        >
                          <Icon size={16} style={{ color: STATUT_HEX[s.key] }} />
                          {s.label}
                        </button>
                      )
                    })}
                  </div>
                </div>
                <button
                  onClick={() => void supprimerSelection()}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#D32F2F]/10 text-[#D32F2F] hover:bg-[#D32F2F]/20 transition-colors"
                  title="Supprimer la sélection"
                >
                  <Trash2 size={16} />
                </button>
              </>
            )}
          </div>
        )}

        {/* Barre de recherche */}
        <div className="relative mb-4">
          <Search size={20} className="absolute left-4 top-1/2 -translate-y-1/2 text-[#757575]" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Rechercher tag, localisation, gaz…"
            className="w-full pl-11 pr-10 py-3 rounded-xl bg-[#F5F5F5] text-sm text-[#111111] focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-[#757575] hover:text-[#111111]"
            >
              <X size={18} />
            </button>
          )}
        </div>

        {loading ? (
          <LoadingSpinner />
        ) : filteredFuites.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            {searchQuery ? (
              <Search size={40} className="text-[#00875a]/30 mb-4" />
            ) : (
              <Droplets size={40} className="text-[#00875a]/30 mb-4" />
            )}
            <p className="text-lg font-bold text-[#111111]">
              {searchQuery ? 'Aucune fuite trouvée' : 'Aucune fuite signalée'}
            </p>
            <p className="text-[#757575] mt-2">
              {searchQuery ? 'Essaie un autre mot-clé' : 'Ajoute ta première fuite !'}
            </p>
          </div>
        ) : (
          <div className="bg-white border border-[#e5e7eb] rounded-2xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-[#9ca3af] border-b border-[#e5e7eb] bg-[#f9fafb]">
                    {selectionMode && (
                      <th className="py-3 px-4 w-10">
                        <button onClick={selectAll} className="text-[#00875a]">
                          {allSelected ? <CheckSquare size={18} /> : <Square size={18} />}
                        </button>
                      </th>
                    )}
                    <th className="py-3 px-4 font-medium">Tag</th>
                    <th className="py-3 px-4 font-medium">Zone</th>
                    <th className="py-3 px-4 font-medium">Statut</th>
                    <th className="py-3 px-4 font-medium">Coût annuel</th>
                    <th className="py-3 px-4 font-medium">Date</th>
                    <th className="py-3 px-4 font-medium text-right">Action</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredFuites.map((fuite) => {
                    const isSelected = selectedIds.has(fuite.id)
                    const statut = fuite.statut ?? ''
                    const cout = fuite.coutAnnuelEstime
                    const coutClr = perteColor(cout)
                    const StatutIcon = STATUT_ICON[statut] ?? HelpCircle
                    return (
                      <tr
                        key={fuite.id}
                        onClick={() =>
                          selectionMode
                            ? toggleSelection(fuite.id)
                            : navigate(`/fuites/${fuite.id}`)
                        }
                        onContextMenu={(e) => {
                          e.preventDefault()
                          toggleSelection(fuite.id)
                        }}
                        className={`border-b border-[#e5e7eb]/50 last:border-0 cursor-pointer transition-colors ${
                          isSelected ? 'bg-[#E8F5E9]' : 'hover:bg-[#f5f5f5]'
                        }`}
                      >
                        {selectionMode && (
                          <td className="py-3 px-4">
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                toggleSelection(fuite.id)
                              }}
                              className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors ${
                                isSelected ? 'bg-[#00875a] border-[#00875a]' : 'border-[#757575]'
                              }`}
                            >
                              {isSelected && <Check size={12} className="text-white" />}
                            </button>
                          </td>
                        )}
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5">
                            <Tag size={14} className="text-[#757575]" />
                            <span className="font-bold text-[#111111]">
                              {fuite.numeroTag ?? 'Sans tag'}
                            </span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-[#757575] max-w-xs truncate">
                          {fuite.zone || '—'}
                        </td>
                        <td className="py-3 px-4">
                          <div className="relative inline-block">
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                document.getElementById(`fuite-statut-${fuite.id}`)?.classList.toggle('hidden')
                              }}
                              className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold"
                              style={{
                                backgroundColor: `${STATUT_HEX[statut]}1A`,
                                color: STATUT_HEX[statut],
                              }}
                            >
                              <StatutIcon size={12} />
                              {STATUT_LABEL[statut] ?? statut}
                              <ChevronDown size={14} />
                            </button>
                            <div
                              id={`fuite-statut-${fuite.id}`}
                              className="hidden absolute left-0 mt-1 w-44 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                            >
                              {STATUTS.map((s) => {
                                const Icon = STATUT_ICON[s.key]
                                return (
                                  <button
                                    key={s.key}
                                    onClick={(e) => {
                                      e.stopPropagation()
                                      document.getElementById(`fuite-statut-${fuite.id}`)?.classList.add('hidden')
                                      void changerStatutFuite(fuite, s.key)
                                    }}
                                    className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                                      s.key === statut ? 'font-bold' : 'text-[#111111]'
                                    }`}
                                    style={s.key === statut ? { color: STATUT_HEX[s.key] } : undefined}
                                  >
                                    <Icon size={16} style={{ color: STATUT_HEX[s.key] }} />
                                    {s.label}
                                    {s.key === statut && <Check size={16} className="ml-auto" />}
                                  </button>
                                )
                              })}
                            </div>
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          {cout != null && cout > 0 ? (
                            <span
                              className="inline-flex items-center gap-1 px-2 py-0.5 rounded-lg text-xs font-bold border"
                              style={{
                                color: coutClr,
                                backgroundColor: `${coutClr}1A`,
                                borderColor: `${coutClr}4D`,
                              }}
                            >
                              <Wallet size={12} />
                              {formatCout(cout)}
                            </span>
                          ) : (
                            <span className="text-[#9ca3af]">—</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-[#9ca3af]">
                          <div className="flex items-center gap-1">
                            <Calendar size={12} />
                            {formatDateTime(fuite.dateDetection)}
                          </div>
                        </td>
                        <td className="py-3 px-4 text-right">
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              setChatFuite(fuite)
                            }}
                            className="inline-flex items-center justify-center p-2 rounded-lg bg-[#00875a]/10 text-[#00875a] hover:bg-[#00875a]/20 transition-colors"
                            title="Conversation"
                          >
                            <MessageCircle size={16} />
                          </button>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Modal conversation */}
      {chatFuite && (
        <FuiteChatModal
          fuiteId={chatFuite.id}
          numeroTag={chatFuite.numeroTag ?? `Fuite #${chatFuite.id}`}
          onClose={() => setChatFuite(null)}
        />
      )}
    </Layout>
  )
}
