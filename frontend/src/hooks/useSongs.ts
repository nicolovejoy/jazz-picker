import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';

export function useSongs() {
  return useQuery({
    queryKey: ['songs'],
    queryFn: api.getSongs,
    staleTime: 1000 * 60 * 5, // 5 minutes
  });
}
