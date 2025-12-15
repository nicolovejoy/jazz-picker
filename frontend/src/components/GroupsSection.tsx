import { useState } from 'react';
import { useGroups } from '@/contexts/GroupsContext';
import type { Group, GroupMember } from '@/types/group';

export function GroupsSection() {
  const { groups, loading, createGroup, joinGroup, leaveGroup, getMembers } = useGroups();
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [viewingMembers, setViewingMembers] = useState<{ group: Group; members: GroupMember[] } | null>(null);
  const [leaveConfirm, setLeaveConfirm] = useState<string | null>(null);

  const handleViewMembers = async (group: Group) => {
    try {
      const members = await getMembers(group.id);
      setViewingMembers({ group, members });
    } catch (err) {
      console.error('Failed to load members:', err);
    }
  };

  const handleLeave = async (groupId: string) => {
    try {
      await leaveGroup(groupId);
      setLeaveConfirm(null);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to leave group');
    }
  };

  const copyCode = (code: string) => {
    navigator.clipboard.writeText(code);
  };

  if (loading) {
    return (
      <div className="space-y-2">
        <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide">Groups</h3>
        <div className="animate-pulse bg-white/5 rounded h-12"></div>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide">Groups</h3>

      {groups.length === 0 ? (
        <div className="p-4 bg-white/5 rounded border border-white/10 text-center">
          <p className="text-gray-400 mb-3">You're not in any groups yet</p>
          <div className="flex gap-2 justify-center">
            <button
              onClick={() => setShowCreateModal(true)}
              className="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Create Group
            </button>
            <button
              onClick={() => setShowJoinModal(true)}
              className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm font-medium transition-colors"
            >
              Join Group
            </button>
          </div>
        </div>
      ) : (
        <>
          {groups.map((group) => (
            <div
              key={group.id}
              className="p-3 bg-white/5 rounded border border-white/10"
            >
              <div className="flex items-center justify-between">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-white truncate">{group.name}</p>
                  <button
                    onClick={() => copyCode(group.code)}
                    className="text-xs text-gray-400 hover:text-gray-300 font-mono"
                    title="Click to copy"
                  >
                    {group.code}
                  </button>
                </div>
                <div className="flex items-center gap-2 ml-2">
                  <button
                    onClick={() => handleViewMembers(group)}
                    className="p-2 text-gray-400 hover:text-white transition-colors"
                    title="View members"
                  >
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                    </svg>
                  </button>
                  {leaveConfirm === group.id ? (
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => handleLeave(group.id)}
                        className="px-2 py-1 text-xs bg-red-500 hover:bg-red-600 text-white rounded"
                      >
                        Leave
                      </button>
                      <button
                        onClick={() => setLeaveConfirm(null)}
                        className="px-2 py-1 text-xs bg-white/10 hover:bg-white/20 text-white rounded"
                      >
                        Cancel
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => setLeaveConfirm(group.id)}
                      className="p-2 text-gray-400 hover:text-red-400 transition-colors"
                      title="Leave group"
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                      </svg>
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}

          <div className="flex gap-2">
            <button
              onClick={() => setShowCreateModal(true)}
              className="flex-1 py-2 bg-white/5 hover:bg-white/10 text-white rounded border border-white/10 text-sm transition-colors"
            >
              Create Group
            </button>
            <button
              onClick={() => setShowJoinModal(true)}
              className="flex-1 py-2 bg-white/5 hover:bg-white/10 text-white rounded border border-white/10 text-sm transition-colors"
            >
              Join Group
            </button>
          </div>
        </>
      )}

      {showCreateModal && (
        <CreateGroupModal
          onClose={() => setShowCreateModal(false)}
          onCreate={createGroup}
        />
      )}

      {showJoinModal && (
        <JoinGroupModal
          onClose={() => setShowJoinModal(false)}
          onJoin={joinGroup}
        />
      )}

      {viewingMembers && (
        <MembersModal
          group={viewingMembers.group}
          members={viewingMembers.members}
          onClose={() => setViewingMembers(null)}
        />
      )}
    </div>
  );
}

// --- Create Group Modal ---

interface CreateGroupModalProps {
  onClose: () => void;
  onCreate: (name: string) => Promise<Group>;
}

function CreateGroupModal({ onClose, onCreate }: CreateGroupModalProps) {
  const [name, setName] = useState('');
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdGroup, setCreatedGroup] = useState<Group | null>(null);

  const handleCreate = async () => {
    if (!name.trim()) return;

    try {
      setCreating(true);
      setError(null);
      const group = await onCreate(name.trim());
      setCreatedGroup(group);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create group');
    } finally {
      setCreating(false);
    }
  };

  const copyCode = () => {
    if (createdGroup) {
      navigator.clipboard.writeText(createdGroup.code);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-xl max-w-md w-full">
        <div className="p-4 border-b border-white/10 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">
            {createdGroup ? 'Group Created' : 'Create Group'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white p-1">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="p-4">
          {createdGroup ? (
            <div className="text-center space-y-4">
              <p className="text-white">
                <span className="font-medium">{createdGroup.name}</span> is ready!
              </p>
              <div className="p-3 bg-white/5 rounded border border-white/10">
                <p className="text-xs text-gray-400 mb-1">Share this code with your band:</p>
                <button
                  onClick={copyCode}
                  className="text-lg font-mono text-blue-400 hover:text-blue-300"
                >
                  {createdGroup.code}
                </button>
                <p className="text-xs text-gray-500 mt-1">Click to copy</p>
              </div>
              <button
                onClick={onClose}
                className="w-full py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors"
              >
                Done
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              <div>
                <label className="block text-sm text-gray-400 mb-1">Group Name</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Friday Jazz Trio"
                  className="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                  autoFocus
                />
              </div>

              {error && (
                <p className="text-sm text-red-400">{error}</p>
              )}

              <div className="flex gap-2">
                <button
                  onClick={onClose}
                  className="flex-1 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg font-medium transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleCreate}
                  disabled={!name.trim() || creating}
                  className="flex-1 py-2 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-500/50 text-white rounded-lg font-medium transition-colors"
                >
                  {creating ? 'Creating...' : 'Create'}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// --- Join Group Modal ---

interface JoinGroupModalProps {
  onClose: () => void;
  onJoin: (code: string) => Promise<Group>;
}

function JoinGroupModal({ onClose, onJoin }: JoinGroupModalProps) {
  const [code, setCode] = useState('');
  const [joining, setJoining] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleJoin = async () => {
    if (!code.trim()) return;

    try {
      setJoining(true);
      setError(null);
      await onJoin(code.trim().toLowerCase());
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join group');
    } finally {
      setJoining(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-xl max-w-md w-full">
        <div className="p-4 border-b border-white/10 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">Join Group</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white p-1">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="p-4 space-y-4">
          <div>
            <label className="block text-sm text-gray-400 mb-1">Group Code</label>
            <input
              type="text"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="e.g., bebop-monk-cool"
              className="w-full px-3 py-2 bg-white/5 border border-white/10 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 font-mono"
              autoFocus
            />
            <p className="text-xs text-gray-500 mt-1">Ask your bandmate for the code</p>
          </div>

          {error && (
            <p className="text-sm text-red-400">{error}</p>
          )}

          <div className="flex gap-2">
            <button
              onClick={onClose}
              className="flex-1 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg font-medium transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={handleJoin}
              disabled={!code.trim() || joining}
              className="flex-1 py-2 bg-blue-500 hover:bg-blue-600 disabled:bg-blue-500/50 text-white rounded-lg font-medium transition-colors"
            >
              {joining ? 'Joining...' : 'Join'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// --- Members Modal ---

interface MembersModalProps {
  group: Group;
  members: GroupMember[];
  onClose: () => void;
}

function MembersModal({ group, members, onClose }: MembersModalProps) {
  return (
    <div className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50">
      <div className="bg-gray-800 rounded-xl max-w-md w-full max-h-[80vh] overflow-y-auto">
        <div className="p-4 border-b border-white/10 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-white">{group.name}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white p-1">
            <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="p-4">
          <p className="text-xs text-gray-400 uppercase tracking-wide mb-3">
            {members.length} member{members.length !== 1 ? 's' : ''}
          </p>

          <div className="space-y-2">
            {members.map((member) => (
              <div
                key={member.userId}
                className="p-3 bg-white/5 rounded border border-white/10 flex items-center justify-between"
              >
                <span className="text-white font-mono text-sm truncate">
                  {member.userId.slice(0, 8)}...
                </span>
                {member.role === 'admin' && (
                  <span className="text-xs text-blue-400 bg-blue-500/20 px-2 py-0.5 rounded">
                    admin
                  </span>
                )}
              </div>
            ))}
          </div>

          <div className="mt-4 p-3 bg-white/5 rounded border border-white/10">
            <p className="text-xs text-gray-400 mb-1">Share this code:</p>
            <button
              onClick={() => navigator.clipboard.writeText(group.code)}
              className="font-mono text-blue-400 hover:text-blue-300"
            >
              {group.code}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
