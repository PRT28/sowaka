import jwt, { JwtPayload, SignOptions } from 'jsonwebtoken';
import { env } from '../config/env';
import { AuthUser } from '../models/auth.model';

interface AuthTokenClaims extends JwtPayload {
  sub: string;
  email: string;
  name: string;
  role: AuthUser['role'];
  company: string;
}

export function signAuthToken(user: AuthUser): string {
  const payload: Omit<AuthTokenClaims, keyof JwtPayload> = {
    sub: user.id,
    email: user.email,
    name: user.name,
    role: user.role,
    company: user.company,
  };
  return jwt.sign(payload, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn as SignOptions['expiresIn'],
  });
}

/** Verifies a token and returns the AuthUser it represents. Throws if invalid/expired. */
export function verifyAuthToken(token: string): AuthUser {
  const claims = jwt.verify(token, env.jwtSecret) as AuthTokenClaims;
  return {
    id: claims.sub,
    email: claims.email,
    name: claims.name,
    role: claims.role,
    company: claims.company,
  };
}
