'use client';

import { useEffect, useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useFormatter } from 'next-intl';
import { useAuth } from '@/contexts/AuthContext';
import { DataTable, Column } from '@/components/admin/DataTable';
import {
  getSuggestedFoods,
  updateSuggestedFoodStatus,
  getUsers,
  updateUserRole,
  getSuggestedIngredients,
  updateSuggestedIngredientStatus,
  getUntranslatedRecipes,
  triggerRecipeRetranslation,
  getUntranslatedLogs,
  triggerLogRetranslation,
} from '@/lib/api/admin';
import type {
  UserSuggestedFood,
  SuggestionStatus,
  PageResponse,
  AdminUser,
  UserRole,
  UserSuggestedIngredient,
  IngredientType,
  UntranslatedRecipe,
  UntranslatedLog,
  TranslationStatus,
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

const INGREDIENT_TYPE_OPTIONS = [
  { value: 'MAIN', label: 'Main' },
  { value: 'SECONDARY', label: 'Secondary' },
  { value: 'SEASONING', label: 'Seasoning' },
];

const TRANSLATION_STATUS_OPTIONS = [
  { value: 'PENDING', label: 'Pending' },
  { value: 'PROCESSING', label: 'Processing' },
  { value: 'COMPLETED', label: 'Completed' },
  { value: 'FAILED', label: 'Failed' },
];

// formatDate is now a hook-based function created inside the component

type TabType = 'suggested-foods' | 'suggested-ingredients' | 'users' | 'untranslated-recipes' | 'untranslated-logs';

export default function AdminPage() {
  const { user, isLoading: authLoading, isAdmin } = useAuth();
  const router = useRouter();
  const format = useFormatter();

  // Locale-aware date formatting
  const formatDate = useCallback((dateString: string | null): string => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return format.dateTime(date, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZoneName: 'short',
    });
  }, [format]);

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
              onClick={() => setActiveTab('suggested-ingredients')}
              className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'suggested-ingredients'
                  ? 'border-[var(--primary)] text-[var(--primary)]'
                  : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              Suggested Ingredients
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
            <button
              onClick={() => setActiveTab('untranslated-recipes')}
              className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'untranslated-recipes'
                  ? 'border-[var(--primary)] text-[var(--primary)]'
                  : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              Untranslated Recipes
            </button>
            <button
              onClick={() => setActiveTab('untranslated-logs')}
              className={`pb-3 px-1 text-sm font-medium border-b-2 transition-colors ${
                activeTab === 'untranslated-logs'
                  ? 'border-[var(--primary)] text-[var(--primary)]'
                  : 'border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
              }`}
            >
              Untranslated Logs
            </button>
          </nav>
        </div>

        {/* Tab Content */}
        {activeTab === 'suggested-foods' && <SuggestedFoodsTab />}
        {activeTab === 'suggested-ingredients' && <SuggestedIngredientsTab />}
        {activeTab === 'users' && <UsersTab currentUserPublicId={user?.publicId} />}
        {activeTab === 'untranslated-recipes' && <UntranslatedRecipesTab />}
        {activeTab === 'untranslated-logs' && <UntranslatedLogsTab />}
      </div>
    </div>
  );
}

