export interface UserProfile {
  instrument: string;
  displayName: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserProfileData {
  instrument: string;
  displayName: string;
  createdAt: unknown;
  updatedAt: unknown;
}
