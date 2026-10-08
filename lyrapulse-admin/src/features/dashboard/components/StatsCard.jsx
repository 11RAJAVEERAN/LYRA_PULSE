import { Box, Card, CardContent, Chip, Typography } from "@mui/material";

export function StatsCard({
  title,
  value,
  subtitle,
  trend,
  icon,
  tone = "primary",
}) {
  const toneMap = {
    primary: {
      bg: "#EFF6FF",
      color: "#1D4ED8",
    },
    success: {
      bg: "#ECFDF5",
      color: "#16A34A",
    },
    warning: {
      bg: "#FFF7ED",
      color: "#F59E0B",
    },
    error: {
      bg: "#FEF2F2",
      color: "#EF4444",
    },
  };

  const color = toneMap[tone] || toneMap.primary;

  return (
    <Card
      sx={{
        height: "100%",
        borderRadius: 2.5,
        border: "1px solid #E2E8F0",
        boxShadow: "0 2px 8px rgba(15, 23, 42, 0.04)",
        transition: "all 0.2s ease",
        "&:hover": {
          boxShadow: "0 6px 18px rgba(15, 23, 42, 0.08)",
          transform: "translateY(-1px)",
        },
      }}
    >
      <CardContent
        sx={{
          p: 2,
          "&:last-child": {
            pb: 2,
          },
        }}
      >
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            gap: 1.5,
          }}
        >
          <Box
            sx={{
              display: "grid",
              placeItems: "center",
              width: 38,
              height: 38,
              borderRadius: 1.8,
              backgroundColor: color.bg,
              color: color.color,
              flexShrink: 0,
            }}
          >
            {icon}
          </Box>

          {trend ? (
            <Chip
              label={trend}
              size="small"
              sx={{
                height: 24,
                backgroundColor: color.bg,
                color: color.color,
                fontSize: 11,
                fontWeight: 700,
                borderRadius: 1.5,
                "& .MuiChip-label": {
                  px: 1,
                },
              }}
            />
          ) : null}
        </Box>

        <Typography
          variant="body2"
          sx={{
            mt: 1.5,
            color: "#64748B",
            fontSize: 12,
            fontWeight: 500,
          }}
        >
          {title}
        </Typography>

        <Typography
          sx={{
            mt: 0.35,
            color: "#0F172A",
            fontSize: 26,
            lineHeight: 1.15,
            fontWeight: 750,
            letterSpacing: "-0.5px",
          }}
        >
          {value}
        </Typography>

        <Typography
          sx={{
            mt: 0.45,
            color: "#94A3B8",
            fontSize: 11,
            lineHeight: 1.3,
          }}
        >
          {subtitle}
        </Typography>
      </CardContent>
    </Card>
  );
}
