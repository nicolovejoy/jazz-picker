// Setlist types for Supabase integration

export interface Setlist {
  id: string;
  user_id: string;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface SetlistItem {
  id: string;
  setlist_id: string;
  song_title: string;
  position: number;
  notes: string | null;
  created_at: string;
}

// For creating new setlists
export interface CreateSetlistInput {
  name: string;
}

// For adding songs to a setlist
export interface AddSetlistItemInput {
  setlist_id: string;
  song_title: string;
  notes?: string;
}

// Combined view for UI
export interface SetlistWithItems extends Setlist {
  items: SetlistItem[];
}

// For sharing (Phase 5)
export interface SetlistShare {
  id: string;
  setlist_id: string;
  shared_with_user_id: string;
  permission: 'read' | 'edit';
  created_at: string;
}
