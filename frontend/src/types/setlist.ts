// Setlist types for Firestore

import type { Timestamp } from 'firebase/firestore';

export interface SetlistItem {
  id: string;
  songTitle: string;
  concertKey: string | null;
  position: number;
  octaveOffset: number;
  notes: string | null;
}

export interface Setlist {
  id: string;
  name: string;
  ownerId: string;
  createdAt: Date;
  updatedAt: Date;
  items: SetlistItem[];
}

// Raw Firestore data (before conversion)
export interface SetlistData {
  name: string;
  ownerId: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  items: SetlistItem[];
}

// For creating new setlists
export interface CreateSetlistInput {
  name: string;
}

// For adding songs to a setlist
export interface AddSetlistItemInput {
  songTitle: string;
  concertKey?: string | null;
  octaveOffset?: number;
  notes?: string | null;
}
