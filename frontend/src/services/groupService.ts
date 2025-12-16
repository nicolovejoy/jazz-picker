import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  serverTimestamp,
  query,
  where,
  arrayUnion,
  arrayRemove,
  type Unsubscribe,
} from 'firebase/firestore';
import { db } from '../firebase';
import type {
  Group,
  GroupData,
  GroupMember,
  GroupMemberData,
  GroupRole,
  AuditAction,
} from '@/types/group';
import { generateJazzSlug } from '@/utils/jazzSlug';

const GROUPS_COLLECTION = 'groups';
const MEMBERS_SUBCOLLECTION = 'members';
const AUDIT_COLLECTION = 'auditLog';

// --- Converters ---

function toGroup(id: string, data: GroupData): Group {
  return {
    id,
    name: data.name,
    code: data.code,
    createdAt: data.createdAt?.toDate?.() || new Date(),
    updatedAt: data.updatedAt?.toDate?.() || new Date(),
  };
}

function toGroupMember(userId: string, data: GroupMemberData): GroupMember {
  return {
    userId,
    role: data.role,
    joinedAt: data.joinedAt?.toDate?.() || new Date(),
  };
}

// --- Audit Logging ---

async function logAudit(
  groupId: string,
  action: AuditAction,
  actorId: string,
  targetId: string,
  metadata?: Record<string, unknown>
): Promise<void> {
  const docRef = doc(collection(db, AUDIT_COLLECTION));
  await setDoc(docRef, {
    groupId,
    action,
    actorId,
    targetId,
    timestamp: serverTimestamp(),
    ...(metadata && { metadata }),
  });
}

// --- Group CRUD ---

export async function createGroup(
  name: string,
  creatorId: string
): Promise<Group> {
  // Generate unique jazz slug
  let code = generateJazzSlug();
  let attempts = 0;
  const maxAttempts = 10;

  // Check for collision (unlikely but possible)
  while (attempts < maxAttempts) {
    const existing = await getGroupByCode(code);
    if (!existing) break;
    code = generateJazzSlug();
    attempts++;
  }

  if (attempts >= maxAttempts) {
    throw new Error('Failed to generate unique band code');
  }

  // Create group document
  const groupRef = doc(collection(db, GROUPS_COLLECTION));
  const groupData = {
    name,
    code,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
  await setDoc(groupRef, groupData);

  // Add creator as admin
  const memberRef = doc(db, GROUPS_COLLECTION, groupRef.id, MEMBERS_SUBCOLLECTION, creatorId);
  await setDoc(memberRef, {
    role: 'admin' as GroupRole,
    joinedAt: serverTimestamp(),
  });

  // Update user's groups array
  const userRef = doc(db, 'users', creatorId);
  await updateDoc(userRef, {
    groups: arrayUnion(groupRef.id),
    lastUsedGroupId: groupRef.id,
    updatedAt: serverTimestamp(),
  });

  // Log audit
  await logAudit(groupRef.id, 'member_joined', creatorId, creatorId, { role: 'admin', isCreator: true });

  return {
    id: groupRef.id,
    name,
    code,
    createdAt: new Date(),
    updatedAt: new Date(),
  };
}

export async function getGroup(groupId: string): Promise<Group | null> {
  const docRef = doc(db, GROUPS_COLLECTION, groupId);
  const docSnap = await getDoc(docRef);

  if (!docSnap.exists()) {
    return null;
  }

  return toGroup(docSnap.id, docSnap.data() as GroupData);
}

export async function getGroupByCode(code: string): Promise<Group | null> {
  const q = query(
    collection(db, GROUPS_COLLECTION),
    where('code', '==', code.toLowerCase())
  );
  const snapshot = await getDocs(q);

  if (snapshot.empty) {
    return null;
  }

  const doc = snapshot.docs[0];
  return toGroup(doc.id, doc.data() as GroupData);
}

export function subscribeToGroup(
  groupId: string,
  callback: (group: Group | null) => void
): Unsubscribe {
  const docRef = doc(db, GROUPS_COLLECTION, groupId);

  return onSnapshot(docRef, (docSnap) => {
    if (!docSnap.exists()) {
      callback(null);
      return;
    }
    callback(toGroup(docSnap.id, docSnap.data() as GroupData));
  });
}

// --- Membership ---

export async function getGroupMembers(groupId: string): Promise<GroupMember[]> {
  const membersRef = collection(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION);
  const snapshot = await getDocs(membersRef);

  return snapshot.docs.map((doc) =>
    toGroupMember(doc.id, doc.data() as GroupMemberData)
  );
}

export function subscribeToGroupMembers(
  groupId: string,
  callback: (members: GroupMember[]) => void
): Unsubscribe {
  const membersRef = collection(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION);

  return onSnapshot(membersRef, (snapshot) => {
    const members = snapshot.docs.map((doc) =>
      toGroupMember(doc.id, doc.data() as GroupMemberData)
    );
    // Sort by joinedAt (most senior first)
    members.sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime());
    callback(members);
  });
}

