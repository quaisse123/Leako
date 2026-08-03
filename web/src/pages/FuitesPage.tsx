import { useEffect, useState } from 'react'
import { Plus, Droplets } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'
import LoadingSpinner from '../components/LoadingSpinner'
import Badge from '../components/Badge'
import { getFuites } from '../api/fuiteApi'
import { useProjetActif } from '../context/ProjetActifContext'
import { useNavigate } from 'react-router-dom'
import type { FuiteResponseDto } from '../types'

const STATUT_LABEL: Record<string, string> = {
  A_REPARER: 'À réparer',
  EN_COURS: 'En cours',
  REPAREE: 'Réparée',
  ANNULEE: 'Annulée',
}

/**
 * Liste des fuites — filtrée par le projet actif (comme l'app mobile).
 */
export default function FuitesPage() {
  const [fuites, setFuites] = useState<FuiteResponseDto[]>([])
  const [loading, setLoading] = useState(true)
  const { projetActif, loading: projetLoading } = useProjetActif()
  const navigate = useNavigate()

  useEffect(() => {
    if (projetLoading) return
    if (!projetActif) {
      setFuites([])
      setLoading(false)
      return
    }
    const load = async () => {
      setLoading(true)
      try {
        const data = await getFuites({ projetId: projetActif.id })
        setFuites(data)
      } catch (err) {
        console.error('Erreur chargement fuites:', err)
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
          title="Fuites"
          subtitle={
            projetActif
              ? `Gestion des fuites détectées — ${projetActif.nom}`
              : 'Sélectionnez un projet pour voir ses fuites'
          }
          actions={(
            <button
              onClick={() => navigate('/fuites/nouvelle')}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#00875a] text-white text-sm font-semibold hover:bg-[#005c3e] transition-colors"
            >
              <Plus size={16} />
              Nouvelle fuite
            </button>
          )}
        />

        {loading ? (
          <LoadingSpinner />
        ) : fuites.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-center">
            <Droplets size={40} className="text-[#9ca3af] mb-4" />
            <p className="text-[#757575]">Aucune fuite enregistrée pour ce projet</p>
          </div>
        ) : (
          <div className="bg-white border border-[#e5e7eb] rounded-2xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-[#9ca3af] border-b border-[#e5e7eb] bg-[#f9fafb]">
                    <th className="py-3 px-4 font-medium">Tag</th>
                    <th className="py-3 px-4 font-medium">Zone</th>
                    <th className="py-3 px-4 font-medium">Statut</th>
                    <th className="py-3 px-4 font-medium">Type vapeur</th>
                    <th className="py-3 px-4 font-medium">Campagne</th>
                    <th className="py-3 px-4 font-medium">Coût annuel</th>
                    <th className="py-3 px-4 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {fuites.map((fuite) => (
                    <tr
                      key={fuite.id}
                      onClick={() => navigate(`/fuites/${fuite.id}`)}
                      className="border-b border-[#e5e7eb]/50 last:border-0 hover:bg-[#f5f5f5] cursor-pointer transition-colors"
                    >
                      <td className="py-3 px-4 font-medium text-[#00875a]">
                        {fuite.numeroTag ?? '—'}
                      </td>
                      <td className="py-3 px-4 text-[#757575] max-w-xs truncate">
                        {fuite.zone || '—'}
                      </td>
                      <td className="py-3 px-4">
                        <Badge
                          color={
                            fuite.statut === 'REPAREE'
                              ? 'green'
                              : fuite.statut === 'A_REPARER'
                                ? 'red'
                                : fuite.statut === 'EN_COURS'
                                  ? 'yellow'
                                  : 'gray'
                          }
                        >
                          {STATUT_LABEL[fuite.statut ?? ''] ?? fuite.statut ?? '—'}
                        </Badge>
                      </td>
                      <td className="py-3 px-4 text-[#757575]">
                        {fuite.typeVapeur?.replace(/_/g, ' ').toLowerCase() ?? '—'}
                      </td>
                      <td className="py-3 px-4 text-[#757575]">
                        {fuite.campagneNom ?? '—'}
                      </td>
                      <td className="py-3 px-4 text-[#757575]">
                        {fuite.coutAnnuelEstime != null
                          ? `${fuite.coutAnnuelEstime.toLocaleString('fr-FR')} DH`
                          : '—'}
                      </td>
                      <td className="py-3 px-4 text-[#9ca3af]">
                        {fuite.dateDetection
                          ? new Date(fuite.dateDetection).toLocaleDateString('fr-FR')
                          : '—'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </Layout>
  )
}
