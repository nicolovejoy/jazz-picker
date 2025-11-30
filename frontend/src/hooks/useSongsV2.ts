import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { api } from '@/services/api';

interface UseSongsV2Params {
  limit?: number;
  offset?: number;
  query?: string;
}

export function useSongsV2({
  limit = 50,
  offset = 0,
  query = '',
}: UseSongsV2Params = {}) {
  return useQuery({
    queryKey: ['songs', limit, offset, query],
    queryFn: () => api.getSongsV2(limit, offset, query),
    staleTime: 1000 * 60 * 5, // 5 minutes
    placeholderData: keepPreviousData, // Keep old data while fetching new page
  });
}
