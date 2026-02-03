import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { ArrowLeft, Edit } from 'lucide-react'
import { api } from '../services/api'
import { useAuth } from '../contexts/AuthContext'

export function RepairHistoryDetailView() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()
  const isAdmin = user?.role === 'ADMIN'

  const [repair, setRepair] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)

  useEffect(() => {
    if (id) {
      loadRepair()
    }
  }, [id])

  const loadRepair = async () => {
    try {
      setLoading(true)
      setError('')
      const data = await api.getRepairHistoryById(id!)
      setRepair(data)
    } catch (err: any) {
      setError(err.message || 'Không thể tải dữ liệu')
    } finally {
      setLoading(false)
    }
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

  if (error || !repair) {
    return (
      <div className="rounded-3xl border border-red-200 bg-red-50/90 backdrop-blur-sm p-6 text-center text-red-800 shadow-sm">
        {error || 'Không tìm thấy lịch sử sửa chữa'}
      </div>
    )
  }

  const pageVariants = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -20 },
  }

  const staggerContainer = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 },
  }

  return (
    <motion.div
      initial="initial"
      animate="animate"
      exit="exit"
      variants={pageVariants}
      className="h-full flex flex-col overflow-hidden"
    >
      {/* Navigation Bar */}
      <motion.div
        variants={itemVariants}
        className="flex-shrink-0 mb-6 flex items-center justify-between"
      >
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={() => navigate('/repair-history')}
          className="flex items-center gap-2 rounded-xl border border-slate-300 bg-white/90 px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition-all hover:bg-slate-50"
        >
          <ArrowLeft className="h-4 w-4" />
          Quay lại
        </motion.button>

        {isAdmin && (
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setIsEditModalOpen(true)}
            className="flex items-center gap-2 rounded-xl border border-indigo-300 bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition-all hover:bg-indigo-700"
          >
            <Edit className="h-4 w-4" />
            Sửa đổi
          </motion.button>
        )}
      </motion.div>

      {/* Main Content */}
      <motion.div
        variants={staggerContainer}
        initial="hidden"
        animate="visible"
        className="flex-1 min-h-0 overflow-y-auto pb-6"
      >
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Left Column - 2/3 */}
          <div className="lg:col-span-2 space-y-6">
            {/* Asset Info Card */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-6 shadow-sm"
            >
              <h2 className="mb-4 text-lg font-bold text-slate-800">Thông tin tài sản</h2>
              <div className="space-y-3">
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Mã tài sản:</span>
                  <span className="text-sm text-slate-800 font-mono">{repair.asset?.code || '—'}</span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Tên thiết bị:</span>
                  <span className="text-sm text-slate-800">{repair.asset?.name || '—'}</span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Người sử dụng:</span>
                  <span className="text-sm text-slate-800">
                    {repair.asset?.assignedUser?.name || repair.asset?.assignedTo || '—'}
                  </span>
                </div>
              </div>
            </motion.div>

            {/* Repair Info Card */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-6 shadow-sm"
            >
              <h2 className="mb-4 text-lg font-bold text-slate-800">Thông tin sửa chữa</h2>
              <div className="space-y-3">
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Ngày báo lỗi:</span>
                  <span className="text-sm text-slate-800">
                    {new Date(repair.errorDate).toLocaleDateString('vi-VN', {
                      day: '2-digit',
                      month: '2-digit',
                      year: 'numeric',
                    })}
                  </span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Mô tả sự cố:</span>
                  <span className="text-sm text-slate-800 flex-1">{repair.description || '—'}</span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Đơn vị xử lý:</span>
                  <span className="text-sm text-slate-800 flex items-center gap-1">
                    <span>{getRepairTypeIcon(repair.repairType)}</span>
                    {getRepairTypeLabel(repair.repairType)}
                    {repair.repairUnit && ` - ${repair.repairUnit}`}
                  </span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Kết quả sửa chữa:</span>
                  <span className="text-sm text-slate-800 flex-1">{repair.result || '—'}</span>
                </div>
                <div className="flex items-start gap-3">
                  <span className="text-sm font-medium text-slate-500 w-32 flex-shrink-0">Trạng thái:</span>
                  <span
                    className={`inline-flex items-center rounded-full border px-3 py-1 text-xs font-semibold ${getStatusColor(repair.status)}`}
                  >
                    {getStatusLabel(repair.status)}
                  </span>
                </div>
              </div>
            </motion.div>

            {/* IT Notes Card */}
            {repair.itNote && (
              <motion.div
                variants={itemVariants}
                className="rounded-3xl border border-slate-200 bg-slate-900/95 backdrop-blur-sm p-6 shadow-sm"
              >
                <h2 className="mb-4 text-lg font-bold text-white">Ghi chú IT</h2>
                <p className="text-sm text-slate-300 whitespace-pre-wrap">{repair.itNote}</p>
              </motion.div>
            )}
          </div>

          {/* Right Column - 1/3 */}
          <div className="space-y-6">
            {/* Status Card */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-6 shadow-sm"
            >
              <h3 className="mb-4 text-sm font-semibold text-slate-500 uppercase tracking-wider">Trạng thái</h3>
              <div className="flex items-center justify-center py-4">
                <span
                  className={`inline-flex items-center rounded-full border px-4 py-2 text-sm font-semibold ${getStatusColor(repair.status)}`}
                >
                  {getStatusLabel(repair.status)}
                </span>
              </div>
            </motion.div>

            {/* Metadata */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-6 shadow-sm"
            >
              <h3 className="mb-4 text-sm font-semibold text-slate-500 uppercase tracking-wider">Thông tin khác</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-slate-500">Ngày tạo:</span>
                  <span className="text-slate-800">
                    {new Date(repair.createdAt).toLocaleDateString('vi-VN')}
                  </span>
                </div>
                {repair.createdBy && (
                  <div className="flex justify-between">
                    <span className="text-slate-500">Người tạo:</span>
                    <span className="text-slate-800">{repair.createdBy.name}</span>
                  </div>
                )}
                {repair.updatedAt && repair.updatedAt !== repair.createdAt && (
                  <div className="flex justify-between">
                    <span className="text-slate-500">Cập nhật:</span>
                    <span className="text-slate-800">
                      {new Date(repair.updatedAt).toLocaleDateString('vi-VN')}
                    </span>
                  </div>
                )}
              </div>
            </motion.div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}
