import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  onSnapshot,
  serverTimestamp,
  type Unsubscribe,
} from 'firebase/firestore';
import { db } from '../firebase';
import type { UserProfile, UserProfileData } from '@/types/userProfile';

function toUserProfile(data: UserProfileData): UserProfile {
  return {
    instrument: data.instrument,
    displayName: data.displayName,
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
