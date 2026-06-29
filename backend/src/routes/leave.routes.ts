import { Router } from 'express';
import { create, getOne, list, remove, update } from '../controllers/leave.controller';

export const leaveRouter = Router();

leaveRouter.post('/', create);
leaveRouter.get('/', list);
leaveRouter.get('/:id', getOne);
leaveRouter.patch('/:id', update);
leaveRouter.delete('/:id', remove);
