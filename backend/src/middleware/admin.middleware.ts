import crypto from 'node:crypto';
import { NextFunction, Request, Response } from 'express';
import { env } from '../config/env';
import { logger } from '../utils/logger';

export function requireHrAdmin(req: Request, res: Response, next: NextFunction) {
  const provided = req.header('x-admin-key') ?? '';
  if (!env.hrAdminApiKey) {
    logger.error('HR admin API key is not configured', requestContext(req, 503));
    res.status(503).json({
      success: false,
      message: 'HR admin API key is not configured',
      requestId: req.requestId,
    });
    return;
  }

  const expectedBuffer = Buffer.from(env.hrAdminApiKey);
  const providedBuffer = Buffer.from(provided);
  if (
    expectedBuffer.length !== providedBuffer.length ||
    !crypto.timingSafeEqual(expectedBuffer, providedBuffer)
  ) {
    logger.warn('HR admin authentication rejected', requestContext(req, 401));
    res.status(401).json({
      success: false,
      message: 'Invalid HR admin API key',
      requestId: req.requestId,
    });
    return;
  }

  next();
}

/**
 * Gates the HR dashboard's org-wide + override endpoints. Runs AFTER `requireAuth`,
 * so it relies on `req.auth.dashboardAccess` (set from the user's `dashboardAccess`
 * flag). Only select users in an org are granted this.
 */
export function requireDashboardAccess(req: Request, res: Response, next: NextFunction) {
  if (!req.auth?.userId) {
    res.status(401).json({
      success: false,
      message: 'Authentication required',
      requestId: req.requestId,
    });
    return;
  }
  if (req.auth.dashboardAccess !== true) {
    logger.warn('Dashboard access denied', requestContext(req, 403));
    res.status(403).json({
      success: false,
      message: 'You do not have HR dashboard access',
      requestId: req.requestId,
    });
    return;
  }
  next();
}

function requestContext(req: Request, statusCode: number) {
  return {
    requestId: req.requestId,
    method: req.method,
    path: req.originalUrl,
    statusCode,
  };
}
