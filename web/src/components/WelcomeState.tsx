import { Link } from 'react-router-dom'
import {
  FolderPlus,
  CalendarDays,
  Droplets,
  ArrowRight,
  Smartphone,
} from 'lucide-react'

interface WelcomeStateProps {
  onCreateProject: () => void
}

/**
 * Page de bienvenue — affichée sur le Dashboard uniquement quand
 * l'utilisateur connecté n'a encore AUCUN projet (nouvel utilisateur).
 *
 * Guide l'utilisateur vers la création de son premier projet au lieu
 * d'afficher un tableau de bord rempli de zéros.
 */
export default function WelcomeState({ onCreateProject }: WelcomeStateProps) {
  const etapes = [
    {
      icon: FolderPlus,
      step: '1',
      title: 'Créer un projet',
      desc: 'Nommez votre projet : site, ville, secteur…',
    },
    {
      icon: CalendarDays,
      step: '2',
      title: 'Lancer une campagne',
      desc: 'Organisez les relevés et inspections',
    },
    {
      icon: Droplets,
      step: '3',
      title: 'Signaler les fuites',
      desc: 'Photos, vidéos et coûts estimés',
    },
  ]

  return (
    <div className="min-h-full flex items-center justify-center p-6">
      <div className="w-full max-w-2xl bg-white rounded-3xl border border-[#e5e7eb] p-8 sm:p-10 shadow-sm">
        {/* Icône */}
        <div className="w-16 h-16 rounded-2xl bg-[#00875a]/10 flex items-center justify-center mb-6">
          <FolderPlus size={32} className="text-[#00875a]" />
        </div>

        <h1 className="text-2xl font-bold tracking-tight text-[#111111]">
          Bienvenue sur OCP Leaks 👋
        </h1>
        <p className="mt-2 text-[#757575]">
          Votre tableau de bord est prêt ! Commencez par créer un projet pour
          suivre vos fuites, campagnes et économies.
        </p>

        {/* Étapes */}
        <div className="mt-8 grid grid-cols-1 sm:grid-cols-3 gap-3">
          {etapes.map(({ icon: Icon, step, title, desc }) => (
            <div
              key={step}
              className="rounded-2xl border border-[#e5e7eb] bg-[#fafafa] p-4"
            >
              <div className="flex items-center gap-2 mb-2">
                <span className="w-6 h-6 rounded-full bg-[#00875a] text-white text-xs font-bold flex items-center justify-center">
                  {step}
                </span>
                <Icon size={16} className="text-[#00875a]" />
              </div>
              <p className="font-semibold text-sm text-[#111111]">{title}</p>
              <p className="text-xs text-[#9ca3af] mt-1">{desc}</p>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div className="mt-8 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          <button
            onClick={onCreateProject}
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
          >
            Créer mon premier projet
            <ArrowRight size={16} />
          </button>
          <Link
            to="/application-mobile"
            className="flex items-center justify-center gap-2 px-5 py-3 rounded-xl border border-black/10 bg-white text-[#757575] text-sm font-medium hover:bg-[#f5f5f5] transition-colors"
          >
            <Smartphone size={16} />
            Découvrir l'application mobile
          </Link>
        </div>
      </div>
    </div>
  )
}