function SuggestedFoodsTab() {
  const format = useFormatter();
  const formatDate = useCallback((dateString: string | null): string => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return format.dateTime(date, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZoneName: 'short',
    });
  }, [format]);

  const [data, setData] = useState<UserSuggestedFood[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // Track pending changes: { publicId: newStatus }
  const [pendingChanges, setPendingChanges] = useState<Record<string, SuggestionStatus>>({});

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
      setPendingChanges({}); // Clear pending changes on data refresh
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

  const handleStatusChange = (publicId: string, newStatus: SuggestionStatus) => {
    // Find original status
    const originalItem = data.find(item => item.publicId === publicId);
    if (!originalItem) return;

    // If new status equals original, remove from pending changes
    if (originalItem.status === newStatus) {
      setPendingChanges(prev => {
        const updated = { ...prev };
        delete updated[publicId];
        return updated;
      });
    } else {
      // Add to pending changes
      setPendingChanges(prev => ({ ...prev, [publicId]: newStatus }));
    }
  };

  const handleSave = async () => {
    const changeEntries = Object.entries(pendingChanges);
    if (changeEntries.length === 0) return;

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    let successCount = 0;
    let failCount = 0;

    for (const [publicId, newStatus] of changeEntries) {
      try {
        await updateSuggestedFoodStatus(publicId, newStatus);
        // Update local data
        setData(prev =>
          prev.map(item =>
            item.publicId === publicId ? { ...item, status: newStatus } : item
          )
        );
        // Remove from pending changes
        setPendingChanges(prev => {
          const updated = { ...prev };
          delete updated[publicId];
          return updated;
        });
        successCount++;
      } catch (err) {
        console.error('Error updating status for', publicId, err);
        failCount++;
      }
    }

    setSaving(false);

    if (failCount === 0) {
      setSuccessMessage(`Successfully saved ${successCount} change(s).`);
      setTimeout(() => setSuccessMessage(null), 3000);
    } else {
      setError(`Saved ${successCount} change(s), but ${failCount} failed. Please try again.`);
    }
  };

  const pendingCount = Object.keys(pendingChanges).length;

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
      render: (item) => {
        const currentValue = pendingChanges[item.publicId] ?? item.status;
        const hasChange = item.publicId in pendingChanges;
        return (
          <select
            className={`px-2 py-1 text-sm border rounded focus:outline-none focus:border-[var(--primary)] ${
              hasChange
                ? 'border-[var(--primary)] bg-[var(--primary-light)] text-[var(--primary)] font-medium'
                : 'border-[var(--border)] bg-[var(--bg-primary)] text-[var(--text-primary)]'
            }`}
            value={currentValue}
            onChange={(e) => handleStatusChange(item.publicId, e.target.value as SuggestionStatus)}
          >
            {STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        );
      },
    },
    {
      key: 'translations',
      header: 'Translations (KO / EN)',
      sortable: false,
      width: '200px',
      render: (item) =>
        item.status === 'APPROVED' && (item.masterFoodNameKo || item.masterFoodNameEn)
          ? `${item.masterFoodNameKo || '-'} / ${item.masterFoodNameEn || '-'}`
          : '-',
    },
    {
      key: 'rejectionReason',
      header: 'Rejection Reason',
      sortable: false,
      width: '200px',
      render: (item) => item.rejectionReason ? (
        <span className="text-sm text-red-600" title={item.rejectionReason}>
          {item.rejectionReason.length > 50
            ? `${item.rejectionReason.substring(0, 50)}...`
            : item.rejectionReason}
        </span>
      ) : '-',
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

      {successMessage && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
          {successMessage}
        </div>
      )}

      {/* Save Button */}
      <div className="mb-4 flex items-center justify-between">
        <div className="text-sm text-[var(--text-secondary)]">
          {pendingCount > 0 && (
            <span className="text-[var(--primary)] font-medium">
              {pendingCount} unsaved change{pendingCount > 1 ? 's' : ''}
            </span>
          )}
        </div>
        <button
          onClick={handleSave}
          disabled={pendingCount === 0 || saving}
          className={`px-6 py-2 rounded-lg font-medium transition-colors ${
            pendingCount > 0
              ? 'bg-[var(--primary)] text-white hover:opacity-90'
              : 'bg-[var(--bg-secondary)] text-[var(--text-secondary)] cursor-not-allowed'
          } disabled:opacity-50`}
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

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
  const format = useFormatter();
  const formatDate = useCallback((dateString: string | null): string => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return format.dateTime(date, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZoneName: 'short',
    });
  }, [format]);

  const [data, setData] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // Track pending changes: { publicId: newRole }
  const [pendingChanges, setPendingChanges] = useState<Record<string, UserRole>>({});

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
      setPendingChanges({}); // Clear pending changes on data refresh
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

  const handleRoleChange = (publicId: string, newRole: UserRole) => {
    // Find original role
    const originalItem = data.find(item => item.publicId === publicId);
    if (!originalItem) return;

    // If new role equals original, remove from pending changes
    if (originalItem.role === newRole) {
      setPendingChanges(prev => {
        const updated = { ...prev };
        delete updated[publicId];
        return updated;
      });
    } else {
      // Add to pending changes
      setPendingChanges(prev => ({ ...prev, [publicId]: newRole }));
    }
  };

  const handleSave = async () => {
    const changeEntries = Object.entries(pendingChanges);
    if (changeEntries.length === 0) return;

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    let successCount = 0;
    let failCount = 0;

    for (const [publicId, newRole] of changeEntries) {
      try {
        await updateUserRole(publicId, newRole);
        // Update local data
        setData(prev =>
          prev.map(item =>
            item.publicId === publicId ? { ...item, role: newRole } : item
          )
        );
        // Remove from pending changes
        setPendingChanges(prev => {
          const updated = { ...prev };
          delete updated[publicId];
          return updated;
        });
        successCount++;
      } catch (err) {
        console.error('Error updating role for', publicId, err);
        failCount++;
      }
    }

    setSaving(false);

    if (failCount === 0) {
      setSuccessMessage(`Successfully saved ${successCount} change(s).`);
      setTimeout(() => setSuccessMessage(null), 3000);
    } else {
      setError(`Saved ${successCount} change(s), but ${failCount} failed. Please try again.`);
    }
  };

  const pendingCount = Object.keys(pendingChanges).length;

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
        const currentValue = pendingChanges[item.publicId] ?? item.role;
        const hasChange = item.publicId in pendingChanges;
        return (
          <div className="relative">
            <select
              className={`px-2 py-1 text-sm border rounded focus:outline-none focus:border-[var(--primary)] ${
                hasChange
                  ? 'border-[var(--primary)] bg-[var(--primary-light)] text-[var(--primary)] font-medium'
                  : item.role === 'ADMIN'
                  ? 'border-green-300 bg-green-50 text-green-800'
                  : 'border-[var(--border)] bg-[var(--bg-primary)] text-[var(--text-primary)]'
              } ${isCurrentUser ? 'opacity-50 cursor-not-allowed' : ''}`}
              value={currentValue}
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

      {successMessage && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
          {successMessage}
        </div>
      )}

      {/* Save Button */}
      <div className="mb-4 flex items-center justify-between">
        <div className="text-sm text-[var(--text-secondary)]">
          {pendingCount > 0 && (
            <span className="text-[var(--primary)] font-medium">
              {pendingCount} unsaved change{pendingCount > 1 ? 's' : ''}
            </span>
          )}
        </div>
        <button
          onClick={handleSave}
          disabled={pendingCount === 0 || saving}
          className={`px-6 py-2 rounded-lg font-medium transition-colors ${
            pendingCount > 0
              ? 'bg-[var(--primary)] text-white hover:opacity-90'
              : 'bg-[var(--bg-secondary)] text-[var(--text-secondary)] cursor-not-allowed'
          } disabled:opacity-50`}
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

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

