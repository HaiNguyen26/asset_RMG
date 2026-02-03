import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Toolbar } from '../components/Toolbar'
import { DataTable } from '../components/DataTable'
import { api } from '../services/api'
import type { Asset } from '../services/api'
import type { AssetStatus } from '../types'

const FRONTEND_TO_API_STATUS: Record<AssetStatus, string> = {
  available: 'AVAILABLE',
  in_use: 'IN_USE',
  maintenance: 'MAINTENANCE',
  retired: 'RETIRED',
}

export function ListView() {
  const { categoryId } = useParams<{ categoryId: string }>()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<AssetStatus | ''>('')
  const [departmentFilter, setDepartmentFilter] = useState('')
  const [assets, setAssets] = useState<Asset[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    loadAssets()
  }, [categoryId, search, statusFilter, departmentFilter])

  const loadAssets = async () => {
    try {
      setLoading(true)
      setError('')
      
      // Map category slug to ID
      const categories = await api.getCategories()
      const category = categories.find((c) => c.slug === categoryId)
      
      const data = await api.getAssets({
        categoryId: category?.id,
        status: statusFilter ? (FRONTEND_TO_API_STATUS[statusFilter] as any) : undefined,
        departmentId: departmentFilter || undefined,
        search: search.trim() || undefined,
      })

      setAssets(data)
    } catch (err: any) {
      setError(err.message || 'Không thể tải dữ liệu')
    } finally {
      setLoading(false)
    }
  }

  const safeCategoryId = (categoryId ?? 'laptop') as 'laptop' | 'it_accessory' | 'tech_equipment'

  if (loading) {
    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        className="flex items-center justify-center py-12"
      >
        <motion.div
          animate={{ opacity: [0.5, 1, 0.5] }}
          transition={{ repeat: Infinity, duration: 1 }}
          className="text-slate-500"
        >
          Đang tải dữ liệu...
        </motion.div>
      </motion.div>
    )
  }

  if (error) {
    return (
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="rounded-3xl border border-red-200 bg-red-50/90 backdrop-blur-sm p-6 text-center text-red-800 shadow-sm"
      >
        {error}
      </motion.div>
    )
  }

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.05,
        duration: 0.2,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1 },
  }

  return (
    <motion.div
      key={categoryId}
      initial="hidden"
      animate="visible"
      variants={containerVariants}
      className="h-full flex flex-col overflow-hidden"
    >
      <motion.div variants={itemVariants} className="flex-shrink-0 mb-4">
        <Toolbar
          search={search}
          onSearchChange={setSearch}
          statusFilter={statusFilter}
          onStatusFilterChange={setStatusFilter}
          departmentFilter={departmentFilter}
          onDepartmentFilterChange={setDepartmentFilter}
        />
      </motion.div>
      <motion.div variants={itemVariants} className="flex-1 min-h-0 overflow-hidden">
        <DataTable assets={assets} categoryId={safeCategoryId} />
      </motion.div>
    </motion.div>
  )
}
