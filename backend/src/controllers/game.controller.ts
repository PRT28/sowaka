import { NextFunction, Request, Response } from 'express';
import { createGame, deleteGame, getGameForPlayer, listGamesForAdmin, publishGame, submitGameScore, updateGame } from '../services/game.service';

const userId = (req: Request) => req.auth!.userId;

export async function adminListGames(req: Request, res: Response, next: NextFunction) {
  try { res.json({ success: true, games: await listGamesForAdmin(userId(req)) }); } catch (error) { next(error); }
}
export async function adminCreateGame(req: Request, res: Response, next: NextFunction) {
  try { res.status(201).json({ success: true, game: await createGame(userId(req), req.body) }); } catch (error) { next(error); }
}
export async function adminUpdateGame(req: Request, res: Response, next: NextFunction) {
  try { res.json({ success: true, game: await updateGame(userId(req), String(req.params.gameId), req.body) }); } catch (error) { next(error); }
}
export async function adminDeleteGame(req: Request, res: Response, next: NextFunction) {
  try { res.json({ success: true, ...(await deleteGame(userId(req), String(req.params.gameId))) }); } catch (error) { next(error); }
}
export async function adminPublishGame(req: Request, res: Response, next: NextFunction) {
  try { res.status(201).json({ success: true, post: await publishGame(userId(req), String(req.params.gameId)) }); } catch (error) { next(error); }
}
export async function playerGame(req: Request, res: Response, next: NextFunction) {
  try { res.json({ success: true, ...(await getGameForPlayer(userId(req), String(req.params.gameId))) }); } catch (error) { next(error); }
}
export async function playerSubmitScore(req: Request, res: Response, next: NextFunction) {
  try { res.json({ success: true, ...(await submitGameScore(userId(req), String(req.params.gameId), req.body.score)) }); } catch (error) { next(error); }
}
