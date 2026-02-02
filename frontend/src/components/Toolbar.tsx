import { useEffect, useState } from 'react'
import { Search } from 'lucide-react'
import { motion } from 'framer-motion'
import { api } from '../services/api'
import { STATUS_LABELS } from '../types'
import type { AssetStatus } from '../types'
import type { Department } from '../services/api'

interface ToolbarProps {
  search: string
  onSearchChange: (v: string) => void
  statusFilter: AssetStatus | ''
  onStatusFilterChange: (v: AssetStatus | '') => void
  departmentFilter: string
  onDepartmentFilterChange: (v: string) => void
}

export function Toolbar({
  search,
  onSearchChange,
  statusFilter,
  onStatusFilterChange,
  departmentFilter,
  onDepartmentFilterChange,
}: ToolbarProps) {
  const [departments, setDepartments] = useState<Department[]>([])

  useEffect(() => {
    api
      .getDepartments()
      .then(setDepartments)
      .catch(() => {
        // Silently fail - departments filter will be empty
      })
  }, [])
  return (
    <div className="mb-4 flex flex-wrap items-center gap-3">
      {/* Search Box */}
      <motion.div
        whileHover={{ scale: 1.02 }}
        whileFocus={{ scale: 1.02 }}
        className="relative flex-1 min-w-[200px] max-w-md"
      >
        <Search className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
        <input
          type="search"
          placeholder="Tìm theo mã hoặc tên..."
          value={search}
          onChange={(e) => onSearchChange(e.target.value)}
          className="w-full rounded-2xl border border-slate-200 bg-white/90 backdrop-blur-sm py-2.5 pl-11 pr-4 text-sm text-slate-800 shadow-sm placeholder:text-slate-400 transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:bg-white"
        />
      </motion.div>

      {/* Status Filter */}
      <motion.select
        whileHover={{ scale: 1.05 }}
        whileFocus={{ scale: 1.05 }}
        value={statusFilter}
        onChange={(e) => onStatusFilterChange((e.target.value || '') as AssetStatus | '')}
        className="rounded-2xl border border-slate-200 bg-white/90 backdrop-blur-sm px-4 py-2.5 text-sm text-slate-700 shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:bg-white"
      >
        <option value="">Trạng thái</option>
        {(Object.entries(STATUS_LABELS) as [AssetStatus, string][]).map(([value, label]) => (
          <option key={value} value={value}>
            {label}
          </option>
        ))}
      </motion.select>

      {/* Department Filter */}
      <motion.select
        whileHover={{ scale: 1.05 }}
        whileFocus={{ scale: 1.05 }}
        value={departmentFilter}
        onChange={(e) => onDepartmentFilterChange(e.target.value)}
        className="rounded-2xl border border-slate-200 bg-white/90 backdrop-blur-sm px-4 py-2.5 text-sm text-slate-700 shadow-sm transition-all focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:bg-white"
      >
        <option value="">Phòng ban</option>
        {departments.map((d) => (
          <option key={d.id} value={d.id}>
            {d.name}
          </option>
        ))}
      </motion.select>
    </div>
  )
}
