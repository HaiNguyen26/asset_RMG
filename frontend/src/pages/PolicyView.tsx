import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { Search, FileText, Shield, AlertCircle, Wrench, XCircle } from 'lucide-react'
import { api } from '../services/api'
import { useAuth } from '../contexts/AuthContext'

const POLICY_CATEGORIES = [
  { category: 'equipment-assignment', title: 'Cấp phát thiết bị', icon: Shield },
  { category: 'user-responsibility', title: 'Trách nhiệm người dùng', icon: AlertCircle },
  { category: 'repair-replacement', title: 'Sửa chữa & thay thế', icon: Wrench },
  { category: 'equipment-return', title: 'Thu hồi thiết bị', icon: XCircle },
  { category: 'penalty-compensation', title: 'Phạt & bồi thường', icon: FileText },
]

export function PolicyView() {
  const { user } = useAuth()
  const isAdmin = user?.role === 'ADMIN'

  const [policies, setPolicies] = useState<any[]>([])
  const [selectedCategory, setSelectedCategory] = useState<string>('equipment-assignment')
  const [selectedPolicy, setSelectedPolicy] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [searchQuery, setSearchQuery] = useState('')

  useEffect(() => {
    loadPolicies()
  }, [])

  useEffect(() => {
    if (selectedCategory && policies.length > 0) {
      const policy = policies.find((p) => p.category === selectedCategory)
      if (policy) {
        setSelectedPolicy(policy)
      } else {
        setSelectedPolicy(null)
      }
    }
  }, [selectedCategory, policies])

  const loadPolicies = async () => {
    try {
      setLoading(true)
      setError('')
      const data = await api.getPolicies()
      setPolicies(data)
      if (data.length > 0 && !selectedPolicy) {
        const firstPolicy = data.find((p) => p.category === selectedCategory) || data[0]
        setSelectedPolicy(firstPolicy)
        setSelectedCategory(firstPolicy.category)
      }
    } catch (err: any) {
      setError(err.message || 'Không thể tải dữ liệu')
    } finally {
      setLoading(false)
    }
  }

  const handleCategoryClick = (category: string) => {
    setSelectedCategory(category)
    const policy = policies.find((p) => p.category === category)
    if (policy) {
      setSelectedPolicy(policy)
    } else {
      setSelectedPolicy(null)
    }
  }

  const highlightSearch = (text: string, query: string) => {
    if (!query.trim()) return text
    const parts = text.split(new RegExp(`(${query})`, 'gi'))
    return parts.map((part, i) =>
      part.toLowerCase() === query.toLowerCase() ? (
        <mark key={i} className="bg-yellow-200 rounded px-1">
          {part}
        </mark>
      ) : (
        part
      ),
    )
  }

  const highlightSearchHTML = (html: string, query: string): string => {
    if (!query.trim()) return html
    // Only highlight in text content, not in HTML tags
    return html.replace(
      new RegExp(`(?![^<]*>)([^<]*?)(${query})([^<]*?)(?![^<]*>)`, 'gi'),
      (match, before, found, after) => {
        return `${before}<mark class="bg-yellow-200 rounded px-1">${found}</mark>${after}`
      }
    )
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
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 10 },
    visible: { opacity: 1, y: 0 },
  }

  return (
    <motion.div
      initial="hidden"
      animate="visible"
      variants={containerVariants}
      className="h-full flex flex-col overflow-hidden"
    >
      {/* Header */}
      <motion.div
        variants={itemVariants}
        className="flex-shrink-0 mb-6"
      >
        <h1 className="mb-2 text-2xl font-bold text-slate-800">Chính Sách Sử Dụng Thiết Bị</h1>
        <p className="text-sm text-slate-500">Áp dụng tại: Công ty RMG Vietnam</p>
      </motion.div>

      <div className="flex-1 min-h-0 flex gap-6 overflow-hidden">
        {/* Sidebar - Categories */}
        <motion.div
          variants={itemVariants}
          className="w-64 flex-shrink-0 flex flex-col"
        >
          <div className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm shadow-sm overflow-hidden flex-1 flex flex-col">
            <div className="p-4 border-b border-slate-200">
              <h2 className="text-sm font-semibold text-slate-700 uppercase tracking-wider mb-3">Danh mục</h2>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  placeholder="Tìm kiếm..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full rounded-lg border border-slate-300 bg-white py-2 pl-10 pr-3 text-sm focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                />
              </div>
            </div>
            <div className="flex-1 overflow-y-auto p-2">
              {POLICY_CATEGORIES.map((cat) => {
                const Icon = cat.icon
                const isActive = selectedCategory === cat.category
                return (
                  <motion.button
                    key={cat.category}
                    whileHover={{ scale: 1.02 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => handleCategoryClick(cat.category)}
                    className={`w-full text-left rounded-xl px-4 py-3 mb-2 transition-all ${
                      isActive
                        ? 'bg-indigo-50 border border-indigo-200 text-indigo-700'
                        : 'hover:bg-slate-50 text-slate-700'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className={`h-5 w-5 ${isActive ? 'text-indigo-600' : 'text-slate-400'}`} />
                      <span className="text-sm font-medium">{cat.title}</span>
                    </div>
                  </motion.button>
                )
              })}
            </div>
          </div>
        </motion.div>

        {/* Main Content */}
        <motion.div
          variants={itemVariants}
          className="flex-1 min-h-0 overflow-y-auto"
        >
          {selectedPolicy ? (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-8 shadow-sm h-full"
            >
              <h2 className="mb-6 text-3xl font-bold text-slate-800">{selectedPolicy.title}</h2>
              <div className="prose prose-slate max-w-none">
                <div 
                  className="text-slate-700 leading-relaxed"
                  dangerouslySetInnerHTML={{ 
                    __html: highlightSearchHTML(selectedPolicy.content, searchQuery) 
                  }}
                />
              </div>
              {isAdmin && (
                <div className="mt-8 pt-6 border-t border-slate-200">
                  <p className="text-xs text-slate-500">
                    Cập nhật lần cuối: {new Date(selectedPolicy.updatedAt).toLocaleDateString('vi-VN')}
                    {selectedPolicy.updatedBy && ` bởi ${selectedPolicy.updatedBy.name}`}
                  </p>
                </div>
              )}
            </motion.div>
          ) : (
            <div className="rounded-3xl border border-slate-200 bg-white/90 backdrop-blur-sm p-8 shadow-sm h-full flex items-center justify-center">
              <div className="text-center text-slate-500">
                <FileText className="h-12 w-12 mx-auto mb-4 text-slate-400" />
                <p>Chưa có nội dung cho danh mục này.</p>
                {isAdmin && <p className="text-sm mt-2">Vui lòng thêm nội dung chính sách.</p>}
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </motion.div>
  )
}