function SuggestedIngredientsTab() {
  const format = useFormatter();
  const formatDate = useCallback((dateString: string | null): string => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return format.dateTime(date, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZoneName: 'short',
    });
  }, [format]);

  const [data, setData] = useState<UserSuggestedIngredient[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');

  // Track pending changes: { publicId: newStatus }
  const [pendingChanges, setPendingChanges] = useState<Record<string, SuggestionStatus>>({});

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response: PageResponse<UserSuggestedIngredient> = await getSuggestedIngredients({
        page,
        size: pageSize,
        suggestedName: filters.suggestedName || undefined,
        ingredientType: filters.ingredientType as IngredientType | undefined,
        localeCode: filters.localeCode || undefined,
        status: filters.status as SuggestionStatus | undefined,
        username: filters.username || undefined,
        sortBy,
        sortOrder,
      });
      setData(response.content);
      setTotalPages(response.totalPages);
      setTotalElements(response.totalElements);
      setPendingChanges({}); // Clear pending changes on data refresh
    } catch (err) {
      console.error('Error fetching suggested ingredients:', err);
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

  const handleStatusChange = (publicId: string, newStatus: SuggestionStatus) => {
    // Find original status
    const originalItem = data.find(item => item.publicId === publicId);
    if (!originalItem) return;

    // If new status equals original, remove from pending changes
    if (originalItem.status === newStatus) {
      setPendingChanges(prev => {
        const updated = { ...prev };
        delete updated[publicId];
        return updated;
      });
    } else {
      // Add to pending changes
      setPendingChanges(prev => ({ ...prev, [publicId]: newStatus }));
    }
  };

  const handleSave = async () => {
    const changeEntries = Object.entries(pendingChanges);
    if (changeEntries.length === 0) return;

    setSaving(true);
    setError(null);
    setSuccessMessage(null);

    let successCount = 0;
    let failCount = 0;

    for (const [publicId, newStatus] of changeEntries) {
      try {
        await updateSuggestedIngredientStatus(publicId, newStatus);
        // Update local data
        setData(prev =>
          prev.map(item =>
            item.publicId === publicId ? { ...item, status: newStatus } : item
          )
        );
        // Remove from pending changes
        setPendingChanges(prev => {
          const updated = { ...prev };
          delete updated[publicId];
          return updated;
        });
        successCount++;
      } catch (err) {
        console.error('Error updating status for', publicId, err);
        failCount++;
      }
    }

    setSaving(false);

    if (failCount === 0) {
      setSuccessMessage(`Successfully saved ${successCount} change(s).`);
      setTimeout(() => setSuccessMessage(null), 3000);
    } else {
      setError(`Saved ${successCount} change(s), but ${failCount} failed. Please try again.`);
    }
  };

  const pendingCount = Object.keys(pendingChanges).length;

  const columns: Column<UserSuggestedIngredient>[] = [
    {
      key: 'suggestedName',
      header: 'Suggested Name',
      sortable: true,
      filterable: true,
      filterType: 'text',
    },
    {
      key: 'ingredientType',
      header: 'Type',
      sortable: true,
      filterable: true,
      filterType: 'select',
      filterOptions: INGREDIENT_TYPE_OPTIONS,
      width: '120px',
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
      render: (item) => {
        const currentValue = pendingChanges[item.publicId] ?? item.status;
        const hasChange = item.publicId in pendingChanges;
        return (
          <select
            className={`px-2 py-1 text-sm border rounded focus:outline-none focus:border-[var(--primary)] ${
              hasChange
                ? 'border-[var(--primary)] bg-[var(--primary-light)] text-[var(--primary)] font-medium'
                : 'border-[var(--border)] bg-[var(--bg-primary)] text-[var(--text-primary)]'
            }`}
            value={currentValue}
            onChange={(e) => handleStatusChange(item.publicId, e.target.value as SuggestionStatus)}
          >
            {STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
        );
      },
    },
    {
      key: 'translations',
      header: 'Translations (KO / EN)',
      sortable: false,
      width: '200px',
      render: (item) =>
        item.status === 'APPROVED' && (item.autocompleteItemNameKo || item.autocompleteItemNameEn)
          ? `${item.autocompleteItemNameKo || '-'} / ${item.autocompleteItemNameEn || '-'}`
          : '-',
    },
    {
      key: 'rejectionReason',
      header: 'Rejection Reason',
      sortable: false,
      width: '200px',
      render: (item) => item.rejectionReason ? (
        <span className="text-sm text-red-600" title={item.rejectionReason}>
          {item.rejectionReason.length > 50
            ? `${item.rejectionReason.substring(0, 50)}...`
            : item.rejectionReason}
        </span>
      ) : '-',
    },
    {
      key: 'username',
      header: 'User',
      sortable: false,
      filterable: true,
      filterType: 'text',
      render: (item) => item.username || '-',
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

      {successMessage && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
          {successMessage}
        </div>
      )}

      {/* Save Button */}
      <div className="mb-4 flex items-center justify-between">
        <div className="text-sm text-[var(--text-secondary)]">
          {pendingCount > 0 && (
            <span className="text-[var(--primary)] font-medium">
              {pendingCount} unsaved change{pendingCount > 1 ? 's' : ''}
            </span>
          )}
        </div>
        <button
          onClick={handleSave}
          disabled={pendingCount === 0 || saving}
          className={`px-6 py-2 rounded-lg font-medium transition-colors ${
            pendingCount > 0
              ? 'bg-[var(--primary)] text-white hover:opacity-90'
              : 'bg-[var(--bg-secondary)] text-[var(--text-secondary)] cursor-not-allowed'
          } disabled:opacity-50`}
        >
          {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

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
          emptyMessage="No suggested ingredients found"
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

function UntranslatedRecipesTab() {
  const format = useFormatter();
  const formatDate = useCallback((dateString: string | null): string => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return format.dateTime(date, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZoneName: 'short',
    });
  }, [format]);

  const [data, setData] = useState<UntranslatedRecipe[]>([]);
  const [loading, setLoading] = useState(true);
  const [retranslating, setRetranslating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response: PageResponse<UntranslatedRecipe> = await getUntranslatedRecipes({
        page,
        size: pageSize,
        title: filters.title || undefined,
        sortBy,
        sortOrder,
      });
      setData(response.content);
      setTotalPages(response.totalPages);
      setTotalElements(response.totalElements);
      setSelectedItems(new Set());
    } catch (err) {
      console.error('Error fetching untranslated recipes:', err);
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

  const handleSelectItem = (publicId: string) => {
    setSelectedItems(prev => {
      const newSet = new Set(prev);
      if (newSet.has(publicId)) {
        newSet.delete(publicId);
      } else {
        newSet.add(publicId);
      }
      return newSet;
    });
  };

  const handleSelectAll = () => {
    if (selectedItems.size === data.length) {
      setSelectedItems(new Set());
    } else {
      setSelectedItems(new Set(data.map(item => item.publicId)));
    }
  };

  const handleRetranslate = async () => {
    if (selectedItems.size === 0) return;

    setRetranslating(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const result = await triggerRecipeRetranslation(Array.from(selectedItems));
      setSuccessMessage(`Successfully queued ${result.recipesQueued} recipe(s) for re-translation.`);
      setTimeout(() => setSuccessMessage(null), 5000);
      setSelectedItems(new Set());
      fetchData();
    } catch (err) {
      console.error('Error triggering re-translation:', err);
      setError('Failed to trigger re-translation. Please try again.');
    } finally {
      setRetranslating(false);
    }
  };

  const getStatusBadgeClass = (status: TranslationStatus | null): string => {
    switch (status) {
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'PROCESSING':
        return 'bg-blue-100 text-blue-800';
      case 'COMPLETED':
        return 'bg-green-100 text-green-800';
      case 'FAILED':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const columns: Column<UntranslatedRecipe>[] = [
    {
      key: 'select',
      header: (
        <input
          type="checkbox"
          checked={data.length > 0 && selectedItems.size === data.length}
          onChange={handleSelectAll}
          className="w-4 h-4"
        />
      ) as unknown as string,
      sortable: false,
      width: '50px',
      render: (item) => (
        <input
          type="checkbox"
          checked={selectedItems.has(item.publicId)}
          onChange={() => handleSelectItem(item.publicId)}
          className="w-4 h-4"
        />
      ),
    },
    {
      key: 'title',
      header: 'Title',
      sortable: true,
      filterable: true,
      filterType: 'text',
      render: (item) => (
        <span className="font-medium" title={item.title}>
          {item.title && item.title.length > 40 ? `${item.title.substring(0, 40)}...` : item.title || '-'}
        </span>
      ),
    },
    {
      key: 'url',
      header: 'URL',
      sortable: false,
      width: '80px',
      render: (item) => (
        <a
          href={`/recipes/${item.publicId}`}
          target="_blank"
          rel="noopener noreferrer"
          className="text-[var(--primary)] hover:underline text-sm"
        >
          View
        </a>
      ),
    },
    {
      key: 'cookingStyle',
      header: 'Locale',
      sortable: true,
      width: '80px',
    },
    {
      key: 'translationStatus',
      header: 'Status',
      sortable: false,
      width: '110px',
      render: (item) => (
        <span
          className={`px-2 py-1 text-xs font-medium rounded ${getStatusBadgeClass(item.translationStatus)}`}
        >
          {item.translationStatus || 'NONE'}
        </span>
      ),
    },
    {
      key: 'progress',
      header: 'Progress',
      sortable: false,
      width: '80px',
      render: (item) => (
        <span className="text-sm">
          {item.translatedLocaleCount}/{item.totalLocaleCount}
        </span>
      ),
    },
    {
      key: 'lastError',
      header: 'Error',
      sortable: false,
      width: '150px',
      render: (item) => item.lastError ? (
        <span className="text-sm text-red-600" title={item.lastError}>
          {item.lastError.length > 30 ? `${item.lastError.substring(0, 30)}...` : item.lastError}
        </span>
      ) : '-',
    },
    {
      key: 'creatorUsername',
      header: 'Creator',
      sortable: false,
      width: '100px',
    },
    {
      key: 'createdAt',
      header: 'Created',
      sortable: true,
      width: '160px',
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

      {successMessage && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
          {successMessage}
        </div>
      )}

      <div className="mb-4 flex items-center justify-between">
        <div className="text-sm text-[var(--text-secondary)]">
          {selectedItems.size > 0 && (
            <span className="text-[var(--primary)] font-medium">
              {selectedItems.size} item{selectedItems.size > 1 ? 's' : ''} selected
            </span>
          )}
        </div>
        <button
          onClick={handleRetranslate}
          disabled={selectedItems.size === 0 || retranslating}
          className={`px-6 py-2 rounded-lg font-medium transition-colors ${
            selectedItems.size > 0
              ? 'bg-[var(--primary)] text-white hover:opacity-90'
              : 'bg-[var(--bg-secondary)] text-[var(--text-secondary)] cursor-not-allowed'
          } disabled:opacity-50`}
        >
          {retranslating ? 'Queueing...' : 'Retranslate Selected'}
        </button>
      </div>

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
          emptyMessage="No untranslated recipes found"
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

function UntranslatedLogsTab() {
  const format = useFormatter();
  const formatDate = useCallback((dateString: string | null): string => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return format.dateTime(date, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZoneName: 'short',
    });
  }, [format]);

  const [data, setData] = useState<UntranslatedLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [retranslating, setRetranslating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [totalElements, setTotalElements] = useState(0);
  const pageSize = 20;
  const [filters, setFilters] = useState<Record<string, string>>({});
  const [sortBy, setSortBy] = useState('createdAt');
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('desc');
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response: PageResponse<UntranslatedLog> = await getUntranslatedLogs({
        page,
        size: pageSize,
        content: filters.content || undefined,
        sortBy,
        sortOrder,
      });
      setData(response.content);
      setTotalPages(response.totalPages);
      setTotalElements(response.totalElements);
      setSelectedItems(new Set());
    } catch (err) {
      console.error('Error fetching untranslated logs:', err);
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

  const handleSelectItem = (publicId: string) => {
    setSelectedItems(prev => {
      const newSet = new Set(prev);
      if (newSet.has(publicId)) {
        newSet.delete(publicId);
      } else {
        newSet.add(publicId);
      }
      return newSet;
    });
  };

  const handleSelectAll = () => {
    if (selectedItems.size === data.length) {
      setSelectedItems(new Set());
    } else {
      setSelectedItems(new Set(data.map(item => item.publicId)));
    }
  };

  const handleRetranslate = async () => {
    if (selectedItems.size === 0) return;

    setRetranslating(true);
    setError(null);
    setSuccessMessage(null);

    try {
      const result = await triggerLogRetranslation(Array.from(selectedItems));
      setSuccessMessage(`Successfully queued ${result.logsQueued} log(s) for re-translation.`);
      setTimeout(() => setSuccessMessage(null), 5000);
      setSelectedItems(new Set());
      fetchData();
    } catch (err) {
      console.error('Error triggering re-translation:', err);
      setError('Failed to trigger re-translation. Please try again.');
    } finally {
      setRetranslating(false);
    }
  };

  const getStatusBadgeClass = (status: TranslationStatus | null): string => {
    switch (status) {
      case 'PENDING':
        return 'bg-yellow-100 text-yellow-800';
      case 'PROCESSING':
        return 'bg-blue-100 text-blue-800';
      case 'COMPLETED':
        return 'bg-green-100 text-green-800';
      case 'FAILED':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const columns: Column<UntranslatedLog>[] = [
    {
      key: 'select',
      header: (
        <input
          type="checkbox"
          checked={data.length > 0 && selectedItems.size === data.length}
          onChange={handleSelectAll}
          className="w-4 h-4"
        />
      ) as unknown as string,
      sortable: false,
      width: '50px',
      render: (item) => (
        <input
          type="checkbox"
          checked={selectedItems.has(item.publicId)}
          onChange={() => handleSelectItem(item.publicId)}
          className="w-4 h-4"
        />
      ),
    },
    {
      key: 'content',
      header: 'Content',
      sortable: false,
      filterable: true,
      filterType: 'text',
      render: (item) => (
        <span className="font-medium" title={item.content}>
          {item.content && item.content.length > 50 ? `${item.content.substring(0, 50)}...` : item.content || '-'}
        </span>
      ),
    },
    {
      key: 'url',
      header: 'URL',
      sortable: false,
      width: '80px',
      render: (item) => (
        <a
          href={`/logs/${item.publicId}`}
          target="_blank"
          rel="noopener noreferrer"
          className="text-[var(--primary)] hover:underline text-sm"
        >
          View
        </a>
      ),
    },
    {
      key: 'translationStatus',
      header: 'Status',
      sortable: false,
      width: '110px',
      render: (item) => (
        <span
          className={`px-2 py-1 text-xs font-medium rounded ${getStatusBadgeClass(item.translationStatus)}`}
        >
          {item.translationStatus || 'NONE'}
        </span>
      ),
    },
    {
      key: 'progress',
      header: 'Progress',
      sortable: false,
      width: '80px',
      render: (item) => (
        <span className="text-sm">
          {item.translatedLocaleCount}/{item.totalLocaleCount}
        </span>
      ),
    },
    {
      key: 'lastError',
      header: 'Error',
      sortable: false,
      width: '150px',
      render: (item) => item.lastError ? (
        <span className="text-sm text-red-600" title={item.lastError}>
          {item.lastError.length > 30 ? `${item.lastError.substring(0, 30)}...` : item.lastError}
        </span>
      ) : '-',
    },
    {
      key: 'creatorUsername',
      header: 'Creator',
      sortable: false,
      width: '100px',
    },
    {
      key: 'createdAt',
      header: 'Created',
      sortable: true,
      width: '160px',
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

      {successMessage && (
        <div className="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-700">
          {successMessage}
        </div>
      )}

      <div className="mb-4 flex items-center justify-between">
        <div className="text-sm text-[var(--text-secondary)]">
          {selectedItems.size > 0 && (
            <span className="text-[var(--primary)] font-medium">
              {selectedItems.size} item{selectedItems.size > 1 ? 's' : ''} selected
            </span>
          )}
        </div>
        <button
          onClick={handleRetranslate}
          disabled={selectedItems.size === 0 || retranslating}
          className={`px-6 py-2 rounded-lg font-medium transition-colors ${
            selectedItems.size > 0
              ? 'bg-[var(--primary)] text-white hover:opacity-90'
              : 'bg-[var(--bg-secondary)] text-[var(--text-secondary)] cursor-not-allowed'
          } disabled:opacity-50`}
        >
          {retranslating ? 'Queueing...' : 'Retranslate Selected'}
        </button>
      </div>

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
          emptyMessage="No untranslated logs found"
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
