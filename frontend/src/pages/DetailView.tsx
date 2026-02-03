import { useEffect, useState } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Edit, Trash2, UserPlus, RotateCcw, Cpu, MapPin, Clock } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { StatusBadge } from '../components/StatusBadge'
import { AssetFormModal } from '../components/AssetFormModal'
import { api } from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import type { Asset } from '../services/api'
import type { AssetCategoryId } from '../types'

export function DetailView() {
  const { categoryId, assetId } = useParams<{ categoryId: string; assetId: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()
  const isAdmin = user?.role === 'ADMIN'
  const [asset, setAsset] = useState<Asset | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [assigning, setAssigning] = useState(false)
  const [returning, setReturning] = useState(false)
  const [isEditModalOpen, setIsEditModalOpen] = useState(false)

  useEffect(() => {
    loadAsset()
  }, [assetId])

  const loadAsset = async () => {
    if (!assetId) return
    try {
      setLoading(true)
      setError('')
      const data = await api.getAsset(assetId)
      setAsset(data)
    } catch (err: any) {
      setError(err.message || 'Không thể tải thông tin tài sản')
    } finally {
      setLoading(false)
    }
  }

  const handleAssign = async () => {
    if (!asset || !assetId) return
    const employeesCode = prompt('Nhập mã nhân viên để cấp phát:')
    if (!employeesCode?.trim()) return

    try {
      setAssigning(true)
      await api.assignAsset(assetId, employeesCode.trim())
      await loadAsset()
      alert('Cấp phát thành công!')
    } catch (err: any) {
      alert(err.message || 'Cấp phát thất bại')
    } finally {
      setAssigning(false)
    }
  }

  const handleReturn = async () => {
    if (!asset || !assetId) return
    if (!confirm('Bạn có chắc muốn thu hồi tài sản này?')) return

    try {
      setReturning(true)
      await api.returnAsset(assetId)
      await loadAsset()
      alert('Thu hồi thành công!')
    } catch (err: any) {
      alert(err.message || 'Thu hồi thất bại')
    } finally {
      setReturning(false)
    }
  }

  const handleDelete = async () => {
    if (!asset || !assetId) return
    if (!confirm('Bạn có chắc muốn xóa hồ sơ này? Hành động này không thể hoàn tác.')) return

    try {
      await api.deleteAsset(assetId)
      navigate(`/category/${categoryId}`)
    } catch (err: any) {
      alert(err.message || 'Xóa thất bại')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <motion.div
          animate={{ opacity: [0.5, 1, 0.5] }}
          transition={{ repeat: Infinity, duration: 1 }}
          className="text-slate-500"
        >
          Đang tải thông tin...
        </motion.div>
      </div>
    )
  }

  if (error || !asset) {
    return (
      <div className="rounded-3xl border border-red-200 bg-red-50/90 backdrop-blur-sm p-8 text-center shadow-sm">
        <p className="text-red-800">{error || 'Không tìm thấy tài sản.'}</p>
        <Link
          to={categoryId ? `/category/${categoryId}` : '/'}
          className="mt-4 inline-flex items-center gap-2 text-indigo-600 hover:underline"
        >
          <ArrowLeft className="h-4 w-4" /> Quay lại danh sách
        </Link>
      </div>
    )
  }

  const safeCategoryId = (categoryId ?? 'laptop') as AssetCategoryId
  const statusMap: Record<string, 'available' | 'in_use' | 'maintenance' | 'retired'> = {
    AVAILABLE: 'available',
    IN_USE: 'in_use',
    MAINTENANCE: 'maintenance',
    RETIRED: 'retired',
  }

  const isLaptop = safeCategoryId === 'laptop'
  const isTechEquipment = safeCategoryId === 'tech_equipment'

  // Parse specification for laptop (CPU, RAM, OS)
  const parseSpecification = (spec?: string) => {
    if (!spec) return null
    const parts = spec.split(',').map(s => s.trim())
    return {
      cpu: parts.find(p => p.toLowerCase().includes('cpu') || p.toLowerCase().includes('intel') || p.toLowerCase().includes('amd')) || null,
      ram: parts.find(p => p.toLowerCase().includes('ram') || p.toLowerCase().includes('gb')) || null,
      os: parts.find(p => p.toLowerCase().includes('windows') || p.toLowerCase().includes('os')) || null,
    }
  }

  const spec = parseSpecification(asset.specification)

  const pageVariants = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    exit: { opacity: 0, y: -20 },
  }

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.05,
        duration: 0.3,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 },
  }

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={assetId}
        initial="initial"
        animate="animate"
        exit="exit"
        variants={pageVariants}
        transition={{ duration: 0.3, ease: 'easeOut' }}
        className="h-full flex flex-col overflow-hidden"
      >
        {/* Navigation Bar - Fixed */}
        <motion.div
          variants={itemVariants}
          className="flex-shrink-0 flex items-center justify-between mb-6"
        >
          <motion.div
            whileHover={{ x: -4 }}
            transition={{ type: 'spring', stiffness: 400, damping: 17 }}
          >
            <Link
              to={`/category/${safeCategoryId}`}
              className="inline-flex items-center gap-2 text-sm font-semibold text-slate-600 transition-colors hover:text-indigo-600"
            >
              <ArrowLeft className="h-4 w-4" />
              Quay lại danh sách
            </Link>
          </motion.div>

          {isAdmin && (
            <div className="flex items-center gap-3">
              <motion.button
                type="button"
                onClick={() => setIsEditModalOpen(true)}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="flex items-center gap-2 rounded-xl border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition-all hover:bg-slate-50"
              >
                <Edit className="h-4 w-4" />
                Sửa đổi
              </motion.button>
              <motion.button
                type="button"
                onClick={handleDelete}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className="flex items-center gap-2 rounded-xl bg-red-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition-all hover:bg-red-700"
              >
                <Trash2 className="h-4 w-4" />
                Xóa hồ sơ
              </motion.button>
            </div>
          )}
          {!isAdmin && (
            <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-4 py-2 text-xs font-semibold text-slate-500">
              Chế độ xem (Read-only)
            </div>
          )}
        </motion.div>

        {/* Main Grid Layout (2:1) - Scrollable */}
        <div className="flex-1 min-h-0 overflow-y-auto">
          <div className="grid gap-6 lg:grid-cols-3 pb-6">
            {/* Left Column - Main Info (2/3) */}
            <motion.div
              variants={containerVariants}
              initial="hidden"
              animate="visible"
              className="lg:col-span-2 space-y-6"
            >
            {/* Main Info Card */}
            <motion.div
              variants={itemVariants}
              className="relative overflow-hidden rounded-3xl border border-slate-200 bg-white p-8 shadow-xl"
            >
              {/* Decor Circles */}
              <div className="absolute -right-20 -top-20 h-40 w-40 rounded-full bg-indigo-100/30 blur-3xl" />
              <div className="absolute -bottom-10 -left-10 h-32 w-32 rounded-full bg-slate-100/50 blur-2xl" />

              <div className="relative">
                {/* Asset ID - Large and Bold */}
                <div className="mb-6">
                  <h1 className="text-4xl font-black tracking-tight text-indigo-900">
                    {asset.code}
                  </h1>
                  <p className="mt-1 text-sm font-medium text-slate-500">{asset.name}</p>
                </div>

                {/* Status Badge */}
                <div className="mb-6">
                  <StatusBadge status={statusMap[asset.status] || 'available'} />
                </div>

                {/* Hardware Info Grid */}
                <div className="grid gap-4 sm:grid-cols-2">
                  {asset.serialNumber && (
                    <div className="rounded-xl bg-slate-50 p-4">
                      <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">Serial</p>
                      <p className="mt-1 text-sm font-semibold text-slate-900">{asset.serialNumber}</p>
                    </div>
                  )}
                  {asset.model && (
                    <div className="rounded-xl bg-slate-50 p-4">
                      <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">Model</p>
                      <p className="mt-1 text-sm font-semibold text-slate-900">{asset.model}</p>
                    </div>
                  )}
                </div>

                {/* Dynamic Content Based on Category */}
                {isLaptop && spec && (
                  <motion.div
                    variants={itemVariants}
                    className="mt-6 rounded-xl bg-gradient-to-br from-indigo-50 to-blue-50 p-6"
                  >
                    <div className="mb-3 flex items-center gap-2">
                      <Cpu className="h-5 w-5 text-indigo-600" />
                      <h3 className="text-sm font-bold uppercase tracking-wider text-indigo-900">Cấu hình</h3>
                    </div>
                    <div className="space-y-2 text-sm">
                      {spec.cpu && (
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-slate-700">CPU:</span>
                          <span className="text-slate-900">{spec.cpu}</span>
                        </div>
                      )}
                      {spec.ram && (
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-slate-700">RAM:</span>
                          <span className="text-slate-900">{spec.ram}</span>
                        </div>
                      )}
                      {spec.os && (
                        <div className="flex items-center gap-2">
                          <span className="font-medium text-slate-700">OS:</span>
                          <span className="text-slate-900">{spec.os}</span>
                        </div>
                      )}
                      {!spec.cpu && !spec.ram && !spec.os && asset.specification && (
                        <div className="text-slate-700">{asset.specification}</div>
                      )}
                    </div>
                  </motion.div>
                )}

                {isTechEquipment && asset.department && (
                  <motion.div
                    variants={itemVariants}
                    className="mt-6 rounded-xl bg-gradient-to-br from-emerald-50 to-teal-50 p-6"
                  >
                    <div className="mb-3 flex items-center gap-2">
                      <MapPin className="h-5 w-5 text-emerald-600" />
                      <h3 className="text-sm font-bold uppercase tracking-wider text-emerald-900">Khu vực quản lý</h3>
                    </div>
                    <p className="text-sm font-semibold text-emerald-900">{asset.department.name}</p>
                  </motion.div>
                )}

                {/* Inspection Date */}
                {asset.inspectionDate && (
                  <div className="mt-6 flex items-center gap-2 text-sm text-slate-600">
                    <Clock className="h-4 w-4" />
                    <span>Ngày kiểm tra: {new Date(asset.inspectionDate).toLocaleDateString('vi-VN')}</span>
                  </div>
                )}
              </div>
            </motion.div>

            {/* Admin Notes - Dark Background */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl bg-slate-900 p-6 shadow-xl"
            >
              <h3 className="mb-3 text-sm font-bold uppercase tracking-wider text-slate-400">
                Ghi chú Nghiệp vụ
              </h3>
              <p className="text-sm leading-relaxed text-slate-200">
                {asset.note || 'Không có lưu ý đặc biệt. Hệ thống hoạt động bình thường.'}
              </p>
            </motion.div>
          </motion.div>

          {/* Right Column - Operational Sidebar (1/3) */}
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="space-y-6"
          >
            {/* User Info Card */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl border border-slate-200 bg-white p-6 shadow-xl"
            >
              <h3 className="mb-4 text-sm font-bold uppercase tracking-wider text-slate-500">
                Thông tin Vận hành
              </h3>

              {/* User Info */}
              <div className="mb-6 space-y-3">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">Người đang giữ</p>
                  <p className="mt-1 text-base font-bold text-slate-900">
                    {asset.assignedUser?.name || asset.assignedTo || 'Chưa cấp phát'}
                  </p>
                </div>
                {asset.department && (
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">Phòng ban</p>
                    <p className="mt-1 text-sm font-semibold text-slate-700">{asset.department.name}</p>
                  </div>
                )}
                {asset.assignedUser?.branch && (
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">Chi nhánh</p>
                    <p className="mt-1 text-sm font-semibold text-slate-700">{asset.assignedUser.branch}</p>
                  </div>
                )}
              </div>

              {/* Action Buttons - Only for Admin */}
              {isAdmin && (
                <div className="space-y-3">
                  <motion.button
                    type="button"
                    onClick={handleAssign}
                    disabled={assigning || asset.status === 'IN_USE'}
                    whileHover={assigning !== true && asset.status !== 'IN_USE' ? { scale: 1.02 } : {}}
                    whileTap={{ scale: 0.98 }}
                    className="w-full rounded-xl bg-indigo-600 px-4 py-3 text-sm font-bold text-white shadow-lg transition-all hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    <div className="flex items-center justify-center gap-2">
                      <UserPlus className="h-4 w-4" />
                      {assigning ? 'Đang xử lý...' : 'Cấp phát'}
                    </div>
                  </motion.button>

                  <motion.button
                    type="button"
                    onClick={handleReturn}
                    disabled={returning || asset.status !== 'IN_USE'}
                    whileHover={returning !== true && asset.status === 'IN_USE' ? { scale: 1.02 } : {}}
                    whileTap={{ scale: 0.98 }}
                    className="w-full rounded-xl border-2 border-slate-300 bg-white px-4 py-3 text-sm font-bold text-slate-700 shadow-md transition-all hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    <div className="flex items-center justify-center gap-2">
                      <RotateCcw className="h-4 w-4" />
                      {returning ? 'Đang xử lý...' : 'Thu hồi'}
                    </div>
                  </motion.button>
                </div>
              )}
              {!isAdmin && (
                <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-center">
                  <p className="text-xs font-medium text-slate-500">
                    Chỉ IT Admin mới có quyền cấp phát và thu hồi tài sản
                  </p>
                </div>
              )}
            </motion.div>

            {/* Timeline */}
            <motion.div
              variants={itemVariants}
              className="rounded-3xl border border-slate-200 bg-white p-6 shadow-xl"
            >
              <h3 className="mb-4 text-sm font-bold uppercase tracking-wider text-slate-500">
                Nhật ký hoạt động
              </h3>
              <div className="space-y-4">
                {/* Timeline Item */}
                <div className="relative pl-6 before:absolute before:left-0 before:top-2 before:h-full before:w-0.5 before:bg-slate-200">
                  <div className="absolute left-0 top-0 h-3 w-3 rounded-full bg-indigo-600" />
                  <p className="text-xs font-semibold text-slate-900">Tài sản được tạo</p>
                  <p className="mt-1 text-xs text-slate-500">
                    {new Date(asset.createdAt).toLocaleDateString('vi-VN', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                  </p>
                </div>
                {asset.inspectionDate && (
                  <div className="relative pl-6 before:absolute before:left-0 before:top-2 before:h-full before:w-0.5 before:bg-slate-200">
                    <div className="absolute left-0 top-0 h-3 w-3 rounded-full bg-emerald-600" />
                    <p className="text-xs font-semibold text-slate-900">Kiểm tra định kỳ</p>
                    <p className="mt-1 text-xs text-slate-500">
                      {new Date(asset.inspectionDate).toLocaleDateString('vi-VN', {
                        year: 'numeric',
                        month: 'long',
                        day: 'numeric',
                      })}
                    </p>
                  </div>
                )}
                {asset.status === 'IN_USE' && asset.assignedUser && (
                  <div className="relative pl-6">
                    <div className="absolute left-0 top-0 h-3 w-3 rounded-full bg-blue-600" />
                    <p className="text-xs font-semibold text-slate-900">Đang sử dụng</p>
                    <p className="mt-1 text-xs text-slate-500">Bởi {asset.assignedUser.name}</p>
                  </div>
                )}
              </div>
            </motion.div>
          </motion.div>
          </div>
        </div>

        {/* Edit Modal */}
        {isEditModalOpen && asset && (
          <AssetFormModal
            isOpen={isEditModalOpen}
            onClose={() => setIsEditModalOpen(false)}
            onSuccess={() => {
              loadAsset()
              setIsEditModalOpen(false)
            }}
            asset={asset}
            categoryId={safeCategoryId}
          />
        )}
      </motion.div>
    </AnimatePresence>
  )
}
