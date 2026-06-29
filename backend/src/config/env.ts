import dotenv from 'dotenv';

dotenv.config();

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 4000),
  corsOrigins: (process.env.CORS_ORIGIN ?? 'http://localhost:5173,http://localhost:8080')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  mobileAppApiBaseUrl: process.env.MOBILE_APP_API_BASE_URL ?? 'http://10.0.2.2:4000',
  mongoUri: process.env.MONGODB_URI ?? '',
  mongoDbName: process.env.MONGODB_DB ?? 'sowaka',
  otpTtlMinutes: Number(process.env.OTP_TTL_MINUTES ?? 10),
  otpDevBypass: process.env.OTP_DEV_BYPASS === 'true',
  jwtSecret: process.env.JWT_SECRET ?? 'dev-insecure-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? '7d',
  zohoSmtp: {
    host: process.env.ZOHO_SMTP_HOST ?? 'smtp.zoho.com',
    port: Number(process.env.ZOHO_SMTP_PORT ?? 465),
    secure: process.env.ZOHO_SMTP_SECURE !== 'false',
    user: process.env.ZOHO_SMTP_USER ?? '',
    pass: process.env.ZOHO_SMTP_PASS ?? '',
    from: process.env.ZOHO_SMTP_FROM ?? process.env.ZOHO_SMTP_USER ?? '',
  },
};
