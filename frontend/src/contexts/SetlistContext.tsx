import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { useAuth } from './AuthContext';
import { useUserProfile } from './UserProfileContext';
import type { Setlist, SetlistItem, AddSetlistItemInput } from '@/types/setlist';
import {
  subscribeToSetlists,
  subscribeToSetlist,
  createSetlist as createSetlistService,
  updateSetlist as updateSetlistService,
  deleteSetlist as deleteSetlistService,
  addItem as addItemService,
  removeItem as removeItemService,
  reorderItems as reorderItemsService,
  updateItem as updateItemService,
} from '@/services/setlistFirestoreService';

interface SetlistContextType {
  setlists: Setlist[];
  loading: boolean;
  createSetlist: (name: string, groupId?: string) => Promise<string>;
  updateSetlist: (id: string, data: Partial<Pick<Setlist, 'name' | 'items'>>) => Promise<void>;
  deleteSetlist: (id: string) => Promise<void>;
  addItem: (setlistId: string, input: AddSetlistItemInput) => Promise<void>;
  removeItem: (setlistId: string, itemId: string) => Promise<void>;
  reorderItems: (setlistId: string, items: SetlistItem[]) => Promise<void>;
  updateItem: (setlistId: string, itemId: string, updates: Partial<Pick<SetlistItem, 'concertKey' | 'octaveOffset' | 'notes'>>) => Promise<void>;
}

const SetlistContext = createContext<SetlistContextType | null>(null);

export function SetlistProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { profile } = useUserProfile();
  const [setlists, setSetlists] = useState<Setlist[]>([]);
  const [loading, setLoading] = useState(true);

  // Get user's group IDs from profile
  const userGroupIds = profile?.groups;

  useEffect(() => {
    if (!user) {
      setSetlists([]);
      setLoading(false);
      return;
    }

    setLoading(true);
    // Pass groupIds to filter setlists (undefined = legacy mode, shows all)
    const unsubscribe = subscribeToSetlists((newSetlists) => {
      setSetlists(newSetlists);
      setLoading(false);
    }, userGroupIds);

    return unsubscribe;
  }, [user, userGroupIds]);

  const createSetlist = async (name: string, groupId?: string): Promise<string> => {
    if (!user) throw new Error('Must be signed in to create setlist');
    return createSetlistService(name, user.uid, groupId);
  };

  const updateSetlist = async (id: string, data: Partial<Pick<Setlist, 'name' | 'items'>>) => {
    if (!user) throw new Error('Must be signed in to update setlist');
    await updateSetlistService(id, data);
  };

  const deleteSetlist = async (id: string) => {
    if (!user) throw new Error('Must be signed in to delete setlist');
    await deleteSetlistService(id);
  };

  const addItem = async (setlistId: string, input: AddSetlistItemInput) => {
    if (!user) throw new Error('Must be signed in to add item');
    await addItemService(setlistId, input);
  };

  const removeItem = async (setlistId: string, itemId: string) => {
    if (!user) throw new Error('Must be signed in to remove item');
    await removeItemService(setlistId, itemId);
  };

  const reorderItems = async (setlistId: string, items: SetlistItem[]) => {
    if (!user) throw new Error('Must be signed in to reorder items');
    await reorderItemsService(setlistId, items);
  };

  const updateItem = async (
    setlistId: string,
    itemId: string,
    updates: Partial<Pick<SetlistItem, 'concertKey' | 'octaveOffset' | 'notes'>>
  ) => {
    if (!user) throw new Error('Must be signed in to update item');
    await updateItemService(setlistId, itemId, updates);
  };

  return (
    <SetlistContext.Provider
      value={{
        setlists,
        loading,
        createSetlist,
        updateSetlist,
        deleteSetlist,
        addItem,
        removeItem,
        reorderItems,
        updateItem,
      }}
    >
      {children}
    </SetlistContext.Provider>
  );
}

export function useSetlists() {
  const context = useContext(SetlistContext);
  if (!context) {
    throw new Error('useSetlists must be used within a SetlistProvider');
  }
  return context;
}

// Hook for subscribing to a single setlist with real-time updates
export function useSetlist(id: string | null) {
  const [setlist, setSetlist] = useState<Setlist | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) {
      setSetlist(null);
      setLoading(false);
      return;
    }

    setLoading(true);
    const unsubscribe = subscribeToSetlist(id, (newSetlist) => {
      setSetlist(newSetlist);
      setLoading(false);
    });

    return unsubscribe;
  }, [id]);

  return { setlist, loading };
}
