import { useEffect, useState } from 'react'
import { User, Mail, Lock, Save, KeyRound, UserRound } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import { getUser, setUser } from '../api/jwtService'
import { updateProfil, changerMotDePasse } from '../api/userApi'
import type { StoredUser } from '../api/jwtService'

/**
 * Page Profil — modification du nom, prénom, email et mot de passe.
 * Accessible via le bloc utilisateur de la sidebar.
 */
export default function ProfilePage() {
  const [currentUser, setCurrentUser] = useState<StoredUser | null>(null)

  // Formulaire informations personnelles
  const [nom, setNom] = useState('')
  const [prenom, setPrenom] = useState('')
  const [email, setEmail] = useState('')
  const [savingInfo, setSavingInfo] = useState(false)
  const [infoMessage, setInfoMessage] = useState<{ type: 'ok' | 'err'; text: string } | null>(null)

  // Formulaire mot de passe
  const [motDePasseActuel, setMotDePasseActuel] = useState('')
  const [nouveauMotDePasse, setNouveauMotDePasse] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [savingPassword, setSavingPassword] = useState(false)
  const [pwdMessage, setPwdMessage] = useState<{ type: 'ok' | 'err'; text: string } | null>(null)

  useEffect(() => {
    const user = getUser()
    setCurrentUser(user)
    setNom(user?.nom ?? '')
    setPrenom(user?.prenom ?? '')
    setEmail(user?.email ?? '')
  }, [])

  const initials = currentUser
    ? `${currentUser.prenom ?? ''} ${currentUser.nom ?? ''}`
        .split(' ')
        .map((p) => p[0])
        .filter(Boolean)
        .slice(0, 2)
        .join('')
        .toUpperCase()
    : 'U'

  const handleSaveInfo = async () => {
    setSavingInfo(true)
    setInfoMessage(null)
    try {
      const updated = await updateProfil({ nom, prenom, email })
      // Met à jour le localStorage pour refléter les nouvelles infos dans la sidebar
      const previous = getUser()
      setUser({
        id: Number(updated.id ?? previous?.id ?? 0),
        nom: updated.nom,
        prenom: updated.prenom ?? '',
        email: updated.email,
        role: previous?.role,
      })
      setCurrentUser(getUser())
      setInfoMessage({ type: 'ok', text: 'Informations mises à jour ✓' })
    } catch (err) {
      console.error('Erreur mise à jour profil:', err)
      setInfoMessage({
        type: 'err',
        text: err instanceof Error ? err.message : 'Erreur lors de la mise à jour.',
      })
    } finally {
      setSavingInfo(false)
    }
  }

  const handleSavePassword = async () => {
    setPwdMessage(null)
    if (nouveauMotDePasse !== confirmation) {
      setPwdMessage({ type: 'err', text: 'La confirmation ne correspond pas au nouveau mot de passe.' })
      return
    }
    setSavingPassword(true)
    try {
      await changerMotDePasse({ motDePasseActuel, nouveauMotDePasse })
      setPwdMessage({ type: 'ok', text: 'Mot de passe modifié avec succès ✓' })
      setMotDePasseActuel('')
      setNouveauMotDePasse('')
      setConfirmation('')
    } catch (err) {
      console.error('Erreur changement mot de passe:', err)
      setPwdMessage({
        type: 'err',
        text: err instanceof Error ? err.message : 'Erreur lors du changement de mot de passe.',
      })
    } finally {
      setSavingPassword(false)
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
    value: string,
    onChange: (v: string) => void,
    type: 'text' | 'email' | 'password' = 'text',
    icon?: React.ReactNode,
    placeholder?: string,
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
          value={value}
          placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)}
          className={`w-full px-3 py-2.5 border border-[#e5e7eb] rounded-xl text-sm bg-[#fafafa] focus:outline-none focus:ring-2 focus:ring-[#00875a]/30 focus:border-[#00875a] focus:bg-white ${
            icon ? 'pl-10' : ''
          }`}
        />
      </div>
    </label>
  )

  return (
    <Layout>
      <div className="p-6 max-w-3xl mx-auto">
        <PageHeader
          title="Mon profil"
          subtitle="Modifiez vos informations personnelles ou votre mot de passe"
        />

        {/* ── Carte identité ── */}
        <div className="flex items-center gap-4 bg-white border border-[#e5e7eb] rounded-2xl p-6 mb-6">
          <div className="w-16 h-16 rounded-full bg-[#00875a]/10 text-[#00875a] flex items-center justify-center font-bold text-2xl flex-shrink-0">
            {initials}
          </div>
          <div className="min-w-0">
            <div className="text-lg font-bold text-[#111111] truncate">
              {`${currentUser?.prenom ?? ''} ${currentUser?.nom ?? ''}`.trim() || 'Utilisateur'}
            </div>
            <div className="text-sm text-[#757575] truncate">{currentUser?.email}</div>
          </div>
        </div>

        {!currentUser ? (
          <LoadingSpinner />
        ) : (
          <div className="space-y-6">
            {/* ── Section : Informations personnelles ── */}
            <div className="bg-white border border-[#e5e7eb] rounded-2xl p-6 space-y-4">
              {sectionHeader(<User size={16} className="text-[#00875a]" />, 'Informations personnelles')}

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {field('Nom', nom, setNom, 'text', <UserRound size={16} />)}
                {field('Prénom', prenom, setPrenom, 'text', <UserRound size={16} />)}
              </div>
              {field('Email', email, setEmail, 'email', <Mail size={16} />)}

              {infoMessage && (
                <p className={`text-sm ${infoMessage.type === 'ok' ? 'text-[#00875a]' : 'text-red-600'}`}>
                  {infoMessage.text}
                </p>
              )}

              <button
                onClick={handleSaveInfo}
                disabled={savingInfo}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-bold hover:bg-[#007049] transition-colors disabled:opacity-60"
              >
                <Save size={16} />
                {savingInfo ? 'Enregistrement…' : 'Enregistrer'}
              </button>
            </div>

            {/* ── Section : Mot de passe ── */}
            <div className="bg-white border border-[#e5e7eb] rounded-2xl p-6 space-y-4">
              {sectionHeader(<KeyRound size={16} className="text-[#00875a]" />, 'Changer le mot de passe')}

              {field('Mot de passe actuel', motDePasseActuel, setMotDePasseActuel, 'password', <Lock size={16} />)}
              {field('Nouveau mot de passe', nouveauMotDePasse, setNouveauMotDePasse, 'password', <Lock size={16} />, 'Au moins 6 caractères')}
              {field('Confirmer le nouveau mot de passe', confirmation, setConfirmation, 'password', <Lock size={16} />)}

              {pwdMessage && (
                <p className={`text-sm ${pwdMessage.type === 'ok' ? 'text-[#00875a]' : 'text-red-600'}`}>
                  {pwdMessage.text}
                </p>
              )}

              <button
                onClick={handleSavePassword}
                disabled={savingPassword}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-bold hover:bg-[#007049] transition-colors disabled:opacity-60"
              >
                <KeyRound size={16} />
                {savingPassword ? 'Modification…' : 'Changer le mot de passe'}
              </button>
            </div>
          </div>
        )}
      </div>
    </Layout>
  )
}
