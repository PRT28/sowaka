import nodemailer from 'nodemailer';
import { env } from '../config/env';

const transporter =
  env.zohoSmtp.user && env.zohoSmtp.pass
    ? nodemailer.createTransport({
        host: env.zohoSmtp.host,
        port: env.zohoSmtp.port,
        secure: env.zohoSmtp.secure,
        auth: {
          user: env.zohoSmtp.user,
          pass: env.zohoSmtp.pass,
        },
      })
    : null;

export async function sendOtpEmail(email: string, otp: string): Promise<void> {
  if (!transporter) {
    if (env.nodeEnv !== 'production' || env.otpDevBypass) {
      console.log(`[auth] OTP for ${email}: ${otp}`);
      return;
    }
    throw new Error('Zoho SMTP credentials are not configured');
  }

  await transporter.sendMail({
    from: env.zohoSmtp.from,
    to: email,
    subject: 'Your Sowaka Connect sign-in code',
    text: `Your Sowaka Connect sign-in code is ${otp}. It expires in ${env.otpTtlMinutes} minutes.`,
    html: `
      <div style="font-family:Arial,sans-serif;color:#2A2420;line-height:1.5">
        <h2 style="margin:0 0 12px">Sowaka Connect sign-in</h2>
        <p>Your 6-digit sign-in code is:</p>
        <div style="font-size:30px;font-weight:700;letter-spacing:6px;margin:16px 0">${otp}</div>
        <p>This code expires in ${env.otpTtlMinutes} minutes.</p>
      </div>
    `,
  });
}
