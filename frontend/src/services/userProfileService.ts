import {
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteField,
  onSnapshot,
  serverTimestamp,
  query,
  collection,
  documentId,
  where,
  type Unsubscribe,
} from 'firebase/firestore';
import { db } from '../firebase';
import type { UserProfile, UserProfileData } from '@/types/userProfile';

function toUserProfile(data: UserProfileData): UserProfile {
  console.log('[UserProfile] Raw Firestore data:', data);
  console.log('[UserProfile] preferredKeys:', data.preferredKeys);
  return {
    instrument: data.instrument,
    displayName: data.displayName,
    preferredKeys: data.preferredKeys,
    groups: data.groups,
    lastUsedGroupId: data.lastUsedGroupId,
    createdAt: data.createdAt instanceof Date ? data.createdAt : (data.createdAt as { toDate: () => Date })?.toDate?.() || new Date(),
    updatedAt: data.updatedAt instanceof Date ? data.updatedAt : (data.updatedAt as { toDate: () => Date })?.toDate?.() || new Date(),
  };
}

export async function getProfile(uid: string): Promise<UserProfile | null> {
  const docRef = doc(db, 'users', uid);
  const docSnap = await getDoc(docRef);

  if (!docSnap.exists()) {
    return null;
  }

  return toUserProfile(docSnap.data() as UserProfileData);
}

export async function createProfile(
  uid: string,
  data: { instrument: string; displayName: string }
): Promise<void> {
  const docRef = doc(db, 'users', uid);
  await setDoc(docRef, {
    instrument: data.instrument,
    displayName: data.displayName,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });
}

export async function updateProfile(
  uid: string,
  data: Partial<Pick<UserProfile, 'instrument' | 'displayName'>>
): Promise<void> {
  const docRef = doc(db, 'users', uid);
  await updateDoc(docRef, {
    ...data,
    updatedAt: serverTimestamp(),
  });
}

export function subscribeToProfile(
  uid: string,
  callback: (profile: UserProfile | null) => void
): Unsubscribe {
  const docRef = doc(db, 'users', uid);

  return onSnapshot(docRef, (docSnap) => {
    if (!docSnap.exists()) {
      callback(null);
      return;
    }
    callback(toUserProfile(docSnap.data() as UserProfileData));
  });
}

export async function setPreferredKey(
  uid: string,
  songTitle: string,
  key: string,
  defaultKey: string
): Promise<void> {
  const docRef = doc(db, 'users', uid);
  const fieldPath = `preferredKeys.${songTitle}`;

  if (key === defaultKey) {
    // Sparse storage: remove entry if it matches default
    await updateDoc(docRef, {
      [fieldPath]: deleteField(),
      updatedAt: serverTimestamp(),
    });
  } else {
    await updateDoc(docRef, {
      [fieldPath]: key,
      updatedAt: serverTimestamp(),
    });
  }
}

/**
 * Get display names for multiple users.
 * Returns a map of userId -> displayName (or email prefix if no displayName).
 */
export async function getUserDisplayNames(
  userIds: string[]
): Promise<Map<string, string>> {
  const displayNames = new Map<string, string>();

  if (userIds.length === 0) return displayNames;

  // Firestore 'in' supports up to 30 values
  const limitedIds = userIds.slice(0, 30);

  const q = query(
    collection(db, 'users'),
    where(documentId(), 'in', limitedIds)
  );

  const snapshot = await getDocs(q);

  snapshot.docs.forEach((docSnap) => {
    const data = docSnap.data();
    const displayName = data.displayName || data.email?.split('@')[0] || docSnap.id.slice(0, 8);
    displayNames.set(docSnap.id, displayName);
  });

  // Fill in any missing users with truncated ID
  for (const userId of userIds) {
    if (!displayNames.has(userId)) {
      displayNames.set(userId, userId.slice(0, 8) + '...');
    }
  }

  return displayNames;
}
