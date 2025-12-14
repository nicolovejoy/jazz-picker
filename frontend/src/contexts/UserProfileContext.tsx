import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { useAuth } from './AuthContext';
import type { UserProfile } from '@/types/userProfile';
import {
  subscribeToProfile,
  createProfile as createProfileService,
  updateProfile as updateProfileService,
  setPreferredKey as setPreferredKeyService,
} from '@/services/userProfileService';

interface UserProfileContextType {
  profile: UserProfile | null;
  loading: boolean;
  createProfile: (data: { instrument: string; displayName: string }) => Promise<void>;
  updateProfile: (data: Partial<Pick<UserProfile, 'instrument' | 'displayName'>>) => Promise<void>;
  getPreferredKey: (songTitle: string, defaultKey: string) => string;
  setPreferredKey: (songTitle: string, key: string, defaultKey: string) => Promise<void>;
}

const UserProfileContext = createContext<UserProfileContextType | null>(null);

export function UserProfileProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) {
      setProfile(null);
      setLoading(false);
      return;
    }

    setLoading(true);
    const unsubscribe = subscribeToProfile(user.uid, (newProfile) => {
      setProfile(newProfile);
      setLoading(false);
    });

    return unsubscribe;
  }, [user]);

  const createProfile = async (data: { instrument: string; displayName: string }) => {
    if (!user) throw new Error('Must be signed in to create profile');
    await createProfileService(user.uid, data);
  };

  const updateProfile = async (data: Partial<Pick<UserProfile, 'instrument' | 'displayName'>>) => {
    if (!user) throw new Error('Must be signed in to update profile');
    await updateProfileService(user.uid, data);
  };

  const getPreferredKey = (songTitle: string, defaultKey: string): string => {
    return profile?.preferredKeys?.[songTitle] ?? defaultKey;
  };

  const setPreferredKey = async (songTitle: string, key: string, defaultKey: string) => {
    if (!user) throw new Error('Must be signed in to set preferred key');
    await setPreferredKeyService(user.uid, songTitle, key, defaultKey);
  };

  return (
    <UserProfileContext.Provider
      value={{
        profile,
        loading,
        createProfile,
        updateProfile,
        getPreferredKey,
        setPreferredKey,
      }}
    >
      {children}
    </UserProfileContext.Provider>
  );
}

export function useUserProfile() {
  const context = useContext(UserProfileContext);
  if (!context) {
    throw new Error('useUserProfile must be used within a UserProfileProvider');
  }
  return context;
}
