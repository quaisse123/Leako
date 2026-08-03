import { useEffect, useState } from 'react'
import { Save, Settings } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import { getParametres, updateParametres } from '../api/parametreApi'
import type { ParametreGlobalRequestDto } from '../types'

/**
 * Configuration — paramètres globaux (Phase 8).
 * Correspond au backend GET/PUT /api/parametres (objet unique).
 */
export default function ConfigPage() {
  const [form, setForm] = useState<ParametreGlobalRequestDto>({})
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState<{ type: 'ok' | 'err'; text: string } | null>(null)

  useEffect(() => {
    const load = async () => {
      try {
        const data = await getParametres()
        setForm({
          devise: data.devise,
          coutVapeurParTonne: data.coutVapeurParTonne,
          heuresFonctionnementAnnuelles: data.heuresFonctionnementAnnuelles,
          facteurEmissionCO2: data.facteurEmissionCO2,
          langue: data.langue,
          heuresActiviteParJour: data.heuresActiviteParJour,
          joursActiviteParAn: data.joursActiviteParAn,
          coutKwhDiram: data.coutKwhDiram,
        })
      } catch (err) {
        console.error('Erreur chargement paramètres:', err)
        setMessage({ type: 'err', text: 'Impossible de charger les paramètres.' })
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [])

  const set = (key: keyof ParametreGlobalRequestDto, value: unknown) =>
    setForm((f) => ({ ...f, [key]: value }))

  const handleSave = async () => {
    setSaving(true)
    setMessage(null)
    try {
      await updateParametres(form)
      setMessage({ type: 'ok', text: 'Paramètres enregistrés avec succès.' })
    } catch (err) {
      console.error('Erreur enregistrement:', err)
      setMessage({ type: 'err', text: "Erreur lors de l'enregistrement." })
    } finally {
      setSaving(false)
    }
  }

  const field = (
    label: string,
    key: keyof ParametreGlobalRequestDto,
    type: 'text' | 'number' = 'text',
  ) => (
    <label className="flex flex-col gap-1.5">
      <span className="text-sm font-medium text-[#757575]">{label}</span>
      <input
        type={type}
        value={form[key] ?? ''}
        onChange={(e) =>
          set(key, type === 'number' ? (e.target.value === '' ? undefined : Number(e.target.value)) : e.target.value)
        }
        className="px-3 py-2 border border-[#e5e7eb] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a] bg-white"
      />
    </label>
  )

  return (
    <Layout>
      <div className="p-6 max-w-3xl mx-auto">
        <PageHeader
          title="Configuration"
          subtitle="Paramètres globaux de l'application"
        />

        {loading ? (
          <LoadingSpinner />
        ) : (
          <div className="bg-white border border-[#e5e7eb] rounded-2xl p-6 space-y-5">
            <div className="flex items-center gap-2 text-[#00875a]">
              <Settings size={18} />
              <h2 className="font-semibold text-[#1f2937]">Paramètres de calcul</h2>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {field('Devise', 'devise')}
              {field('Langue', 'langue')}
              {field('Coût vapeur par tonne (DH)', 'coutVapeurParTonne', 'number')}
              {field('Heures de fonctionnement annuelles', 'heuresFonctionnementAnnuelles', 'number')}
              {field("Heures d'activité par jour", 'heuresActiviteParJour', 'number')}
              {field("Jours d'activité par an", 'joursActiviteParAn', 'number')}
              {field('Facteur émission CO₂', 'facteurEmissionCO2', 'number')}
              {field('Coût kWh (DH)', 'coutKwhDiram', 'number')}
            </div>

            {message && (
              <p className={`text-sm ${message.type === 'ok' ? 'text-[#00875a]' : 'text-red-600'}`}>
                {message.text}
              </p>
            )}

            <button
              onClick={handleSave}
              disabled={saving}
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-medium hover:bg-[#007049] transition-colors disabled:opacity-60"
            >
              <Save size={16} />
              {saving ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </div>
        )}
      </div>
    </Layout>
  )
}

