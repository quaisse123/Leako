import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft,
  Calculator,
  Camera,
  Loader2,
  MapPin,
  Save,
  Tag,
} from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import { useProjetActif } from '../context/ProjetActifContext'
import { getCampagnes } from '../api/campagneApi'
import { createFuite, getProchainTag } from '../api/fuiteApi'
import { uploadPhoto } from '../api/photoApi'
import type { CampagneResponseDto, StatutFuite, TypeVapeur } from '../types'

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

export default function NouvelleFuitePage() {
  const navigate = useNavigate()
  const { projetActif } = useProjetActif()

  const [campagnes, setCampagnes] = useState<CampagneResponseDto[]>([])
  const [campagnesLoading, setCampagnesLoading] = useState(true)

  const [campagneId, setCampagneId] = useState<number | ''>('')
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

  const [photos, setPhotos] = useState<File[]>([])
  const [photoPreviews, setPhotoPreviews] = useState<string[]>([])

  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [tagLoading, setTagLoading] = useState(false)

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
        0.85, // coût kWh par défaut, remplacé par les paramètres globaux
        24,
        365,
      ),
    [debit, pression],
  )

  useEffect(() => {
    if (!projetActif) return
    const now = new Date()
    const pad = (n: number) => String(n).padStart(2, '0')
    setDateDetection(
      `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}:${pad(now.getMinutes())}`,
    )

    let cancelled = false
    const load = async () => {
      try {
        const data = await getCampagnes(projetActif.id)
        if (cancelled) return
        setCampagnes(data)
        if (data.length > 0) {
          setCampagneId(data[0].id)
          void genererTag(data[0].nom, data[0].id)
        }
      } catch (err) {
        console.error('Erreur chargement campagnes:', err)
      } finally {
        if (!cancelled) setCampagnesLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [projetActif?.id])

  const genererTag = async (nom: string, id: number) => {
    setTagLoading(true)
    try {
      const tag = await getProchainTag(nom, id)
      setNumeroTag(tag)
    } catch (err) {
      console.error('Erreur génération tag:', err)
    } finally {
      setTagLoading(false)
    }
  }

  const handleCampagneChange = (id: number) => {
    setCampagneId(id)
    const campagne = campagnes.find((c) => c.id === id)
    if (campagne) void genererTag(campagne.nom, campagne.id)
  }

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
      (err) => {
        console.error('Erreur GPS:', err)
        setError('Impossible de récupérer la position GPS.')
        setGpsLoading(false)
      },
      { enableHighAccuracy: true, timeout: 10000 },
    )
  }

  const handlePhotos = (files: FileList | null) => {
    if (!files) return
    const arr = Array.from(files).slice(0, 6)
    setPhotos((prev) => [...prev, ...arr])
    const previews = arr.map((f) => URL.createObjectURL(f))
    setPhotoPreviews((prev) => [...prev, ...previews])
  }

  const removePhoto = (index: number) => {
    setPhotos((prev) => prev.filter((_, i) => i !== index))
    setPhotoPreviews((prev) => prev.filter((_, i) => i !== index))
  }

  const handleSubmit = async () => {
    if (!projetActif) {
      setError('Aucun projet actif sélectionné.')
      return
    }
    if (campagneId === '') {
      setError('Veuillez sélectionner une campagne.')
      return
    }
    if (!pressionBar || Number(pressionBar) <= 0) {
      setError('La pression est requise et doit être positive.')
      return
    }
    setSaving(true)
    setError('')
    try {
      const fuite = await createFuite({
        numeroTag: (numeroTag ?? '').trim() || undefined,
        dateDetection: dateDetection,
        statut,
        pressionBar: pression,
        diametreOrifice,
        typeVapeur: typeVapeur || undefined,
        gpsLatitude: gpsLatitude ?? undefined,
        gpsLongitude: gpsLongitude ?? undefined,
        zone: (zone ?? '').trim() || undefined,
        description: (description ?? '').trim() || undefined,
        coutAnnuelEstime: Math.round(coutAnnuel * 100) / 100,
        campagneId: Number(campagneId),
      })

      // Upload des photos
      for (const file of photos) {
        await uploadPhoto(fuite.id, file)
      }

      navigate('/fuites')
    } catch (err) {
      console.error('Erreur création fuite:', err)
      setError('Erreur lors de la création de la fuite.')
    } finally {
      setSaving(false)
    }
  }

  const inputCls =
    'w-full px-3 py-2 border border-[#e5e7eb] rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]'
  const labelCls = 'block text-sm font-medium text-[#757575] mb-1.5'

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
          title="Nouvelle fuite"
          subtitle="Signaler une fuite — Projet OCP Vapeur"
        />

        {campagnesLoading ? (
          <LoadingSpinner />
        ) : (
          <div className="bg-white border border-[#e5e7eb] rounded-2xl p-6 space-y-6">
            {/* Campagne */}
            <div>
              <label className={labelCls}>Campagne *</label>
              <select
                className={inputCls}
                value={campagneId}
                onChange={(e) => handleCampagneChange(Number(e.target.value))}
              >
                {campagnes.length === 0 && <option value="">Aucune campagne</option>}
                {campagnes.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.nom}
                  </option>
                ))}
              </select>
            </div>

            {/* Tag */}
            <div>
              <label className={labelCls}>Numéro de tag</label>
              <div className="relative">
                <Tag size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9ca3af]" />
                <input
                  className={`${inputCls} pl-9 ${tagLoading ? 'opacity-60' : ''}`}
                  value={numeroTag}
                  onChange={(e) => setNumeroTag(e.target.value)}
                  placeholder="Généré automatiquement"
                  readOnly
                />
              </div>
              {tagLoading && (
                <p className="text-xs text-[#9ca3af] mt-1 flex items-center gap-1">
                  <Loader2 size={12} className="animate-spin" />
                  Génération du tag…
                </p>
              )}
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
                    max={30}
                    step={0.5}
                    value={diametreOrifice}
                    onChange={(e) => setDiametreOrifice(Number(e.target.value))}
                    className="flex-1 accent-[#00875a]"
                  />
                  <span className="text-sm text-[#757575]">30 mm</span>
                </div>
                <p className="text-lg font-bold text-[#00875a] mt-2 text-center">
                  {diametreOrifice.toFixed(1)} mm
                </p>
              </div>
              <div>
                <label className={labelCls}>Estimation</label>
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
                      {Math.round(coutAnnuel).toLocaleString('fr-FR')} DH
                    </span>
                  </div>
                </div>
              </div>
            </div>

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
                  <div className="text-sm text-[#757575]">
                    {gpsLatitude.toFixed(6)}, {gpsLongitude.toFixed(6)}
                  </div>
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

            {/* Photos */}
            <div>
              <label className={labelCls}>Photos</label>
              <div className="flex flex-wrap gap-3">
                {photoPreviews.map((preview, i) => (
                  <div key={i} className="relative w-24 h-24 rounded-xl overflow-hidden border border-[#e5e7eb]">
                    <img src={preview} alt={`Photo ${i + 1}`} className="w-full h-full object-cover" />
                    <button
                      type="button"
                      onClick={() => removePhoto(i)}
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
                    onChange={(e) => handlePhotos(e.target.files)}
                  />
                </label>
              </div>
            </div>

            {error && (
              <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-xl px-4 py-2.5">
                {error}
              </p>
            )}

            <div className="flex items-center justify-end gap-3 pt-2 border-t border-[#e5e7eb]">
              <button
                onClick={() => navigate('/fuites')}
                className="px-5 py-2.5 rounded-xl border border-[#e5e7eb] text-sm font-medium text-[#757575] hover:bg-[#f9fafb] transition-colors"
              >
                Annuler
              </button>
              <button
                onClick={handleSubmit}
                disabled={saving}
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-medium hover:bg-[#007049] transition-colors disabled:opacity-60"
              >
                {saving ? <Loader2 size={16} className="animate-spin" /> : <Save size={16} />}
                {saving ? 'Création…' : 'Créer la fuite'}
              </button>
            </div>
          </div>
        )}
      </div>
    </Layout>
  )
}
