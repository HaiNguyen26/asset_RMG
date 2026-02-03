import { Link, useParams, useNavigate, useLocation } from 'react-router-dom'
import { Laptop, Mouse, Wrench, User, LogOut, History, FileText } from 'lucide-react'
import { motion } from 'framer-motion'
import { useAuth } from '../contexts/AuthContext'
import { ASSET_CATEGORIES } from '../types'

const iconMap = { Laptop, Mouse, Wrench }

export function Sidebar() {
  const { categoryId } = useParams<{ categoryId: string }>()
  const location = useLocation()
  const currentCategory = categoryId ?? 'laptop'
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const isRepairHistoryActive = location.pathname.startsWith('/repair-history')
  const isPolicyActive = location.pathname.startsWith('/policies')

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <aside className="fixed left-0 top-0 z-30 flex h-screen w-64 flex-col border-r border-slate-200 bg-white shadow-sm">
      {/* Branding */}
      <motion.div
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.3 }}
        className="flex flex-col items-center justify-center gap-2 border-b border-slate-200 px-5 py-4"
      >
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="flex h-16 w-16 shrink-0 items-center justify-center rounded-xl overflow-hidden shadow-lg shadow-indigo-200"
        >
          <img
            src={`${import.meta.env.BASE_URL}RMG-logo.jpg`}
            alt="RMG Logo"
            className="h-full w-full object-contain"
          />
        </motion.div>
        <div className="text-center">
          <motion.h1
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="font-black uppercase tracking-tighter text-slate-900 text-lg leading-tight"
          >
            ASSET PRO
          </motion.h1>
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.2 }}
            className="text-[10px] font-bold uppercase tracking-[0.2em] text-slate-500 mt-0.5"
          >
            QUẢN TRỊ HỆ THỐNG
          </motion.p>
        </div>
      </motion.div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto px-3 py-4">
        <ul className="relative space-y-1">
          {ASSET_CATEGORIES.map((cat) => {
            const Icon = iconMap[cat.icon as keyof typeof iconMap] ?? Laptop
            const isActive = currentCategory === cat.id && !isRepairHistoryActive && !isPolicyActive
            return (
              <li key={cat.id} className="relative">
                {isActive && (
                  <motion.div
                    layoutId="activeNav"
                    className="absolute inset-0 rounded-2xl bg-indigo-600 shadow-md"
                    initial={false}
                    transition={{
                      type: 'spring',
                      stiffness: 500,
                      damping: 25,
                    }}
                  />
                )}
                <Link
                  to={`/category/${cat.id}`}
                  className={`relative flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition-colors ${
                    isActive
                      ? 'text-white'
                      : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                  }`}
                >
                  <Icon className="h-5 w-5 shrink-0" />
                  <span>{cat.name}</span>
                </Link>
              </li>
            )
          })}

          {/* Divider */}
          <li className="my-3 border-t border-slate-200" />

          {/* Repair History */}
          <li className="relative">
            {isRepairHistoryActive && (
              <motion.div
                layoutId="activeNav"
                className="absolute inset-0 rounded-2xl bg-indigo-600 shadow-md"
                initial={false}
                transition={{
                  type: 'spring',
                  stiffness: 500,
                  damping: 25,
                }}
              />
            )}
            <Link
              to="/repair-history"
              className={`relative flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition-colors ${
                isRepairHistoryActive
                  ? 'text-white'
                  : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
              }`}
            >
              <History className="h-5 w-5 shrink-0" />
              <span>Lịch Sử Sửa Chữa</span>
            </Link>
          </li>

          {/* Policy */}
          <li className="relative">
            {isPolicyActive && (
              <motion.div
                layoutId="activeNav"
                className="absolute inset-0 rounded-2xl bg-indigo-600 shadow-md"
                initial={false}
                transition={{
                  type: 'spring',
                  stiffness: 500,
                  damping: 25,
                }}
              />
            )}
            <Link
              to="/policies"
              className={`relative flex items-center gap-3 rounded-2xl px-4 py-3 text-sm font-medium transition-colors ${
                isPolicyActive
                  ? 'text-white'
                  : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
              }`}
            >
              <FileText className="h-5 w-5 shrink-0" />
              <span>Chính Sách</span>
            </Link>
          </li>
        </ul>
      </nav>

      {/* User Profile Card */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1, duration: 0.2 }}
        className="border-t border-slate-200 p-4"
      >
        <motion.div
          whileHover={{ scale: 1.02 }}
          className="rounded-3xl bg-slate-900 px-4 py-3 shadow-lg"
        >
          <div className="flex items-center gap-3">
            <motion.div
              whileHover={{ scale: 1.1, rotate: 360 }}
              transition={{ duration: 0.3 }}
              className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-indigo-500 text-white"
            >
              <User className="h-5 w-5" />
            </motion.div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-white">{user?.name || 'User'}</p>
              <div className="flex items-center gap-1.5 text-xs text-slate-400">
                <motion.span
                  animate={{ scale: [1, 1.2, 1] }}
                  transition={{ repeat: Infinity, duration: 2 }}
                  className="flex h-1.5 w-1.5 rounded-full bg-emerald-400"
                />
                <span>{user?.employeesCode || '—'}</span>
              </div>
              {user?.branch && (
                <div className="mt-1 text-xs text-slate-500">
                  {user.branch}
                </div>
              )}
            </div>
          </div>
          <motion.button
            onClick={handleLogout}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="mt-2 flex w-full items-center gap-2 rounded-xl px-3 py-2 text-xs text-slate-400 transition hover:bg-slate-800 hover:text-white"
            title="Đăng xuất"
          >
            <LogOut className="h-4 w-4" />
            <span>Đăng xuất</span>
          </motion.button>
        </motion.div>
      </motion.div>
    </aside>
  )
}
