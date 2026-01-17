'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { DataTable, Column } from '@/components/admin/DataTable';
import {
  getSuggestedFoods,
  updateSuggestedFoodStatus,
  getUsers,
  updateUserRole,
} from '@/lib/api/admin';
import type {
  UserSuggestedFood,
  SuggestionStatus,
  PageResponse,
  AdminUser,
  UserRole,
} from '@/lib/types/admin';

const STATUS_OPTIONS = [
  { value: 'PENDING', label: 'Pending' },
  { value: 'APPROVED', label: 'Approved' },
  { value: 'REJECTED', label: 'Rejected' },
];

const LOCALE_OPTIONS = [
  { value: 'ko', label: 'Korean' },
  { value: 'en', label: 'English' },
];

const ROLE_OPTIONS = [
  { value: 'USER', label: 'User' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'CREATOR', label: 'Creator' },
  { value: 'BOT', label: 'Bot' },
];

function formatDate(dateString: string | null): string {
  if (!dateString) return '-';
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

type TabType = 'suggested-foods' | 'users';

export default function AdminPage() {
  const { user, isLoading: authLoading, isAdmin } = useAuth();
  const router = useRouter();

  const [activeTab, setActiveTab] = useState<TabType>('suggested-foods');

  // Debug logging
  useEffect(() => {
    console.log('[Admin] Auth state:', { user, authLoading, isAdmin, role: user?.role });
  }, [user, authLoading, isAdmin]);

  // Redirect non-admin users
  useEffect(() => {
    if (!authLoading && !isAdmin) {
      console.log('[Admin] Redirecting non-admin user. isAdmin:', isAdmin, 'role:', user?.role);
      router.push('/');
    }
  }, [authLoading, isAdmin, router, user?.role]);

  // Show loading while checking auth
  if (authLoading) {
    return (
      <div className="min-h-screen bg-[var(--bg-primary)] flex items-center justify-center">
        <p className="text-[var(--text-secondary)]">Loading...</p>
      </div>
    );
  }

  // Redirect happens in useEffect, but show nothing while redirecting
  if (!isAdmin) {
    return null;
  }

  return (
    <div className="min-h-screen bg-[var(--bg-primary)]">
      <div className="max-w-7xl mx-auto px-4 py-8">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Admin Dashboard</h1>
          <p className="text-[var(--text-secondary)] mt-1">
            Manage users and suggested foods
          </p>
        </div>

        {/* Tabs */}
        <div className="mb-6 border-b border-[var(--border)]">
          <nav className="flex gap-4">
            <button
              onClick={() => setActiveTab('suggested-foods')}
              className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'suggested-foods'
                  ? 'border-[var(--primary)] text-[var(--primary)]'
                  : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              Suggested Foods
            </button>
            <button
              onClick={() => setActiveTab('users')}
              className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'users'
                  ? 'border-[var(--primary)] text-[var(--primary)]'
                  : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              Users
            </button>
          </nav>
        </div>

        {/* Tab Content */}
        {activeTab === 'suggested-foods' && <SuggestedFoodsTab />}
        {activeTab === 'users' && <UsersTab currentUserPublicId={user?.publicId} />}
      </div>
    </div>
  );
}

function SuggestedFoodsTab() {
  const [data, setData] = useState<UserSuggestedFood[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response: PageResponse<UserSuggestedFood> = await getSuggestedFoods({
        page,
        size: pageSize,
        suggestedName: filters.suggestedName || undefined,
        localeCode: filters.localeCode || undefined,
        status: filters.status as SuggestionStatus | undefined,
        username: filters.username || undefined,
        sortBy,
        sortOrder,
      });
      setData(response.content);
      setTotalPages(response.totalPages);
      setTotalElements(response.totalElements);
    } catch (err) {
      console.error('Error fetching suggested foods:', err);
      setError('Failed to load data. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [page, filters, sortBy, sortOrder]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleSort = (key: string) => {
    if (sortBy === key) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(key);
      setSortOrder('desc');
    }
    setPage(0);
  };

  const handleFilterChange = (key: string, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
    setPage(0);
  };

  const handleStatusChange = async (publicId: string, newStatus: SuggestionStatus) => {
    try {
      await updateSuggestedFoodStatus(publicId, newStatus);
      setData((prev) =>
        prev.map((item) =>
          item.publicId === publicId ? { ...item, status: newStatus } : item
        )
      );
    } catch (err) {
      console.error('Error updating status:', err);
      alert('Failed to update status. Please try again.');
    }
  };

  const columns: Column<UserSuggestedFood>[] = [
    {
      key: 'suggestedName',
      header: 'Suggested Name',
      sortable: true,
      filterable: true,
      filterType: 'text',
    },
    {
      key: 'localeCode',
      header: 'Locale',
      sortable: true,
      filterable: true,
      filterType: 'select',
      filterOptions: LOCALE_OPTIONS,
      width: '100px',
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      filterable: true,
      filterType: 'select',
      filterOptions: STATUS_OPTIONS,
      width: '150px',
      render: (item) => (
        <select
          className="px-2 py-1 text-sm border border-[var(--border)] rounded bg-[var(--bg-primary)] text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
          value={item.status}
          onChange={(e) => handleStatusChange(item.publicId, e.target.value as SuggestionStatus)}
        >
          {STATUS_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      ),
    },
    {
      key: 'username',
      header: 'User',
      sortable: false,
      filterable: true,
      filterType: 'text',
    },
    {
      key: 'createdAt',
      header: 'Created',
      sortable: true,
      width: '180px',
      render: (item) => formatDate(item.createdAt),
    },
  ];

  return (
    <>
      <div className="mb-4 p-4 bg-[var(--bg-secondary)] rounded-lg border border-[var(--border)]">
        <p className="text-sm text-[var(--text-secondary)]">
          Total items: <span className="font-semibold text-[var(--text-primary)]">{totalElements}</span>
        </p>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      <div className="bg-[var(--bg-primary)] border border-[var(--border)] rounded-lg overflow-hidden">
        <DataTable
          data={data}
          columns={columns}
          sortBy={sortBy}
          sortOrder={sortOrder}
          onSort={handleSort}
          filters={filters}
          onFilterChange={handleFilterChange}
          loading={loading}
          emptyMessage="No suggested foods found"
        />
      </div>

      {totalPages > 1 && (
        <div className="mt-6 flex justify-center items-center gap-2">
          <button
            onClick={() => setPage((p) => Math.max(0, p - 1))}
            disabled={page === 0}
            className="px-4 py-2 border border-[var(--border)] rounded-lg text-[var(--text-secondary)] hover:bg-[var(--bg-secondary)] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <span className="px-4 py-2 text-[var(--text-secondary)]">
            Page {page + 1} of {totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
            disabled={page >= totalPages - 1}
            className="px-4 py-2 border border-[var(--border)] rounded-lg text-[var(--text-secondary)] hover:bg-[var(--bg-secondary)] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}
    </>
  );
}

function UsersTab({ currentUserPublicId }: { currentUserPublicId?: string }) {
  const [data, setData] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response: PageResponse<AdminUser> = await getUsers({
        page,
        size: pageSize,
        username: filters.username || undefined,
        email: filters.email || undefined,
        role: filters.role as UserRole | undefined,
        sortBy,
        sortOrder,
      });
      setData(response.content);
      setTotalPages(response.totalPages);
      setTotalElements(response.totalElements);
    } catch (err) {
      console.error('Error fetching users:', err);
      setError('Failed to load data. Please try again.');
    } finally {
      setLoading(false);
    }
  }, [page, filters, sortBy, sortOrder]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleSort = (key: string) => {
    if (sortBy === key) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortBy(key);
      setSortOrder('desc');
    }
    setPage(0);
  };

  const handleFilterChange = (key: string, value: string) => {
    setFilters((prev) => ({ ...prev, [key]: value }));
    setPage(0);
  };

  const handleRoleChange = async (publicId: string, newRole: UserRole) => {
    try {
      await updateUserRole(publicId, newRole);
      setData((prev) =>
        prev.map((item) =>
          item.publicId === publicId ? { ...item, role: newRole } : item
        )
      );
    } catch (err) {
      console.error('Error updating role:', err);
      alert('Failed to update role. Please try again.');
    }
  };

  const columns: Column<AdminUser>[] = [
    {
      key: 'username',
      header: 'Username',
      sortable: true,
      filterable: true,
      filterType: 'text',
    },
    {
      key: 'email',
      header: 'Email',
      sortable: true,
      filterable: true,
      filterType: 'text',
    },
    {
      key: 'role',
      header: 'Role',
      sortable: true,
      filterable: true,
      filterType: 'select',
      filterOptions: ROLE_OPTIONS,
      width: '150px',
      render: (item) => {
        const isCurrentUser = item.publicId === currentUserPublicId;
        return (
          <div className="relative">
            <select
              className={`px-2 py-1 text-sm border rounded focus:outline-none focus:border-[var(--primary)] ${
                item.role === 'ADMIN'
                  ? 'border-green-300 bg-green-50 text-green-800'
                  : 'border-[var(--border)] bg-[var(--bg-primary)] text-[var(--text-primary)]'
              } ${isCurrentUser ? 'opacity-50 cursor-not-allowed' : ''}`}
              value={item.role}
              onChange={(e) => handleRoleChange(item.publicId, e.target.value as UserRole)}
              disabled={isCurrentUser}
              title={isCurrentUser ? 'You cannot change your own role' : undefined}
            >
              {ROLE_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
            {isCurrentUser && (
              <span className="ml-2 text-xs text-[var(--text-secondary)]">(You)</span>
            )}
          </div>
        );
      },
    },
    {
      key: 'status',
      header: 'Status',
      sortable: true,
      width: '100px',
      render: (item) => (
        <span
          className={`px-2 py-1 text-xs font-medium rounded ${
            item.status === 'ACTIVE'
              ? 'bg-green-100 text-green-800'
              : item.status === 'BANNED'
              ? 'bg-red-100 text-red-800'
              : 'bg-gray-100 text-gray-800'
          }`}
        >
          {item.status}
        </span>
      ),
    },
    {
      key: 'createdAt',
      header: 'Created',
      sortable: true,
      width: '180px',
      render: (item) => formatDate(item.createdAt),
    },
    {
      key: 'lastLoginAt',
      header: 'Last Login',
      sortable: true,
      width: '180px',
      render: (item) => formatDate(item.lastLoginAt),
    },
  ];

  return (
    <>
      <div className="mb-4 p-4 bg-[var(--bg-secondary)] rounded-lg border border-[var(--border)]">
        <p className="text-sm text-[var(--text-secondary)]">
          Total users: <span className="font-semibold text-[var(--text-primary)]">{totalElements}</span>
        </p>
      </div>

      {error && (
        <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-700">
          {error}
        </div>
      )}

      <div className="bg-[var(--bg-primary)] border border-[var(--border)] rounded-lg overflow-hidden">
        <DataTable
          data={data}
          columns={columns}
          sortBy={sortBy}
          sortOrder={sortOrder}
          onSort={handleSort}
          filters={filters}
          onFilterChange={handleFilterChange}
          loading={loading}
          emptyMessage="No users found"
        />
      </div>

      {totalPages > 1 && (
        <div className="mt-6 flex justify-center items-center gap-2">
          <button
            onClick={() => setPage((p) => Math.max(0, p - 1))}
            disabled={page === 0}
            className="px-4 py-2 border border-[var(--border)] rounded-lg text-[var(--text-secondary)] hover:bg-[var(--bg-secondary)] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          <span className="px-4 py-2 text-[var(--text-secondary)]">
            Page {page + 1} of {totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
            disabled={page >= totalPages - 1}
            className="px-4 py-2 border border-[var(--border)] rounded-lg text-[var(--text-secondary)] hover:bg-[var(--bg-secondary)] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Next
          </button>
        </div>
      )}
    </>
  );
}
