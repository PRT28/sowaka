import { Router } from 'express';
import { create, getOne, list, remove, update } from '../controllers/user.controller';

export const userRouter = Router();

userRouter.post('/', create);
userRouter.get('/', list);
userRouter.get('/:userId', getOne);
userRouter.patch('/:userId', update);
userRouter.delete('/:userId', remove);