export async function joinGroup(
  code: string,
  userId: string
): Promise<Group> {
  const group = await getGroupByCode(code);
  if (!group) {
    throw new Error('Band not found');
  }

  // Check if already a member
  const memberRef = doc(db, GROUPS_COLLECTION, group.id, MEMBERS_SUBCOLLECTION, userId);
  const memberSnap = await getDoc(memberRef);
  if (memberSnap.exists()) {
    throw new Error('Already a member of this band');
  }

  // Add as member
  await setDoc(memberRef, {
    role: 'member' as GroupRole,
    joinedAt: serverTimestamp(),
  });

  // Update user's groups array
  const userRef = doc(db, 'users', userId);
  await updateDoc(userRef, {
    groups: arrayUnion(group.id),
    lastUsedGroupId: group.id,
    updatedAt: serverTimestamp(),
  });

  // Log audit
  await logAudit(group.id, 'member_joined', userId, userId);

  return group;
}

export async function leaveGroup(
  groupId: string,
  userId: string
): Promise<void> {
  // Get members to check admin status
  const members = await getGroupMembers(groupId);
  const member = members.find((m) => m.userId === userId);

  if (!member) {
    throw new Error('Not a member of this band');
  }

  // Check if sole admin
  const admins = members.filter((m) => m.role === 'admin');
  if (member.role === 'admin' && admins.length === 1) {
    throw new Error('Cannot leave band as the only admin. Promote another member first.');
  }

  // Remove from members subcollection
  const memberRef = doc(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION, userId);
  await deleteDoc(memberRef);

  // Update user's groups array
  const userRef = doc(db, 'users', userId);
  await updateDoc(userRef, {
    groups: arrayRemove(groupId),
    updatedAt: serverTimestamp(),
  });

  // Log audit
  await logAudit(groupId, 'member_left', userId, userId);
}

export async function deleteGroup(
  groupId: string,
  userId: string
): Promise<void> {
  // Check membership and count
  const members = await getGroupMembers(groupId);

  if (members.length !== 1) {
    throw new Error('Can only delete a band when you are the only member');
  }

  if (members[0].userId !== userId) {
    throw new Error('Not a member of this band');
  }

  // Count setlists for this group
  const setlistsQuery = query(
    collection(db, 'setlists'),
    where('groupId', '==', groupId)
  );
  const setlistsSnap = await getDocs(setlistsQuery);
  const setlistCount = setlistsSnap.size;

  if (setlistCount > 0) {
    throw new Error(`Band has ${setlistCount} setlist${setlistCount === 1 ? '' : 's'}. Delete them first.`);
  }

  // Delete member doc
  const memberRef = doc(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION, userId);
  await deleteDoc(memberRef);

  // Delete group doc
  const groupRef = doc(db, GROUPS_COLLECTION, groupId);
  await deleteDoc(groupRef);

  // Update user's groups array
  const userRef = doc(db, 'users', userId);
  await updateDoc(userRef, {
    groups: arrayRemove(groupId),
    updatedAt: serverTimestamp(),
  });
}

// --- Admin Actions ---

export async function promoteToAdmin(
  groupId: string,
  targetUserId: string,
  actorId: string
): Promise<void> {
  // Verify actor is admin
  const actorMemberRef = doc(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION, actorId);
  const actorSnap = await getDoc(actorMemberRef);
  if (!actorSnap.exists() || (actorSnap.data() as GroupMemberData).role !== 'admin') {
    throw new Error('Only admins can promote members');
  }

  // Update target's role
  const targetMemberRef = doc(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION, targetUserId);
  await updateDoc(targetMemberRef, { role: 'admin' });

  // Log audit
  await logAudit(groupId, 'admin_granted', actorId, targetUserId);
}

export async function demoteFromAdmin(
  groupId: string,
  targetUserId: string,
  actorId: string
): Promise<void> {
  // Get members to check admin count
  const members = await getGroupMembers(groupId);
  const admins = members.filter((m) => m.role === 'admin');

  if (admins.length <= 1) {
    throw new Error('Cannot demote the last admin');
  }

  // Verify actor is admin
  const actorMemberRef = doc(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION, actorId);
  const actorSnap = await getDoc(actorMemberRef);
  if (!actorSnap.exists() || (actorSnap.data() as GroupMemberData).role !== 'admin') {
    throw new Error('Only admins can demote members');
  }

  // Update target's role
  const targetMemberRef = doc(db, GROUPS_COLLECTION, groupId, MEMBERS_SUBCOLLECTION, targetUserId);
  await updateDoc(targetMemberRef, { role: 'member' });

  // Log audit
  await logAudit(groupId, 'admin_revoked', actorId, targetUserId);
}

// TODO: Implement removeMember when needed
// export async function removeMember(
//   groupId: string,
//   targetUserId: string,
//   actorId: string
// ): Promise<void> {
//   // Placeholder for admin remove functionality
// }

// --- User's Groups ---

export async function getUserGroups(userId: string): Promise<Group[]> {
  // Get user's groups array
  const userRef = doc(db, 'users', userId);
  const userSnap = await getDoc(userRef);

  if (!userSnap.exists()) {
    return [];
  }

  const groupIds = userSnap.data().groups as string[] | undefined;
  if (!groupIds || groupIds.length === 0) {
    return [];
  }

  // Fetch all groups
  const groups = await Promise.all(
    groupIds.map((id) => getGroup(id))
  );

  return groups.filter((g): g is Group => g !== null);
}

export async function setLastUsedGroup(
  userId: string,
  groupId: string
): Promise<void> {
  const userRef = doc(db, 'users', userId);
  await updateDoc(userRef, {
    lastUsedGroupId: groupId,
    updatedAt: serverTimestamp(),
  });
}
