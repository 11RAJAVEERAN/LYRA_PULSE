import { InputAdornment, TextField } from '@mui/material'
import { Search } from 'lucide-react'

export function SearchInput({ value, onChange, placeholder = 'Search' }) {
  return (
    <TextField
      value={value}
      onChange={(event) => onChange(event.target.value)}
      placeholder={placeholder}
      size="small"
      fullWidth
      slotProps={{
        input: {
          startAdornment: (
            <InputAdornment position="start">
              <Search size={16} />
            </InputAdornment>
          ),
        },
      }}
    />
  )
}
