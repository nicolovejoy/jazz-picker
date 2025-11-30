import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { setlistService } from '@/services/setlistService';
import type { CreateSetlistInput, AddSetlistItemInput } from '@/types/setlist';

// Query keys
export const setlistKeys = {
  all: ['setlists'] as const,
  detail: (id: string) => ['setlists', id] as const,
};

// Get all setlists for current user
export function useSetlists() {
  return useQuery({
    queryKey: setlistKeys.all,
    queryFn: () => setlistService.getSetlists(),
  });
}

// Get a single setlist with items
export function useSetlist(id: string | null) {
  return useQuery({
    queryKey: setlistKeys.detail(id || ''),
    queryFn: () => (id ? setlistService.getSetlistWithItems(id) : null),
    enabled: !!id,
  });
}

// Create a new setlist
export function useCreateSetlist() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: CreateSetlistInput) => setlistService.createSetlist(input),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: setlistKeys.all });
    },
  });
}

// Update setlist name
export function useUpdateSetlist() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, name }: { id: string; name: string }) =>
      setlistService.updateSetlist(id, name),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: setlistKeys.all });
      queryClient.invalidateQueries({ queryKey: setlistKeys.detail(id) });
    },
  });
}

// Delete a setlist
export function useDeleteSetlist() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => setlistService.deleteSetlist(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: setlistKeys.all });
    },
  });
}

// Add item to setlist
export function useAddSetlistItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: AddSetlistItemInput) => setlistService.addItem(input),
    onSuccess: (_, { setlist_id }) => {
      queryClient.invalidateQueries({ queryKey: setlistKeys.detail(setlist_id) });
      queryClient.invalidateQueries({ queryKey: setlistKeys.all });
    },
  });
}

// Remove item from setlist
export function useRemoveSetlistItem() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ itemId }: { itemId: string; setlistId: string }) =>
      setlistService.removeItem(itemId),
    onSuccess: (_, { setlistId }) => {
      queryClient.invalidateQueries({ queryKey: setlistKeys.detail(setlistId) });
      queryClient.invalidateQueries({ queryKey: setlistKeys.all });
    },
  });
}

// Reorder items
export function useReorderSetlistItems() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ setlistId, itemIds }: { setlistId: string; itemIds: string[] }) =>
      setlistService.reorderItems(setlistId, itemIds),
    onSuccess: (_, { setlistId }) => {
      queryClient.invalidateQueries({ queryKey: setlistKeys.detail(setlistId) });
    },
  });
}
