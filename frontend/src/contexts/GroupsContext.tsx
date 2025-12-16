import { createContext, useContext, useEffect, useState, useCallback, type ReactNode } from 'react';
import { useAuth } from './AuthContext';
import { useUserProfile } from './UserProfileContext';
import type { Group, GroupMember } from '@/types/group';
import {
  getUserGroups,
  createGroup as createGroupService,
  joinGroup as joinGroupService,
  leaveGroup as leaveGroupService,
  deleteGroup as deleteGroupService,
  getGroupMembers,
  setLastUsedGroup as setLastUsedGroupService,
} from '@/services/groupService';

interface GroupsContextType {
  groups: Group[];
  loading: boolean;
  error: string | null;
  createGroup: (name: string) => Promise<Group>;
  joinGroup: (code: string) => Promise<Group>;
  leaveGroup: (groupId: string) => Promise<void>;
  deleteGroup: (groupId: string) => Promise<void>;
  getMembers: (groupId: string) => Promise<GroupMember[]>;
  setLastUsedGroup: (groupId: string) => Promise<void>;
  refreshGroups: () => Promise<void>;
}

const GroupsContext = createContext<GroupsContextType | null>(null);

export function GroupsProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const { profile } = useUserProfile();
  const [groups, setGroups] = useState<Group[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadGroups = useCallback(async () => {
    if (!user) {
      setGroups([]);
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const userGroups = await getUserGroups(user.uid);
      setGroups(userGroups);
    } catch (err) {
      console.error('Failed to load groups:', err);
      setError('Failed to load groups');
    } finally {
      setLoading(false);
    }
  }, [user]);

  // Load groups when user or profile changes
  useEffect(() => {
    loadGroups();
  }, [loadGroups, profile?.groups]);

  const createGroup = async (name: string): Promise<Group> => {
    if (!user) throw new Error('Must be signed in to create band');

    const group = await createGroupService(name, user.uid);
    // Refresh groups list
    await loadGroups();
    return group;
  };

  const joinGroup = async (code: string): Promise<Group> => {
    if (!user) throw new Error('Must be signed in to join band');

    const group = await joinGroupService(code, user.uid);
    // Refresh groups list
    await loadGroups();
    return group;
  };

  const leaveGroup = async (groupId: string): Promise<void> => {
    if (!user) throw new Error('Must be signed in to leave band');

    await leaveGroupService(groupId, user.uid);
    // Refresh groups list
    await loadGroups();
  };

  const deleteGroup = async (groupId: string): Promise<void> => {
    if (!user) throw new Error('Must be signed in to delete band');

    await deleteGroupService(groupId, user.uid);
    // Refresh groups list
    await loadGroups();
  };

  const getMembers = async (groupId: string): Promise<GroupMember[]> => {
    return getGroupMembers(groupId);
  };

  const setLastUsedGroup = async (groupId: string): Promise<void> => {
    if (!user) throw new Error('Must be signed in');
    await setLastUsedGroupService(user.uid, groupId);
  };

  return (
    <GroupsContext.Provider
      value={{
        groups,
        loading,
        error,
        createGroup,
        joinGroup,
        leaveGroup,
        deleteGroup,
        getMembers,
        setLastUsedGroup,
        refreshGroups: loadGroups,
      }}
    >
      {children}
    </GroupsContext.Provider>
  );
}

export function useGroups() {
  const context = useContext(GroupsContext);
  if (!context) {
    throw new Error('useGroups must be used within a GroupsProvider');
  }
  return context;
}
