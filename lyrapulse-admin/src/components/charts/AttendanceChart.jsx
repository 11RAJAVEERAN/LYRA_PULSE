
import { Box, Typography } from "@mui/material";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const COLORS = {
  primary: "#172554",
  primaryBlue: "#2563EB",
  error: "#DC2626",
  textSecondary: "#64748B",
  border: "#E2E8F0",
  surface: "#FFFFFF",
};

export function AttendanceChart({ data }) {
  return (
    <Box sx={{ width: "100%" }}>
      <Box
        sx={{
          width: "100%",
          height: 285,
          borderRadius: 3,
          background:
            "linear-gradient(180deg, #FFFFFF 0%, #FAFCFF 100%)",
          border: `1px solid ${COLORS.border}`,
          overflow: "hidden",
        }}
      >
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={data}
            margin={{
              top: 20,
              right: 18,
              left: -18,
              bottom: 12,
            }}
          >
            <defs>
              <linearGradient
                id="presentGradient"
                x1="0"
                y1="0"
                x2="0"
                y2="1"
              >
                <stop
                  offset="0%"
                  stopColor={COLORS.primaryBlue}
                  stopOpacity={0.25}
                />
                <stop
                  offset="100%"
                  stopColor={COLORS.primaryBlue}
                  stopOpacity={0}
                />
              </linearGradient>

              <linearGradient
                id="absentGradient"
                x1="0"
                y1="0"
                x2="0"
                y2="1"
              >
                <stop
                  offset="0%"
                  stopColor={COLORS.error}
                  stopOpacity={0.16}
                />
                <stop
                  offset="100%"
                  stopColor={COLORS.error}
                  stopOpacity={0}
                />
              </linearGradient>
            </defs>

            <CartesianGrid
              vertical={false}
              stroke="#E2E8F0"
              strokeDasharray="3 6"
            />

            <XAxis
              dataKey="day"
              axisLine={false}
              tickLine={false}
              tick={{
                fill: COLORS.textSecondary,
                fontSize: 11,
                fontWeight: 600,
              }}
              dy={10}
            />

            <YAxis
              axisLine={false}
              tickLine={false}
              tick={{
                fill: "#94A3B8",
                fontSize: 10,
              }}
              width={38}
            />

            <Tooltip
              cursor={{
                stroke: COLORS.primaryBlue,
                strokeWidth: 1,
                strokeDasharray: "5 5",
              }}
              contentStyle={{
                backgroundColor: COLORS.surface,
                border: `1px solid ${COLORS.border}`,
                borderRadius: 12,
                boxShadow: "0 12px 30px rgba(15, 23, 42, 0.12)",
                padding: "10px 13px",
              }}
              labelStyle={{
                color: COLORS.primary,
                fontSize: 12,
                fontWeight: 800,
                marginBottom: 6,
              }}
              formatter={(value, name) => [
                value,
                name === "present" ? "Present" : "Absent",
              ]}
              itemStyle={{
                fontSize: 12,
                fontWeight: 600,
              }}
            />

            <Area
              type="monotone"
              dataKey="present"
              name="present"
              stroke={COLORS.primaryBlue}
              fill="url(#presentGradient)"
              strokeWidth={3}
              dot={{
                r: 4,
                fill: COLORS.primaryBlue,
                stroke: "#FFFFFF",
                strokeWidth: 2,
              }}
              activeDot={{
                r: 7,
                fill: COLORS.primaryBlue,
                stroke: "#FFFFFF",
                strokeWidth: 3,
              }}
            />

            <Area
              type="monotone"
              dataKey="absent"
              name="absent"
              stroke={COLORS.error}
              fill="url(#absentGradient)"
              strokeWidth={2}
              strokeDasharray="6 5"
              dot={{
                r: 3,
                fill: COLORS.error,
                stroke: "#FFFFFF",
                strokeWidth: 2,
              }}
              activeDot={{
                r: 5,
                fill: COLORS.error,
                stroke: "#FFFFFF",
                strokeWidth: 2,
              }}
            />
          </AreaChart>
        </ResponsiveContainer>
      </Box>

      <Box
        sx={{
          display: "flex",
          justifyContent: "center",
          alignItems: "center",
          gap: 3,
          mt: 1.8,
        }}
      >
        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            gap: 0.8,
          }}
        >
          <Box
            sx={{
              width: 8,
              height: 8,
              borderRadius: "50%",
              backgroundColor: COLORS.primaryBlue,
            }}
          />

          <Typography
            sx={{
              fontSize: 11,
              color: COLORS.textSecondary,
              fontWeight: 600,
            }}
          >
            Present
          </Typography>
        </Box>

        <Box
          sx={{
            display: "flex",
            alignItems: "center",
            gap: 0.8,
          }}
        >
          <Box
            sx={{
              width: 8,
              height: 8,
              borderRadius: "50%",
              backgroundColor: COLORS.error,
            }}
          />

          <Typography
            sx={{
              fontSize: 11,
              color: COLORS.textSecondary,
              fontWeight: 600,
            }}
          >
            Absent
          </Typography>
        </Box>
      </Box>
    </Box>
  );
}

