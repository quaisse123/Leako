import { FileBarChart } from 'lucide-react'
import Layout from '../components/Layout'
import PageHeader from '../components/PageHeader'

/**
 * Rapports & PDF — Phase 6 (placeholder).
 */
export default function RapportsPage() {
  return (
    <Layout>
      <div className="p-6 max-w-7xl mx-auto">
        <PageHeader
          title="Rapports"
          subtitle="Génération et visualisation de rapports PDF"
        />
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <FileBarChart size={40} className="text-[#9ca3af] mb-4" />
          <p className="text-[#757575]">
            La génération de rapports sera disponible dans une prochaine phase.
          </p>
        </div>
      </div>
    </Layout>
  )
}
