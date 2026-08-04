import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import ProtectedRoute from './components/ProtectedRoute'
import { ProjetActifProvider } from './context/ProjetActifContext'
import { MediaViewerProvider } from './context/MediaViewerContext'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import FuitesPage from './pages/FuitesPage'
import NouvelleFuitePage from './pages/NouvelleFuitePage'
import DetailFuitePage from './pages/DetailFuitePage'
import CampagnesPage from './pages/CampagnesPage'
import NouvelleCampagnePage from './pages/NouvelleCampagnePage'
import DetailCampagnePage from './pages/DetailCampagnePage'
import ProjetsPage from './pages/ProjetsPage'
import RapportsPage from './pages/RapportsPage'
import PdfViewerPage from './pages/PdfViewerPage'
import ConfigPage from './pages/ConfigPage'

export default function App() {
  return (
    <BrowserRouter>
      <MediaViewerProvider>
        <ProjetActifProvider>
          <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route
          path="/"
          element={(
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/fuites"
          element={(
            <ProtectedRoute>
              <FuitesPage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/fuites/nouvelle"
          element={(
            <ProtectedRoute>
              <NouvelleFuitePage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/fuites/:id"
          element={(
            <ProtectedRoute>
              <DetailFuitePage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/campagnes"
          element={(
            <ProtectedRoute>
              <CampagnesPage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/campagnes/nouvelle"
          element={(
            <ProtectedRoute>
              <NouvelleCampagnePage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/campagnes/:id"
          element={(
            <ProtectedRoute>
              <DetailCampagnePage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/projets"
          element={(
            <ProtectedRoute>
              <ProjetsPage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/rapports"
          element={(
            <ProtectedRoute>
              <RapportsPage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/rapports/pdf"
          element={(
            <ProtectedRoute>
              <PdfViewerPage />
            </ProtectedRoute>
          )}
        />
        <Route
          path="/config"
          element={(
            <ProtectedRoute>
              <ConfigPage />
            </ProtectedRoute>
          )}
        />
        <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
        </ProjetActifProvider>
      </MediaViewerProvider>
    </BrowserRouter>
  )
}
