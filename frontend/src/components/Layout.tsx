import { useState } from 'react'
import { Outlet, useParams, useLocation } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { Sidebar } from './Sidebar'
import { Header } from './Header'
import { AssetFormModal } from './AssetFormModal'
import { ASSET_CATEGORIES } from '../types'
import type { AssetCategoryId } from '../types'

const pageVariants = {
  initial: {
    opacity: 0,
  },
  animate: {
    opacity: 1,
  },
  exit: {
    opacity: 0,
  },
}

const pageTransition = {
  duration: 0.2,
}

export function Layout() {
  const { categoryId } = useParams<{ categoryId: string }>()
  const location = useLocation()
  const currentCategory = (categoryId ?? 'laptop') as AssetCategoryId
  const isValidCategory = ASSET_CATEGORIES.some((c) => c.id === currentCategory)
  const [isAddModalOpen, setIsAddModalOpen] = useState(false)
  const [refreshKey, setRefreshKey] = useState(0)

  const handleRefresh = () => {
    setRefreshKey((k) => k + 1)
  }

  return (
    <div className="flex h-screen bg-slate-50 overflow-hidden">
      <Sidebar />
      <main className="ml-64 flex h-screen flex-1 flex-col overflow-hidden">
        {isValidCategory && (
          <Header
            categoryId={currentCategory}
            onAddAsset={() => setIsAddModalOpen(true)}
            onRefresh={handleRefresh}
          />
        )}
        <div className="flex-1 p-6 overflow-hidden">
          <AnimatePresence mode="wait">
            <motion.div
              key={location.pathname + refreshKey}
              initial="initial"
              animate="animate"
              exit="exit"
              variants={pageVariants}
              transition={pageTransition}
              className="h-full overflow-hidden"
            >
              <Outlet />
            </motion.div>
          </AnimatePresence>
        </div>
      </main>
      {isValidCategory && (
        <AssetFormModal
          isOpen={isAddModalOpen}
          onClose={() => setIsAddModalOpen(false)}
          onSuccess={() => {
            handleRefresh()
            setIsAddModalOpen(false)
          }}
          categoryId={currentCategory}
        />
      )}
    </div>
  )
}
