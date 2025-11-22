import { useQuery } from '@tanstack/react-query';
import { api } from '@/services/api';

export function useSongDetail(title: string | null) {
  return useQuery({
    queryKey: ['song', title],
    queryFn: () => api.getSongV2(title!),
    enabled: !!title, // Only fetch if title is provided
    staleTime: 1000 * 60 * 30, // 30 minutes
  });
}
