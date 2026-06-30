/** Error carrying an HTTP status code; translated to a JSON response by the error middleware. */
export class ApiError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}
