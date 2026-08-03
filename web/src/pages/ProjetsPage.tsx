import { useEffect, useState } from 'react'
import { Plus, FolderKanban, Users, Star, CheckCircle2 } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import { getProjets } from '../api/projetApi'
import { getUser } from '../api/jwtService'
import { useProjetActif } from '../context/ProjetActifContext'
import type { ProjetResponseDto } from '../types'

/**
 * Liste des projets de l'utilisateur (comme la page « Gestion projets » mobile).
 */
export default function ProjetsPage() {
  const [projets, setProjets] = useState<ProjetResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const { projetActif, setProjetActif } = useProjetActif()
  const user = getUser()

  useEffect(() => {
    const load = async () => {
      try {
        const data = await getProjets()
        setProjets(data)
      } catch (err) {
        console.error('Erreur chargement projets:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [])

  return (
    <Layout>
      <div className="p-6 max-w-7xl mx-auto">
        <PageHeader
          title="Projets"
          subtitle="Projets industriels suivis"
          actions={(
            <button
              onClick={() => setProjetActif(null)}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
            >
              <Plus size={16} />
              Nouveau projet
            </button>
          )}
        />

        {loading ? (
          <LoadingSpinner />
        ) : projets.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <FolderKanban size={40} className="text-[#9ca3af] mb-4" />
            <p className="text-[#757575]">Aucun projet</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {projets.map((projet) => {
              const isMine = projet.createurId === user?.id
              const active = projetActif?.id === projet.id
              return (
                <div
                  key={projet.id}
                  onClick={() => setProjetActif(projet)}
                  className={`bg-white border rounded-2xl p-5 hover:shadow-lg hover:shadow-black/5 transition-all cursor-pointer ${
                    active ? 'border-[#00875a] ring-2 ring-[#00875a]/20' : 'border-[#e5e7eb]'
                  }`}
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2 min-w-0">
                      {isMine ? (
                        <Star size={16} className="text-[#00875a] flex-shrink-0" />
                      ) : (
                        <Users size={16} className="text-[#9ca3af] flex-shrink-0" />
                      )}
                      <h3 className="font-semibold text-[#111111] truncate">{projet.nom}</h3>
                    </div>
                    {active && (
                      <Badge color="green">
                        <CheckCircle2 size={12} /> Actif
                      </Badge>
                    )}
                  </div>
                  <p className="text-sm text-[#757575] line-clamp-2 mb-4">
                    {projet.description || 'Aucune description'}
                  </p>
                  <div className="flex items-center gap-1.5 text-xs text-[#9ca3af]">
                    <Users size={12} className="text-[#00875a]" />
                    {projet.membresCount ?? 0} membre(s) •{' '}
                    {projet.dateCreation
                      ? new Date(projet.dateCreation).toLocaleDateString('fr-FR')
                      : '—'}
                  </div>
                  {active && (
                    <p className="mt-2 text-[11px] text-[#00875a] font-medium">
                      Cliquer pour sélectionner ce projet
                    </p>
                  )}
                </div>
              )
            })}
          </div>
        )}
      </div>
    </Layout>
  )
}
