import { Fragment, useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  AlertCircle,
  ArrowLeft,
  ArrowUpDown,
  Ban,
  Calendar,
  Check,
  CheckCircle2,
  CheckSquare,
  ChevronDown,
  Droplets,
  Filter,
  HelpCircle,
  Loader2,
  Lock,
  MapPin,
  Pencil,
  Plus,
  RefreshCw,
  Repeat,
  Save,
  Search,
  Square,
  Tag,
  Trash2,
  Wrench,
  X,
} from 'lucide-react'
import type { LucideIcon } from 'lucide-react'
import Layout from '../components/Layout'
import LoadingSpinner from '../components/LoadingSpinner'
import PhotosRow from '../components/PhotosRow'
import {
  deleteCampagne,
  getCampagneById,
  patchCampagne,
  updateCampagne,
} from '../api/campagneApi'
import {
  getFuites,
  getFuiteById,
  updateFuite,
  deleteFuite,
} from '../api/fuiteApi'
import type { CampagneResponseDto, FuiteResponseDto, StatutFuite } from '../types'

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

const STATUT_ICON: Record<string, LucideIcon> = {
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

type SortKey = 'date' | 'tag' | 'statut' | 'cout'

const SORT_OPTIONS: { key: SortKey; label: string }[] = [
  { key: 'date', label: 'Date' },
  { key: 'tag', label: 'Tag' },
  { key: 'statut', label: 'Statut' },
  { key: 'cout', label: 'Coût' },
]

function formatDateTime(iso?: string): string {
  if (!iso) return '—'
  try {
    const d = new Date(iso.replace(' ', 'T'))
    const date = `${String(d.getDate()).padStart(2, '0')}/${String(
      d.getMonth() + 1,
    ).padStart(2, '0')}/${d.getFullYear()}`
    const hasTime =
      iso.includes('T') || iso.includes(' ') || d.getHours() !== 0 || d.getMinutes() !== 0
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
 * Détail d'une campagne — récap, stats, liste des fuites avec
 * recherche / filtre / tri / sélection multiple.
 * Reproduit fidèlement detail_campagne_page.dart.
 */
export default function DetailCampagnePage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  const [campagne, setCampagne] = useState<CampagneResponseDto | null>(null)
  const [fuites, setFuites] = useState<FuiteResponseDto[]>([])
  const [loading, setLoading] = useState(true)

  // Recherche & filtres fuites
  const [searchQuery, setSearchQuery] = useState('')
  const [statutFilter, setStatutFilter] = useState('TOUS')
  const [sortBy, setSortBy] = useState<SortKey>('date')

  // Sélection multiple
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set())
  const [selectionMode, setSelectionMode] = useState(false)

  // Photos (panneau miniatures ouvert)
  const [photosOpenId, setPhotosOpenId] = useState<number | null>(null)

  // Édition campagne
  const [editing, setEditing] = useState(false)
  const [editNom, setEditNom] = useState('')
  const [editDescription, setEditDescription] = useState('')
  const [editEstCloturee, setEditEstCloturee] = useState(false)
  const [saving, setSaving] = useState(false)

  const campagneId = Number(id)

  const loadData = async () => {
    if (!campagneId) return
    setLoading(true)
    try {
      const [c, f] = await Promise.all([
        getCampagneById(campagneId),
        getFuites({ campagneId }),
      ])
      setCampagne(c)
      setFuites(f)
    } catch (err) {
      console.error('Erreur chargement campagne:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [campagneId])

  // ─── Stats ─────────────────────────────────────────────────────
  const stats = useMemo(() => {
    return {
      total: fuites.length,
      a_reparer: fuites.filter((f) => f.statut === 'A_REPARER').length,
      en_cours: fuites.filter((f) => f.statut === 'EN_COURS').length,
      reparees: fuites.filter((f) => f.statut === 'REPAREE').length,
      annulees: fuites.filter((f) => f.statut === 'ANNULEE').length,
    }
  }, [fuites])

  // ─── Filtrage & tri (même logique que le mobile) ───────────────
  const filteredFuites = useMemo(() => {
    let result = [...fuites]

    // Filtre par statut
    if (statutFilter !== 'TOUS') {
      result = result.filter((f) => f.statut === statutFilter)
    }

    // Recherche textuelle (tag, zone, description, typeVapeur)
    const q = searchQuery.trim().toLowerCase()
    if (q) {
      result = result.filter((f) => {
        const tag = (f.numeroTag ?? '').toLowerCase()
        const zone = (f.zone ?? '').toLowerCase()
        const desc = (f.description ?? '').toLowerCase()
        const typeVapeur = (f.typeVapeur ?? '').replace(/_/g, ' ').toLowerCase()
        return (
          tag.includes(q) ||
          zone.includes(q) ||
          desc.includes(q) ||
          typeVapeur.includes(q)
        )
      })
    }

    // Tri (défaut mobile : DATE, plus récent en premier)
    switch (sortBy) {
      case 'tag':
        result.sort((a, b) => (a.numeroTag ?? '').localeCompare(b.numeroTag ?? ''))
        break
      case 'statut':
        result.sort((a, b) => (a.statut ?? '').localeCompare(b.statut ?? ''))
        break
      case 'cout':
        result.sort((a, b) => (b.coutAnnuelEstime ?? 0) - (a.coutAnnuelEstime ?? 0))
        break
      default: // date
        result.sort((a, b) => {
          const dateA = a.dateDetection ? new Date(a.dateDetection).getTime() : 0
          const dateB = b.dateDetection ? new Date(b.dateDetection).getTime() : 0
          return dateB - dateA
        })
    }

    return result
  }, [fuites, statutFilter, searchQuery, sortBy])

  // ─── Sélection multiple ────────────────────────────────────────
  const toggleSelection = (fid: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(fid)) {
        next.delete(fid)
        if (next.size === 0) setSelectionMode(false)
      } else {
        next.add(fid)
        setSelectionMode(true)
      }
      return next
    })
  }

  const clearSelection = () => {
    setSelectedIds(new Set())
    setSelectionMode(false)
  }

  const allSelected = filteredFuites.length > 0 && selectedIds.size === filteredFuites.length

  const selectAll = () => {
    if (allSelected) {
      clearSelection()
    } else {
      setSelectedIds(new Set(filteredFuites.map((f) => f.id)))
      setSelectionMode(true)
    }
  }

  const supprimerSelection = async () => {
    if (selectedIds.size === 0) return
    const count = selectedIds.size
    if (!window.confirm(`${count} fuite(s) seront définitivement supprimées.`)) return
    const ids = [...selectedIds]
    clearSelection()
    try {
      for (const fid of ids) {
        await deleteFuite(fid)
      }
      await loadData()
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
      for (const fid of ids) {
        const fuite = await getFuiteById(fid)
        await updateFuite(fid, {
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
          campagneId: fuite.campagneId ?? campagneId,
        })
      }
      await loadData()
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
        campagneId: fuite.campagneId ?? campagneId,
      })
      await loadData()
      alert('Statut mis à jour ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const supprimerCampagne = async () => {
    if (!campagne) return
    if (!window.confirm(`Supprimer la campagne « ${campagne.nom} » ?`)) return
    try {
      await deleteCampagne(campagne.id)
      navigate('/campagnes')
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const toggleCloturee = async () => {
    if (!campagne) return
    try {
      await patchCampagne(campagne.id, { estCloturee: !campagne.estCloturee })
      await loadData()
      alert(campagne.estCloturee ? 'Campagne réouverte ✓' : 'Campagne clôturée ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const openEdit = () => {
    if (!campagne) return
    setEditNom(campagne.nom ?? '')
    setEditDescription(campagne.description ?? '')
    setEditEstCloturee(!!campagne.estCloturee)
    setEditing(true)
  }

  const saveEdit = async () => {
    if (!campagne) return
    if (!editNom.trim()) {
      alert('Le nom de la campagne est obligatoire.')
      return
    }
    setSaving(true)
    try {
      await updateCampagne(campagne.id, {
        nom: editNom.trim(),
        description: editDescription.trim() || undefined,
        zone: campagne.zone,
        estCloturee: editEstCloturee,
        createurId: campagne.createurId,
        projetId: campagne.projetId,
      })
      setEditing(false)
      await loadData()
      alert('Campagne mise à jour ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <Layout>
        <div className="p-6 max-w-5xl mx-auto">
          <LoadingSpinner />
        </div>
      </Layout>
    )
  }

  if (!campagne) {
    return (
      <Layout>
        <div className="p-6 max-w-5xl mx-auto flex flex-col items-center py-20 text-center">
          <HelpCircle size={40} className="text-[#00875a]/30 mb-4" />
          <p className="text-lg font-bold text-[#111111]">Campagne introuvable</p>
          <button
            onClick={() => navigate('/campagnes')}
            className="mt-4 inline-flex items-center gap-1.5 text-sm text-[#00875a] font-medium"
          >
            <ArrowLeft size={16} />
            Retour aux campagnes
          </button>
        </div>
      </Layout>
    )
  }

  const isActive = !campagne.estCloturee

  const inputCls =
    'w-full px-3 py-2 border border-[#e5e7eb] rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]'
  const labelCls = 'block text-sm font-medium text-[#757575] mb-1.5'

  return (
    <Layout>
      <div className="p-6 max-w-5xl mx-auto">
        <button
          onClick={() => navigate('/campagnes')}
          className="inline-flex items-center gap-1.5 text-sm text-[#757575] hover:text-[#00875a] mb-4 transition-colors"
        >
          <ArrowLeft size={16} />
          Retour aux campagnes
        </button>

        {/* Header */}
        <div className="flex flex-wrap items-start justify-between gap-3 mb-4">
          <div>
            <div className="flex items-center gap-2 flex-wrap">
              <h1 className="text-2xl font-extrabold text-[#111111]">
                {campagne.nom}
              </h1>
              <span
                className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${
                  isActive
                    ? 'bg-[#E8F5E9] text-[#00875A] border-[#00875A]/20'
                    : 'bg-[#F5F5F5] text-[#757575] border-[#e5e7eb]'
                }`}
              >
                {isActive ? 'Active' : 'Clôturée'}
              </span>
            </div>
            {campagne.description && (
              <p className="text-[#757575] mt-1 text-sm max-w-xl">
                {campagne.description}
              </p>
            )}
            <p className="text-xs text-[#9ca3af] mt-2 flex items-center gap-1.5">
              <Calendar size={12} />
              Créée le {formatDateTime(campagne.dateCreation)}
              {campagne.zone && (
                <>
                  <span className="mx-1">•</span>
                  <MapPin size={12} />
                  {campagne.zone}
                </>
              )}
            </p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={openEdit}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
              title="Modifier la campagne"
            >
              <Pencil size={15} />
              Modifier
            </button>
            <button
              onClick={() => void toggleCloturee()}
              className={`flex items-center gap-2 px-3 py-2 rounded-xl border text-sm font-medium transition-colors ${
                isActive
                  ? 'border-[#e5e7eb] text-[#757575] bg-white hover:bg-[#f5f5f5]'
                  : 'border-[#00875a] text-[#00875a] bg-[#00875a]/5 hover:bg-[#00875a]/10'
              }`}
            >
              <Lock size={15} />
              {isActive ? 'Clôturer' : 'Réouvrir'}
            </button>
            <button
              onClick={() => void supprimerCampagne()}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#D32F2F]/30 text-sm font-medium text-[#D32F2F] bg-white hover:bg-[#D32F2F]/5 transition-colors"
              title="Supprimer la campagne"
            >
              <Trash2 size={15} />
              Supprimer
            </button>
            <button
              onClick={() => navigate(`/fuites/nouvelle?campagneId=${campagne.id}`)}
              disabled={!isActive}
              className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Plus size={16} />
              Ajouter une fuite
            </button>
          </div>
        </div>

        {/* Récap stats */}
        <div className="bg-[#00875a]/5 border border-[#00875a]/15 rounded-2xl p-4 mb-4">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {[
              { label: 'Total', value: stats.total, color: '#00875A', icon: Droplets },
              { label: 'À réparer', value: stats.a_reparer, color: '#D32F2F', icon: AlertCircle },
              { label: 'En cours', value: stats.en_cours, color: '#E65100', icon: Wrench },
              { label: 'Réparées', value: stats.reparees, color: '#00875A', icon: CheckCircle2 },
            ].map((s) => {
              const Icon = s.icon
              return (
                <div
                  key={s.label}
                  className="flex flex-col items-center py-3 rounded-xl"
                  style={{ backgroundColor: `${s.color}14` }}
                >
                  <Icon size={18} style={{ color: s.color }} />
                  <span className="font-black text-xl mt-1" style={{ color: s.color }}>
                    {s.value}
                  </span>
                  <span className="text-xs font-medium" style={{ color: s.color }}>
                    {s.label}
                  </span>
                </div>
              )
            })}
          </div>
        </div>

        {/* Barre d'outils fuites */}
        <div className="flex flex-wrap items-center gap-2 mb-3">
          {/* Filtre statut */}
          <div className="relative">
            <button
              onClick={() => document.getElementById('dcp-statut-menu')?.classList.toggle('hidden')}
              className={`flex items-center gap-2 px-3 py-2 rounded-xl border text-sm font-medium transition-colors ${
                statutFilter !== 'TOUS'
                  ? 'border-[#00875a] text-[#00875a] bg-[#00875a]/5'
                  : 'border-[#e5e7eb] text-[#757575] bg-white hover:bg-[#f5f5f5]'
              }`}
            >
              <Filter size={15} />
              {statutFilter === 'TOUS' ? 'Tous' : STATUT_LABEL[statutFilter]}
              <ChevronDown size={13} />
            </button>
            <div
              id="dcp-statut-menu"
              className="hidden absolute left-0 mt-2 w-48 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
            >
              <button
                onClick={() => {
                  setStatutFilter('TOUS')
                  document.getElementById('dcp-statut-menu')?.classList.add('hidden')
                }}
                className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                  statutFilter === 'TOUS' ? 'font-bold text-[#00875a]' : 'text-[#111111]'
                }`}
              >
                <span className="w-4">{statutFilter === 'TOUS' && <Check size={15} />}</span>
                Tous
              </button>
              {STATUTS.map((s) => {
                const isActiveFilter = statutFilter === s.key
                const Icon = STATUT_ICON[s.key]
                return (
                  <button
                    key={s.key}
                    onClick={() => {
                      setStatutFilter(s.key)
                      document.getElementById('dcp-statut-menu')?.classList.add('hidden')
                    }}
                    className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                      isActiveFilter ? 'font-bold' : 'text-[#111111]'
                    }`}
                    style={isActiveFilter ? { color: STATUT_HEX[s.key] } : undefined}
                  >
                    <span className="w-4">{isActiveFilter && <Check size={15} />}</span>
                    <Icon size={15} style={{ color: STATUT_HEX[s.key] }} />
                    {s.label}
                  </button>
                )
              })}
            </div>
          </div>

          {/* Tri */}
          <div className="relative">
            <button
              onClick={() => document.getElementById('dcp-sort-menu')?.classList.toggle('hidden')}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
            >
              <ArrowUpDown size={15} />
              {SORT_OPTIONS.find((o) => o.key === sortBy)?.label}
              <ChevronDown size={13} />
            </button>
            <div
              id="dcp-sort-menu"
              className="hidden absolute left-0 mt-2 w-40 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
            >
              {SORT_OPTIONS.map((o) => (
                <button
                  key={o.key}
                  onClick={() => {
                    setSortBy(o.key)
                    document.getElementById('dcp-sort-menu')?.classList.add('hidden')
                  }}
                  className={`w-full flex items-center gap-2 px-4 py-2 text-sm hover:bg-[#f5f5f5] ${
                    sortBy === o.key ? 'font-bold text-[#00875a]' : 'text-[#111111]'
                  }`}
                >
                  <span className="w-4">{sortBy === o.key && <Check size={15} />}</span>
                  {o.label}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={() => void loadData()}
            className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
            title="Rafraîchir"
          >
            <RefreshCw size={15} />
          </button>

          <div className="flex-1" />

          {!selectionMode ? (
            <button
              onClick={() => {
                setSelectionMode(true)
                setSelectedIds(new Set())
              }}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
              title="Sélection multiple"
            >
              <CheckSquare size={15} />
              Sélectionner
            </button>
          ) : (
            <button
              onClick={clearSelection}
              className="flex items-center gap-2 px-3 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
            >
              <X size={15} />
              Annuler la sélection
            </button>
          )}
        </div>

        {/* Barre de sélection */}
        {selectionMode && (
          <div className="flex items-center gap-3 px-4 py-2.5 bg-[#E8F5E9] rounded-xl mb-3">
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
                <div className="relative">
                  <button
                    onClick={() => document.getElementById('dcp-bulk-statut')?.classList.toggle('hidden')}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1565C0]/10 text-[#1565C0] hover:bg-[#1565C0]/20 transition-colors"
                    title="Changer le statut"
                  >
                    <Repeat size={16} />
                  </button>
                  <div
                    id="dcp-bulk-statut"
                    className="hidden absolute right-0 mt-2 w-44 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                  >
                    {STATUTS.map((s) => {
                      const Icon = STATUT_ICON[s.key]
                      return (
                        <button
                          key={s.key}
                          onClick={() => {
                            document.getElementById('dcp-bulk-statut')?.classList.add('hidden')
                            void changerStatutSelection(s.key)
                          }}
                          className="w-full flex items-center gap-2 px-4 py-2 text-sm text-[#111111] hover:bg-[#f5f5f5]"
                        >
                          <Icon size={15} style={{ color: STATUT_HEX[s.key] }} />
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
            placeholder="Rechercher tag, localisation…"
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

        {filteredFuites.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-center">
            {searchQuery || statutFilter !== 'TOUS' ? (
              <Search size={40} className="text-[#00875a]/30 mb-4" />
            ) : (
              <Droplets size={40} className="text-[#00875a]/30 mb-4" />
            )}
            <p className="text-lg font-bold text-[#111111]">
              {searchQuery || statutFilter !== 'TOUS'
                ? 'Aucune fuite trouvée'
                : 'Aucune fuite dans cette campagne'}
            </p>
            <p className="text-[#757575] mt-2">
              {searchQuery || statutFilter !== 'TOUS'
                ? 'Essaie un autre mot-clé'
                : isActive
                  ? 'Ajoute ta première fuite !'
                  : 'Campagne clôturée'}
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
                    {/* <th className="py-3 px-4 font-medium">Type vapeur</th> */}
                    <th className="py-3 px-4 font-medium">Coût annuel</th>
                    <th className="py-3 px-4 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredFuites.map((fuite) => {
                    const isSelected = selectedIds.has(fuite.id)
                    const statut = fuite.statut ?? ''
                    const cout = fuite.coutAnnuelEstime
                    const coutClr = perteColor(cout)
                    const StatutIcon = STATUT_ICON[statut] ?? HelpCircle
                    const photosOpen = photosOpenId === fuite.id
                    return (
                      <Fragment key={fuite.id}>
                      <tr
                        onClick={() =>
                          selectionMode
                            ? toggleSelection(fuite.id)
                            : navigate(`/fuites/${fuite.id}`)
                        }
                        onContextMenu={(e) => {
                          e.preventDefault()
                          toggleSelection(fuite.id)
                        }}
                        className={`group border-b border-[#e5e7eb]/50 last:border-0 cursor-pointer transition-colors ${
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
                            {/* Flèche photos — remplace l'icône Tag au survol de la ligne */}
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                setPhotosOpenId(photosOpen ? null : fuite.id)
                              }}
                              className={`hidden group-hover:inline-flex items-center justify-center w-5 h-5 rounded-md transition-colors ${
                                photosOpen ? 'bg-[#00875a]/10 rotate-180' : ''
                              }`}
                              title={photosOpen ? 'Masquer les photos' : 'Voir les photos'}
                            >
                              <ChevronDown
                                size={14}
                                className={`transition-colors ${photosOpen ? 'text-[#00875a]' : 'text-[#757575]'}`}
                              />
                            </button>
                            <Tag size={14} className="text-[#757575] group-hover:hidden" />
                            <span className="font-bold text-[#111111]">
                              {fuite.numeroTag ?? 'Sans tag'}
                            </span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-[#757575] max-w-xs truncate">
                          {fuite.zone ?? '—'}
                        </td>
                        <td className="py-3 px-4">
                          <div className="relative inline-block">
                            <button
                              onClick={(e) => {
                                e.stopPropagation()
                                document
                                  .getElementById(`dcp-fuite-statut-${fuite.id}`)
                                  ?.classList.toggle('hidden')
                              }}
                              className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold"
                              style={{ backgroundColor: `${STATUT_HEX[statut] ?? '#757575'}1A`, color: STATUT_HEX[statut] ?? '#757575' }}
                            >
                              <StatutIcon size={12} />
                              {STATUT_LABEL[statut] ?? statut}
                              <ChevronDown size={11} />
                            </button>
                            <div
                              id={`dcp-fuite-statut-${fuite.id}`}
                              className="hidden absolute left-0 mt-1 w-40 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                            >
                              {STATUTS.map((s) => {
                                const Icon = STATUT_ICON[s.key]
                                return (
                                  <button
                                    key={s.key}
                                    onClick={(e) => {
                                      e.stopPropagation()
                                      document
                                        .getElementById(`dcp-fuite-statut-${fuite.id}`)
                                        ?.classList.add('hidden')
                                      void changerStatutFuite(fuite, s.key)
                                    }}
                                    className="w-full flex items-center gap-2 px-3 py-1.5 text-xs text-[#111111] hover:bg-[#f5f5f5]"
                                  >
                                    <Icon size={13} style={{ color: STATUT_HEX[s.key] }} />
                                    {s.label}
                                  </button>
                                )
                              })}
                            </div>
                          </div>
                        </td>
                        {/* <td className="py-3 px-4 text-[#757575]">
                          {(fuite.typeVapeur ?? '').replace(/_/g, ' ') || '—'}
                        </td> */}
                        <td className="py-3 px-4">
                          {cout != null && cout > 0 ? (
                            <span className="font-bold" style={{ color: coutClr }}>
                              {formatCout(cout)}
                            </span>
                          ) : (
                            <span className="text-[#9ca3af]">—</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-[#757575] whitespace-nowrap">
                          {formatDateTime(fuite.dateDetection)}
                        </td>
                      </tr>
                      {photosOpen && (
                        <tr className="bg-[#fafafa] border-b border-[#e5e7eb]/50">
                          <td colSpan={selectionMode ? 6 : 5} className="px-4 py-2">
                            <PhotosRow fuiteId={fuite.id} />
                          </td>
                        </tr>
                      )}
                      </Fragment>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* Modal d'édition campagne */}
      {editing && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={() => setEditing(false)}
        >
          <div
            className="bg-white rounded-2xl p-6 w-full max-w-md shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3 mb-5">
              <div className="w-10 h-10 rounded-full bg-[#E8F5E9] flex items-center justify-center">
                <Pencil size={18} className="text-[#00875a]" />
              </div>
              <div>
                <h3 className="text-lg font-extrabold text-[#111111]">Modifier la campagne</h3>
                <p className="text-xs text-[#757575]">Mets à jour les informations</p>
              </div>
            </div>

            <label className={labelCls}>Nom *</label>
            <input
              type="text"
              value={editNom}
              onChange={(e) => setEditNom(e.target.value)}
              maxLength={100}
              placeholder="Ex: Inspection Jorf Lasfar T1"
              className={inputCls}
            />

            <label className={`${labelCls} mt-4`}>Description (optionnel)</label>
            <textarea
              value={editDescription}
              onChange={(e) => setEditDescription(e.target.value)}
              rows={3}
              placeholder="Décrivez la campagne…"
              className={`${inputCls} resize-none`}
            />

            <label className="flex items-center justify-between mt-4 px-1 cursor-pointer">
              <span className="text-sm font-medium text-[#757575]">Campagne clôturée</span>
              <button
                onClick={() => setEditEstCloturee((v) => !v)}
                className={`relative w-11 h-6 rounded-full transition-colors ${
                  editEstCloturee ? 'bg-[#757575]' : 'bg-[#00875a]'
                }`}
                role="switch"
                aria-checked={editEstCloturee}
              >
                <span
                  className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${
                    editEstCloturee ? 'translate-x-[22px]' : 'translate-x-0.5'
                  }`}
                />
              </button>
            </label>

            {saving && (
              <p className="mt-3 text-xs text-[#00875a] flex items-center gap-1.5">
                <Loader2 size={14} className="animate-spin" />
                Enregistrement…
              </p>
            )}

            <div className="flex justify-end gap-2 mt-6">
              <button
                onClick={() => setEditing(false)}
                className="px-4 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] hover:bg-[#f5f5f5] transition-colors"
              >
                Annuler
              </button>
              <button
                onClick={() => void saveEdit()}
                disabled={saving}
                className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors disabled:opacity-50"
              >
                <Save size={15} />
                Enregistrer
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  )
}
