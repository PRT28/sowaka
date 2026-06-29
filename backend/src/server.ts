import { app } from './app';
import { env } from './config/env';
import { closeDb, connectDb } from './config/db';

async function start(): Promise<void> {
  await connectDb();
  console.log('Connected to MongoDB');

  const server = app.listen(env.port, () => {
    console.log(`API listening on port ${env.port}`);
  });

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`${signal} received, shutting down`);
    server.close();
    await closeDb();
    process.exit(0);
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
}

start().catch((error) => {
  console.error('Failed to start server', error);
  process.exit(1);
});
