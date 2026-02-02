import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { Wrench, Building2, Search, Calendar } from 'lucide-react'
import { api } from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import { ASSET_CATEGORIES } from '../types'

export function RepairHistoryListView() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const isAdmin = user?.role === 'ADMIN'

  const [repairs, setRepairs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Filters
  const [search, setSearch] = useState('')
  const [categoryId, setCategoryId] = useState('')
  const [repairType, setRepairType] = useState<'INTERNAL_IT' | 'EXTERNAL_VENDOR' | ''>('')
  const [status, setStatus] = useState<'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED' | ''>('')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')

  useEffect(() => {
    loadRepairs()
  }, [search, categoryId, repairType, status, fromDate, toDate])

  const loadRepairs = async () => {
    try {
      setLoading(true)
      setError('')
      const data = await api.getRepairHistory({
        search: search.trim() || undefined,
        categoryId: categoryId || undefined,
        repairType: repairType || undefined,
        status: status || undefined,
        fromDate: fromDate || undefined,
        toDate: toDate || undefined,
      })
      setRepairs(data)
    } catch (err: any) {
      setError(err.message || 'Không thể tải dữ liệu')
    } finally {
      setLoading(false)
    }
  }

  const handleRowClick = (repairId: string) => {
    navigate(`/repair-history/${repairId}`)
  }

  const getRepairTypeLabel = (type: string) => {
    return type === 'INTERNAL_IT' ? 'IT nội bộ' : 'Đơn vị bên ngoài'
  }

  const getRepairTypeIcon = (type: string) => {
    return type === 'INTERNAL_IT' ? '🔧' : '🏭'
  }

  const getStatusLabel = (status: string) => {
    const map: Record<string, string> = {
      IN_PROGRESS: 'Đang sửa',
      COMPLETED: 'Hoàn thành',
      CANCELLED: 'Đã hủy',
    }
    return map[status] || status
  }

  const getStatusColor = (status: string) => {
    const map: Record<string, string> = {
      IN_PROGRESS: 'bg-amber-100 text-amber-800 border-amber-200',
      COMPLETED: 'bg-emerald-100 text-emerald-800 border-emerald-200',
      CANCELLED: 'bg-red-100 text-red-800 border-red-200',
    }
    return map[status] || 'bg-slate-100 text-slate-800'
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <motion.div
          animate={{ opacity: [0.5, 1, 0.5] }}
          transition={{ repeat: Infinity, duration: 1 }}
          className="text-slate-500"
        >
          Đang tải dữ liệu...
        </motion.div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="rounded-3xl border border-red-200 bg-red-50/90 backdrop-blur-sm p-6 text-center text-red-800 shadow-sm">
        {error}
      </div>
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
      initial="hidden"
      animate="visible"
      variants={containerVariants}
      className="h-full flex flex-col overflow-hidden"
    >
      {/* Filters */}
      <motion.div
        variants={itemVariants}
        className="flex-shrink-0 mb-6 rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-6 shadow-sm"
      >
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {/* Search */}
          <motion.div
            whileFocus={{ scale: 1.02 }}
            className="relative"
          >
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Tìm theo mã TS / Tên thiết bị"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full rounded-xl border border-slate-300 bg-white/90 py-2.5 pl-10 pr-4 text-sm shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
            />
          </motion.div>

          {/* Category */}
          <motion.select
            whileFocus={{ scale: 1.02 }}
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            className="rounded-xl border border-slate-300 bg-white/90 px-4 py-2.5 text-sm shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
          >
            <option value="">Tất cả loại tài sản</option>
            {ASSET_CATEGORIES.map((cat) => (
              <option key={cat.id} value={cat.id}>
                {cat.name}
              </option>
            ))}
          </motion.select>

          {/* Repair Type */}
          <motion.select
            whileFocus={{ scale: 1.02 }}
            value={repairType}
            onChange={(e) => setRepairType(e.target.value as any)}
            className="rounded-xl border border-slate-300 bg-white/90 px-4 py-2.5 text-sm shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
          >
            <option value="">Tất cả hình thức</option>
            <option value="INTERNAL_IT">🔧 IT nội bộ</option>
            <option value="EXTERNAL_VENDOR">🏭 Đơn vị bên ngoài</option>
          </motion.select>

          {/* Status */}
          <motion.select
            whileFocus={{ scale: 1.02 }}
            value={status}
            onChange={(e) => setStatus(e.target.value as any)}
            className="rounded-xl border border-slate-300 bg-white/90 px-4 py-2.5 text-sm shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
          >
            <option value="">Tất cả trạng thái</option>
            <option value="IN_PROGRESS">Đang sửa</option>
            <option value="COMPLETED">Hoàn thành</option>
            <option value="CANCELLED">Đã hủy</option>
          </motion.select>

          {/* Date Range */}
          <motion.div
            whileFocus={{ scale: 1.02 }}
            className="relative"
          >
            <Calendar className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="date"
              placeholder="Từ ngày"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              className="w-full rounded-xl border border-slate-300 bg-white/90 py-2.5 pl-10 pr-4 text-sm shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
            />
          </motion.div>

          <motion.div
            whileFocus={{ scale: 1.02 }}
            className="relative"
          >
            <Calendar className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="date"
              placeholder="Đến ngày"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              className="w-full rounded-xl border border-slate-300 bg-white/90 py-2.5 pl-10 pr-4 text-sm shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
            />
          </motion.div>
        </div>
      </motion.div>

      {/* Table */}
      <motion.div
        variants={itemVariants}
        className="flex-1 min-h-0 overflow-hidden"
      >
        <div className="h-full overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm">
          <div className="flex-1 overflow-x-auto overflow-y-auto">
            <table className="w-full border-collapse" style={{ minWidth: '1000px' }}>
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50/80 sticky top-0 z-10">
                  <th className="text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 whitespace-nowrap w-32">
                    Mã TS
                  </th>
                  <th className="text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 whitespace-nowrap w-48">
                    Thiết bị
                  </th>
                  <th className="text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 whitespace-nowrap w-32">
                    Ngày lỗi
                  </th>
                  <th className="text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 whitespace-nowrap w-40">
                    Hình thức
                  </th>
                  <th className="text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 whitespace-nowrap w-48">
                    Kết quả
                  </th>
                  <th className="text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 whitespace-nowrap w-32">
                    Trạng thái
                  </th>
                </tr>
              </thead>
              <tbody>
                {repairs.map((repair) => (
                  <motion.tr
                    key={repair.id}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    whileHover={{ scale: 1.01, backgroundColor: 'rgba(241, 245, 249, 0.8)' }}
                    onClick={() => handleRowClick(repair.id)}
                    className="group border-b border-slate-100 last:border-0 transition-all cursor-pointer"
                  >
                    <td className="px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap font-medium text-slate-800">
                      {repair.asset?.code || '—'}
                    </td>
                    <td className="px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap">
                      <span className="truncate block" title={repair.asset?.name}>
                        {repair.asset?.name || '—'}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap">
                      {new Date(repair.errorDate).toLocaleDateString('vi-VN')}
                    </td>
                    <td className="px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap">
                      <span className="flex items-center gap-1">
                        <span>{getRepairTypeIcon(repair.repairType)}</span>
                        {getRepairTypeLabel(repair.repairType)}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap">
                      <span className="truncate block" title={repair.result || undefined}>
                        {repair.result || '—'}
                      </span>
                    </td>
                    <td className="px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap">
                      <span
                        className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold ${getStatusColor(repair.status)}`}
                      >
                        {getStatusLabel(repair.status)}
                      </span>
                    </td>
                  </motion.tr>
                ))}
              </tbody>
            </table>
            {repairs.length === 0 && (
              <div className="py-16 text-center text-slate-500">
                Không có lịch sử sửa chữa nào phù hợp với bộ lọc.
              </div>
            )}
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}
