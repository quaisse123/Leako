import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Loader2, LogIn, UserPlus, Mail, Lock, User } from 'lucide-react'
import { login, register } from '../api/authApi'
import { useProjetActif } from '../context/ProjetActifContext'

/**
 * Page de connexion / inscription.
 * Design aligné avec l'app mobile Flutter (login_page.dart) :
 * - Fond clair, carte blanche avec ombres douces (radius 24)
 * - Logo OCP grand en haut
 * - Bouton vert OCP (#00875A), radius 14
 * - Toggle connexion / inscription
 */
export default function LoginPage() {
  const [isLogin, setIsLogin] = useState(true)
  const [nom, setNom] = useState('')
  const [prenom, setPrenom] = useState('')
  const [email, setEmail] = useState('')
  const [motDePasse, setMotDePasse] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()
  const { reload: reloadProjets } = useProjetActif()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    // Validation des champs requis
    if (!email.trim()) {
      setError("L'email est requis")
      return
    }
    if (!motDePasse) {
      setError('Le mot de passe est requis')
      return
    }
    if (!isLogin && !nom.trim()) {
      setError('Le nom est requis')
      return
    }
    if (!isLogin && !prenom.trim()) {
      setError('Le prénom est requis')
      return
    }

    setLoading(true)
    setError(null)
    try {
      if (isLogin) {
        await login({ email: email.trim(), motDePasse })
      } else {
        await register({
          nom: nom.trim(),
          prenom: prenom.trim(),
          email: email.trim(),
          motDePasse,
        })
        // Après inscription, connexion automatique
        await login({ email: email.trim(), motDePasse })
      }
      // Recharger les projets maintenant que l'utilisateur est connecté
      // (évite le spinner infini sur le dashboard après le login).
      await reloadProjets()
      navigate('/', { replace: true })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur de connexion')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-white p-4">
      <div className="w-full max-w-md">
        {/* ╔════════════════════════════════════╗
            ║  LOGO OCP (grand)                 ║
            ╚════════════════════════════════════╝ */}
        <div className="flex justify-center mb-8">
          <img
            src="/logo.png"
            alt="OCP Leaks"
            className="w-28 h-28 object-contain"
            onError={(e) => {
              // Fallback si le logo ne charge pas
              ;(e.target as HTMLImageElement).style.display = 'none'
            }}
          />
        </div>

        {/* ╔════════════════════════════════════╗
            ║  FORMULAIRE (carte blanche ombrée) ║
            ╚════════════════════════════════════╝ */}
        <div
          className="bg-white rounded-3xl px-6 py-8"
          style={{
            boxShadow:
              '0 8px 30px rgba(0,0,0,0.06), 0 4px 60px rgba(0,135,90,0.04)',
          }}
        >
          {/* Titre */}
          <h1 className="text-xl font-extrabold text-[#111111] text-center">
            {isLogin ? 'Connexion' : 'Nouveau compte'}
          </h1>
          <p className="text-[13px] text-[#757575] text-center mt-1 mb-7">
            {isLogin
              ? 'Connectez-vous pour continuer'
              : 'Créez votre compte technicien'}
          </p>

          {/* Erreur */}
          {error && (
            <div className="mb-4 p-3 rounded-xl bg-red-50 border border-red-200 text-red-600 text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-3.5">
            {/* Prénom (inscription) */}
            {!isLogin && (
              <div className="relative">
                <User
                  size={18}
                  className="absolute left-4 top-1/2 -translate-y-1/2 text-[#9ca3af]"
                />
                <input
                  value={prenom}
                  onChange={(e) => setPrenom(e.target.value)}
                  placeholder="Prénom"
                  className="w-full pl-11 pr-4 py-3 rounded-xl bg-white border border-gray-200 text-sm text-[#111111] outline-none focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/10 transition-all"
                />
              </div>
            )}

            {/* Nom (inscription) */}
            {!isLogin && (
              <div className="relative">
                <User
                  size={18}
                  className="absolute left-4 top-1/2 -translate-y-1/2 text-[#9ca3af]"
                />
                <input
                  value={nom}
                  onChange={(e) => setNom(e.target.value)}
                  placeholder="Nom"
                  className="w-full pl-11 pr-4 py-3 rounded-xl bg-white border border-gray-200 text-sm text-[#111111] outline-none focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/10 transition-all"
                />
              </div>
            )}

            {/* Email */}
            <div className="relative">
              <Mail
                size={18}
                className="absolute left-4 top-1/2 -translate-y-1/2 text-[#9ca3af]"
              />
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Email"
                className="w-full pl-11 pr-4 py-3 rounded-xl bg-white border border-gray-200 text-sm text-[#111111] outline-none focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/10 transition-all"
              />
            </div>

            {/* Mot de passe */}
            <div className="relative">
              <Lock
                size={18}
                className="absolute left-4 top-1/2 -translate-y-1/2 text-[#9ca3af]"
              />
              <input
                type="password"
                value={motDePasse}
                onChange={(e) => setMotDePasse(e.target.value)}
                placeholder="Mot de passe"
                className="w-full pl-11 pr-4 py-3 rounded-xl bg-white border border-gray-200 text-sm text-[#111111] outline-none focus:border-[#00875a] focus:ring-2 focus:ring-[#00875a]/10 transition-all"
              />
            </div>

            {/* Bouton vert OCP */}
            <button
              type="submit"
              disabled={loading}
              className="w-full h-[52px] rounded-xl bg-[#00875a] text-white text-base font-bold hover:bg-[#005c3e] disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2.5"
            >
              {loading ? (
                <Loader2 size={22} className="animate-spin" />
              ) : (
                <>
                  {isLogin ? (
                    <LogIn size={20} />
                  ) : (
                    <UserPlus size={20} />
                  )}
                  {isLogin ? 'Se connecter' : "S'inscrire"}
                </>
              )}
            </button>
          </form>

          {/* Toggle connexion / inscription */}
          <div className="flex items-center justify-center gap-1 mt-5">
            <span className="text-[13px] text-[#757575]">
              {isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? '}
            </span>
            <button
              onClick={() => {
                setIsLogin(!isLogin)
                setError(null)
              }}
              className="text-[13px] font-bold text-[#00875a] hover:text-[#005c3e] transition-colors"
            >
              {isLogin ? "S'inscrire" : 'Se connecter'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
