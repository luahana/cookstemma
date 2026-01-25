'use client';

import { useState, useRef, useEffect } from 'react';

export interface ActionMenuItem {
  label: string;
  onClick: () => void;
  icon?: React.ReactNode;
  disabled?: boolean;
  isDestructive?: boolean;
  tooltip?: string; // Shown when disabled
}

interface ActionMenuProps {
  items: ActionMenuItem[];
  disabled?: boolean;
}

export function ActionMenu({ items, disabled = false }: ActionMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  // Close menu on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Close menu on escape
  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setIsOpen(false);
      }
    }
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleItemClick = (item: ActionMenuItem) => {
    if (item.disabled) return;
    setIsOpen(false);
    item.onClick();
  };

  return (
    <div className="relative" ref={menuRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        disabled={disabled}
        className="p-2 rounded-lg hover:bg-[var(--background)] transition-colors disabled:opacity-50"
        aria-label="Actions menu"
        aria-expanded={isOpen}
        aria-haspopup="true"
      >
        <svg
          className="w-5 h-5 text-[var(--text-secondary)]"
          fill="currentColor"
          viewBox="0 0 24 24"
        >
          <circle cx="12" cy="5" r="2" />
          <circle cx="12" cy="12" r="2" />
          <circle cx="12" cy="19" r="2" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-1 w-48 bg-[var(--surface)] border border-[var(--border)] rounded-xl shadow-lg py-1 z-50">
          {items.map((item, index) => (
            <button
              key={index}
              onClick={() => handleItemClick(item)}
              disabled={item.disabled}
              title={item.disabled ? item.tooltip : undefined}
              className={`w-full flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                item.disabled
                  ? 'text-[var(--text-secondary)] cursor-not-allowed'
                  : item.isDestructive
                    ? 'text-[var(--error)] hover:bg-red-50'
                    : 'text-[var(--text-primary)] hover:bg-[var(--background)]'
              }`}
            >
              {item.icon && (
                <span className="w-5 h-5 flex items-center justify-center">
                  {item.icon}
                </span>
              )}
              <span className="flex-1 text-left">{item.label}</span>
              {item.disabled && (
                <svg
                  className="w-4 h-4 text-[var(--text-secondary)]"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

// Common icons for action menu items
export const ActionMenuIcons = {
  edit: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
      />
    </svg>
  ),
  delete: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
      />
    </svg>
  ),
  block: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"
      />
    </svg>
  ),
  report: (
    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth={2}
        d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
      />
    </svg>
  ),
};
