import { NextFunction, Request, Response } from 'express';
import {
  addConnectComment,
  ConnectError,
  createConnectPost,
  deleteConnectPost,
  getConnectFeed,
  performConnectAction,
  toggleConnectReaction,
  updateConnectPost,
} from '../services/connect.service';

export async function connectFeed(req: Request, res: Response, next: NextFunction) {
  try {
    const posts = await getConnectFeed(requireUserId(req));
    res.status(200).json({ success: true, posts });
  } catch (error) {
    handleConnectError(error, next);
  }
}

export async function createPost(req: Request, res: Response, next: NextFunction) {
  try {
    const post = await createConnectPost(requireUserId(req), connectPostInput(req));
    res.status(201).json({ success: true, post });
  } catch (error) {
    handleConnectError(error, next);
  }
}

export async function reactToConnectPost(req: Request, res: Response, next: NextFunction) {
  try {
    const post = await toggleConnectReaction(requireUserId(req), String(req.params.postId ?? ''));
    res.status(200).json({ success: true, post });
  } catch (error) {
    handleConnectError(error, next);
  }
}

export async function commentOnConnectPost(req: Request, res: Response, next: NextFunction) {
  try {
    const post = await addConnectComment(
      requireUserId(req),
      String(req.params.postId ?? ''),
      String(req.body.text ?? ''),
    );
    res.status(201).json({ success: true, post });
  } catch (error) {
    handleConnectError(error, next);
  }
}

export async function actOnConnectPost(req: Request, res: Response, next: NextFunction) {
  try {
    const post = await performConnectAction(requireUserId(req), String(req.params.postId ?? ''), {
      optionId: req.body.optionId == null ? undefined : String(req.body.optionId),
    });
    res.status(200).json({ success: true, post });
  } catch (error) {
    handleConnectError(error, next);
  }
}

export async function updatePost(req: Request, res: Response, next: NextFunction) {
  try {
    const post = await updateConnectPost(
      requireUserId(req),
      String(req.params.postId ?? ''),
      connectPostInput(req),
    );
    res.status(200).json({ success: true, post });
  } catch (error) {
    handleConnectError(error, next);
  }
}

export async function deletePost(req: Request, res: Response, next: NextFunction) {
  try {
    const result = await deleteConnectPost(requireUserId(req), String(req.params.postId ?? ''));
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    handleConnectError(error, next);
  }
}

function requireUserId(req: Request) {
  if (!req.auth?.userId) throw new ConnectError(401, 'Authentication required');
  return req.auth.userId;
}

function connectPostInput(req: Request) {
  const body = parseBody(req.body.body) ?? req.body.body ?? req.body;
  return {
    type: stringField(req.body.type ?? body.type),
    removeMedia: req.body.removeMedia === 'true' || body.removeMedia === true,
    body: parseBody(req.body.body) ?? body.body ?? body,
    media: req.file
      ? {
          originalName: req.file.originalname,
          contentType: req.file.mimetype,
          size: req.file.size,
          bytes: req.file.buffer,
        }
      : undefined,
  };
}

function parseBody(value: unknown) {
  if (typeof value !== 'string' || value.trim().length === 0) return undefined;
  try {
    return JSON.parse(value) as Record<string, unknown>;
  } catch {
    throw new ConnectError(400, 'Post body must be valid JSON');
  }
}

function stringField(value: unknown) {
  return typeof value === 'string' ? value : undefined;
}

function handleConnectError(error: unknown, next: NextFunction) {
  next(error);
}
