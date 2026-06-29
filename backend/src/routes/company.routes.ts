import { Router } from 'express';
import { create, getOne, list, remove, update } from '../controllers/company.controller';

export const companyRouter = Router();

companyRouter.post('/', create);
companyRouter.get('/', list);
companyRouter.get('/:id', getOne);
companyRouter.patch('/:id', update);
companyRouter.delete('/:id', remove);
