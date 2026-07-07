export interface RecognitionNomination {
  managerUserId: string;
  employeeUserId: string;
  period: string;
  category: 'artist' | 'mentor' | 'culture' | 'rising';
  reason?: string; // why the manager nominated this person
  createdAt: Date;
  updatedAt: Date;
}

