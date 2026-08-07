import { useCallback, useRef, useState } from 'react'
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
  Smartphone,
} from 'lucide-react'
import { clearToken, getUser } from '../api/jwtService'
import { useProjetActif } from '../context/ProjetActifContext'
import type { ReactNode } from 'react'

const NAV_ITEMS = [
  { label: 'Dashboard', path: '/', icon: LayoutDashboard },
  { label: 'Fuites', path: '/fuites', icon: Droplets },
  { label: 'Campagnes', path: '/campagnes', icon: CalendarDays },
  // { label: 'Projets', path: '/projets', icon: FolderKanban },
  { label: 'Rapports', path: '/rapports', icon: FileBarChart },
  { label: 'Configuration', path: '/config', icon: Settings },
  { label: 'Application Mobile', path: '/application-mobile', icon: Smartphone },
]

const MIN_WIDTH = 200
const MAX_WIDTH = 400
const COLLAPSED_WIDTH = 80

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
  const [width, setWidth] = useState(300)
  const resizingRef = useRef(false)
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

  const startResize = useCallback((e: React.MouseEvent) => {
    e.preventDefault()
    resizingRef.current = true
    document.body.style.cursor = 'col-resize'
    document.body.style.userSelect = 'none'

    const onMouseMove = (ev: MouseEvent) => {
      if (!resizingRef.current) return
      const newWidth = Math.min(
        MAX_WIDTH,
        Math.max(MIN_WIDTH, ev.clientX)
      )
      setWidth(newWidth)
      setCollapsed(false)
    }

    const onMouseUp = () => {
      resizingRef.current = false
      document.body.style.cursor = ''
      document.body.style.userSelect = ''
      document.removeEventListener('mousemove', onMouseMove)
      document.removeEventListener('mouseup', onMouseUp)
    }

    document.addEventListener('mousemove', onMouseMove)
    document.addEventListener('mouseup', onMouseUp)
  }, [])

  const sidebarWidth = collapsed ? COLLAPSED_WIDTH : width

  return (
    <div className="flex h-screen bg-[#f5f5f5] text-[#111111]">
      {/* Sidebar */}
      <aside
        className="relative flex flex-col border-r border-[#e5e7eb] bg-white transition-[width] duration-300"
        style={{ width: sidebarWidth }}
      >
        {/* Logo + bouton réduire */}
        <div className="flex items-center gap-2.5 px-4 h-16 border-b border-[#e5e7eb]">
          <img
            src="/logo.png"
            alt="OCP"
            className={`object-contain flex-shrink-0 ${collapsed ? 'w-6 h-6' : 'w-9 h-9'}`}
            onError={(e) => {
              ;(e.target as HTMLImageElement).style.display = 'none'
            }}
          />
          {!collapsed && (
            <span className="font-bold text-lg tracking-tight text-[#111111] truncate">
              OCP Leaks
            </span>
          )}
          <button
            onClick={() => setCollapsed(!collapsed)}
            title={collapsed ? 'Agrandir la barre' : 'Réduire la barre'}
            className="ml-auto flex items-center justify-center w-8 h-8 rounded-lg text-[#9ca3af] hover:bg-[#f0f4f2] hover:text-[#00875a] transition-colors"
          >
            {collapsed ? <ChevronRight size={18} /> : <ChevronLeft size={18} />}
          </button>
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
          {!collapsed && user ? (
            <div
              onClick={() => navigate('/profil')}
              title="Mon profil"
              role="button"
              tabIndex={0}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault()
                  navigate('/profil')
                }
              }}
              className="flex items-center gap-2.5 w-full px-2 py-2 rounded-xl hover:bg-[#f5f5f5] transition-colors cursor-pointer"
            >
              <div className="w-9 h-9 rounded-full bg-[#00875a]/10 text-[#00875a] flex items-center justify-center font-bold text-sm flex-shrink-0">
                {fullName
                  .split(' ')
                  .map((p) => p[0])
                  .slice(0, 2)
                  .join('')
                  .toUpperCase() || 'U'}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-sm font-semibold text-[#111111] truncate">
                  {fullName}
                </div>
                <div className="text-xs text-[#9ca3af] truncate">{user.email}</div>
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  handleLogout()
                }}
                title="Déconnexion"
                className="flex items-center justify-center w-8 h-8 rounded-lg text-[#9ca3af] hover:bg-red-50 hover:text-red-500 transition-colors flex-shrink-0"
              >
                <LogOut size={16} />
              </button>
            </div>
          ) : (
            <button
              onClick={handleLogout}
              title="Déconnexion"
              className="flex items-center justify-center w-full py-2.5 rounded-xl text-[#9ca3af] hover:bg-red-50 hover:text-red-500 transition-colors"
            >
              <LogOut size={18} />
            </button>
          )}
        </div>

        {/* Poignée de redimensionnement */}
        <div
          onMouseDown={startResize}
          title="Redimensionner la barre"
          className="absolute top-0 right-0 w-1.5 h-full cursor-col-resize group/resize"
        >
          <div className="absolute top-1/2 -translate-y-1/2 right-0 w-1 h-10 rounded-full bg-[#00875a]/0 group-hover/resize:bg-[#00875a]/40 transition-colors" />
        </div>
      </aside>

      {/* Contenu */}
      <main className="flex-1 overflow-y-auto">{children}</main>
    </div>
  )
}
