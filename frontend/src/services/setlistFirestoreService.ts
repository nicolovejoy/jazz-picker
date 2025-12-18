import {
  collection,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  serverTimestamp,
  query,
  orderBy,
  where,
  type Unsubscribe,
} from 'firebase/firestore';
import { db } from '../firebase';
import type { Setlist, SetlistData, SetlistItem, AddSetlistItemInput } from '@/types/setlist';

const COLLECTION = 'setlists';

function toSetlist(id: string, data: SetlistData): Setlist {
  return {
    id,
    name: data.name,
    ownerId: data.ownerId,
    groupId: data.groupId,
    createdAt: data.createdAt?.toDate?.() || new Date(),
    updatedAt: data.updatedAt?.toDate?.() || new Date(),
    items: data.items || [],
  };
}

/**
 * Subscribe to setlists.
 * @param callback - Called with updated setlists
 * @param groupIds - If provided, filter to these groups. If undefined, show all (legacy mode).
 */
export function subscribeToSetlists(
  callback: (setlists: Setlist[]) => void,
  groupIds?: string[]
): Unsubscribe {
  // If groupIds provided but empty, return no setlists
  if (groupIds !== undefined && groupIds.length === 0) {
    callback([]);
    return () => {}; // No-op unsubscribe
  }

  // Build query
  let q;
  if (groupIds && groupIds.length > 0) {
    // Firestore 'in' supports up to 30 values
    const limitedGroupIds = groupIds.slice(0, 30);
    q = query(
      collection(db, COLLECTION),
      where('groupId', 'in', limitedGroupIds),
      orderBy('updatedAt', 'desc')
    );
  } else {
    // Legacy mode: all setlists
    q = query(collection(db, COLLECTION), orderBy('updatedAt', 'desc'));
  }

  return onSnapshot(q, (snapshot) => {
    const setlists = snapshot.docs.map((doc) =>
      toSetlist(doc.id, doc.data() as SetlistData)
    );
    callback(setlists);
  });
}

export function subscribeToSetlist(
  id: string,
  callback: (setlist: Setlist | null) => void
): Unsubscribe {
  const docRef = doc(db, COLLECTION, id);

  return onSnapshot(docRef, (docSnap) => {
    if (!docSnap.exists()) {
      callback(null);
      return;
    }
    callback(toSetlist(docSnap.id, docSnap.data() as SetlistData));
  });
}

export async function getSetlist(id: string): Promise<Setlist | null> {
  const docRef = doc(db, COLLECTION, id);
  const docSnap = await getDoc(docRef);

  if (!docSnap.exists()) {
    return null;
  }

  return toSetlist(docSnap.id, docSnap.data() as SetlistData);
}

export async function createSetlist(
  name: string,
  ownerId: string,
  groupId?: string
): Promise<string> {
  const docRef = doc(collection(db, COLLECTION));
  const data: Record<string, unknown> = {
    name,
    ownerId,
    items: [],
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  if (groupId) {
    data.groupId = groupId;
  }

  await setDoc(docRef, data);
  return docRef.id;
}

export async function updateSetlist(
  id: string,
  data: Partial<Pick<Setlist, 'name' | 'items'>>
): Promise<void> {
  const docRef = doc(db, COLLECTION, id);
  await updateDoc(docRef, {
    ...data,
    updatedAt: serverTimestamp(),
  });
}

export async function deleteSetlist(id: string): Promise<void> {
  const docRef = doc(db, COLLECTION, id);
  await deleteDoc(docRef);
}

export async function addItem(
  setlistId: string,
  input: AddSetlistItemInput
): Promise<void> {
  const setlist = await getSetlist(setlistId);
  if (!setlist) throw new Error('Setlist not found');

  const newItem: SetlistItem = {
    id: crypto.randomUUID(),
    songTitle: input.songTitle,
    concertKey: input.concertKey ?? null,
    position: setlist.items.length,
    octaveOffset: input.octaveOffset ?? 0,
    notes: input.notes ?? null,
  };

  await updateSetlist(setlistId, {
    items: [...setlist.items, newItem],
  });
}

export async function removeItem(
  setlistId: string,
  itemId: string
): Promise<void> {
  const setlist = await getSetlist(setlistId);
  if (!setlist) throw new Error('Setlist not found');

  const filteredItems = setlist.items
    .filter((item) => item.id !== itemId)
    .map((item, index) => ({ ...item, position: index }));

  await updateSetlist(setlistId, { items: filteredItems });
}

export async function reorderItems(
  setlistId: string,
  items: SetlistItem[]
): Promise<void> {
  const reorderedItems = items.map((item, index) => ({
    ...item,
    position: index,
  }));

  await updateSetlist(setlistId, { items: reorderedItems });
}

export async function updateItem(
  setlistId: string,
  itemId: string,
  updates: Partial<Pick<SetlistItem, 'concertKey' | 'octaveOffset' | 'notes'>>
): Promise<void> {
  const setlist = await getSetlist(setlistId);
  if (!setlist) throw new Error('Setlist not found');

  const updatedItems = setlist.items.map((item) =>
    item.id === itemId ? { ...item, ...updates } : item
  );

  await updateSetlist(setlistId, { items: updatedItems });
}

export async function duplicateSetlist(
  sourceId: string,
  newName: string,
  ownerId: string
): Promise<string> {
  const source = await getSetlist(sourceId);
  if (!source) throw new Error('Source setlist not found');

  // Create new setlist with same groupId
  const newId = await createSetlist(newName, ownerId, source.groupId);

  // Copy items with new IDs
  const newItems = source.items.map((item, index) => ({
    ...item,
    id: crypto.randomUUID(),
    position: index,
  }));

  if (newItems.length > 0) {
    await updateSetlist(newId, { items: newItems });
  }

  return newId;
}
