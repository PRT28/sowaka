import { NextFunction, Request, Response } from 'express';
import { ApiError } from '../utils/api-error';
import { verifyAuthToken } from '../utils/token';

/** Requires a valid `Authorization: Bearer <jwt>` header; attaches the user to req.user. */
export function requireAuth(req: Request, _res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    next(new ApiError(401, 'Missing or malformed Authorization header'));
    return;
  }

  const token = header.slice('Bearer '.length).trim();
  try {
    req.user = verifyAuthToken(token);
    next();
  } catch {
    next(new ApiError(401, 'Invalid or expired token'));
  }
}
