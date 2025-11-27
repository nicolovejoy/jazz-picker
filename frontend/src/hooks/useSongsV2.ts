import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { api } from '@/services/api';
import type { InstrumentType } from '@/types/catalog';

interface UseSongsV2Params {
  limit?: number;
  offset?: number;
  query?: string;
  instrument?: InstrumentType;
}

export function useSongsV2({
  limit = 50,
  offset = 0,
  query = '',
  instrument = 'All',
}: UseSongsV2Params = {}) {
  return useQuery({
    queryKey: ['songs', limit, offset, query, instrument],
    queryFn: () => api.getSongsV2(limit, offset, query, instrument),
    staleTime: 1000 * 60 * 5, // 5 minutes
    placeholderData: keepPreviousData, // Keep old data while fetching new page
  });
}
