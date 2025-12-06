// Setlist types for Flask API integration

export interface Setlist {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
  created_by_device?: string;
}

export interface SetlistItem {
  id: string;
  setlist_id?: string;
  song_title: string;
  concert_key: string | null;
  position: number;
  notes?: string | null;
  created_at?: string;
}

// For creating new setlists
export interface CreateSetlistInput {
  name: string;
}

// For adding songs to a setlist
export interface AddSetlistItemInput {
  setlist_id: string;
  song_title: string;
  concert_key?: string;
  notes?: string;
}

// Combined view for UI (returned by GET /api/v2/setlists/:id)
export interface SetlistWithItems extends Setlist {
  items: SetlistItem[];
}
