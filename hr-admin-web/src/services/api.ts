const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'https://d3lwup4rvo6csf.cloudfront.net';

export async function apiGet<T>(path: string): Promise<T> {
  const response = await fetch(`${API_BASE_URL}${path}`);

  if (!response.ok) {
    throw new Error(`Request failed with status ${response.status}`);
  }

  return response.json() as Promise<T>;
}
