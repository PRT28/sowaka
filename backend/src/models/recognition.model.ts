export interface RecognitionNomination {
  managerUserId: string;
  employeeUserId: string;
  period: string;
  category: 'artist' | 'mentor' | 'culture' | 'rising';
  createdAt: Date;
  updatedAt: Date;
}

