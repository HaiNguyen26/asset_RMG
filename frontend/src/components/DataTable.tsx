import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import { StatusBadge } from './StatusBadge'
import { AssetFormModal } from './AssetFormModal'
import { api } from '../services/api'
import type { Asset as ApiAsset } from '../services/api'
import type { AssetCategoryId } from '../types'

interface DataTableProps {
  assets: ApiAsset[]
  categoryId: AssetCategoryId
  onRefresh?: () => void
}

const thClass =
  'text-left text-xs font-extrabold uppercase tracking-wider text-slate-500 px-4 py-3 first:rounded-l-2xl last:rounded-r-2xl whitespace-nowrap'

const tdClass = 'px-4 py-3.5 text-slate-600 text-sm whitespace-nowrap'

export function DataTable({ assets, categoryId, onRefresh }: DataTableProps) {
  const navigate = useNavigate()

  const handleRowClick = (assetId: string) => {
    navigate(`/category/${categoryId}/asset/${assetId}`)
  }

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.02,
      },
    },
  }

  const rowVariants = {
    hidden: { opacity: 0, y: 20, scale: 0.95 },
    visible: {
      opacity: 1,
      y: 0,
      scale: 1,
      transition: {
        type: 'spring' as const,
        stiffness: 150,
        damping: 20,
      },
    },
  }

  return (
    <>
    <motion.div
      initial="hidden"
      animate="visible"
      variants={containerVariants}
      className="h-full flex flex-col overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-sm"
    >
      <div className="flex-1 overflow-x-auto overflow-y-auto">
        <table className="w-full border-collapse" style={{ minWidth: '1200px' }}>
        <thead>
          <tr className="border-b border-slate-200 bg-slate-50/80 sticky top-0 z-10">
            <th className={thClass + ' w-32'}>Mã laptop</th>
            <th className={thClass + ' w-40'}>Người sử dụng</th>
            <th className={thClass + ' w-48'}>Tên thiết bị</th>
            <th className={thClass + ' w-32'}>Serial</th>
            <th className={thClass + ' w-64'}>Cấu hình</th>
            <th className={thClass + ' w-32'}>Mã nhân viên</th>
            <th className={thClass + ' w-32'}>Phòng ban</th>
            <th className={thClass + ' w-32'}>Chi nhánh</th>
            <th className={thClass + ' w-32'}>Ngày kiểm tra</th>
            <th className={thClass + ' w-32'}>Trạng thái</th>
          </tr>
        </thead>
        <tbody>
          {assets.map((asset) => (
            <motion.tr
              key={asset.id}
              variants={rowVariants}
              whileHover={{ scale: 1.01, backgroundColor: 'rgba(241, 245, 249, 0.8)' }}
              onClick={() => handleRowClick(asset.id)}
              className="group border-b border-slate-100 last:border-0 transition-all cursor-pointer"
            >
              <td className={tdClass + ' font-medium text-slate-800'}>{asset.code}</td>
              <td className={tdClass}>
                <span className="truncate block" title={asset.assignedUser?.name || asset.assignedTo || undefined}>
                  {asset.assignedUser?.name || asset.assignedTo || '—'}
                </span>
              </td>
              <td className={tdClass + ' text-slate-700'}>
                <span className="font-medium truncate block" title={asset.name}>{asset.name}</span>
              </td>
              <td className={tdClass}>
                <span className="truncate block" title={asset.serialNumber || undefined}>{asset.serialNumber ?? '—'}</span>
              </td>
              <td className={tdClass}>
                <span className="truncate block" title={asset.specification || undefined}>{asset.specification ?? '—'}</span>
              </td>
              <td className={tdClass}>
                {asset.assignedUser?.employeesCode || asset.employeesCode || '—'}
              </td>
              <td className={tdClass}>
                {asset.department?.name ?? '—'}
              </td>
              <td className={tdClass}>
                {asset.assignedUser?.branch ?? '—'}
              </td>
              <td className={tdClass}>
                {asset.inspectionDate
                  ? new Date(asset.inspectionDate).toLocaleDateString('vi-VN')
                  : '—'}
              </td>
              <td className={tdClass}>
                <StatusBadge
                  status={
                    asset.status === 'AVAILABLE'
                      ? 'available'
                      : asset.status === 'IN_USE'
                        ? 'in_use'
                        : asset.status === 'MAINTENANCE'
                          ? 'maintenance'
                          : 'retired'
                  }
                />
              </td>
            </motion.tr>
          ))}
        </tbody>
      </table>
      {assets.length === 0 && (
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="py-16 text-center text-slate-500"
        >
          Không có tài sản nào phù hợp với bộ lọc.
        </motion.div>
      )}
      </div>
      </motion.div>
    </>
  )
}
