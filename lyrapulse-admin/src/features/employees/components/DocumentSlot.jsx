import { useRef, useState } from 'react'
import { Box, Button, CircularProgress, Typography } from '@mui/material'
import { Upload } from 'lucide-react'
import { colors } from '../../../theme/colors'

// One drag-and-drop upload target (front/back of a document, or a single upload).
// `stored` is the document already saved on the server; `staged` is a File chosen but not uploaded yet.
export function DocumentSlot({ label, stored, staged, error, busy, disabled, onPick, onRemoveStaged, onView, onRemoveStored }) {
  const inputRef = useRef(null)
  const [dragging, setDragging] = useState(false)

  const pick = (fileList) => {
    const file = fileList?.[0]
    if (file) onPick(file)
  }

  const hasFile = Boolean(staged || stored)
  return (
    <Box sx={{ minWidth: 0 }}>
      {label ? <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 0.75 }}>{label}</Typography> : null}
      <Box
        role="group"
        aria-label={`${label || 'Document'} upload`}
        onDragOver={(event) => { event.preventDefault(); if (!disabled) setDragging(true) }}
        onDragLeave={() => setDragging(false)}
        onDrop={(event) => { event.preventDefault(); setDragging(false); if (!disabled) pick(event.dataTransfer.files) }}
        sx={{
          border: `1px dashed ${dragging ? colors.focus : error ? colors.error : colors.borderStrong}`,
          bgcolor: dragging ? colors.selected : colors.surfaceMuted,
          borderRadius: 1.5, minHeight: 96, p: 1.25, minWidth: 0, overflow: 'hidden', display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 0.5,
        }}
      >
        {busy ? <CircularProgress size={22} aria-label="Uploading" /> : hasFile ? (
          <>
            <Typography variant="body2" sx={{ fontWeight: 600, wordBreak: 'break-all', maxWidth: '100%' }}>{staged ? staged.name : stored.original_name}</Typography>
            <Typography variant="caption" color="text.secondary">{staged ? 'Ready to upload on save' : 'Uploaded'}</Typography>
            <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', justifyContent: 'center' }}>
              {!staged && stored ? <Button size="small" onClick={onView}>View</Button> : null}
              <Button size="small" disabled={disabled} onClick={() => inputRef.current?.click()}>Replace</Button>
              <Button size="small" color="error" disabled={disabled} onClick={staged ? onRemoveStaged : onRemoveStored}>Remove</Button>
            </Box>
          </>
        ) : (
          <>
            <Box sx={{ width: 34, height: 34, borderRadius: '50%', bgcolor: colors.infoBackground, color: colors.primaryBlue, display: 'grid', placeItems: 'center' }}>
              <Upload size={16} aria-hidden="true" />
            </Box>
            <Typography variant="caption" sx={{ fontWeight: 600 }}>Drag to Upload</Typography>
            <Typography variant="caption" color="text.secondary">
              Or{' '}
              <Button size="small" variant="text" disabled={disabled} onClick={() => inputRef.current?.click()} sx={{ p: 0, minWidth: 0, textDecoration: 'underline', fontSize: 'inherit' }}>
                Browse Files
              </Button>
            </Typography>
          </>
        )}
        <input ref={inputRef} type="file" hidden accept=".png,.jpg,.jpeg,.pdf,image/png,image/jpeg,application/pdf"
          onChange={(event) => { pick(event.target.files); event.target.value = '' }} />
      </Box>
      {error ? <Typography variant="caption" color="error" role="alert" sx={{ display: 'block', mt: 0.5 }}>{error}</Typography> : null}
    </Box>
  )
}