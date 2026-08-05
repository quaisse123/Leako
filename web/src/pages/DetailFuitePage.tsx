import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft,
  Calculator,
  Camera,
  CheckCircle2,
  Droplets,
  Loader2,
  Map,
  MapPin,
  MessageCircle,
  Pencil,
  Play,
  Ruler,
  Save,
  Sparkles,
  Tag,
  Trash2,
  X,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import FuiteChatModal from '../components/FuiteChatModal'
import ConfigModal from '../components/ConfigModal'
import CartePredictionIA from '../components/CartePredictionIA'
import { getFuiteById, updateFuite, deleteFuite } from '../api/fuiteApi'
import { getPhotosByFuite, uploadPhoto, deletePhoto } from '../api/photoApi'
import { getParametres } from '../api/parametreApi'
import { analyserParFuite, getDerniereAnalyse } from '../api/analyseIaApi'
import { fileUrl } from '../utils/fileUrl'
import { toBackendDate, toDatetimeLocal } from '../utils/dateFormat'
import { useMediaViewer, isVideoPath } from '../context/MediaViewerContext'
import type {
  AnalyseIAReponse,
  FuiteResponseDto,
  ParametreGlobalResponseDto,
  PhotoResponseDto,
  StatutFuite,
  TypeVapeur,
} from '../types'

const STATUTS: Record<StatutFuite, string> = {
  A_REPARER: 'À réparer',
  EN_COURS: 'En cours',
  REPAREE: 'Réparée',
  ANNULEE: 'Annulée',
}

const TYPES_VAPEUR: Record<TypeVapeur, string> = {
  VAPEUR_SATUREE: 'Vapeur saturée',
  VAPEUR_SURCHAUFFEE: 'Vapeur surchauffée',
  VAPEUR_HAUTE_PRESSION: 'Vapeur haute pression (HP)',
  VAPEUR_BASSE_PRESSION: 'Vapeur basse pression (BP)',
  VAPEUR_RESIDUELLE: 'Vapeur résiduelle',
}

/** Formule de Napier (identique à l'app mobile). */
function calculerDebit(pressionRel: number, diametreMm: number): number {
  return 0.262 * diametreMm * diametreMm * (pressionRel + 1)
}

function calculerCoutAnnuel(
  debitKgh: number,
  pressionRel: number,
  coutKwh: number,
  heuresJour: number,
  joursAn: number,
): number {
  const heuresAnnuelles = heuresJour * joursAn
  const enthalpie = (2700 + pressionRel * 8) / 3600
  return debitKgh * enthalpie * heuresAnnuelles * coutKwh
}

/**
 * Détail d'une fuite — affichage + modification + suppression + photos.
 * Réplique l'app mobile (modifier_fuite_page.dart).
 */
