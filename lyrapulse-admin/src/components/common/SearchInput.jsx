import { InputAdornment, TextField } from '@mui/material'
import { Search } from 'lucide-react'

export function SearchInput({ value, onChange, placeholder = 'Search', label = 'Search' }) {
  return (
    <TextField
      value={value}
      onChange={(event) => onChange(event.target.value)}
      placeholder={placeholder}
      size="small"
      fullWidth
      slotProps={{
        htmlInput: { 'aria-label': label },
        input: {
          startAdornment: (
            <InputAdornment position="start">
              <Search size={17} aria-hidden="true" />
            </InputAdornment>
          ),
        },
      }}
    />
  )
}