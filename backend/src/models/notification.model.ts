export interface DeviceToken {
  userId: string;
  token: string;
  platform: 'android' | 'ios' | 'web';
  updatedAt: Date;
  createdAt: Date;
}

export interface AppNotification {
  id: string;
  userId: string;
  org: string;
  scenario: string;
  title: string;
  body: string;
  data: Record<string, string>;
  readAt?: Date;
  createdAt: Date;
}
