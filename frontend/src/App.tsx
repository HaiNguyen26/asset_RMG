import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import { ProtectedRoute } from './components/ProtectedRoute'
import { Layout } from './components/Layout'
import { LoginPage } from './pages/LoginPage'
import { ListView } from './pages/ListView'
import { DetailView } from './pages/DetailView'
import { RepairHistoryListView } from './pages/RepairHistoryListView'
import { RepairHistoryDetailView } from './pages/RepairHistoryDetailView'
import { PolicyView } from './pages/PolicyView'

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/category/laptop" replace />} />
            <Route path="category/:categoryId" element={<ListView />} />
            <Route path="category/:categoryId/asset/:assetId" element={<DetailView />} />
            <Route path="repair-history" element={<RepairHistoryListView />} />
            <Route path="repair-history/:id" element={<RepairHistoryDetailView />} />
            <Route path="policies" element={<PolicyView />} />
          </Route>
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}

export default App
