export interface UserProfile {
  instrument: string;
  displayName: string;
  preferredKeys?: Record<string, string>;
  createdAt: Date;
  updatedAt: Date;
}

export interface UserProfileData {
  instrument: string;
  displayName: string;
  preferredKeys?: Record<string, string>;
  createdAt: unknown;
  updatedAt: unknown;
}
