export interface UserProfile {
  instrument: string;
  displayName: string;
  preferredKeys?: Record<string, string>;
  groups?: string[];           // group IDs user belongs to
  lastUsedGroupId?: string;    // for default group selection
  createdAt: Date;
  updatedAt: Date;
}

export interface UserProfileData {
  instrument: string;
  displayName: string;
  preferredKeys?: Record<string, string>;
  groups?: string[];
  lastUsedGroupId?: string;
  createdAt: unknown;
  updatedAt: unknown;
}
