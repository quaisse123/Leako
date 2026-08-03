import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft, CalendarDays, Loader2, Save } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import { useProjetActif } from '../context/ProjetActifContext'
import { createCampagne } from '../api/campagneApi'
import { getUser } from '../api/jwtService'

/**
 * Création d'une campagne d'inspection.
 * Reproduit fidèlement creer_campagne_page.dart (nom obligatoire, description optionnelle).
 */
export default function NouvelleCampagnePage() {
  const navigate = useNavigate()
  const { projetActif } = useProjetActif()

  const [nom, setNom] = useState('')
  const [description, setDescription] = useState('')
  const [zone, setZone] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const inputCls =
    'w-full px-3 py-2 border border-[#e5e7eb] rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a]'
  const labelCls = 'block text-sm font-medium text-[#757575] mb-1.5'

  const handleSubmit = async () => {
    if (!nom.trim()) {
      setError('Le nom de la campagne est obligatoire.')
      return
    }
    if (!projetActif) {
      setError('Aucun projet actif sélectionné.')
      return
    }
    const user = getUser()
    if (!user?.id) {
      setError('Utilisateur non identifié.')
      return
    }
    setSaving(true)
    setError('')
    try {
      await createCampagne({
        nom: nom.trim(),
        description: description.trim() || undefined,
        zone: zone.trim() || undefined,
        createurId: user.id,
        projetId: projetActif.id,
      })
      navigate('/campagnes')
    } catch (err) {
      console.error('Erreur création campagne:', err)
      setError('Erreur lors de la création de la campagne.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Layout>
      <div className="p-6 max-w-3xl mx-auto">
        <button
          onClick={() => navigate('/campagnes')}
          className="inline-flex items-center gap-1.5 text-sm text-[#757575] hover:text-[#00875a] mb-4 transition-colors"
        >
          <ArrowLeft size={16} />
          Retour aux campagnes
        </button>

        <PageHeader
          title="Nouvelle campagne"
          subtitle="Lancer une inspection — Projet OCP Vapeur"
        />

        <div className="bg-white border border-[#e5e7eb] rounded-2xl p-6 space-y-6">
          {/* En-tête illustré */}
          <div className="flex flex-col items-center text-center py-2">
            <div className="w-16 h-16 rounded-full bg-[#00875a]/10 flex items-center justify-center">
              <CalendarDays size={32} className="text-[#00875a]" />
            </div>
            <h2 className="text-xl font-extrabold text-[#111111] mt-4">
              Lancer une inspection
            </h2>
            <p className="text-sm text-[#757575] mt-1">
              Renseigne les informations de la campagne
            </p>
          </div>

          {/* Nom */}
          <div>
            <label className={labelCls}>Nom de la campagne *</label>
            <input
              className={inputCls}
              value={nom}
              onChange={(e) => setNom(e.target.value)}
              placeholder="Ex: Inspection Jorf Lasfar T1"
              maxLength={100}
            />
          </div>

          {/* Zone */}
          <div>
            <label className={labelCls}>Zone (optionnelle)</label>
            <input
              className={inputCls}
              value={zone}
              onChange={(e) => setZone(e.target.value)}
              placeholder="Ex: Jorf Lasfar - Ligne 3"
            />
          </div>

          {/* Description */}
          <div>
            <label className={labelCls}>Description (optionnelle)</label>
            <textarea
              className={`${inputCls} min-h-[110px] resize-y`}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Objectifs, périmètre, notes…"
            />
          </div>

          {error && (
            <p className="text-sm text-[#D32F2F] bg-[#D32F2F]/5 border border-[#D32F2F]/20 rounded-xl px-4 py-3">
              {error}
            </p>
          )}

          {/* Bouton Créer */}
          <button
            onClick={() => void handleSubmit()}
            disabled={saving}
            className="w-full inline-flex items-center justify-center gap-2 px-4 py-3 rounded-xl bg-[#00875a] text-white text-sm font-bold hover:bg-[#007049] transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {saving ? (
              <Loader2 size={18} className="animate-spin" />
            ) : (
              <Save size={18} />
            )}
            {saving ? 'Création…' : 'Créer la campagne'}
          </button>
        </div>
      </div>
    </Layout>
  )
}
