import {
  Alert,
  Box,
  Button,
  Checkbox,
  CircularProgress,
  FormControlLabel,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { colors } from "../../../theme/colors";
import loginImage from "../../../assets/lyra-login-img.png";

// ========================================
// LOGIN VALIDATION
// ========================================

const loginSchema = z.object({
  mobile: z
    .string()
    .trim()
    .min(1, "Please enter your mobile number")
    .regex(/^[0-9]{10}$/, "Please enter a valid 10-digit mobile number"),
});

// ========================================
// LOGIN PAGE
// ========================================

export function LoginPage() {
  const navigate = useNavigate();
  const { login, isLoading } = useAuth();

  const [rememberMe, setRememberMe] = useState(false);
  const [loginError, setLoginError] = useState("");

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      mobile: "",
    },
  });

  // ========================================
  // LOGIN SUBMIT
  // ========================================

  const onSubmit = async (values) => {
    setLoginError("");

    try {
      await login({
        mobile: values.mobile,
        rememberMe,
      });

      navigate("/dashboard", { replace: true });
    } catch (error) {
      setLoginError(error.message || "Unable to sign in.");
    }
  };

  return (
    <Box
      sx={{
        minHeight: "100vh",
        width: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",

        // FIRST IMAGE STYLE BACKGROUND
        background: `
          radial-gradient(
            circle at 15% 85%,
            rgba(77, 157, 238, 0.18),
            transparent 28%
          ),
          radial-gradient(
            circle at 90% 90%,
            rgba(77, 157, 238, 0.15),
            transparent 30%
          ),
          #f4faff
        `,

        px: {
          xs: 2,
          sm: 4,
          md: 6,
        },

        py: {
          xs: 3,
          md: 5,
        },

        overflow: "hidden",
      }}
    >
      {/* ========================================
          MAIN CONTENT
      ======================================== */}

      <Box
        sx={{
          width: "100%",
          maxWidth: 1200,

          minHeight: {
            xs: "auto",
            md: 650,
          },

          display: "flex",
          flexDirection: {
            xs: "column",
            md: "row",
          },

          alignItems: "center",

          gap: {
            xs: 4,
            md: 5,
          },
        }}
      >
        {/* ========================================
            LEFT SIDE
        ======================================== */}

        <Box
          sx={{
            width: {
              xs: "100%",
              md: "52%",
            },

            display: "flex",
            flexDirection: "column",
            justifyContent: "center",

            px: {
              xs: 1,
              sm: 2,
              md: 1,
            },
          }}
        >
          {/* ========================================
              BRAND
          ======================================== */}

          <Box
            sx={{
              display: "flex",
              alignItems: "center",
              mb: 2,

              justifyContent: {
                xs: "center",
                md: "flex-start",
              },
            }}
          >
            {/* LOGO MARK */}

            <Box
              sx={{
                width: 58,
                height: 58,
                mr: 1.5,
                position: "relative",

                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Box
                sx={{
                  width: 46,
                  height: 46,
                  borderRadius: "10px 10px 18px 10px",

                  background:
                    "linear-gradient(135deg, #0d8df5 0%, #1877d5 100%)",

                  position: "relative",

                  boxShadow: "0 8px 20px rgba(20, 125, 220, 0.18)",

                  "&::after": {
                    content: '""',
                    position: "absolute",
                    width: 28,
                    height: 28,
                    left: 12,
                    top: 8,
                    background: "#082e67",
                    borderRadius: "5px 5px 12px 5px",
                  },
                }}
              />

              <Typography
                sx={{
                  position: "absolute",
                  zIndex: 2,
                  color: "#ffffff",
                  fontWeight: 800,
                  fontSize: 28,
                  lineHeight: 1,
                  left: 17,
                  top: 13,
                }}
              >
                L
              </Typography>

              {/* PLUS */}

              <Typography
                sx={{
                  position: "absolute",
                  zIndex: 3,
                  color: "#2c91ed",
                  fontWeight: 900,
                  fontSize: 25,
                  right: 1,
                  top: 0,
                }}
              >
                +
              </Typography>
            </Box>

            {/* BRAND NAME */}

            <Box>
              <Typography
                sx={{
                  color: "#092e67",
                  fontWeight: 800,

                  fontSize: {
                    xs: 27,
                    sm: 30,
                    md: 32,
                  },

                  letterSpacing: "1px",
                  lineHeight: 1,
                }}
              >
                LYRA PULSE
              </Typography>

              <Typography
                sx={{
                  color: "#2588e6",
                  fontWeight: 600,
                  fontSize: 13,
                  letterSpacing: "5px",
                  mt: 0.7,
                }}
              >
                ADMIN
              </Typography>
            </Box>
          </Box>

          {/* ========================================
              IMAGE / ILLUSTRATION
          ======================================== */}

          <Box
            sx={{
              width: "100%",

              height: {
                xs: 300,
                sm: 360,
                md: 390,
              },

              display: "flex",
              alignItems: "center",
              justifyContent: "center",

              position: "relative",

              my: {
                xs: 1,
                md: 2,
              },
            }}
          >
            <Box
              component="img"
              src={loginImage}
              alt="Lyra Pulse administrator"
              sx={{
                width: "100%",
                height: "100%",

                objectFit: "contain",

                objectPosition: "center",

                display: "block",
              }}
            />
          </Box>

          {/* ========================================
              LEFT TAGLINE
          ======================================== */}

          <Box
            sx={{
              textAlign: {
                xs: "center",
                md: "left",
              },

              px: {
                xs: 1,
                md: 2,
              },
            }}
          >
            <Typography
              sx={{
                color: "#092e67",

                fontWeight: 800,

                fontSize: {
                  xs: 25,
                  sm: 28,
                  md: 27,
                },

                lineHeight: 1.2,
              }}
            >
              Track Today,
            </Typography>

            <Typography
              sx={{
                color: "#087fe9",

                fontWeight: 800,

                fontSize: {
                  xs: 25,
                  sm: 28,
                  md: 27,
                },

                lineHeight: 1.2,
              }}
            >
              Build a Better Tomorrow
            </Typography>

            <Typography
              sx={{
                mt: 1,

                color: "#60738e",

                fontSize: {
                  xs: 13,
                  md: 14,
                },

                lineHeight: 1.5,
              }}
            >
              Simple, smart and secure access
              <br />
              for Lyra Pulse administrators.
            </Typography>
          </Box>
        </Box>

        {/* ========================================
            RIGHT SIDE LOGIN CARD
        ======================================== */}

        <Box
          sx={{
            width: {
              xs: "100%",
              sm: 500,
              md: 440,
            },

            flexShrink: 0,

            backgroundColor: "#ffffff",

            borderRadius: {
              xs: 3,
              md: 3,
            },

            boxShadow: "0 15px 45px rgba(27, 104, 170, 0.14)",

            px: {
              xs: 3,
              sm: 4,
              md: 4.5,
            },

            py: {
              xs: 4,
              sm: 5,
              md: 4.5,
            },
          }}
        >
          {/* ========================================
              CARD BRAND
          ======================================== */}

          <Box
            sx={{
              textAlign: "left",
              mb: 3,
            }}
          >
            <Typography
              sx={{
                color: "#092e67",

                fontWeight: 800,

                fontSize: {
                  xs: 27,
                  sm: 30,
                },

                letterSpacing: "1px",

                lineHeight: 1.1,
              }}
            >
              Welcome Back
            </Typography>

            <Typography
              sx={{
                mt: 1,

                color: "#6b7d95",

                fontSize: 14,

                lineHeight: 1.5,
              }}
            >
              Sign in with your mobile number to continue.
            </Typography>
          </Box>

          {/* ========================================
              LOGIN FORM
          ======================================== */}

          <Box component="form" onSubmit={handleSubmit(onSubmit)} noValidate>
            <Stack spacing={1.8}>
              {/* MOBILE NUMBER */}

              <TextField
                label="Mobile Number"
                type="tel"
                fullWidth
                autoComplete="tel"
                inputProps={{
                  maxLength: 10,
                }}
                {...register("mobile")}
                error={Boolean(errors.mobile)}
                helperText={errors.mobile?.message}
                sx={{
                  "& .MuiOutlinedInput-root": {
                    borderRadius: 1.5,

                    backgroundColor: "#ffffff",

                    minHeight: 54,

                    "& fieldset": {
                      borderColor: "#d6dee8",
                    },

                    "&:hover fieldset": {
                      borderColor: "#2588e6",
                    },

                    "&.Mui-focused fieldset": {
                      borderColor: "#2588e6",
                      borderWidth: 1.5,
                    },
                  },

                  "& .MuiInputLabel-root": {
                    color: "#72839a",
                  },

                  "& .MuiInputLabel-root.Mui-focused": {
                    color: "#2588e6",
                  },

                  "& .MuiFormHelperText-root": {
                    marginLeft: 0,
                    fontSize: 11,
                  },
                }}
              />

              {/* REMEMBER ME */}

              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",

                  mt: 0.3,
                }}
              >
                <FormControlLabel
                  sx={{
                    margin: 0,
                  }}
                  control={
                    <Checkbox
                      checked={rememberMe}
                      onChange={(event) => setRememberMe(event.target.checked)}
                      sx={{
                        color: "#8ca0b7",

                        "&.Mui-checked": {
                          color: "#2588e6",
                        },
                      }}
                    />
                  }
                  label={
                    <Typography
                      sx={{
                        fontSize: 13,
                        color: "#53677f",
                      }}
                    >
                      Remember me
                    </Typography>
                  }
                />
              </Box>

              {/* ========================================
                  SIGN IN BUTTON
              ======================================== */}

              <Button
                type="submit"
                variant="contained"
                fullWidth
                disabled={isLoading}
                sx={{
                  minHeight: 52,

                  mt: 0.5,

                  background:
                    "linear-gradient(90deg, #086fc4 0%, #07579c 100%)",

                  borderRadius: 1.5,

                  textTransform: "none",

                  fontSize: 16,

                  fontWeight: 700,

                  boxShadow: "0 7px 18px rgba(10, 103, 181, 0.20)",

                  "&:hover": {
                    background:
                      "linear-gradient(90deg, #075fa9 0%, #064d89 100%)",
                  },

                  "&:disabled": {
                    background: "#9bb9d2",
                    color: "#ffffff",
                  },
                }}
              >
                {isLoading ? (
                  <>
                    <CircularProgress
                      size={18}
                      color="inherit"
                      sx={{
                        mr: 1,
                      }}
                    />
                    Signing in...
                  </>
                ) : (
                  <>
                    Sign In
                    <Typography
                      component="span"
                      sx={{
                        ml: 1.5,
                        fontSize: 22,
                        lineHeight: 1,
                      }}
                    >
                      →
                    </Typography>
                  </>
                )}
              </Button>

              {/* ========================================
                  LOGIN ERROR
              ======================================== */}

              {loginError ? (
                <Alert
                  severity="error"
                  sx={{
                    mt: 0.5,

                    borderRadius: 1.5,

                    fontSize: 12,

                    py: 0.3,

                    "& .MuiAlert-icon": {
                      fontSize: 20,
                    },
                  }}
                >
                  {loginError}
                </Alert>
              ) : null}
            </Stack>
          </Box>

          {/* ========================================
              CARD FOOTER
          ======================================== */}

          <Box
            sx={{
              mt: 4,

              pt: 2,

              borderTop: "1px solid #e8edf3",

              textAlign: "center",
            }}
          >
            <Typography
              sx={{
                color: "#71849b",

                fontSize: 11,

                lineHeight: 1.5,
              }}
            >
              Protected access for Lyra Pulse administrators
            </Typography>
          </Box>
        </Box>
      </Box>
    </Box>
  );
}
