import { Router } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { notificationInbox, readNotification, registerToken, testNotification, unregisterToken } from '../controllers/notification.controller';

export const notificationRouter = Router();
notificationRouter.post('/test', testNotification);
notificationRouter.use(requireAuth);
notificationRouter.post('/devices', registerToken);
notificationRouter.delete('/devices', unregisterToken);
notificationRouter.get('/', notificationInbox);
notificationRouter.patch('/:notificationId/read', readNotification);
