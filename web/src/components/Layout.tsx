import { useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  Droplets,
  CalendarDays,
  FolderKanban,
  FileBarChart,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  Folder,
  Star,
  Users,
} from 'lucide-react'
import { clearToken, getUser } from '../api/jwtService'
import { useProjetActif } from '../context/ProjetActifContext'
import type { ReactNode } from 'react'

const NAV_ITEMS = [
  { label: 'Dashboard', path: '/', icon: LayoutDashboard },
  { label: 'Fuites', path: '/fuites', icon: Droplets },
  { label: 'Campagnes', path: '/campagnes', icon: CalendarDays },
  { label: 'Projets', path: '/projets', icon: FolderKanban },
  { label: 'Rapports', path: '/rapports', icon: FileBarChart },
  { label: 'Configuration', path: '/config', icon: Settings },
]

interface LayoutProps {
  children: ReactNode
}

/**
 * Layout principal — sidebar + contenu.
 * Design aligné avec l'app mobile OCP : fond clair, sidebar blanche,
 * logo OCP, accent vert #00875A.
 */
export default function Layout({ children }: LayoutProps) {
  const [collapsed, setCollapsed] = useState(false)
  const [projetOpen, setProjetOpen] = useState(false)
  const navigate = useNavigate()
  const user = getUser()
  const { projets, projetActif, setProjetActif, loading } = useProjetActif()

  const handleLogout = () => {
    clearToken()
    navigate('/login', { replace: true })
  }

  const fullName = user
    ? `${user.prenom ?? ''} ${user.nom ?? ''}`.trim()
    : ''

  return (
    <div className="flex h-screen bg-[#f5f5f5] text-[#111111]">
      {/* Sidebar */}
      <aside
        className={`flex flex-col border-r border-[#e5e7eb] bg-white transition-all duration-300 ${
          collapsed ? 'w-16' : 'w-60'
        }`}
      >
        {/* Logo */}
        <div className="flex items-center gap-2.5 px-4 h-16 border-b border-[#e5e7eb]">
          <img
            src="/logo.png"
            alt="OCP"
            className="w-9 h-9 object-contain flex-shrink-0"
            onError={(e) => {
              ;(e.target as HTMLImageElement).style.display = 'none'
            }}
          />
          {!collapsed && (
            <span className="font-bold text-lg tracking-tight text-[#111111] truncate">
              OCP Leaks
            </span>
          )}
        </div>

        {/* Sélecteur de projet (équivalent drawer mobile) */}
        <div className="px-2 pt-3 pb-1 border-b border-[#e5e7eb]">
          {collapsed ? (
            <button
              onClick={() => setProjetOpen(!projetOpen)}
              title={projetActif?.nom ?? 'Sélectionner un projet'}
              className="flex items-center justify-center w-full py-2 rounded-xl text-[#00875a] hover:bg-[#f0f4f2] transition-colors"
            >
              <Folder size={18} />
            </button>
          ) : (
            <div className="px-2">
              <div className="flex items-center gap-1.5 mb-1.5">
                <Folder size={13} className="text-[#757575]" />
                <span className="text-[11px] font-bold tracking-wide text-[#757575] uppercase">
                  Projet actif
                </span>
              </div>
              <button
                onClick={() => setProjetOpen(!projetOpen)}
                className="flex items-center justify-between w-full px-3 py-2.5 rounded-xl border border-black/10 bg-white hover:border-[#00875a]/40 transition-colors"
              >
                <span className="text-sm font-medium text-[#111111] truncate">
                  {loading
                    ? 'Chargement…'
                    : projetActif?.nom ?? 'Sélectionner un projet'}
                </span>
                <ChevronDown
                  size={16}
                  className={`text-[#00875a] transition-transform ${projetOpen ? 'rotate-180' : ''}`}
                />
              </button>
              {projetOpen && (
                <div className="mt-1.5 rounded-xl border border-[#e5e7eb] bg-white shadow-lg max-h-56 overflow-y-auto py-1">
                  {projets.length === 0 ? (
                    <p className="px-3 py-2 text-sm text-[#9ca3af] italic">
                      Aucun projet disponible
                    </p>
                  ) : (
                    projets.map((projet) => {
                      const isMine = projet.createurId === user?.id
                      const active = projetActif?.id === projet.id
                      return (
                        <button
                          key={projet.id}
                          onClick={() => {
                            setProjetActif(projet)
                            setProjetOpen(false)
                          }}
                          className={`flex items-center gap-2 w-full px-3 py-2 text-left text-sm transition-colors ${
                            active
                              ? 'bg-[#00875a]/10 text-[#00875a] font-medium'
                              : 'text-[#111111] hover:bg-[#f5f5f5]'
                          }`}
                        >
                          {isMine ? (
                            <Star size={14} className="text-[#00875a] flex-shrink-0" />
                          ) : (
                            <Users size={14} className="text-[#9ca3af] flex-shrink-0" />
                          )}
                          <span className="truncate">{projet.nom}</span>
                          {active && <span className="ml-auto text-[11px]">✓</span>}
                        </button>
                      )
                    })
                  )}
                  {/* ── Mes projets : navigation vers la page de gestion ── */}
                  <div className="my-1 border-t border-[#e5e7eb]" />
                  <button
                    onClick={() => {
                      setProjetOpen(false)
                      navigate('/projets')
                    }}
                    className="flex items-center gap-2 w-full px-3 py-2 text-left text-sm font-medium text-[#00875a] hover:bg-[#f0f4f2] transition-colors"
                  >
                    <FolderKanban size={14} className="flex-shrink-0" />
                    <span>Mes projets</span>
                  </button>
                </div>
              )}
              {projetActif && (
                <p className="mt-1 text-[11px] text-[#757575] truncate">
                  {projetActif.membresCount ?? 0} membre(s) •{' '}
                  {projetActif.createurNom ?? '—'}
                </p>
              )}
            </div>
          )}
        </div>

        {/* Nav */}
        <nav className="flex-1 py-3 px-2 space-y-1 overflow-y-auto">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              end={item.path === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-[#00875a]/10 text-[#00875a] border border-[#00875a]/20'
                    : 'text-[#757575] hover:bg-[#f0f4f2] hover:text-[#111111]'
                }`
              }
              title={collapsed ? item.label : undefined}
            >
              <item.icon size={18} className="flex-shrink-0" />
              {!collapsed && <span className="truncate">{item.label}</span>}
            </NavLink>
          ))}
        </nav>

        {/* Utilisateur + déconnexion */}
        <div className="border-t border-[#e5e7eb] p-3">
          {!collapsed && fullName && (
            <div className="px-3 py-2 mb-2 text-sm text-[#757575] truncate">
              {fullName}
            </div>
          )}
          <button
            onClick={handleLogout}
            className="flex items-center gap-3 w-full px-3 py-2.5 rounded-xl text-sm font-medium text-[#757575] hover:bg-red-50 hover:text-red-500 transition-colors"
          >
            <LogOut size={18} className="flex-shrink-0" />
            {!collapsed && <span>Déconnexion</span>}
          </button>
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="flex items-center gap-3 w-full px-3 py-2 mt-1 rounded-xl text-sm text-[#9ca3af] hover:bg-[#f0f4f2] transition-colors"
          >
            {collapsed ? (
              <ChevronRight size={18} />
            ) : (
              <>
                <ChevronLeft size={18} />
                <span>Réduire</span>
              </>
            )}
          </button>
        </div>
      </aside>

      {/* Contenu */}
      <main className="flex-1 overflow-y-auto">{children}</main>
    </div>
  )
}
