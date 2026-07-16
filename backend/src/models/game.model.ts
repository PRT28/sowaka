export interface Game {
  id: string;
  org: string;
  name: string;
  description: string;
  hostedUrl: string;
  technology: 'vanilla_js' | 'react_js';
  accentColor: string;
  instructions?: string;
  active: boolean;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface GameScore {
  gameId: string;
  org: string;
  userId: string;
  playerName: string;
  score: number;
  achievedAt: Date;
  updatedAt: Date;
}