export default function DetailFuitePage() {
  const { id } = useParams<{ id: string }>()
  const fuiteId = Number(id)
  const navigate = useNavigate()
  const { openMedia } = useMediaViewer()

  const [fuite, setFuite] = useState<FuiteResponseDto | null>(null)
  const [photos, setPhotos] = useState<PhotoResponseDto[]>([])
  const [loading, setLoading] = useState(true)

  // ─── Mode édition ────────────────────────────────────
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState('')

  // Champs du formulaire
  const [numeroTag, setNumeroTag] = useState('')
  const [dateDetection, setDateDetection] = useState('')
  const [statut, setStatut] = useState<StatutFuite>('A_REPARER')
  const [typeVapeur, setTypeVapeur] = useState<TypeVapeur | ''>('')
  const [pressionBar, setPressionBar] = useState('')
  const [diametreOrifice, setDiametreOrifice] = useState(5)
  const [zone, setZone] = useState('')
  const [description, setDescription] = useState('')
  const [gpsLatitude, setGpsLatitude] = useState<number | null>(null)
  const [gpsLongitude, setGpsLongitude] = useState<number | null>(null)
  const [gpsLoading, setGpsLoading] = useState(false)

  // Nouvelles photos à uploader + photos existantes marquées supprimées
  const [newPhotos, setNewPhotos] = useState<File[]>([])
  const [newPreviews, setNewPreviews] = useState<string[]>([])
  const [deletedPhotoIds, setDeletedPhotoIds] = useState<number[]>([])

  // ─── IA ───────────────────────────────────────────────
  const [iaLoading, setIaLoading] = useState(false)
  const [iaEffectuee, setIaEffectuee] = useState(false)
  const [iaReponse, setIaReponse] = useState<AnalyseIAReponse | null>(null)
  /** true si les photos ont changé depuis l'analyse persistée → la carte IA n'est plus valide. */
  const [photosModifiees, setPhotosModifiees] = useState(false)

  // ─── Chat ─────────────────────────────────────────────
  const [chatOpen, setChatOpen] = useState(false)
  // Paramètres globaux (coût kWh, heures/jour, jours/an) — comme l'app mobile
  const [parametres, setParametres] = useState<ParametreGlobalResponseDto | null>(null)
  // Modale de configuration ouverte par-dessus le formulaire (sans le perdre)
  const [configOpen, setConfigOpen] = useState(false)

  const chargerParametres = async () => {
    try {
      const data = await getParametres()
      setParametres(data)
    } catch (err) {
      console.error('Erreur chargement paramètres:', err)
    }
  }

  useEffect(() => {
    void chargerParametres()
  }, [])

  useEffect(() => {
    let cancelled = false
    const load = async () => {
      setLoading(true)
      try {
        const [fuiteData, photosData] = await Promise.all([
          getFuiteById(fuiteId),
          getPhotosByFuite(fuiteId),
        ])
        if (cancelled) return
        setFuite(fuiteData)
        setPhotos(photosData)

        // Préremplir le formulaire
        setNumeroTag(fuiteData.numeroTag ?? '')
        setDateDetection(toDatetimeLocal(fuiteData.dateDetection))
        setStatut(fuiteData.statut ?? 'A_REPARER')
        setTypeVapeur(fuiteData.typeVapeur ?? '')
        setPressionBar(
          fuiteData.pressionBar != null
            ? String(fuiteData.pressionBar)
            : '',
        )
        setDiametreOrifice(fuiteData.diametreOrifice ?? 5)
        setZone(fuiteData.zone ?? '')
        setDescription(fuiteData.description ?? '')
        setGpsLatitude(fuiteData.gpsLatitude ?? null)
        setGpsLongitude(fuiteData.gpsLongitude ?? null)

        // Charger la dernière analyse IA persistée pour préremplir
        // la carte IA + la description si elle est à jour.
        void chargerAnalysePersistee()
      } catch (err) {
        console.error('Erreur chargement fuite:', err)
        setError('Impossible de charger la fuite.')
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
  }, [fuiteId])

  const pression = useMemo(() => Number(pressionBar) || 0, [pressionBar])
  const debit = useMemo(
    () => calculerDebit(pression, diametreOrifice),
    [pression, diametreOrifice],
  )
  const coutAnnuel = useMemo(
    () =>
      calculerCoutAnnuel(
        debit,
        pression,
        parametres?.coutKwhDiram ?? 0,
        parametres?.heuresActiviteParJour ?? 0,
        parametres?.joursActiviteParAn ?? 0,
      ),
    [debit, pression, parametres],
  )

  const capturerGps = () => {
    if (!('geolocation' in navigator)) {
      setError('La géolocalisation n\'est pas disponible dans ce navigateur.')
      return
    }
    setGpsLoading(true)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setGpsLatitude(pos.coords.latitude)
        setGpsLongitude(pos.coords.longitude)
        setGpsLoading(false)
      },
      () => {
        setError('Impossible de récupérer la position GPS.')
        setGpsLoading(false)
      },
      { enableHighAccuracy: true, timeout: 10000 },
    )
  }

  const handleNewPhotos = (files: FileList | null) => {
    if (!files) return
    const arr = Array.from(files)
    setNewPhotos((prev) => [...prev, ...arr])
    setNewPreviews((prev) => [
      ...prev,
      ...arr.map((f) => URL.createObjectURL(f)),
    ])
    // Les photos ont changé → l'analyse persistée n'est plus à jour
    invaliderIA()
  }

  const removeNewPhoto = (index: number) => {
    setNewPhotos((prev) => prev.filter((_, i) => i !== index))
    setNewPreviews((prev) => prev.filter((_, i) => i !== index))
    // Les photos ont changé → l'analyse persistée n'est plus à jour
    invaliderIA()
  }

  const markPhotoDeleted = (photoId: number) => {
    setPhotos((prev) => prev.filter((p) => p.id !== photoId))
    setDeletedPhotoIds((prev) => [...prev, photoId])
    // Les photos ont changé → l'analyse persistée n'est plus à jour
    invaliderIA()
  }

  /** Invalide la carte IA quand les photos changent. */
  const invaliderIA = () => {
    setPhotosModifiees(true)
    setIaReponse(null)
    setIaEffectuee(false)
  }

  /**
   * Charge la dernière analyse IA persistée en DB (si elle existe et si
   * les photos de la fuite n'ont pas changé depuis) puis préremplit la
   * carte IA et la description. (équivalent _chargerAnalysePersistee)
   */
  const chargerAnalysePersistee = async () => {
    try {
      const reponse = await getDerniereAnalyse(fuiteId)
      if (!reponse) return

      // La description actuelle est vide → on la préremplit avec la synthèse.
      const synthese = reponse.synthese?.trim() ?? ''
      setIaReponse(reponse)
      setIaEffectuee(true)
      if (description.trim().length === 0 && synthese.length > 0) {
        setDescription(synthese)
      }
    } catch (err) {
      console.error('Erreur chargement analyse persistée:', err)
      // Silencieux : pas d'analyse persistée → formulaire normal.
    }
  }

  /**
   * IA : Analyser les photos (fonction réutilisable).
   * Renvoie la réponse IA, ou null en cas d'échec.
   * (équivalent _analyserPhotos du mobile en mode édition)
   */
  const analyserPhotos = async (): Promise<AnalyseIAReponse | null> => {
    setIaLoading(true)
    setError('')

    try {
      // ── Uploader d'abord les nouvelles photos pour que l'analyse
      //    porte sur l'ensemble (existantes + nouvelles) ──
      if (newPhotos.length > 0) {
        for (const file of newPhotos) {
          await uploadPhoto(fuiteId, file)
        }
        setNewPhotos([])
        setNewPreviews([])
      }

      const reponse = await analyserParFuite(fuiteId)
      return reponse
    } catch (err) {
      console.error('Erreur analyse IA:', err)
      // Message convivial : on préfère le message du backend s'il est fourni,
      // sinon un message générique compréhensible par l'utilisateur.
      const message =
        err instanceof Error && err.message && !err.message.startsWith('Request failed')
          ? err.message
          : "Une erreur est survenue lors de l'analyse IA. Veuillez réessayer plus tard."
      setError(message)
      return null
    } finally {
      setIaLoading(false)
    }
  }

  /**
   * IA : Prédire le diamètre (indépendant de la description).
   * Seul ce bouton remplit iaReponse → affiche la carte d'analyse.
   */
  const predireDiametre = async () => {
    const reponse = await analyserPhotos()
    if (!reponse) return

    // Seul ce bouton remplit iaReponse → affiche la carte d'analyse.
    setIaReponse(reponse)
    setIaEffectuee(true)
    setPhotosModifiees(false) // La carte est à nouveau à jour.
    // Borner le diamètre dans la plage du slider (1.0 - 50.0).
    // Quand aucune fuite n'est détectée, diametreMoyenMm vaut 0.0.
    setDiametreOrifice(Math.min(50, Math.max(1, reponse.resume.diametreMoyenMm)))
  }

  /**
   * IA : Générer la description (indépendant du diamètre).
   * Priorité à la synthèse globale de l'IA si elle existe,
   * sinon concaténer les observations des médias avec fuite visible.
   */
  const genererDescriptionIA = async () => {
    // Si l'analyse n'a pas encore été faite, on la déclenche ici.
    let reponse = iaReponse
    if (reponse == null || reponse.resultats.length === 0) {
      reponse = await analyserPhotos()
      if (!reponse) return
    }

    const synthese = (reponse.synthese ?? '').trim()
    const descriptions = synthese
      ? [synthese]
      : reponse.resultats
          .filter((r) => r.fuiteVisible)
          .map((r) => (r.observation ?? '').trim())
          .filter((o) => o.length > 0)

    if (descriptions.length === 0) {
      setError('Aucune description générée par l\'IA')
      return
    }

    const actuelle = (description ?? '').trim()
    const nouvelle = actuelle
      ? `${actuelle}\n${descriptions.join('\n')}`
      : descriptions.join('\n')
    setDescription(nouvelle)
  }

  const handleSave = async () => {
    if (!fuite) return
    if (!pressionBar || Number(pressionBar) <= 0) {
      setError('La pression est requise et doit être positive.')
      return
    }
    setSaving(true)
    setError('')
    try {
      await updateFuite(fuite.id, {
        numeroTag: (numeroTag ?? '').trim() || undefined,
        dateDetection: toBackendDate(dateDetection),
        statut,
        pressionBar: pression,
        diametreOrifice,
        typeVapeur: typeVapeur || undefined,
        gpsLatitude: gpsLatitude ?? undefined,
        gpsLongitude: gpsLongitude ?? undefined,
        zone: (zone ?? '').trim() || undefined,
        description: (description ?? '').trim() || undefined,
        coutAnnuelEstime: Math.round(coutAnnuel * 100) / 100,
        campagneId: fuite.campagneId ?? 0,
      })

      // Nouvelles photos
      for (const file of newPhotos) {
        await uploadPhoto(fuite.id, file)
      }
      // Photos supprimées
      for (const photoId of deletedPhotoIds) {
        await deletePhoto(photoId)
      }

      // Recharger la fuite pour refléter les changements
      const [fuiteData, photosData] = await Promise.all([
        getFuiteById(fuite.id),
        getPhotosByFuite(fuite.id),
      ])
      setFuite(fuiteData)
      setPhotos(photosData)
      setNewPhotos([])
      setNewPreviews([])
      setDeletedPhotoIds([])
      setEditing(false)
    } catch (err) {
      console.error('Erreur enregistrement fuite:', err)
      setError('Erreur lors de l\'enregistrement.')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!fuite) return
    if (
      !window.confirm(
        `Supprimer la fuite ${fuite.numeroTag ?? `#${fuite.id}`} ? Cette action est irréversible.`,
      )
    ) {
      return
    }
    setDeleting(true)
    try {
      await deleteFuite(fuite.id)
      navigate('/fuites')
    } catch (err) {
      console.error('Erreur suppression fuite:', err)
      setError('Erreur lors de la suppression.')
      setDeleting(false)
    }
  }

  const inputCls =
    'w-full px-3 py-2 border border-[#e5e7eb] rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]'
  const labelCls = 'block text-sm font-medium text-[#757575] mb-1.5'

  const statutColor = (s?: string) =>
    s === 'REPAREE'
      ? 'green'
      : s === 'A_REPARER'
        ? 'red'
        : s === 'EN_COURS'
          ? 'yellow'
          : 'gray'

  if (loading) {
    return (
      <Layout>
        <div className="p-6 max-w-3xl mx-auto">
          <LoadingSpinner />
        </div>
      </Layout>
    )
  }

  if (!fuite) {
    return (
      <Layout>
        <div className="p-6 max-w-3xl mx-auto text-center py-20">
          <Droplets size={40} className="text-[#9ca3af] mx-auto mb-4" />
          <p className="text-[#757575]">Fuite introuvable.</p>
          <button
            onClick={() => navigate('/fuites')}
            className="mt-4 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-medium hover:bg-[#007049]"
          >
            Retour aux fuites
          </button>
        </div>
      </Layout>
    )
  }

  return (
    <Layout>
      <div className="p-6 max-w-3xl mx-auto">
        <button
          onClick={() => navigate('/fuites')}
          className="inline-flex items-center gap-1.5 text-sm text-[#757575] hover:text-[#00875a] mb-4 transition-colors"
        >
          <ArrowLeft size={16} />
          Retour aux fuites
        </button>

        <PageHeader
          title={editing ? 'Modifier la fuite' : (fuite.numeroTag ?? `Fuite #${fuite.id}`)}
          subtitle={
            editing
              ? 'Modifier les informations de la fuite'
              : `${fuite.campagneNom ?? 'Campagne inconnue'} • détectée le ${
                  fuite.dateDetection
                    ? new Date(fuite.dateDetection).toLocaleDateString('fr-FR')
                    : '—'
                }`
          }
          actions={
            <>
              <button
                onClick={() => setChatOpen(true)}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-[#00875a] text-[#00875a] text-sm font-semibold hover:bg-[#00875a]/5 transition-colors"
                title="Conversation sur cette fuite"
              >
                <MessageCircle size={16} />
                Conversation
              </button>
              {editing ? (
                <>
                  <button
                    onClick={() => setEditing(false)}
                    className="px-4 py-2 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] hover:bg-[#f9fafb] transition-colors"
                  >
                    Annuler
                  </button>
                  <button
                    onClick={handleSave}
                    disabled={saving}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#007049] transition-colors disabled:opacity-60"
                  >
                    {saving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
                    Enregistrer
                  </button>
                </>
              ) : (
                <>
                  <button
                    onClick={() => setEditing(true)}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#007049] transition-colors"
                  >
                    <Pencil size={16} />
                    Modifier
                  </button>
                  <button
                    onClick={handleDelete}
                    disabled={deleting}
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-red-200 text-red-600 text-sm font-semibold hover:bg-red-50 transition-colors disabled:opacity-60"
                  >
                    {deleting ? <Loader2 size={16} className="animate-spin" /> : <Trash2 size={16} />}
                    Supprimer
                  </button>
                </>
              )}
            </>
          }
        />

        {error && (
          <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-xl px-4 py-2.5 mb-4">
            {error}
          </p>
        )}

        {chatOpen && fuite && (
          <FuiteChatModal
            fuiteId={fuite.id}
            numeroTag={fuite.numeroTag ?? `Fuite #${fuite.id}`}
            onClose={() => setChatOpen(false)}
          />
        )}

        {editing ? (
          /* ─────────── MODE ÉDITION ─────────── */
          <div className="bg-white border border-[#e5e7eb] rounded-2xl p-6 space-y-6">
            {/* Campagne (lecture seule) */}
            <div>
              <label className={labelCls}>Campagne</label>
              <div className="flex items-center gap-2 px-3 py-2 border border-[#e5e7eb] rounded-xl bg-[#f9fafb] text-sm text-[#111111]">
                <span className="text-[#00875a]">●</span>
                {fuite.campagneNom ?? '—'}
              </div>
            </div>

            {/* Tag */}
            <div>
              <label className={labelCls}>Numéro de tag</label>
              <div className="relative">
                <Tag size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9ca3af]" />
                <input
                  className={`${inputCls} pl-9`}
                  value={numeroTag}
                  onChange={(e) => setNumeroTag(e.target.value)}
                  placeholder="Tag de la fuite"
                  readOnly
                />
              </div>
            </div>

            {/* Date + Statut */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelCls}>Date de détection</label>
                <input
                  type="datetime-local"
                  className={inputCls}
                  value={dateDetection}
                  onChange={(e) => setDateDetection(e.target.value)}
                />
              </div>
              <div>
                <label className={labelCls}>Statut</label>
                <select
                  className={inputCls}
                  value={statut}
                  onChange={(e) => setStatut(e.target.value as StatutFuite)}
                >
                  {Object.entries(STATUTS).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>
            </div>

            {/* Type vapeur + Pression */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelCls}>Type de vapeur</label>
                <select
                  className={inputCls}
                  value={typeVapeur}
                  onChange={(e) => setTypeVapeur(e.target.value as TypeVapeur)}
                >
                  <option value="">Sélectionner un type</option>
                  {Object.entries(TYPES_VAPEUR).map(([key, label]) => (
                    <option key={key} value={key}>{label}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className={labelCls}>Pression (bar) *</label>
                <input
                  type="number"
                  step="0.1"
                  min="0"
                  className={inputCls}
                  value={pressionBar}
                  onChange={(e) => setPressionBar(e.target.value)}
                  placeholder="Ex: 7.5"
                />
              </div>
            </div>

            {/* Diamètre + Estimation */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelCls}>Diamètre orifice (mm)</label>
                <div className="flex items-center gap-3 border border-[#e5e7eb] rounded-xl px-4 py-2">
                  <span className="text-sm text-[#757575] flex-1">1 mm</span>
                  <input
                    type="range"
                    min={1}
                    max={50}
                    step={0.5}
                    value={diametreOrifice}
                    onChange={(e) => setDiametreOrifice(Number(e.target.value))}
                    className="flex-1 accent-[#00875a]"
                  />
                  <span className="text-sm text-[#757575]">50 mm</span>
                </div>
                <p className="text-lg font-bold text-[#00875a] mt-2 text-center">
                  {diametreOrifice.toFixed(1)} mm
                </p>
              </div>
              <div>
                <label className={labelCls}>Estimation</label>
                {coutAnnuel === 0 && (
                  <div className="mb-2 flex items-center gap-2.5 rounded-xl border border-[#ffb74d]/50 bg-[#fff3e0] px-3 py-2.5">
                    <span className="text-[#e65100]">
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z" />
                        <path d="M12 9v4" />
                        <path d="M12 17h.01" />
                      </svg>
                    </span>
                    <span className="flex-1 text-xs font-medium text-[#e65100]">
                      Prix kWh à 0,00 MAD — configurez-le
                    </span>
                    <button
                      type="button"
                      onClick={() => setConfigOpen(true)}
                      className="text-[#e65100] hover:opacity-80 transition-opacity"
                      title="Paramètres"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        width="20"
                        height="20"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="2"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                      >
                        <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z" />
                        <circle cx="12" cy="12" r="3" />
                      </svg>
                    </button>
                  </div>
                )}
                <div className="border border-[#e5e7eb] rounded-xl p-4 bg-[#f9fafb] space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-[#757575] flex items-center gap-1.5">
                      <Calculator size={14} />
                      Débit estimé
                    </span>
                    <span className="font-semibold text-[#111111]">
                      {debit.toFixed(1)} kg/h
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-[#757575]">Coût annuel estimé</span>
                    <span className="font-semibold text-[#00875a]">
                      {Math.round(coutAnnuel).toLocaleString('fr-FR')} {parametres?.devise ?? 'MAD'}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* ── Bouton Prédire le diamètre avec IA ──
                Masqué tant que le prix kWh n'est pas configuré (0,00 MAD). */}
            {(parametres?.coutKwhDiram ?? 0) > 0 && (
              <button
                type="button"
                onClick={predireDiametre}
                disabled={iaLoading}
                className="w-full h-12 inline-flex items-center justify-center gap-2 rounded-xl bg-[#7B1FA2] text-white text-[15px] font-bold hover:bg-[#6a1b9a] transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {iaLoading ? (
                  <Loader2 size={20} className="animate-spin" />
                ) : (
                  <Ruler size={20} />
                )}
                {iaLoading
                  ? 'Analyse IA en cours…'
                  : iaEffectuee
                  ? '🔄 Ré-prédire le diamètre'
                  : '📏 Prédire le diamètre'}
              </button>
            )}

            {/* ── Carte de résultat IA ──
                Masquée si les photos ont changé depuis l'analyse persistée. */}
            {iaReponse && !photosModifiees && (
              <div>
                <CartePredictionIA reponse={iaReponse} />
              </div>
            )}

            {/* GPS */}
            <div>
              <label className={labelCls}>GPS</label>
              <div className="flex items-center gap-3 border border-[#e5e7eb] rounded-xl p-4">
                <button
                  type="button"
                  onClick={capturerGps}
                  disabled={gpsLoading}
                  className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#00875a] text-white text-sm font-medium hover:bg-[#007049] transition-colors disabled:opacity-60"
                >
                  {gpsLoading ? (
                    <Loader2 size={16} className="animate-spin" />
                  ) : (
                    <MapPin size={16} />
                  )}
                  {gpsLatitude !== null ? 'Recapturer' : 'Capturer ma position'}
                </button>
                {gpsLatitude !== null && gpsLongitude !== null && (
                  <>
                    <div className="text-sm text-[#757575]">
                      {gpsLatitude.toFixed(6)}, {gpsLongitude.toFixed(6)}
                    </div>
                    <a
                      href={`https://www.google.com/maps?q=${gpsLatitude},${gpsLongitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-[#00875a] text-[#00875a] text-sm font-medium hover:bg-[#00875a]/5 transition-colors"
                      title="Ouvrir dans Google Maps"
                    >
                      <Map size={16} />
                    </a>
                  </>
                )}
              </div>
            </div>

            {/* Zone */}
            <div>
              <label className={labelCls}>Localisation (zone)</label>
              <input
                className={inputCls}
                value={zone}
                onChange={(e) => setZone(e.target.value)}
                placeholder="Ex: Échangeur T1, niveau +15m"
              />
            </div>

            {/* Description */}
            <div>
              <label className={labelCls}>Description (optionnelle)</label>
              <textarea
                className={`${inputCls} min-h-[80px]`}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Ex: Fuite sur joint de bride, côté chaudière"
              />
            </div>

            {/* ── Bouton Générer description avec IA ── */}
            <button
              type="button"
              onClick={genererDescriptionIA}
              disabled={iaLoading}
              className="w-full h-[42px] inline-flex items-center justify-center gap-2 rounded-xl border-2 bg-transparent text-sm font-semibold transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
              style={{
                color: '#7B1FA2',
                borderColor: iaReponse ? '#7B1FA2' : '#d1d5db',
              }}
            >
              <Sparkles size={18} />
              ✨ Générer avec IA
            </button>

            {/* Photos existantes */}
            <div>
              <label className={labelCls}>Photos existantes</label>
              {photos.length === 0 ? (
                <p className="text-sm text-[#9ca3af]">Aucune photo.</p>
              ) : (
                <div className="flex flex-wrap gap-3">
                  {photos.map((photo) => (
                    <div
                      key={photo.id}
                      className="relative w-24 h-24 rounded-xl overflow-hidden border border-[#e5e7eb]"
                    >
                      <button
                        type="button"
                        onClick={() =>
                          openMedia(
                            fileUrl(photo.cheminFichier),
                            isVideoPath(photo.cheminFichier) ? 'video' : 'image',
                          )
                        }
                        className="w-full h-full cursor-pointer hover:opacity-90 transition-opacity"
                        title="Agrandir"
                      >
                        <img
                          src={fileUrl(photo.thumbnailUrl ?? photo.cheminFichier)}
                          alt={photo.cheminFichier ?? 'Photo fuite'}
                          className="w-full h-full object-cover"
                        />
                        {isVideoPath(photo.cheminFichier) && (
                          <span className="absolute inset-0 flex items-center justify-center bg-black/30">
                            <Play size={20} className="text-white" fill="white" />
                          </span>
                        )}
                      </button>
                      <button
                        type="button"
                        onClick={() => markPhotoDeleted(photo.id)}
                        className="absolute top-1 right-1 bg-black/60 text-white rounded-full w-5 h-5 text-xs leading-none hover:bg-red-600"
                        title="Supprimer la photo"
                      >
                        <X size={12} className="m-auto" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Nouvelles photos */}
            <div>
              <label className={labelCls}>Ajouter des photos</label>
              <div className="flex flex-wrap gap-3">
                {newPreviews.map((preview, i) => (
                  <div
                    key={i}
                    className="relative w-24 h-24 rounded-xl overflow-hidden border border-[#e5e7eb]"
                  >
                    <button
                      type="button"
                      onClick={() => openMedia(preview, 'image')}
                      className="w-full h-full cursor-pointer hover:opacity-90 transition-opacity"
                      title="Agrandir"
                    >
                      <img src={preview} alt={`Nouvelle photo ${i + 1}`} className="w-full h-full object-cover" />
                    </button>
                    <button
                      type="button"
                      onClick={() => removeNewPhoto(i)}
                      className="absolute top-1 right-1 bg-black/60 text-white rounded-full w-5 h-5 text-xs leading-none"
                    >
                      ×
                    </button>
                  </div>
                ))}
                <label className="w-24 h-24 rounded-xl border-2 border-dashed border-[#d1d5db] flex flex-col items-center justify-center gap-1 cursor-pointer hover:border-[#00875a] hover:text-[#00875a] transition-colors text-[#9ca3af]">
                  <Camera size={20} />
                  <span className="text-[10px]">Ajouter</span>
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    className="hidden"
                    onChange={(e) => handleNewPhotos(e.target.files)}
                  />
                </label>
              </div>
            </div>
          </div>
        ) : (
          /* ─────────── MODE AFFICHAGE ─────────── */
          <div className="bg-white border border-[#e5e7eb] rounded-2xl overflow-hidden">
            {/* Statut */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-[#e5e7eb]">
              <span className="text-sm text-[#757575]">Statut</span>
              <Badge color={statutColor(fuite.statut)}>
                {fuite.statut ? (STATUTS[fuite.statut] ?? fuite.statut) : '—'}
              </Badge>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 divide-y sm:divide-y-0 divide-[#e5e7eb]/70">
              <DetailRow label="Tag" value={fuite.numeroTag ?? '—'} />
              <DetailRow
                label="Date de détection"
                value={
                  fuite.dateDetection
                    ? new Date(fuite.dateDetection).toLocaleString('fr-FR')
                    : '—'
                }
              />
              <DetailRow label="Campagne" value={fuite.campagneNom ?? '—'} />
              <DetailRow
                label="Type de vapeur"
                value={
                  fuite.typeVapeur
                    ? (TYPES_VAPEUR[fuite.typeVapeur] ?? fuite.typeVapeur)
                    : '—'
                }
              />
              <DetailRow
                label="Pression"
                value={fuite.pressionBar != null ? `${fuite.pressionBar} bar` : '—'}
              />
              <DetailRow
                label="Diamètre orifice"
                value={fuite.diametreOrifice != null ? `${fuite.diametreOrifice} mm` : '—'}
              />
              <DetailRow label="Zone" value={fuite.zone ?? '—'} />
              <DetailRow
                label="Coût annuel estimé"
                value={
                  fuite.coutAnnuelEstime != null
                    ? `${fuite.coutAnnuelEstime.toLocaleString('fr-FR')} DH`
                    : '—'
                }
                valueClass="text-[#00875a] font-semibold"
              />
              <DetailRow
                label="GPS"
                value={
                  fuite.gpsLatitude != null && fuite.gpsLongitude != null
                    ? `${fuite.gpsLatitude.toFixed(6)}, ${fuite.gpsLongitude.toFixed(6)}`
                    : '—'
                }
                className="sm:col-span-2"
              />
              {fuite.description && (
                <DetailRow
                  label="Description"
                  value={fuite.description}
                  className="sm:col-span-2"
                />
              )}
            </div>

            {/* Photos */}
            <div className="px-6 py-4 border-t border-[#e5e7eb]">
              <p className="text-sm font-medium text-[#757575] mb-3">
                Photos ({photos.length})
              </p>
              {photos.length === 0 ? (
                <p className="text-sm text-[#9ca3af]">
                  <Camera size={14} className="inline mr-1.5 -mt-0.5" />
                  Aucune photo pour cette fuite
                </p>
              ) : (
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-3">
                  {photos.map((photo) => (
                    <button
                      key={photo.id}
                      type="button"
                      onClick={() =>
                        openMedia(
                          fileUrl(photo.cheminFichier),
                          isVideoPath(photo.cheminFichier) ? 'video' : 'image',
                        )
                      }
                      className="relative block aspect-square rounded-xl overflow-hidden border border-[#e5e7eb] hover:opacity-90 transition-opacity cursor-pointer"
                      title={photo.cheminFichier}
                    >
                      <img
                        src={fileUrl(photo.thumbnailUrl ?? photo.cheminFichier)}
                        alt={photo.cheminFichier ?? 'Photo fuite'}
                        className="w-full h-full object-cover"
                      />
                      {isVideoPath(photo.cheminFichier) && (
                        <span className="absolute inset-0 flex items-center justify-center bg-black/30">
                          <Play size={24} className="text-white" fill="white" />
                        </span>
                      )}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Estimation persistée */}
            {fuite.coutAnnuelEstime != null && (
              <div className="px-6 py-4 border-t border-[#e5e7eb] bg-[#f9fafb] flex items-center gap-3">
                <CheckCircle2 size={18} className="text-[#00875a]" />
                <p className="text-sm text-[#757575]">
                  Coût annuel estimé et enregistré à la détection :
                  <span className="font-semibold text-[#00875a] ml-1.5">
                    {fuite.coutAnnuelEstime.toLocaleString('fr-FR')} DH
                  </span>
                </p>
              </div>
            )}
          </div>
        )}

        {/* Modale de configuration — s'ouvre par-dessus le formulaire sans le perdre */}
        {configOpen && (
          <ConfigModal
            onClose={() => setConfigOpen(false)}
            onSaved={() => void chargerParametres()}
          />
        )}
      </div>
    </Layout>
  )
}

function DetailRow({
  label,
  value,
  className = '',
  valueClass = '',
}: {
  label: string
  value: string
  className?: string
  valueClass?: string
}) {
  return (
    <div className={`px-6 py-4 ${className}`}>
      <p className="text-xs uppercase tracking-wide text-[#9ca3af] mb-1">{label}</p>
      <p className={`text-sm text-[#111111] ${valueClass}`}>{value}</p>
    </div>
  )
}
