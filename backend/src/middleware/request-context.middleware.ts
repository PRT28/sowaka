import crypto from 'node:crypto';
import { NextFunction, Request, Response } from 'express';

export function requestContext(req: Request, res: Response, next: NextFunction): void {
  const incomingId = req.header('x-request-id')?.trim();
  req.requestId = incomingId || crypto.randomUUID();
  res.setHeader('x-request-id', req.requestId);
  next();
}
