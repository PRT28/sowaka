import { NextFunction, Request, Response } from 'express';
import { logger } from '../utils/logger';

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
