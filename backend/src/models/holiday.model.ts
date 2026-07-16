export interface Holiday {
  org: string;
  state: string;
  date: Date;
  name: string;
  createdByUserId?: string;
  createdAt?: number;
  updatedAt?: Date;
}
