type LogLevel = 'info' | 'warn' | 'error';

type LogContext = Record<string, unknown>;

function write(level: LogLevel, message: string, context: LogContext = {}, error?: unknown): void {
  const entry = {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...context,
    ...(error === undefined ? {} : { error: serializeError(error) }),
  };

  const output = JSON.stringify(entry);
  if (level === 'error') {
    console.error(output);
  } else if (level === 'warn') {
    console.warn(output);
  } else {
    console.info(output);
  }
}

function serializeError(error: unknown): Record<string, unknown> {
  if (!(error instanceof Error)) {
    return { value: String(error) };
  }

  const details = error as Error & {
    code?: string | number;
    codeName?: string;
    errorLabelSet?: Set<string>;
    cause?: unknown;
  };

  return {
    name: error.name,
    message: error.message,
    stack: error.stack,
    ...(details.code === undefined ? {} : { code: details.code }),
    ...(details.codeName === undefined ? {} : { codeName: details.codeName }),
    ...(details.errorLabelSet ? { labels: [...details.errorLabelSet] } : {}),
    ...(details.cause === undefined ? {} : { cause: serializeError(details.cause) }),
  };
}

export const logger = {
  info: (message: string, context?: LogContext) => write('info', message, context),
  warn: (message: string, context?: LogContext, error?: unknown) =>
    write('warn', message, context, error),
  error: (message: string, context?: LogContext, error?: unknown) =>
    write('error', message, context, error),
};
