import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { api } from '@/services/api';
import type { InstrumentType, SingerRangeType } from '@/types/catalog';

interface UseSongsV2Params {
  limit?: number;
  offset?: number;
  query?: string;
  instrument?: InstrumentType;
  singerRange?: SingerRangeType;
}

export function useSongsV2({ 
  limit = 50, 
  offset = 0, 
  query = '',
  instrument = 'All',
  singerRange = 'All'
}: UseSongsV2Params = {}) {
  return useQuery({
    queryKey: ['songs', limit, offset, query, instrument, singerRange],
    queryFn: () => api.getSongsV2(limit, offset, query, instrument, singerRange),
    staleTime: 1000 * 60 * 5, // 5 minutes
    placeholderData: keepPreviousData, // Keep old data while fetching new page
  });
}
