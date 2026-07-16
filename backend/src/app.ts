import cors from 'cors';
import express, { Request } from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env';
import { errorHandler, notFoundHandler } from './middleware/error.middleware';
import { requestContext } from './middleware/request-context.middleware';
import { router } from './routes';

export const app = express();

app.use(requestContext);
app.use(helmet());
app.use(cors({ origin: env.corsOrigins }));
app.use(express.json());
morgan.token('request-id', (req) => (req as Request).requestId ?? '-');
app.use(
  morgan(
    env.nodeEnv === 'production'
      ? ':remote-addr :method :url :status :response-time ms requestId=:request-id'
      : ':method :url :status :response-time ms requestId=:request-id',
  ),
);

console.log('CORS Origins:', env.corsOrigins)

app.use(router);

app.use(notFoundHandler);
app.use(errorHandler);
