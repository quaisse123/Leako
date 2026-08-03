import { useEffect, useState } from 'react'
import {
  Plus,
  FolderKanban,
  Users,
  Star,
  CheckCircle2,
  Pencil,
  UserPlus,
  Trash2,
  LogOut,
  X,
  ChevronDown,
  ChevronUp,
  Mail,
  Search,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import {
  getProjets,
  getMesInvitations,
  repondreInvitation,
  createProjet,
  updateProjet,
  deleteProjet,
  inviterMembre,
  getAllUtilisateurs,
  getInvitationsByProjet,
  retirerMembre,
  quitterProjet,
} from '../api/projetApi'
import { getUser } from '../api/jwtService'
import { useProjetActif } from '../context/ProjetActifContext'
import type {
  ProjetResponseDto,
  ProjetMembreDto,
  InvitationResponseDto,
  UtilisateurResponseDto,
} from '../types'

/** Modale générique (formulaire ou confirmation). */
function Modal({
  title,
  children,
  onClose,
}: {
  title: string
  children: React.ReactNode
  onClose: () => void
}) {
  return (
    <div
      className="fixed inset-0 z-50 bg-black/40 flex items-end sm:items-center justify-center"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md bg-white rounded-t-3xl sm:rounded-3xl shadow-xl max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between px-5 py-4 border-b border-[#e5e7eb] sticky top-0 bg-white">
          <h2 className="text-lg font-bold text-[#111111]">{title}</h2>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-[#757575] hover:bg-[#f5f5f5] transition-colors"
            aria-label="Fermer"
          >
            <X size={18} />
          </button>
        </div>
        <div className="p-5">{children}</div>
      </div>
    </div>
  )
}

/** Carte projet — reprend exactement la logique mobile (owner vs membre). */
function ProjetCard({
  projet,
  isOwner,
  userId,
  expanded,
  onToggleExpand,
  onEdit,
  onInvite,
  onDelete,
  onQuit,
  onRetirerMembre,
}: {
  projet: ProjetResponseDto
  isOwner: boolean
  userId: number
  expanded: boolean
  onToggleExpand: () => void
  onEdit: () => void
  onInvite: () => void
  onDelete: () => void
  onQuit: () => void
  onRetirerMembre: (membreId: number, membreNom: string) => void
}) {
  const accepted =
    projet.membres?.filter((m) => m.statut === 'ACCEPTE') ?? []

  return (
    <div className="bg-white border border-[#e5e7eb] rounded-2xl p-5 shadow-sm">
      {/* Header : icône + nom + badge */}
      <div className="flex items-center gap-2 mb-2">
        {isOwner ? (
          <Star size={18} className="text-[#f57c00] flex-shrink-0" />
        ) : (
          <Users size={18} className="text-[#1565c0] flex-shrink-0" />
        )}
        <h3 className="font-bold text-base text-[#111111] flex-1 truncate">
          {projet.nom}
        </h3>
        <Badge color={isOwner ? 'orange' : 'blue'}>
          {isOwner ? 'Owner' : 'Membre'}
        </Badge>
      </div>

      {projet.description && (
        <p className="text-[13px] text-[#757575] mb-2">{projet.description}</p>
      )}

      {/* Membres count + expand/collapse */}
      <button
        onClick={onToggleExpand}
        className="flex items-center gap-1.5 w-full py-1.5 rounded-lg hover:bg-[#f5f5f5] transition-colors text-left"
      >
        <Users size={14} className="text-[#757575] flex-shrink-0" />
        <span className="text-xs text-[#757575]">
          {accepted.length} membre(s)
        </span>
        <span className="ml-auto text-[11px] text-[#757575]">
          Créé par {projet.createurNom ?? '—'}
        </span>
        {expanded ? (
          <ChevronUp size={16} className="text-[#757575] flex-shrink-0" />
        ) : (
          <ChevronDown size={16} className="text-[#757575] flex-shrink-0" />
        )}
      </button>

      {expanded && (
        <div className="mt-1 border-t border-black/10 pt-2">
          {accepted.length === 0 && (
            <p className="text-xs text-[#9ca3af] italic px-1 py-2">
              Aucun membre accepté
            </p>
          )}
          {accepted.map((m) => (
            <MembreTile
              key={m.id}
              membre={m}
              createurId={projet.createurId ?? 0}
              currentUserId={userId}
              onRetirer={() =>
                onRetirerMembre(m.utilisateurId, m.utilisateurNom)
              }
            />
          ))}
        </div>
      )}

      {/* Actions */}
      <div className="flex justify-end gap-1 mt-2.5">
        {isOwner ? (
          <>
            <ActionBtn
              icon={<Pencil size={14} />}
              label="Modifier"
              color="#00875a"
              onClick={onEdit}
            />
            <ActionBtn
              icon={<UserPlus size={14} />}
              label="Inviter"
              color="#1565c0"
              onClick={onInvite}
            />
            <ActionBtn
              icon={<Trash2 size={14} />}
              label="Supprimer"
              color="#d32f2f"
              onClick={onDelete}
            />
          </>
        ) : (
          <ActionBtn
            icon={<LogOut size={14} />}
            label="Quitter"
            color="#d32f2f"
            onClick={onQuit}
          />
        )}
      </div>
    </div>
  )
}

/** Bouton d'action textuel (comme TextButton.icon mobile). */
function ActionBtn({
  icon,
  label,
  color,
  onClick,
}: {
  icon: React.ReactNode
  label: string
  color: string
  onClick: () => void
}) {
  return (
    <button
      onClick={onClick}
      className="flex items-center gap-1 px-2 py-1.5 rounded-lg text-xs font-semibold hover:bg-black/5 transition-colors"
      style={{ color }}
    >
      {icon}
      {label}
    </button>
  )
}

/** Ligne d'un membre — identique au mobile. */
function MembreTile({
  membre,
  createurId,
  currentUserId,
  onRetirer,
}: {
  membre: ProjetMembreDto
  createurId: number
  currentUserId: number
  onRetirer: () => void
}) {
  const isOwner = membre.utilisateurId === createurId
  const initial = membre.utilisateurNom?.[0]?.toUpperCase() ?? '?'

  return (
    <div className="flex items-center gap-2.5 py-1.5">
      <div
        className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold ${
          isOwner ? 'bg-[#f57c00]/15 text-[#f57c00]' : 'bg-[#00875a]/10 text-[#00875a]'
        }`}
      >
        {initial}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-[13px] font-semibold text-[#111111] truncate">
          {membre.utilisateurNom}
        </p>
        {membre.utilisateurEmail && (
          <p className="text-[11px] text-[#757575] truncate">
            {membre.utilisateurEmail}
          </p>
        )}
      </div>
      <Badge color={isOwner ? 'orange' : 'green'}>
        {isOwner ? 'Owner' : 'Membre'}
      </Badge>
      {/* Retirer visible seulement pour l'owner (pas sur lui-même) */}
      {!isOwner && currentUserId === createurId && (
        <button
          onClick={onRetirer}
          title="Retirer ce membre"
          className="p-1 rounded-lg bg-[#d32f2f]/10 text-[#d32f2f] hover:bg-[#d32f2f]/20 transition-colors"
        >
          <X size={14} />
        </button>
      )}
    </div>
  )
}

/**
 * Gestion des Projets — réplique exacte de l'app mobile :
 * Invitations en attente · Créer un projet · Mes projets (owner) · Projets d'équipe.
 */
export default function ProjetsPage() {
  const [mesProjets, setMesProjets] = useState<ProjetResponseDto[]>([])
  const [teamProjets, setTeamProjets] = useState<ProjetResponseDto[]>([])
  const [invitations, setInvitations] = useState<InvitationResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const [expandedIds, setExpandedIds] = useState<Set<number>>(new Set())
  const [toast, setToast] = useState<string | null>(null)

  // Dialogues
  const [showCreate, setShowCreate] = useState(false)
  const [editing, setEditing] = useState<ProjetResponseDto | null>(null)
  const [inviting, setInviting] = useState<ProjetResponseDto | null>(null)
  const [deleting, setDeleting] = useState<ProjetResponseDto | null>(null)
  const [quitting, setQuitting] = useState<ProjetResponseDto | null>(null)
  const [retiring, setRetiring] = useState<{
    projetId: number
    membreId: number
    membreNom: string
  } | null>(null)

  // Champs de formulaire
  const [nom, setNom] = useState('')
  const [description, setDescription] = useState('')

  const { reload: reloadContext } = useProjetActif()
  const user = getUser()
  const userId = user?.id ?? 0

  const showToast = (msg: string) => {
    setToast(msg)
    setTimeout(() => setToast(null), 3000)
  }

  const loadAll = async () => {
    setLoading(true)
    try {
      const [projets, invs] = await Promise.all([
        getProjets(),
        getMesInvitations(),
      ])
      const mes = projets.filter((p) => p.createurId === userId)
      const team = projets.filter((p) => p.createurId !== userId)
      setMesProjets(mes)
      setTeamProjets(team)
      setInvitations(invs.filter((i) => i.statut === 'INVITE'))
    } catch (err) {
      console.error('Erreur chargement projets:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void loadAll()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // ── Invitations ──
  const handleRepondreInvitation = async (inv: InvitationResponseDto, accepte: boolean) => {
    try {
      await repondreInvitation(inv.id, accepte)
      await reloadContext()
      await loadAll()
      showToast(accepte ? 'Invitation acceptée !' : 'Invitation refusée')
    } catch (err) {
      console.error(err)
      showToast('Erreur lors de la réponse à l\'invitation')
    }
  }

  // ── Créer / Modifier ──
  const openCreate = () => {
    setNom('')
    setDescription('')
    setShowCreate(true)
  }

  const openEdit = (projet: ProjetResponseDto) => {
    setNom(projet.nom)
    setDescription(projet.description ?? '')
    setEditing(projet)
  }

  const handleSave = async () => {
    if (!nom.trim()) return
    try {
      if (editing) {
        await updateProjet(editing.id, {
          nom: nom.trim(),
          description: description.trim() || undefined,
        })
      } else {
        await createProjet({
          nom: nom.trim(),
          description: description.trim() || undefined,
        })
      }
      setShowCreate(false)
      setEditing(null)
      await reloadContext()
      await loadAll()
      showToast(editing ? 'Projet modifié ✓' : 'Projet créé ✓')
    } catch (err) {
      console.error(err)
      showToast('Erreur lors de l\'enregistrement')
    }
  }

  // ── Inviter ──
  const handleInvite = async (projet: ProjetResponseDto) => {
    setInviting(projet)
  }

  const handleInviteUser = async (projetId: number, utilisateurId: number, nom: string) => {
    try {
      await inviterMembre(projetId, utilisateurId)
      setInviting(null)
      await loadAll()
      showToast(`${nom} invité avec succès !`)
    } catch (err) {
      console.error(err)
      showToast('Erreur lors de l\'invitation')
    }
  }

  // ── Supprimer / Quitter / Retirer ──
  const handleDelete = async () => {
    if (!deleting) return
    try {
      await deleteProjet(deleting.id)
      setDeleting(null)
      await reloadContext()
      await loadAll()
      showToast('Projet supprimé')
    } catch (err) {
      console.error(err)
      showToast('Erreur lors de la suppression')
    }
  }

  const handleQuit = async () => {
    if (!quitting) return
    try {
      await quitterProjet(quitting.id)
      setQuitting(null)
      await reloadContext()
      await loadAll()
      showToast('Vous avez quitté le projet')
    } catch (err) {
      console.error(err)
      showToast('Erreur lors de la sortie du projet')
    }
  }

  const handleRetirer = async () => {
    if (!retiring) return
    try {
      await retirerMembre(retiring.projetId, retiring.membreId)
      setRetiring(null)
      await loadAll()
      showToast(`${retiring.membreNom} a été retiré du projet`)
    } catch (err) {
      console.error(err)
      showToast('Erreur lors du retrait du membre')
    }
  }

  return (
    <Layout>
      <div className="p-6 max-w-4xl mx-auto">
        <PageHeader
          title="Gestion des Projets"
          subtitle="Mes projets (owner) · Projets d'équipe · Invitations"
          actions={(
            <button
              onClick={openCreate}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
            >
              <Plus size={16} />
              Nouveau projet
            </button>
          )}
        />

        {loading ? (
          <LoadingSpinner />
        ) : (
          <div className="space-y-8">
            {/* ── Invitations en attente ── */}
            {invitations.length > 0 && (
              <section>
                <SectionTitle title="Invitations en attente" color="#f57c00" />
                <div className="mt-2 space-y-2">
                  {invitations.map((inv) => (
                    <div
                      key={inv.id}
                      className="flex items-center gap-3 p-4 rounded-2xl border border-[#f57c00]/30 bg-[#f57c00]/5"
                    >
                      <div className="p-2 rounded-full bg-[#f57c00]/10 text-[#f57c00] flex-shrink-0">
                        <Mail size={18} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-bold text-sm text-[#111111] truncate">
                          Invitation : {inv.projetNom ?? 'Projet'}
                        </p>
                        <p className="text-xs text-[#757575]">
                          Par {inv.createurNom ?? '—'}
                        </p>
                      </div>
                      <button
                        onClick={() => handleRepondreInvitation(inv, true)}
                        title="Accepter"
                        className="p-2 rounded-lg text-[#00875a] hover:bg-[#00875a]/10 transition-colors"
                      >
                        <CheckCircle2 size={20} />
                      </button>
                      <button
                        onClick={() => handleRepondreInvitation(inv, false)}
                        title="Refuser"
                        className="p-2 rounded-lg text-[#d32f2f] hover:bg-[#d32f2f]/10 transition-colors"
                      >
                        <X size={20} />
                      </button>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* ── Créer un projet ── */}
            <button
              onClick={openCreate}
              className="flex items-center gap-3 w-full p-4 rounded-2xl border border-black/10 bg-[#f5f5f5] hover:bg-[#f0f4f2] transition-colors text-left"
            >
              <div className="p-2 rounded-full bg-[#00875a] text-white flex-shrink-0">
                <Plus size={18} />
              </div>
              <span className="font-bold text-[#00875a] flex-1">
                Créer un nouveau projet
              </span>
              <ChevronDown size={18} className="text-[#757575] rotate-[-90deg]" />
            </button>

            {/* ── Mes projets (owner) ── */}
            <section>
              <SectionTitle title="Mes projets" color="#00875a" />
              {mesProjets.length === 0 ? (
                <EmptyState message="Vous n'avez créé aucun projet" />
              ) : (
                <div className="mt-2 space-y-2">
                  {mesProjets.map((p) => (
                    <ProjetCard
                      key={p.id}
                      projet={p}
                      isOwner
                      userId={userId}
                      expanded={expandedIds.has(p.id)}
                      onToggleExpand={() => {
                        const next = new Set(expandedIds)
                        if (next.has(p.id)) next.delete(p.id)
                        else next.add(p.id)
                        setExpandedIds(next)
                      }}
                      onEdit={() => openEdit(p)}
                      onInvite={() => handleInvite(p)}
                      onDelete={() => setDeleting(p)}
                      onQuit={() => {}}
                      onRetirerMembre={(membreId, membreNom) =>
                        setRetiring({ projetId: p.id, membreId, membreNom })
                      }
                    />
                  ))}
                </div>
              )}
            </section>

            {/* ── Projets d'équipe (member) ── */}
            <section>
              <SectionTitle title="Projets d'équipe" color="#1565c0" />
              {teamProjets.length === 0 ? (
                <EmptyState message="Vous n'êtes membre d'aucune équipe" />
              ) : (
                <div className="mt-2 space-y-2">
                  {teamProjets.map((p) => (
                    <ProjetCard
                      key={p.id}
                      projet={p}
                      isOwner={false}
                      userId={userId}
                      expanded={expandedIds.has(p.id)}
                      onToggleExpand={() => {
                        const next = new Set(expandedIds)
                        if (next.has(p.id)) next.delete(p.id)
                        else next.add(p.id)
                        setExpandedIds(next)
                      }}
                      onEdit={() => {}}
                      onInvite={() => {}}
                      onDelete={() => {}}
                      onQuit={() => setQuitting(p)}
                      onRetirerMembre={() => {}}
                    />
                  ))}
                </div>
              )}
            </section>
          </div>
        )}

        {/* ── Dialogues ── */}

        {/* Créer / Modifier */}
        {(showCreate || editing) && (
          <Modal
            title={editing ? 'Modifier le projet' : 'Nouveau Projet'}
            onClose={() => {
              setShowCreate(false)
              setEditing(null)
            }}
          >
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-[#111111] mb-1.5">
                  Nom du projet
                </label>
                <input
                  value={nom}
                  onChange={(e) => setNom(e.target.value)}
                  placeholder="Nom du projet"
                  className="w-full px-3 py-2.5 rounded-xl border border-black/10 focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/20 outline-none text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-[#111111] mb-1.5">
                  Description (optionnelle)
                </label>
                <textarea
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Description du projet"
                  rows={2}
                  className="w-full px-3 py-2.5 rounded-xl border border-black/10 focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/20 outline-none text-sm resize-none"
                />
              </div>
              <div className="flex justify-end gap-2 pt-1">
                <button
                  onClick={() => {
                    setShowCreate(false)
                    setEditing(null)
                  }}
                  className="px-4 py-2 rounded-xl text-sm font-semibold text-[#757575] hover:bg-[#f5f5f5] transition-colors"
                >
                  Annuler
                </button>
                <button
                  onClick={handleSave}
                  disabled={!nom.trim()}
                  className="px-5 py-2 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors disabled:opacity-50"
                >
                  {editing ? 'Enregistrer' : 'Créer'}
                </button>
              </div>
            </div>
          </Modal>
        )}

        {/* Inviter */}
        {inviting && (
          <InviteModal
            projet={inviting}
            onClose={() => setInviting(null)}
            onInvite={handleInviteUser}
          />
        )}

        {/* Confirmation suppression */}
        {deleting && (
          <ConfirmModal
            title="Supprimer le projet ?"
            message={`Êtes-vous sûr de vouloir supprimer « ${deleting.nom} » ? Cette action est irréversible.`}
            confirmLabel="Supprimer"
            confirmColor="#d32f2f"
            onCancel={() => setDeleting(null)}
            onConfirm={handleDelete}
          />
        )}

        {/* Confirmation quitter */}
        {quitting && (
          <ConfirmModal
            title="Quitter le projet ?"
            message={`Êtes-vous sûr de vouloir quitter « ${quitting.nom} » ?`}
            confirmLabel="Quitter"
            confirmColor="#d32f2f"
            onCancel={() => setQuitting(null)}
            onConfirm={handleQuit}
          />
        )}

        {/* Confirmation retirer membre */}
        {retiring && (
          <ConfirmModal
            title="Retirer ce membre ?"
            message={`Êtes-vous sûr de vouloir retirer « ${retiring.membreNom} » du projet ?`}
            confirmLabel="Retirer"
            confirmColor="#d32f2f"
            onCancel={() => setRetiring(null)}
            onConfirm={handleRetirer}
          />
        )}

        {/* Toast */}
        {toast && (
          <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[60] px-5 py-3 rounded-xl bg-[#111111] text-white text-sm font-medium shadow-lg">
            {toast}
          </div>
        )}
      </div>
    </Layout>
  )
}

/** Titre de section avec barre colorée (comme mobile). */
function SectionTitle({ title, color }: { title: string; color: string }) {
  return (
    <div className="flex items-center gap-2">
      <div
        className="w-1 h-5 rounded"
        style={{ backgroundColor: color }}
      />
      <h2 className="text-[17px] font-black text-[#111111]">{title}</h2>
    </div>
  )
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="mt-2 p-5 rounded-2xl border border-black/10 bg-[#f5f5f5] text-center">
      <FolderKanban size={32} className="mx-auto text-[#9ca3af] mb-2" />
      <p className="text-sm text-[#757575]">{message}</p>
    </div>
  )
}

/** Modale de confirmation. */
function ConfirmModal({
  title,
  message,
  confirmLabel,
  confirmColor,
  onCancel,
  onConfirm,
}: {
  title: string
  message: string
  confirmLabel: string
  confirmColor: string
  onCancel: () => void
  onConfirm: () => void
}) {
  return (
    <Modal title={title} onClose={onCancel}>
      <p className="text-sm text-[#111111] mb-5">{message}</p>
      <div className="flex justify-end gap-2">
        <button
          onClick={onCancel}
          className="px-4 py-2 rounded-xl text-sm font-semibold text-[#757575] hover:bg-[#f5f5f5] transition-colors"
        >
          Annuler
        </button>
        <button
          onClick={onConfirm}
          className="px-5 py-2 rounded-xl text-white text-sm font-semibold transition-colors"
          style={{ backgroundColor: confirmColor }}
        >
          {confirmLabel}
        </button>
      </div>
    </Modal>
  )
}

/** Modale d'invitation avec recherche (comme mobile). */
function InviteModal({
  projet,
  onClose,
  onInvite,
}: {
  projet: ProjetResponseDto
  onClose: () => void
  onInvite: (projetId: number, utilisateurId: number, nom: string) => void
}) {
  const [users, setUsers] = useState<UtilisateurResponseDto[]>([])
  const [filtered, setFiltered] = useState<UtilisateurResponseDto[]>([])
  const [pendingIds, setPendingIds] = useState<Set<number>>(new Set())
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const load = async () => {
      try {
        const [allUsers, pendingInvs] = await Promise.all([
          getAllUtilisateurs(),
          getInvitationsByProjet(projet.id),
        ])
        // Exclure les membres déjà acceptés, garder les pending (grisés)
        const acceptedIds =
          projet.membres
            ?.filter((m) => m.statut === 'ACCEPTE')
            .map((m) => m.utilisateurId) ?? []
        const pending = new Set(
          pendingInvs
            .filter((i) => i.statut === 'INVITE')
            .map((i) => i.utilisateurId ?? 0),
        )
        const available = allUsers.filter((u) => !acceptedIds.includes(u.id))
        setUsers(available)
        setFiltered(available)
        setPendingIds(pending)
      } catch (err) {
        console.error('Erreur chargement utilisateurs:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projet.id])

  const handleSearch = (value: string) => {
    setSearch(value)
    const q = value.toLowerCase()
    setFiltered(
      users.filter(
        (u) =>
          u.nom.toLowerCase().includes(q) ||
          (u.email?.toLowerCase().includes(q) ?? false),
      ),
    )
  }

  return (
    <Modal title="Inviter un membre" onClose={onClose}>
      <div className="relative mb-3">
        <Search
          size={16}
          className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9ca3af]"
        />
        <input
          value={search}
          onChange={(e) => handleSearch(e.target.value)}
          placeholder="Rechercher par nom ou email"
          className="w-full pl-9 pr-9 py-2.5 rounded-xl border border-black/10 focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/20 outline-none text-sm"
        />
        {search && (
          <button
            onClick={() => handleSearch('')}
            className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#111111]"
            aria-label="Effacer"
          >
            <X size={14} />
          </button>
        )}
      </div>

      {loading ? (
        <div className="py-10 flex justify-center">
          <LoadingSpinner />
        </div>
      ) : filtered.length === 0 ? (
        <p className="py-10 text-center text-sm text-[#757575]">
          Aucun utilisateur disponible
        </p>
      ) : (
        <div className="max-h-56 overflow-y-auto space-y-0.5">
          {filtered.map((u) => {
            const isPending = pendingIds.has(u.id)
            return (
              <button
                key={u.id}
                disabled={isPending}
                onClick={() => onInvite(projet.id, u.id, u.nom)}
                className={`flex items-center gap-3 w-full px-2 py-2 rounded-xl text-left transition-colors ${
                  isPending ? 'opacity-60 cursor-not-allowed' : 'hover:bg-[#f5f5f5]'
                }`}
              >
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold ${
                    isPending
                      ? 'bg-[#757575]/15 text-[#757575]'
                      : 'bg-[#00875a]/10 text-[#00875a]'
                  }`}
                >
                  {u.nom?.[0]?.toUpperCase() ?? '?'}
                </div>
                <div className="flex-1 min-w-0">
                  <p
                    className={`text-sm font-semibold truncate ${
                      isPending ? 'text-[#757575]' : 'text-[#111111]'
                    }`}
                  >
                    {u.nom}
                  </p>
                  {isPending ? (
                    <p className="text-xs italic text-[#757575]">
                      Déjà invité · En attente de réponse
                    </p>
                  ) : (
                    <p className="text-xs text-[#757575] truncate">
                      {u.email}
                    </p>
                  )}
                </div>
                {!isPending && (
                  <UserPlus size={14} className="text-[#00875a] flex-shrink-0" />
                )}
              </button>
            )
          })}
        </div>
      )}

      <div className="flex justify-end mt-4">
        <button
          onClick={onClose}
          className="px-4 py-2 rounded-xl text-sm font-semibold text-[#757575] hover:bg-[#f5f5f5] transition-colors"
        >
          Fermer
        </button>
      </div>
    </Modal>
  )
}
