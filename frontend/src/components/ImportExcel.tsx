import { useState } from 'react'
import { Upload } from 'lucide-react'
import { motion, AnimatePresence } from 'framer-motion'
import { api } from '../services/api'
import type { AssetCategoryId } from '../types'

interface ImportExcelProps {
  categoryId?: AssetCategoryId
  onSuccess?: () => void
}

export function ImportExcel({ categoryId, onSuccess }: ImportExcelProps) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [errorDetails, setErrorDetails] = useState<any[]>([])

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    if (!file.name.endsWith('.xlsx') && !file.name.endsWith('.xls')) {
      setError('Vui lòng chọn file Excel (.xlsx hoặc .xls)')
      return
    }

    try {
      setLoading(true)
      setError('')
      setSuccess('')
      setErrorDetails([])

      const result = await api.importExcel(file, categoryId)
      
      if (result.errorDetails && result.errorDetails.length > 0) {
        setErrorDetails(result.errorDetails)
      }
      
      if (result.success === 0) {
        // No records imported
        const errorMsg = result.message || 'Không có dữ liệu nào được import. Vui lòng kiểm tra format file Excel.'
        setError(errorMsg)
      } else {
        setSuccess(
          result.message || `Import thành công: ${result.success} bản ghi. ${result.errorCount > 0 ? `${result.errorCount} lỗi.` : ''}`,
        )
        if (onSuccess) {
          setTimeout(() => {
            onSuccess()
            setSuccess('')
            setErrorDetails([])
          }, 2000)
        }
      }
    } catch (err: any) {
      setError(err.message || 'Import thất bại')
      setErrorDetails([])
    } finally {
      setLoading(false)
      e.target.value = ''
    }
  }

  return (
    <div className="flex items-center gap-2">
      <motion.label
        whileHover={{ scale: 1.05, boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
        whileTap={{ scale: 0.95 }}
        className="flex cursor-pointer items-center gap-2 rounded-2xl border border-slate-200 bg-white/90 backdrop-blur-sm px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-sm transition-all hover:bg-white"
      >
        <motion.div
          animate={loading ? { rotate: 360 } : {}}
          transition={loading ? { repeat: Infinity, duration: 1 } : {}}
        >
          <Upload className="h-4 w-4" />
        </motion.div>
        {loading ? 'Đang import...' : 'Import Excel'}
        <input
          type="file"
          accept=".xlsx,.xls"
          onChange={handleFileChange}
          className="hidden"
          disabled={loading}
        />
      </motion.label>
      <AnimatePresence>
        {error && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="flex flex-col gap-1"
          >
            <span className="text-sm text-red-600 font-medium">{error}</span>
            {errorDetails.length > 0 && (
              <div className="text-xs text-red-500 max-w-md">
                {errorDetails.slice(0, 5).map((e: any, idx: number) => (
                  <div key={idx}>• Dòng {e.row}: {e.error}</div>
                ))}
                {errorDetails.length > 5 && (
                  <div className="mt-1 text-red-400">... và {errorDetails.length - 5} lỗi khác</div>
                )}
              </div>
            )}
          </motion.div>
        )}
        {success && (
          <motion.span
            initial={{ opacity: 0, x: -10 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -10 }}
            className="text-sm text-emerald-600"
          >
            {success}
          </motion.span>
        )}
      </AnimatePresence>
    </div>
  )
}
