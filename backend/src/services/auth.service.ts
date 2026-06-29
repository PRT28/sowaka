import crypto from 'crypto';
import { env } from '../config/env';
import { otpChallenges, users } from '../config/db';
import { AuthUser } from '../models/auth.model';
import { generateOtp, hashOtp, isValidEmail } from '../utils/otp.util';
import { sendOtpEmail } from './email.service';

const maxAttempts = 5;

export async function requestLoginOtp(emailInput: string): Promise<void> {
  const email = normalizeEmail(emailInput);
  if (!isValidEmail(email)) {
    throw new AuthError(400, 'Please enter a valid work email');
  }

  const otp = generateOtp();
  const now = Date.now();
  await otpChallenges().updateOne(
    { email },
    {
      $set: {
        email,
        otpHash: hashOtp(email, otp),
        expiresAt: now + env.otpTtlMinutes * 60 * 1000,
        attempts: 0,
        createdAt: now,
      },
    },
    { upsert: true },
  );

  await sendOtpEmail(email, otp);
}

export async function verifyLoginOtp(
  emailInput: string,
  otpInput: string,
): Promise<{ token: string; user: AuthUser }> {
  const email = normalizeEmail(emailInput);
  const otp = otpInput.trim();

  if (!isValidEmail(email) || !/^\d{6}$/.test(otp)) {
    throw new AuthError(400, 'Invalid email or code');
  }

  const challenge = await otpChallenges().findOne({ email });
  if (!challenge) {
    throw new AuthError(400, 'Code expired or not requested');
  }

  if (challenge.expiresAt < Date.now()) {
    await otpChallenges().deleteOne({ email });
    throw new AuthError(400, 'Code expired');
  }

  if (challenge.attempts >= maxAttempts) {
    await otpChallenges().deleteOne({ email });
    throw new AuthError(429, 'Too many attempts. Request a new code');
  }

  const expectedHash = challenge.otpHash;
  const actualHash = hashOtp(email, otp);
  const valid =
    env.otpDevBypass && otp === '123456' ? true : timingSafeEqualHex(expectedHash, actualHash);

  if (!valid) {
    await otpChallenges().updateOne({ email }, { $inc: { attempts: 1 } });
    throw new AuthError(401, 'Incorrect code');
  }

  await otpChallenges().deleteOne({ email });

  const user = await upsertUser(email);
  const token = crypto.randomBytes(32).toString('hex');
  return { token, user };
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

async function upsertUser(email: string): Promise<AuthUser> {
  const user = buildUser(email);
  await users().updateOne(
    { email },
    {
      $set: user,
      $setOnInsert: { createdAt: Date.now() },
      $currentDate: { lastLoginAt: true },
    },
    { upsert: true },
  );
  return user;
}

function buildUser(email: string): AuthUser {
  const local = email.split('@')[0] || 'user';
  const name = local
    .split(/[._-]/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join(' ');

  return {
    id: crypto.createHash('sha1').update(email).digest('hex').slice(0, 12),
    email,
    name: name || 'Manager',
    role: 'manager',
    company: 'Sowaka',
  };
}

function timingSafeEqualHex(a: string, b: string): boolean {
  const bufA = Buffer.from(a, 'hex');
  const bufB = Buffer.from(b, 'hex');
  if (bufA.length !== bufB.length) {
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

export class AuthError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}
