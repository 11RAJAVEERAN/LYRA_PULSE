import { useEffect, useMemo } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { MapContainer, Marker, Popup, TileLayer, useMap } from 'react-leaflet'
import { Box, Stack, Typography, useTheme } from '@mui/material'
import { formatAccuracy, formatCoordinate, formatDistance, formatTime } from '../utils/format'

const OSM_ATTRIBUTION = '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noreferrer">OpenStreetMap</a> contributors'

// Pin-shaped marker drawn with CSS so no Leaflet image assets are needed (they break under bundlers).
function pinIcon(background, ring, text) {
  return L.divIcon({
    className: '',
    html: `<span style="display:grid;place-items:center;width:28px;height:28px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);background:${background};border:2px solid ${ring};box-shadow:0 2px 6px rgba(15,23,42,0.35)"><b style="transform:rotate(45deg);color:${ring};font:700 11px/1 sans-serif">${text}</b></span>`,
    iconSize: [28, 28],
    iconAnchor: [14, 34],
    popupAnchor: [0, -34],
  })
}

// Keeps every available marker in view, and re-fits once the drawer finishes sliding in (Leaflet measures the
// container size on mount, which is wrong mid-animation).
function FitToPoints({ points }) {
  const map = useMap()

  useEffect(() => {
    const fit = () => {
      map.invalidateSize()
      if (points.length === 1) {
        map.setView([points[0].latitude, points[0].longitude], 17)
      } else {
        map.fitBounds(L.latLngBounds(points.map((point) => [point.latitude, point.longitude])), { padding: [36, 36], maxZoom: 18 })
      }
    }
    fit()
    const observer = new ResizeObserver(fit)
    observer.observe(map.getContainer())
    return () => observer.disconnect()
  }, [map, points])

  return null
}

function PopupBody({ point }) {
  const rows = [
    point.time ? ['Time', formatTime(point.time)] : null,
    ['Latitude / Longitude', `${formatCoordinate(point.latitude)}, ${formatCoordinate(point.longitude)}`],
    point.kind !== 'branch' ? ['GPS accuracy', formatAccuracy(point.accuracy_m)] : null,
    point.kind !== 'branch' ? ['Distance from branch', formatDistance(point.distance_from_branch_m)] : null,
    point.kind !== 'branch' ? ['Location verified', point.location_verified === null || point.location_verified === undefined ? '—' : (point.location_verified ? 'Yes' : 'No')] : null,
  ].filter(Boolean)

  return (
    <Box sx={{ minWidth: 190 }}>
      <Typography variant="subtitle2" sx={{ mb: 0.5 }}>{point.title}</Typography>
      {rows.map(([label, value]) => (
        <Stack key={label} direction="row" sx={{ justifyContent: 'space-between', gap: 1.5 }}>
          <Typography variant="caption" color="text.secondary">{label}</Typography>
          <Typography variant="caption" sx={{ fontWeight: 600, textAlign: 'right' }}>{value}</Typography>
        </Stack>
      ))}
    </Box>
  )
}

// Display-only map: markers are not draggable and no editing controls exist. Wheel zoom is off so the page/drawer
// can still scroll; zoom with the +/- buttons, double-click or pinch.
export function AttendanceMap({ points }) {
  const theme = useTheme()
  const ring = theme.palette.background.paper
  const icons = useMemo(() => ({
    branch: pinIcon(theme.palette.primary.main, ring, 'B'),
    checkIn: pinIcon(theme.palette.success.main, ring, 'IN'),
    checkOut: pinIcon(theme.palette.info.main, ring, 'OUT'),
  }), [theme, ring])

  return (
    <Box sx={{ height: 240, borderRadius: 1.5, overflow: 'hidden', border: 1, borderColor: 'divider', '& .leaflet-container': { height: '100%', width: '100%', fontFamily: 'inherit' } }}>
      <MapContainer center={[points[0].latitude, points[0].longitude]} zoom={16} scrollWheelZoom={false} style={{ height: '100%', width: '100%' }}>
        <TileLayer attribution={OSM_ATTRIBUTION} url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" maxZoom={19} />
        <FitToPoints points={points} />
        {points.map((point) => (
          <Marker
            key={point.kind} position={[point.latitude, point.longitude]} icon={icons[point.kind]}
            draggable={false} title={point.title} alt={point.title} zIndexOffset={point.kind === 'branch' ? 0 : 100}
          >
            <Popup><PopupBody point={point} /></Popup>
          </Marker>
        ))}
      </MapContainer>
    </Box>
  )
}
