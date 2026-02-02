import { motion } from 'framer-motion'
import { STATUS_LABELS, STATUS_STYLES } from '../types'
import type { AssetStatus } from '../types'

interface StatusBadgeProps {
  status: AssetStatus
}

export function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <motion.span
      initial={{ scale: 0.8, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      whileHover={{ scale: 1.1 }}
      className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold backdrop-blur-sm ${STATUS_STYLES[status]}`}
    >
      {STATUS_LABELS[status]}
    </motion.span>
  )
}
