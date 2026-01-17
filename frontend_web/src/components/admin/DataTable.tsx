'use client';

import { ReactNode } from 'react';

export interface Column<T> {
  key: string;
  header: string;
  sortable?: boolean;
  filterable?: boolean;
  filterType?: 'text' | 'select';
  filterOptions?: { value: string; label: string }[];
  render?: (item: T) => ReactNode;
  width?: string;
}

interface DataTableProps<T> {
  data: T[];
  columns: Column<T>[];
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
  onSort?: (key: string) => void;
  filters?: Record<string, string>;
  onFilterChange?: (key: string, value: string) => void;
  loading?: boolean;
  emptyMessage?: string;
}

function SortIcon({ active, direction }: { active: boolean; direction: 'asc' | 'desc' }) {
  return (
    <span className="ml-1 inline-flex flex-col text-xs">
      <span className={`leading-none ${active && direction === 'asc' ? 'text-[var(--primary)]' : 'text-[var(--text-secondary)] opacity-40'}`}>
        ▲
      </span>
      <span className={`leading-none ${active && direction === 'desc' ? 'text-[var(--primary)]' : 'text-[var(--text-secondary)] opacity-40'}`}>
        ▼
      </span>
    </span>
  );
}

export function DataTable<T extends { publicId: string }>({
  data,
  columns,
  sortBy,
  sortOrder = 'desc',
  onSort,
  filters = {},
  onFilterChange,
  loading = false,
  emptyMessage = 'No data available',
}: DataTableProps<T>) {
  const handleSort = (key: string) => {
    if (onSort) {
      onSort(key);
    }
  };

  const handleFilterChange = (key: string, value: string) => {
    if (onFilterChange) {
      onFilterChange(key, value);
    }
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full border-collapse">
        {/* Header Row */}
        <thead>
          <tr className="bg-[var(--bg-secondary)] border-b border-[var(--border)]">
            {columns.map((column) => (
              <th
                key={column.key}
                className={`px-4 py-3 text-left text-sm font-semibold text-[var(--text-primary)] ${
                  column.sortable ? 'cursor-pointer hover:bg-[var(--bg-tertiary)] select-none' : ''
                }`}
                style={{ width: column.width }}
                onClick={() => column.sortable && handleSort(column.key)}
              >
                <div className="flex items-center">
                  {column.header}
                  {column.sortable && (
                    <SortIcon active={sortBy === column.key} direction={sortOrder} />
                  )}
                </div>
              </th>
            ))}
          </tr>
          {/* Filter Row */}
          {columns.some(col => col.filterable) && (
            <tr className="bg-[var(--bg-primary)] border-b border-[var(--border)]">
              {columns.map((column) => (
                <th key={`filter-${column.key}`} className="px-4 py-2">
                  {column.filterable && column.filterType === 'select' ? (
                    <select
                      className="w-full px-2 py-1 text-sm border border-[var(--border)] rounded bg-[var(--bg-primary)] text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
                      value={filters[column.key] || ''}
                      onChange={(e) => handleFilterChange(column.key, e.target.value)}
                    >
                      <option value="">All</option>
                      {column.filterOptions?.map((opt) => (
                        <option key={opt.value} value={opt.value}>
                          {opt.label}
                        </option>
                      ))}
                    </select>
                  ) : column.filterable ? (
                    <input
                      type="text"
                      className="w-full px-2 py-1 text-sm border border-[var(--border)] rounded bg-[var(--bg-primary)] text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
                      placeholder={`Filter ${column.header.toLowerCase()}...`}
                      value={filters[column.key] || ''}
                      onChange={(e) => handleFilterChange(column.key, e.target.value)}
                    />
                  ) : null}
                </th>
              ))}
            </tr>
          )}
        </thead>
        {/* Body */}
        <tbody>
          {loading ? (
            <tr>
              <td
                colSpan={columns.length}
                className="px-4 py-8 text-center text-[var(--text-secondary)]"
              >
                Loading...
              </td>
            </tr>
          ) : data.length === 0 ? (
            <tr>
              <td
                colSpan={columns.length}
                className="px-4 py-8 text-center text-[var(--text-secondary)]"
              >
                {emptyMessage}
              </td>
            </tr>
          ) : (
            data.map((item) => (
              <tr
                key={item.publicId}
                className="border-b border-[var(--border)] hover:bg-[var(--bg-secondary)] transition-colors"
              >
                {columns.map((column) => (
                  <td
                    key={`${item.publicId}-${column.key}`}
                    className="px-4 py-3 text-sm text-[var(--text-primary)]"
                  >
                    {column.render
                      ? column.render(item)
                      : (item as Record<string, unknown>)[column.key]?.toString() || '-'}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
