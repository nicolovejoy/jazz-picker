import {
  doc,
  deleteDoc,
  onSnapshot,
  type Unsubscribe,
} from 'firebase/firestore';
import { db } from '../firebase';

// Session timeout: 15 minutes in milliseconds
const SESSION_TIMEOUT_MS = 15 * 60 * 1000;

// Types for Groove Sync session
export interface SharedSong {
  title: string;
  concertKey: string;
  source: 'standard' | 'custom';
  octaveOffset?: number;
}

export interface GrooveSyncSession {
  groupId: string;
  leaderId: string;
  leaderName: string;
  startedAt: Date;
  lastActivityAt: Date;
  currentSong: SharedSong | null;
}

interface SessionData {
  leaderId: string;
  leaderName: string;
  startedAt?: { toDate: () => Date };
  lastActivityAt?: { toDate: () => Date };
  currentSong?: {
    title: string;
    concertKey: string;
    source?: string;
    octaveOffset?: number;
  } | null;
}

function toSession(groupId: string, data: SessionData): GrooveSyncSession {
  return {
    groupId,
    leaderId: data.leaderId,
    leaderName: data.leaderName,
    startedAt: data.startedAt?.toDate() ?? new Date(),
    lastActivityAt: data.lastActivityAt?.toDate() ?? new Date(),
    currentSong: data.currentSong
      ? {
          title: data.currentSong.title,
          concertKey: data.currentSong.concertKey,
          source: (data.currentSong.source as 'standard' | 'custom') ?? 'standard',
          octaveOffset: data.currentSong.octaveOffset,
        }
      : null,
  };
}

/**
 * Check if a session is stale (no activity for 15 minutes)
 */
function isSessionStale(session: GrooveSyncSession): boolean {
  const elapsed = Date.now() - session.lastActivityAt.getTime();
  return elapsed > SESSION_TIMEOUT_MS;
}

/**
 * Subscribe to a Groove Sync session for a specific group.
 * Automatically filters out and cleans up stale sessions (15 min timeout).
 * @param groupId - The group ID to watch
 * @param callback - Called with session data (null if no active session)
 */
export function subscribeToSession(
  groupId: string,
  callback: (session: GrooveSyncSession | null) => void
): Unsubscribe {
  const sessionRef = doc(db, 'groups', groupId, 'session', 'current');

  return onSnapshot(
    sessionRef,
    (snapshot) => {
      if (!snapshot.exists()) {
        callback(null);
        return;
      }
      const data = snapshot.data() as SessionData;
      if (!data.leaderId) {
        callback(null);
        return;
      }

      const session = toSession(groupId, data);

      // Check for stale session (15 min timeout)
      if (isSessionStale(session)) {
        console.log(`[GrooveSync] Session in group ${groupId} is stale, cleaning up...`);
        // Delete the stale session
        deleteDoc(sessionRef).catch((err) => {
          console.error('[GrooveSync] Failed to delete stale session:', err);
        });
        callback(null);
        return;
      }

      callback(session);
    },
    (error) => {
      console.error('Groove Sync listener error:', error);
      callback(null);
    }
  );
}

/**
 * Subscribe to sessions for multiple groups.
 * Returns combined unsubscribe function.
 */
export function subscribeToSessions(
  groupIds: string[],
  callback: (sessions: GrooveSyncSession[]) => void
): Unsubscribe {
  if (!groupIds || groupIds.length === 0) {
    callback([]);
    return () => {};
  }

  const sessions = new Map<string, GrooveSyncSession>();
  const unsubscribes: Unsubscribe[] = [];

  for (const groupId of groupIds) {
    const unsubscribe = subscribeToSession(groupId, (session) => {
      if (session) {
        sessions.set(groupId, session);
      } else {
        sessions.delete(groupId);
      }
      callback(Array.from(sessions.values()));
    });
    unsubscribes.push(unsubscribe);
  }

  return () => {
    unsubscribes.forEach((unsub) => unsub());
  };
}
