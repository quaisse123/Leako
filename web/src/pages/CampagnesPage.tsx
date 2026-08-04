import { useEffect, useMemo, useState } from 'react'
import {
  Plus,
  CalendarDays,
  Droplets,
  MapPin,
  Search,
  X,
  Filter,
  ArrowUpDown,
  RefreshCw,
  Check,
  CheckSquare,
  Square,
  Trash2,
  Lock,
  LockOpen,
  Pencil,
  ChevronDown,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import {
  getCampagnes,
  updateCampagne,
  deleteCampagne,
  patchCampagne,
} from '../api/campagneApi'
import { useProjetActif } from '../context/ProjetActifContext'
import { useNavigate } from 'react-router-dom'
import type { CampagneResponseDto } from '../types'

type SortKey = 'date' | 'nom' | 'statut'

const SORT_OPTIONS: { key: SortKey; label: string }[] = [
  { key: 'date', label: 'Date' },
  { key: 'nom', label: 'Nom' },
  { key: 'statut', label: 'Statut' },
]

function formatDate(iso?: string): string {
  if (!iso) return '—'
  try {
    const d = new Date(iso.replace(' ', 'T'))
    return `${String(d.getDate()).padStart(2, '0')}/${String(
      d.getMonth() + 1,
    ).padStart(2, '0')}/${d.getFullYear()}`
  } catch {
    return iso
  }
}

/**
 * Liste des campagnes — recherche, filtre, tri, sélection multiple.
 * Reproduit fidèlement le comportement de l'app mobile (campagnes_page.dart).
 */
export default function CampagnesPage() {
  const [campagnes, setCampagnes] = useState<CampagneResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const { projetActif, loading: projetLoading } = useProjetActif()
  const navigate = useNavigate()

  // Recherche & filtres
  const [searchQuery, setSearchQuery] = useState('')
  const [showActiveOnly, setShowActiveOnly] = useState(false)
  const [sortBy, setSortBy] = useState<SortKey>('date')

  // Sélection multiple
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set())
  const [selectionMode, setSelectionMode] = useState(false)

  // Modale d'édition
  const [editing, setEditing] = useState<CampagneResponseDto | null>(null)
  const [editNom, setEditNom] = useState('')
  const [editDescription, setEditDescription] = useState('')
  const [editZone, setEditZone] = useState('')
  const [editCloturee, setEditCloturee] = useState(false)
  const [saving, setSaving] = useState(false)

  const loadCampagnes = async () => {
    if (!projetActif) return
    setLoading(true)
    try {
      const data = await getCampagnes(projetActif.id)
      setCampagnes(data)
    } catch (err) {
      console.error('Erreur chargement campagnes:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (projetLoading) return
    if (!projetActif) {
      setCampagnes([])
      setLoading(false)
      return
    }
    void loadCampagnes()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projetActif, projetLoading])

  // ─── Filtrage & tri (même logique que le mobile) ───────────────
  const filteredCampagnes = useMemo(() => {
    let result = [...campagnes]

    // Filtre "actives uniquement"
    if (showActiveOnly) {
      result = result.filter((c) => !c.estCloturee)
    }

    // Recherche textuelle (nom, description, zone)
    const q = searchQuery.trim().toLowerCase()
    if (q) {
      result = result.filter((c) => {
        const nom = (c.nom ?? '').toLowerCase()
        const desc = (c.description ?? '').toLowerCase()
        const zone = (c.zone ?? '').toLowerCase()
        return nom.includes(q) || desc.includes(q) || zone.includes(q)
      })
    }

    // Tri
    switch (sortBy) {
      case 'nom':
        result.sort((a, b) => (a.nom ?? '').localeCompare(b.nom ?? ''))
        break
      case 'statut':
        result.sort((a, b) => Number(a.estCloturee ?? false) - Number(b.estCloturee ?? false))
        break
      default: // date — plus récente en premier
        result.sort((a, b) => {
          const dateA = a.dateCreation ? new Date(a.dateCreation).getTime() : 0
          const dateB = b.dateCreation ? new Date(b.dateCreation).getTime() : 0
          return dateB - dateA
        })
    }

    return result
  }, [campagnes, showActiveOnly, searchQuery, sortBy])

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
    if (selectedIds.size === filteredCampagnes.length) {
      setSelectedIds(new Set())
      setSelectionMode(false)
    } else {
      setSelectedIds(new Set(filteredCampagnes.map((c) => c.id)))
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
    if (!window.confirm(`${count} campagne(s) seront définitivement supprimées.`)) return
    const ids = [...selectedIds]
    clearSelection()
    try {
      for (const id of ids) {
        await deleteCampagne(id)
      }
      await loadCampagnes()
      alert(`${count} campagne(s) supprimée(s) ✓`)
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const cloturerSelection = async () => {
    if (selectedIds.size === 0) return
    const ids = [...selectedIds]
    clearSelection()
    try {
      for (const id of ids) {
        await patchCampagne(id, { estCloturee: true })
      }
      await loadCampagnes()
      alert(`${ids.length} campagne(s) clôturée(s) ✓`)
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  // ─── Actions par campagne ──────────────────────────────────────
  const toggleCloturee = async (campagne: CampagneResponseDto) => {
    try {
      await patchCampagne(campagne.id, { estCloturee: !campagne.estCloturee })
      await loadCampagnes()
      alert(campagne.estCloturee ? 'Campagne réouverte ✓' : 'Campagne clôturée ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const supprimerCampagne = async (campagne: CampagneResponseDto) => {
    if (!window.confirm(`Supprimer la campagne « ${campagne.nom} » ?`)) return
    try {
      await deleteCampagne(campagne.id)
      await loadCampagnes()
      alert('Campagne supprimée ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    }
  }

  const openEdit = (campagne: CampagneResponseDto) => {
    setEditing(campagne)
    setEditNom(campagne.nom ?? '')
    setEditDescription(campagne.description ?? '')
    setEditZone(campagne.zone ?? '')
    setEditCloturee(campagne.estCloturee ?? false)
  }

  const saveEdit = async () => {
    if (!editing) return
    if (!editNom.trim()) {
      alert('Le nom est obligatoire.')
      return
    }
    setSaving(true)
    try {
      await updateCampagne(editing.id, {
        nom: editNom.trim(),
        description: editDescription,
        zone: editZone,
        estCloturee: editCloturee,
        createurId: editing.createurId,
        projetId: projetActif?.id,
      })
      setEditing(null)
      await loadCampagnes()
      alert('Campagne mise à jour ✓')
    } catch (e) {
      alert(`Erreur : ${e}`)
    } finally {
      setSaving(false)
    }
  }

  const allSelected = filteredCampagnes.length > 0 && selectedIds.size === filteredCampagnes.length

  return (
    <Layout>
      <div className="p-6 max-w-7xl mx-auto">
        <PageHeader
          title="Campagnes"
          subtitle={
            projetActif
              ? `${filteredCampagnes.length} campagne${filteredCampagnes.length > 1 ? 's' : ''} — ${projetActif.nom}`
              : 'Sélectionnez un projet pour voir ses campagnes'
          }
          actions={
            !selectionMode ? (
              <div className="flex items-center gap-2">
                {/* Filtre actives uniquement */}
                <button
                  onClick={() => setShowActiveOnly((v) => !v)}
                  className={`flex items-center gap-2 px-3 py-2.5 rounded-xl border text-sm font-medium transition-colors ${
                    showActiveOnly
                      ? 'border-[#00875a] text-[#00875a] bg-[#00875a]/5'
                      : 'border-[#e5e7eb] text-[#757575] bg-white hover:bg-[#f5f5f5]'
                  }`}
                  title="Actives uniquement"
                >
                  <Filter size={16} />
                  Actives
                </button>

                {/* Tri */}
                <div className="relative">
                  <button
                    onClick={() => document.getElementById('campagnes-sort-menu')?.classList.toggle('hidden')}
                    className="flex items-center gap-2 px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] bg-white hover:bg-[#f5f5f5] transition-colors"
                  >
                    <ArrowUpDown size={16} />
                    {SORT_OPTIONS.find((o) => o.key === sortBy)?.label}
                    <ChevronDown size={14} />
                  </button>
                  <div
                    id="campagnes-sort-menu"
                    className="hidden absolute right-0 mt-2 w-44 bg-white border border-[#e5e7eb] rounded-xl shadow-lg z-20 py-1"
                  >
                    {SORT_OPTIONS.map((o) => (
                      <button
                        key={o.key}
                        onClick={() => {
                          setSortBy(o.key)
                          document.getElementById('campagnes-sort-menu')?.classList.add('hidden')
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
                  onClick={() => void loadCampagnes()}
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
                  onClick={() => navigate('/campagnes/nouvelle')}
                  className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
                >
                  <Plus size={16} />
                  Nouvelle campagne
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
                <button
                  onClick={() => void cloturerSelection()}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1565C0]/10 text-[#1565C0] hover:bg-[#1565C0]/20 transition-colors"
                  title="Clôturer la sélection"
                >
                  <Lock size={16} />
                </button>
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
            placeholder="Rechercher une campagne…"
            className="w-full pl-11 pr-10 py-3 rounded-xl bg-transparent border border-[#e5e7eb] text-sm text-[#111111] focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]"
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
        ) : filteredCampagnes.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            {searchQuery ? (
              <Search size={40} className="text-[#00875a]/30 mb-4" />
            ) : (
              <CalendarDays size={40} className="text-[#00875a]/30 mb-4" />
            )}
            <p className="text-lg font-bold text-[#111111]">
              {searchQuery ? 'Aucune campagne trouvée' : 'Aucune campagne'}
            </p>
            <p className="text-[#757575] mt-2">
              {searchQuery ? 'Essaie un autre mot-clé' : 'Crée ta première campagne !'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredCampagnes.map((campagne) => {
              const isSelected = selectedIds.has(campagne.id)
              const cloturee = campagne.estCloturee ?? false
              return (
                <div
                  key={campagne.id}
                  onClick={() =>
                    selectionMode
                      ? toggleSelection(campagne.id)
                      : navigate(`/campagnes/${campagne.id}`)
                  }
                  onContextMenu={(e) => {
                    e.preventDefault()
                    toggleSelection(campagne.id)
                  }}
                  className={`bg-white border rounded-2xl p-5 transition-all cursor-pointer ${
                    isSelected
                      ? 'border-[#00875a] ring-2 ring-[#00875a]/20'
                      : 'border-[#e5e7eb] hover:shadow-lg hover:shadow-black/5'
                  }`}
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2 min-w-0">
                      {selectionMode && (
                        <button
                          onClick={(e) => {
                            e.stopPropagation()
                            toggleSelection(campagne.id)
                          }}
                          className={`w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-colors ${
                            isSelected ? 'bg-[#00875a] border-[#00875a]' : 'border-[#757575]'
                          }`}
                        >
                          {isSelected && <Check size={12} className="text-white" />}
                        </button>
                      )}
                      <h3 className="font-semibold text-[#111111] truncate">{campagne.nom}</h3>
                    </div>
                    <Badge color={cloturee ? 'gray' : 'green'}>
                      {cloturee ? 'Clôturée' : 'Active'}
                    </Badge>
                  </div>
                  <p className="text-sm text-[#757575] line-clamp-2 mb-4">
                    {campagne.description || 'Aucune description'}
                  </p>
                  {campagne.zone && (
                    <div className="flex items-center gap-1.5 text-xs text-[#757575] mb-2">
                      <MapPin size={12} className="text-[#00875a]" />
                      {campagne.zone}
                    </div>
                  )}
                  <div className="flex items-center gap-1.5 text-xs text-[#9ca3af] mb-4">
                    <Droplets size={12} className="text-[#00875a]" />
                    {campagne.nombreFuites ?? 0} fuite(s) •{' '}
                    {formatDate(campagne.dateCreation)}
                  </div>

                  {!selectionMode && (
                    <div className="flex items-center gap-2 pt-3 border-t border-[#e5e7eb]/60">
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          openEdit(campagne)
                        }}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#00875a]/10 text-[#00875a] text-xs font-semibold hover:bg-[#00875a]/20 transition-colors"
                      >
                        <Pencil size={14} />
                        Modifier
                      </button>
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          void toggleCloturee(campagne)
                        }}
                        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                          cloturee
                            ? 'bg-[#00875a]/10 text-[#00875a] hover:bg-[#00875a]/20'
                            : 'bg-[#1565C0]/10 text-[#1565C0] hover:bg-[#1565C0]/20'
                        }`}
                      >
                        {cloturee ? <LockOpen size={14} /> : <Lock size={14} />}
                        {cloturee ? 'Réouvrir' : 'Clôturer'}
                      </button>
                      <div className="flex-1" />
                      <button
                        onClick={(e) => {
                          e.stopPropagation()
                          void supprimerCampagne(campagne)
                        }}
                        className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#D32F2F]/10 text-[#D32F2F] text-xs font-semibold hover:bg-[#D32F2F]/20 transition-colors"
                      >
                        <Trash2 size={14} />
                        
                      </button>
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        )}

        {/* Modale d'édition */}
        {editing && (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
            onClick={() => setEditing(null)}
          >
            <div
              className="bg-white rounded-2xl w-full max-w-md p-6 shadow-xl"
              onClick={(e) => e.stopPropagation()}
            >
              <h2 className="text-lg font-bold text-[#111111] mb-4">Modifier la campagne</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-[#111111] mb-1">Nom *</label>
                  <input
                    type="text"
                    value={editNom}
                    onChange={(e) => setEditNom(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#111111] mb-1">Description</label>
                  <textarea
                    value={editDescription}
                    onChange={(e) => setEditDescription(e.target.value)}
                    rows={3}
                    className="w-full px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#111111] mb-1">Zone</label>
                  <input
                    type="text"
                    value={editZone}
                    onChange={(e) => setEditZone(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl border border-[#e5e7eb] text-sm focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]"
                  />
                </div>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editCloturee}
                    onChange={(e) => setEditCloturee(e.target.checked)}
                    className="w-4 h-4 accent-[#00875a]"
                  />
                  <span className="text-sm text-[#111111]">Clôturée</span>
                </label>
              </div>
              <div className="flex items-center justify-end gap-2 mt-6">
                <button
                  onClick={() => setEditing(null)}
                  className="px-4 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] hover:bg-[#f5f5f5] transition-colors"
                >
                  Annuler
                </button>
                <button
                  onClick={() => void saveEdit()}
                  disabled={saving}
                  className="px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors disabled:opacity-50"
                >
                  {saving ? 'Enregistrement…' : 'Enregistrer'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </Layout>
  )
}
