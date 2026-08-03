import { useEffect, useState } from 'react'
import { Save, Settings, Globe, Clock, CalendarDays, Zap, X } from 'lucide-react'
import { getParametres, updateParametres } from '../api/parametreApi'
import type { ParametreGlobalRequestDto } from '../types'

interface ConfigModalProps {
  onClose: () => void
  /** Appelé après une sauvegarde réussie pour recharger les paramètres dans la page parente. */
  onSaved?: () => void
}

/**
 * Modale de configuration — s'ouvre par-dessus un formulaire (création/édition de fuite)
 * sans le perdre, comme `Navigator.push` sur mobile.
 */
export default function ConfigModal({ onClose, onSaved }: ConfigModalProps) {
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
      setMessage({ type: 'ok', text: 'Configuration sauvegardée ✓' })
      onSaved?.()
    } catch (err) {
      console.error('Erreur enregistrement:', err)
      setMessage({ type: 'err', text: "Erreur lors de l'enregistrement." })
    } finally {
      setSaving(false)
    }
  }

  const sectionHeader = (icon: React.ReactNode, title: string) => (
    <div className="flex items-center gap-2.5">
      <span className="w-1 h-5 rounded bg-[#00875a]" />
      <span className="text-lg font-bold text-[#111111]">{title}</span>
      {icon}
    </div>
  )

  const field = (
    label: string,
    key: keyof ParametreGlobalRequestDto,
    type: 'text' | 'number' = 'text',
    icon?: React.ReactNode,
    suffix?: string,
  ) => (
    <label className="flex flex-col gap-1.5">
      <span className="text-sm font-bold text-[#111111]">{label}</span>
      <div className="relative">
        {icon && (
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[#00875a]">
            {icon}
          </span>
        )}
        <input
          type={type}
          value={form[key] ?? ''}
          onChange={(e) =>
            set(key, type === 'number' ? (e.target.value === '' ? undefined : Number(e.target.value)) : e.target.value)
          }
          className={`w-full px-3 py-2.5 border border-[#e5e7eb] rounded-xl text-sm bg-[#fafafa] focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a] focus:bg-white ${
            icon ? 'pl-10' : ''
          }`}
        />
        {suffix && (
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-[#6b7280]">
            {suffix}
          </span>
        )}
      </div>
    </label>
  )

  return (
    <div className="fixed inset-0 z-50 bg-black/40 flex items-end sm:items-center justify-center">
      <div className="w-full max-w-2xl bg-white rounded-t-3xl sm:rounded-3xl max-h-[90vh] overflow-y-auto">
        {/* En-tête */}
        <div className="sticky top-0 bg-white border-b border-[#e5e7eb] px-6 py-4 flex items-center justify-between rounded-t-3xl">
          <div>
            <h2 className="text-lg font-bold text-[#111111]">Configuration OCP</h2>
            <p className="text-sm text-[#757575]">Paramètres de calcul du coût des fuites</p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-full hover:bg-[#f3f4f6] transition-colors text-[#6b7280]"
            title="Fermer"
          >
            <X size={20} />
          </button>
        </div>

        <div className="p-6 space-y-8">
          {loading ? (
            <div className="flex justify-center py-10">
              <div className="w-8 h-8 border-4 border-[#00875a]/20 border-t-[#00875a] rounded-full animate-spin" />
            </div>
          ) : (
            <>
              {/* ── Section : Général ── */}
              <div className="space-y-4">
                {sectionHeader(<Globe size={16} className="text-[#00875a]" />, 'Général')}

                <label className="flex flex-col gap-1.5">
                  <span className="text-sm font-bold text-[#111111]">Langue de l'application</span>
                  <div className="relative">
                    <Globe size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#00875a]" />
                    <select
                      value={form.langue ?? 'fr'}
                      onChange={(e) => set('langue', e.target.value)}
                      className="w-full px-3 py-2.5 pl-10 border border-[#e5e7eb] rounded-xl text-sm bg-[#fafafa] focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a] focus:bg-white"
                    >
                      <option value="fr">Français</option>
                      <option value="en">English</option>
                      <option value="ar">العربية</option>
                    </select>
                  </div>
                </label>

                {field('Heures d\'activité par jour', 'heuresActiviteParJour', 'number', <Clock size={16} />)}
                {field('Jours d\'activité par an', 'joursActiviteParAn', 'number', <CalendarDays size={16} />)}
              </div>

              {/* ── Section : Coût de fuite ── */}
              <div className="space-y-4">
                {sectionHeader(<Settings size={16} className="text-[#00875a]" />, 'Coût de fuite')}

                {field('Coût par kWh (en Diram)', 'coutKwhDiram', 'number', <Zap size={16} />, 'MAD/kWh')}
                {field('Coût vapeur par tonne (DH)', 'coutVapeurParTonne', 'number', undefined, 'DH/tonne')}
                {field('Heures de fonctionnement annuelles', 'heuresFonctionnementAnnuelles', 'number', undefined, 'h/an')}
                {field('Facteur émission CO₂', 'facteurEmissionCO2', 'number')}
                {field('Devise', 'devise')}
              </div>

              {message && (
                <p className={`text-sm ${message.type === 'ok' ? 'text-[#00875a]' : 'text-red-600'}`}>
                  {message.text}
                </p>
              )}

              <button
                onClick={handleSave}
                disabled={saving}
                className="w-full inline-flex items-center justify-center gap-2 px-5 py-3.5 rounded-xl bg-[#00875a] text-white text-sm font-bold hover:bg-[#007049] transition-colors disabled:opacity-60"
              >
                <Save size={16} />
                {saving ? 'Enregistrement…' : 'Sauvegarder'}
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
