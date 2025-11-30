import { supabase } from '@/lib/supabase';
import type {
  Setlist,
  SetlistItem,
  SetlistWithItems,
  CreateSetlistInput,
  AddSetlistItemInput,
} from '@/types/setlist';

export const setlistService = {
  // Get all setlists for current user
  async getSetlists(): Promise<Setlist[]> {
    const { data, error } = await supabase
      .from('setlists')
      .select('*')
      .order('updated_at', { ascending: false });

    if (error) throw error;
    return data || [];
  },

  // Get a single setlist with its items
  async getSetlistWithItems(id: string): Promise<SetlistWithItems | null> {
    const { data: setlist, error: setlistError } = await supabase
      .from('setlists')
      .select('*')
      .eq('id', id)
      .single();

    if (setlistError) throw setlistError;
    if (!setlist) return null;

    const { data: items, error: itemsError } = await supabase
      .from('setlist_items')
      .select('*')
      .eq('setlist_id', id)
      .order('position', { ascending: true });

    if (itemsError) throw itemsError;

    return {
      ...setlist,
      items: items || [],
    };
  },

  // Create a new setlist
  async createSetlist(input: CreateSetlistInput): Promise<Setlist> {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('Not authenticated');

    const { data, error } = await supabase
      .from('setlists')
      .insert({ name: input.name, user_id: user.id })
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // Update setlist name
  async updateSetlist(id: string, name: string): Promise<Setlist> {
    const { data, error } = await supabase
      .from('setlists')
      .update({ name, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  },

  // Delete a setlist (cascade deletes items via FK)
  async deleteSetlist(id: string): Promise<void> {
    const { error } = await supabase
      .from('setlists')
      .delete()
      .eq('id', id);

    if (error) throw error;
  },

  // Add a song to a setlist
  async addItem(input: AddSetlistItemInput): Promise<SetlistItem> {
    // Get current max position
    const { data: existing } = await supabase
      .from('setlist_items')
      .select('position')
      .eq('setlist_id', input.setlist_id)
      .order('position', { ascending: false })
      .limit(1);

    const nextPosition = existing && existing.length > 0 ? existing[0].position + 1 : 0;

    const { data, error } = await supabase
      .from('setlist_items')
      .insert({
        setlist_id: input.setlist_id,
        song_title: input.song_title,
        concert_key: input.concert_key || null,
        notes: input.notes || null,
        position: nextPosition,
      })
      .select()
      .single();

    if (error) throw error;

    // Update setlist's updated_at
    await supabase
      .from('setlists')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', input.setlist_id);

    return data;
  },

  // Remove a song from a setlist
  async removeItem(itemId: string): Promise<void> {
    // Get the item first to know which setlist to update
    const { data: item } = await supabase
      .from('setlist_items')
      .select('setlist_id')
      .eq('id', itemId)
      .single();

    const { error } = await supabase
      .from('setlist_items')
      .delete()
      .eq('id', itemId);

    if (error) throw error;

    // Update setlist's updated_at
    if (item) {
      await supabase
        .from('setlists')
        .update({ updated_at: new Date().toISOString() })
        .eq('id', item.setlist_id);
    }
  },

  // Reorder items in a setlist
  async reorderItems(setlistId: string, itemIds: string[]): Promise<void> {
    // Update each item's position based on array index
    const updates = itemIds.map((id, index) =>
      supabase
        .from('setlist_items')
        .update({ position: index })
        .eq('id', id)
    );

    await Promise.all(updates);

    // Update setlist's updated_at
    await supabase
      .from('setlists')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', setlistId);
  },
};
