import type { NextFunction, Request, Response } from 'express';
import { ApiError } from '../utils/api-error';

export const notFoundHandler = (request: Request, response: Response) => {
  response.status(404).json({
    message: `Route not found: ${request.method} ${request.originalUrl}`,
  });
};

export const errorHandler = (
  error: Error,
  _request: Request,
  response: Response,
  _next: NextFunction,
) => {
  void _next;

  if (error instanceof ApiError) {
    response.status(error.statusCode).json({ success: false, message: error.message });
    return;
  }

  response.status(500).json({
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'production' ? undefined : error.message,
  });
};
