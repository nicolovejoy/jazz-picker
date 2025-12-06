import type {
  Setlist,
  SetlistItem,
  SetlistWithItems,
  CreateSetlistInput,
  AddSetlistItemInput,
} from '@/types/setlist';

// Web uses relative URLs (Vite proxy in dev, same origin in prod)
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || '';
const API_BASE = `${BACKEND_URL}/api/v2`;

export const setlistService = {
  // Get all setlists (shared across all users)
  async getSetlists(): Promise<Setlist[]> {
    const response = await fetch(`${API_BASE}/setlists`);
    if (!response.ok) throw new Error('Failed to fetch setlists');
    const data = await response.json();
    return data.setlists || [];
  },

  // Get a single setlist by ID
  async getSetlist(id: string): Promise<Setlist | null> {
    const response = await fetch(`${API_BASE}/setlists/${id}`);
    if (response.status === 404) return null;
    if (!response.ok) throw new Error('Failed to fetch setlist');
    return response.json();
  },

  // Get a single setlist with its items
  async getSetlistWithItems(id: string): Promise<SetlistWithItems | null> {
    const response = await fetch(`${API_BASE}/setlists/${id}`);
    if (response.status === 404) return null;
    if (!response.ok) throw new Error('Failed to fetch setlist');
    return response.json();
  },

  // Create a new setlist
  async createSetlist(input: CreateSetlistInput): Promise<Setlist> {
    const response = await fetch(`${API_BASE}/setlists`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: input.name }),
    });
    if (!response.ok) throw new Error('Failed to create setlist');
    return response.json();
  },

  // Update setlist (name and/or items)
  async updateSetlist(id: string, name: string): Promise<Setlist> {
    const response = await fetch(`${API_BASE}/setlists/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name }),
    });
    if (!response.ok) throw new Error('Failed to update setlist');
    return response.json();
  },

  // Delete a setlist (soft delete)
  async deleteSetlist(id: string): Promise<void> {
    const response = await fetch(`${API_BASE}/setlists/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('Failed to delete setlist');
  },

  // Add a song to a setlist
  async addItem(input: AddSetlistItemInput): Promise<SetlistItem> {
    // First get the current setlist to know item count
    const setlist = await this.getSetlistWithItems(input.setlist_id);
    if (!setlist) throw new Error('Setlist not found');

    const newItem: SetlistItem = {
      id: crypto.randomUUID(),
      setlist_id: input.setlist_id,
      song_title: input.song_title,
      concert_key: input.concert_key || null,
      position: setlist.items.length,
      notes: input.notes || null,
      created_at: new Date().toISOString(),
    };

    // Add the new item to existing items
    const updatedItems = [...setlist.items, newItem];

    // Update the setlist with new items
    const response = await fetch(`${API_BASE}/setlists/${input.setlist_id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: updatedItems.map(item => ({
          song_title: item.song_title,
          concert_key: item.concert_key,
        })),
      }),
    });

    if (!response.ok) throw new Error('Failed to add item');
    return newItem;
  },

  // Remove a song from a setlist (requires setlist context)
  async removeItem(_itemId: string): Promise<void> {
    // This method requires setlist context - use removeItemFromSetlist instead
    throw new Error('removeItem requires setlist context - use removeItemFromSetlist instead');
  },

  // Remove item with setlist context
  async removeItemFromSetlist(setlistId: string, itemId: string): Promise<void> {
    const setlist = await this.getSetlistWithItems(setlistId);
    if (!setlist) throw new Error('Setlist not found');

    const updatedItems = setlist.items.filter(item => item.id !== itemId);

    const response = await fetch(`${API_BASE}/setlists/${setlistId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: updatedItems.map(item => ({
          song_title: item.song_title,
          concert_key: item.concert_key,
        })),
      }),
    });

    if (!response.ok) throw new Error('Failed to remove item');
  },

  // Reorder items in a setlist
  async reorderItems(setlistId: string, itemIds: string[]): Promise<void> {
    const setlist = await this.getSetlistWithItems(setlistId);
    if (!setlist) throw new Error('Setlist not found');

    // Reorder items based on itemIds array
    const itemMap = new Map(setlist.items.map(item => [item.id, item]));
    const reorderedItems = itemIds
      .map(id => itemMap.get(id))
      .filter((item): item is SetlistItem => item !== undefined);

    const response = await fetch(`${API_BASE}/setlists/${setlistId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        items: reorderedItems.map(item => ({
          song_title: item.song_title,
          concert_key: item.concert_key,
        })),
      }),
    });

    if (!response.ok) throw new Error('Failed to reorder items');
  },
};
