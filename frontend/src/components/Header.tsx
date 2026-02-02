import { useState, useEffect } from 'react'
import { Plus, Laptop, Mouse, Wrench, Clock } from 'lucide-react'
import { motion } from 'framer-motion'
import { ASSET_CATEGORIES } from '../types'
import { ImportExcel } from './ImportExcel'
import type { AssetCategoryId } from '../types'

interface HeaderProps {
  categoryId: AssetCategoryId
  onAddAsset?: () => void
  onRefresh?: () => void
}

const iconMap = { Laptop, Mouse, Wrench }

const categoryGradients: Record<AssetCategoryId, string> = {
  laptop: 'from-blue-500 to-indigo-600',
  it_accessory: 'from-purple-500 to-pink-600',
  tech_equipment: 'from-orange-500 to-red-600',
}

export function Header({ categoryId, onAddAsset, onRefresh }: HeaderProps) {
  const category = ASSET_CATEGORIES.find((c) => c.id === categoryId) ?? ASSET_CATEGORIES[0]
  const Icon = iconMap[category.icon as keyof typeof iconMap] ?? Laptop
  const gradient = categoryGradients[categoryId] || categoryGradients.laptop

  const [currentTime, setCurrentTime] = useState(new Date())

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)

    return () => clearInterval(timer)
  }, [])

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('vi-VN', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    })
  }

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('vi-VN', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  return (
    <motion.header
      key={categoryId}
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
      className="sticky top-0 z-20 relative overflow-hidden"
    >
      {/* Background with gradient overlay */}
      <div className={`absolute inset-0 bg-gradient-to-r ${gradient} opacity-5`} />
      <div className="absolute inset-0 bg-white/90 backdrop-blur-xl" />
      
      {/* Decorative elements */}
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-indigo-500/30 to-transparent" />
      <div className="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-slate-300/50 to-transparent" />
      
      <div className="relative flex items-center justify-between px-6 py-4">
        {/* Dynamic Context - Left */}
        <motion.div
          key={`${categoryId}-context`}
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.3, ease: 'easeOut' }}
          className="flex items-center gap-4"
        >
          {/* Icon Box with Enhanced Gradient */}
          <motion.div
            whileHover={{ scale: 1.08, rotate: [0, -5, 5, 0] }}
            transition={{ duration: 0.3 }}
            className={`relative flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br ${gradient} shadow-xl shadow-indigo-500/20`}
          >
            {/* Shine effect */}
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-white/30 to-transparent" />
            {/* Glow effect */}
            <div className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${gradient} opacity-50 blur-xl`} />
            <Icon className="relative h-7 w-7 text-white drop-shadow-lg" />
            
            {/* Animated ring */}
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
              className="absolute inset-0 rounded-2xl border-2 border-white/20"
            />
          </motion.div>

          <div className="relative">
            <div className="flex items-center gap-3">
              <motion.h1
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.1 }}
                className="text-xl font-black text-slate-900 tracking-tight"
              >
                {category.name}
              </motion.h1>
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
                className="relative"
              >
                <motion.div
                  animate={{ scale: [1, 1.3, 1], opacity: [1, 0.5, 1] }}
                  transition={{ repeat: Infinity, duration: 2 }}
                  className="h-2.5 w-2.5 rounded-full bg-emerald-500 shadow-lg shadow-emerald-500/50"
                />
                <motion.div
                  animate={{ scale: [1, 1.5, 1], opacity: [0.5, 0, 0.5] }}
                  transition={{ repeat: Infinity, duration: 2 }}
                  className="absolute inset-0 h-2.5 w-2.5 rounded-full bg-emerald-400"
                />
              </motion.div>
            </div>
            <motion.div
              initial={{ opacity: 0, y: -5 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15 }}
              className="flex items-center gap-2 mt-1"
            >
              <div className="h-1 w-1 rounded-full bg-slate-400" />
              <p className="text-xs font-semibold text-slate-600 uppercase tracking-wider">
                Danh mục đang hoạt động
              </p>
            </motion.div>
          </div>
        </motion.div>

        {/* Action - Right */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.3, ease: 'easeOut' }}
          className="flex items-center gap-3"
        >
          {/* Real-time Clock - Enhanced */}
          <motion.div
            whileHover={{ scale: 1.02 }}
            className="relative flex items-center gap-3 rounded-xl border border-slate-200/80 bg-white/95 backdrop-blur-md px-4 py-2.5 shadow-lg shadow-slate-200/50 overflow-hidden"
          >
            {/* Background gradient */}
            <div className="absolute inset-0 bg-gradient-to-br from-indigo-50/50 to-purple-50/30" />
            
            {/* Animated border glow */}
            <motion.div
              animate={{ opacity: [0.5, 1, 0.5] }}
              transition={{ repeat: Infinity, duration: 3 }}
              className="absolute inset-0 rounded-xl border border-indigo-200/50"
            />
            
            <div className="relative flex items-center gap-2.5">
              <motion.div
                animate={{ rotate: [0, 360] }}
                transition={{ duration: 60, repeat: Infinity, ease: 'linear' }}
                className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 shadow-md"
              >
                <Clock className="h-4 w-4 text-white" />
              </motion.div>
              <div className="flex flex-col">
                <motion.span
                  key={formatTime(currentTime)}
                  initial={{ opacity: 0.7 }}
                  animate={{ opacity: 1 }}
                  transition={{ duration: 0.2 }}
                  className="text-sm font-bold text-slate-900 tabular-nums tracking-tight"
                >
                  {formatTime(currentTime)}
                </motion.span>
                <span className="text-xs font-medium text-slate-600 leading-tight">
                  {formatDate(currentTime)}
                </span>
              </div>
            </div>
          </motion.div>

          <ImportExcel categoryId={categoryId} onSuccess={onRefresh} />
          
          <motion.button
            type="button"
            onClick={onAddAsset}
            whileHover={{ scale: 1.05, boxShadow: '0 10px 25px rgba(0, 0, 0, 0.2)' }}
            whileTap={{ scale: 0.95 }}
            className="relative flex items-center gap-2 rounded-2xl bg-gradient-to-r from-slate-900 to-slate-800 px-6 py-2.5 text-sm font-bold text-white shadow-xl shadow-slate-900/30 transition-all hover:from-slate-800 hover:to-slate-700 overflow-hidden group"
          >
            {/* Shine effect on hover */}
            <motion.div
              className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent"
              initial={{ x: '-100%' }}
              whileHover={{ x: '100%' }}
              transition={{ duration: 0.6 }}
            />
            
            <Plus className="h-4 w-4 relative z-10 group-hover:rotate-90 transition-transform duration-300" />
            <span className="relative z-10">Thêm tài sản</span>
            
            {/* Glow effect */}
            <div className="absolute inset-0 rounded-2xl bg-white/10 blur-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
          </motion.button>
        </motion.div>
      </div>
    </motion.header>
  )
}
