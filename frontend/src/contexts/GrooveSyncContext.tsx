import { createContext, useContext, useEffect, useState, useCallback, type ReactNode } from 'react';
import { useAuth } from './AuthContext';
import { useUserProfile } from './UserProfileContext';
import {
  subscribeToSessions,
  type GrooveSyncSession,
} from '@/services/grooveSyncService';

interface GrooveSyncContextType {
  // Active sessions in user's groups
  activeSessions: GrooveSyncSession[];

  // Current following state
  isFollowing: boolean;
  followingSession: GrooveSyncSession | null;

  // Actions
  startFollowing: (session: GrooveSyncSession) => void;
  stopFollowing: () => void;

  // Get session for a specific group (if any)
  getSessionForGroup: (groupId: string) => GrooveSyncSession | null;

  // Check if there's any joinable session
  hasJoinableSession: boolean;
}

const GrooveSyncContext = createContext<GrooveSyncContextType | null>(null);

export function GrooveSyncProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { profile } = useUserProfile();
  const [activeSessions, setActiveSessions] = useState<GrooveSyncSession[]>([]);
  const [isFollowing, setIsFollowing] = useState(false);
  const [followingSession, setFollowingSession] = useState<GrooveSyncSession | null>(null);

  // Get user's group IDs from profile
  const userGroupIds = profile?.groups;
  const userGroupIdsKey = userGroupIds?.slice().sort().join(',') ?? '';

  // Subscribe to sessions in all user's groups
  useEffect(() => {
    if (!user || !userGroupIds || userGroupIds.length === 0) {
      setActiveSessions([]);
      return;
    }

    console.log('🎵 Subscribing to Groove Sync sessions for groups:', userGroupIds);
    const unsubscribe = subscribeToSessions(userGroupIds, (sessions) => {
      console.log('🎵 Active sessions:', sessions.length);
      setActiveSessions(sessions);

      // If we're following a session that ended, stop following
      if (followingSession) {
        const stillActive = sessions.find(
          (s) => s.groupId === followingSession.groupId && s.leaderId === followingSession.leaderId
        );
        if (!stillActive) {
          console.log('🎵 Session ended, stopping follow');
          setIsFollowing(false);
          setFollowingSession(null);
        } else {
          // Update the followed session with latest data (including currentSong)
          setFollowingSession(stillActive);
        }
      }
    });

    return unsubscribe;
  }, [user, userGroupIdsKey, userGroupIds]);

  const startFollowing = useCallback((session: GrooveSyncSession) => {
    console.log('🎵 Starting to follow:', session.leaderName);
    setIsFollowing(true);
    setFollowingSession(session);
  }, []);

  const stopFollowing = useCallback(() => {
    console.log('🎵 Stopped following');
    setIsFollowing(false);
    setFollowingSession(null);
  }, []);

  const getSessionForGroup = useCallback(
    (groupId: string): GrooveSyncSession | null => {
      return activeSessions.find((s) => s.groupId === groupId) ?? null;
    },
    [activeSessions]
  );

  // Check if there's any session the user can join (not their own)
  const hasJoinableSession = activeSessions.some((s) => s.leaderId !== user?.uid);

  return (
    <GrooveSyncContext.Provider
      value={{
        activeSessions,
        isFollowing,
        followingSession,
        startFollowing,
        stopFollowing,
        getSessionForGroup,
        hasJoinableSession,
      }}
    >
      {children}
    </GrooveSyncContext.Provider>
  );
}

export function useGrooveSync() {
  const context = useContext(GrooveSyncContext);
  if (!context) {
    throw new Error('useGrooveSync must be used within a GrooveSyncProvider');
  }
  return context;
}
