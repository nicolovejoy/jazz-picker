// Group types for Firestore

import type { Timestamp } from 'firebase/firestore';

export type GroupRole = 'admin' | 'member';

export interface GroupMember {
  userId: string;
  role: GroupRole;
  joinedAt: Date;
}

export interface GroupMemberData {
  role: GroupRole;
  joinedAt: Timestamp;
}

export interface Group {
  id: string;
  name: string;
  code: string; // jazz slug like "bebop-monk-cool"
  createdAt: Date;
  updatedAt: Date;
}

export interface GroupData {
  name: string;
  code: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface GroupWithMembers extends Group {
  members: GroupMember[];
}

// For creating new groups
export interface CreateGroupInput {
  name: string;
}

// Audit log types
export type AuditAction =
  | 'member_joined'
  | 'member_left'
  | 'member_removed'
  | 'admin_granted'
  | 'admin_revoked';

export interface AuditLogEntry {
  id: string;
  groupId: string;
  action: AuditAction;
  actorId: string;    // who performed the action
  targetId: string;   // who was affected
  timestamp: Date;
  metadata?: Record<string, unknown>;
}

export interface AuditLogEntryData {
  groupId: string;
  action: AuditAction;
  actorId: string;
  targetId: string;
  timestamp: Timestamp;
  metadata?: Record<string, unknown>;
}
