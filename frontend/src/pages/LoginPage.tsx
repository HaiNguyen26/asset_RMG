import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion, AnimatePresence } from 'framer-motion'
import { useAuth } from '../contexts/AuthContext'

export function LoginPage() {
  const [employeesCode, setEmployeesCode] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(employeesCode, password)
      navigate('/category/laptop')
    } catch (err: any) {
      setError(err.message || 'Đăng nhập thất bại. Vui lòng kiểm tra lại mã nhân viên và mật khẩu.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-slate-100">
      <motion.div
        initial={{ opacity: 0, scale: 0.9, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ type: 'spring', stiffness: 400, damping: 25 }}
        className="w-full max-w-md rounded-3xl border border-slate-200/50 bg-white/90 backdrop-blur-md p-8 shadow-2xl"
      >
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1, type: 'spring', stiffness: 300 }}
          className="mb-6 flex flex-col items-center justify-center gap-4"
        >
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="flex h-24 w-24 items-center justify-center rounded-2xl overflow-hidden shadow-lg bg-white p-2"
          >
            <img
              src="/RMG-logo.jpg"
              alt="RMG Logo"
              className="h-full w-full object-contain"
            />
          </motion.div>
          <motion.h1
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.15 }}
            className="text-center text-2xl font-black uppercase tracking-tight text-slate-800"
          >
            Quản Trị Tài Sản
          </motion.h1>
        </motion.div>
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="mb-6 text-center text-sm text-slate-500"
        >
          Đăng nhập bằng mã nhân viên và mật khẩu
        </motion.p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.25 }}
          >
            <label htmlFor="employeesCode" className="mb-2 block text-sm font-medium text-slate-700">
              Mã nhân viên
            </label>
            <motion.input
              id="employeesCode"
              type="text"
              value={employeesCode}
              onChange={(e) => setEmployeesCode(e.target.value)}
              placeholder="Nhập mã nhân viên"
              required
              whileFocus={{ scale: 1.02 }}
              className="w-full rounded-2xl border border-slate-200 bg-white/90 backdrop-blur-sm px-4 py-3 text-slate-800 shadow-sm placeholder:text-slate-400 transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:bg-white"
              autoFocus
            />
          </motion.div>
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
          >
            <label htmlFor="password" className="mb-2 block text-sm font-medium text-slate-700">
              Mật khẩu
            </label>
            <motion.input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Nhập mật khẩu"
              required
              whileFocus={{ scale: 1.02 }}
              className="w-full rounded-2xl border border-slate-200 bg-white/90 backdrop-blur-sm px-4 py-3 text-slate-800 shadow-sm placeholder:text-slate-400 transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:bg-white"
            />
          </motion.div>

          <AnimatePresence>
            {error && (
              <motion.div
                initial={{ opacity: 0, y: -10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -10, scale: 0.95 }}
                className="rounded-2xl border border-red-200 bg-red-50/90 backdrop-blur-sm px-4 py-3 text-sm text-red-800"
              >
                {error}
              </motion.div>
            )}
          </AnimatePresence>

          <motion.button
            type="submit"
            disabled={loading}
            whileHover={{ scale: loading ? 1 : 1.02, boxShadow: loading ? 'none' : '0 10px 25px rgba(99, 102, 241, 0.3)' }}
            whileTap={{ scale: 0.98 }}
            className="w-full rounded-2xl bg-indigo-600 px-4 py-3 text-sm font-semibold text-white shadow-lg transition-all hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
          >
            {loading ? 'Đang đăng nhập...' : 'Đăng nhập'}
          </motion.button>
        </form>
      </motion.div>
    </div>
  )
}
