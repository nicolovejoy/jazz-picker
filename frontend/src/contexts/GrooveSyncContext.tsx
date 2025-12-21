import { createContext, useContext, useEffect, useState, useCallback, useRef, type ReactNode } from 'react';
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

  // Ref to track current following state (avoids stale closure in subscription callback)
  const followingRef = useRef<{ groupId: string; leaderId: string } | null>(null);

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
      console.log('🎵 Active sessions:', sessions.length, 'following ref:', followingRef.current);
      setActiveSessions(sessions);

      // If we're following a session, update it with latest data or stop if ended
      if (followingRef.current) {
        const stillActive = sessions.find(
          (s) => s.groupId === followingRef.current!.groupId && s.leaderId === followingRef.current!.leaderId
        );
        if (!stillActive) {
          console.log('🎵 Session ended, stopping follow');
          followingRef.current = null;
          setIsFollowing(false);
          setFollowingSession(null);
        } else {
          // Update the followed session with latest data (including currentSong)
          console.log('🎵 Updating followed session, currentSong:', stillActive.currentSong?.title);
          setFollowingSession(stillActive);
        }
      }
    });

    return unsubscribe;
  }, [user, userGroupIdsKey, userGroupIds]);

  const startFollowing = useCallback((session: GrooveSyncSession) => {
    console.log('🎵 Starting to follow:', session.leaderName);
    followingRef.current = { groupId: session.groupId, leaderId: session.leaderId };
    setIsFollowing(true);
    setFollowingSession(session);
  }, []);

  const stopFollowing = useCallback(() => {
    console.log('🎵 Stopped following');
    followingRef.current = null;
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
