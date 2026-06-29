import { AuthUser } from '../models/auth.model';

declare global {
  namespace Express {
    interface Request {
      /** Populated by requireAuth once a valid bearer token is verified. */
      user?: AuthUser;
    }
  }
}

export {};
