import { useEffect, useState } from 'react'
import { Plus, CalendarDays, Droplets, MapPin } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import { getCampagnes } from '../api/campagneApi'
import { useProjetActif } from '../context/ProjetActifContext'
import { useNavigate } from 'react-router-dom'
import type { CampagneResponseDto } from '../types'

/**
 * Liste des campagnes — filtrée par le projet actif (comme l'app mobile).
 */
export default function CampagnesPage() {
  const [campagnes, setCampagnes] = useState<CampagneResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const { projetActif, loading: projetLoading } = useProjetActif()
  const navigate = useNavigate()

  useEffect(() => {
    if (projetLoading) return
    if (!projetActif) {
      setCampagnes([])
      setLoading(false)
      return
    }
    const load = async () => {
      setLoading(true)
      try {
        const data = await getCampagnes(projetActif.id)
        setCampagnes(data)
      } catch (err) {
        console.error('Erreur chargement campagnes:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [projetActif, projetLoading])

  return (
    <Layout>
      <div className="p-6 max-w-7xl mx-auto">
        <PageHeader
          title="Campagnes"
          subtitle={
            projetActif
              ? `Campagnes de détection de fuites — ${projetActif.nom}`
              : 'Sélectionnez un projet pour voir ses campagnes'
          }
          actions={(
            <button
              onClick={() => navigate('/campagnes/nouvelle')}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
            >
              <Plus size={16} />
              Nouvelle campagne
            </button>
          )}
        />

        {loading ? (
          <LoadingSpinner />
        ) : campagnes.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <CalendarDays size={40} className="text-[#9ca3af] mb-4" />
            <p className="text-[#757575]">Aucune campagne pour ce projet</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {campagnes.map((campagne) => (
              <div
                key={campagne.id}
                onClick={() => navigate(`/campagnes/${campagne.id}`)}
                className="bg-white border border-[#e5e7eb] rounded-2xl p-5 hover:shadow-lg hover:shadow-black/5 transition-all cursor-pointer"
              >
                <div className="flex items-center justify-between mb-3">
                  <h3 className="font-semibold text-[#111111] truncate">{campagne.nom}</h3>
                  <Badge color={campagne.estCloturee ? 'gray' : 'green'}>
                    {campagne.estCloturee ? 'Clôturée' : 'Active'}
                  </Badge>
                </div>
                <p className="text-sm text-[#757575] line-clamp-2 mb-4">
                  {campagne.description || 'Aucune description'}
                </p>
                {campagne.zone && (
                  <div className="flex items-center gap-1.5 text-xs text-[#757575] mb-2">
                    <MapPin size={12} className="text-[#00875a]" />
                    {campagne.zone}
                  </div>
                )}
                <div className="flex items-center gap-1.5 text-xs text-[#9ca3af]">
                  <Droplets size={12} className="text-[#00875a]" />
                  {campagne.nombreFuites ?? 0} fuite(s) •{' '}
                  {campagne.dateCreation
                    ? new Date(campagne.dateCreation).toLocaleDateString('fr-FR')
                    : '—'}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Layout>
  )
}
