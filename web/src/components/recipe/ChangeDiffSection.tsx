'use client';

import { useState } from 'react';

interface ChangeDiffSectionProps {
  changeDiff: Record<string, unknown> | null;
}

interface DiffData {
  added?: string[];
  removed?: string[];
  modified?: Array<{ from?: string; to?: string } | string>;
}

export function ChangeDiffSection({ changeDiff }: ChangeDiffSectionProps) {
  const [isExpanded, setIsExpanded] = useState(false); // Collapsed by default

  if (!changeDiff) return null;

  const ingredientsDiff = changeDiff.ingredients as DiffData | undefined;
  const stepsDiff = changeDiff.steps as DiffData | undefined;

  const hasChanges = (diff: DiffData | undefined): boolean => {
    if (!diff) return false;
    return (
      (diff.added?.length ?? 0) > 0 ||
      (diff.removed?.length ?? 0) > 0 ||
      (diff.modified?.length ?? 0) > 0
    );
  };

  const hasIngredientChanges = hasChanges(ingredientsDiff);
  const hasStepChanges = hasChanges(stepsDiff);

  if (!hasIngredientChanges && !hasStepChanges) return null;

  return (
    <div className="border border-[var(--border)] rounded-xl overflow-hidden">
      {/* Header with toggle */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full flex items-center justify-between p-4 bg-[var(--surface)] hover:bg-[var(--background)] transition-colors"
      >
        <div className="flex items-center gap-2">
          <svg
            className="w-5 h-5 text-[#F39C12]"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
            />
          </svg>
          <span className="font-semibold text-[var(--text-primary)]">
            What Changed
          </span>
        </div>
        <div className="flex items-center gap-2 text-sm text-[var(--primary)]">
          <svg
            className={`w-4 h-4 transition-transform ${isExpanded ? '' : 'rotate-180'}`}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 15l7-7 7 7"
            />
          </svg>
          <span>{isExpanded ? 'Hide' : 'Show'}</span>
        </div>
      </button>

      {/* Content */}
      {isExpanded && (
        <div className="border-t border-[var(--border)]">
          {hasIngredientChanges && ingredientsDiff && (
            <DiffGroup
              title="Ingredients"
              icon={
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 3h18v18H3zM12 8v8m-4-4h8" />
                </svg>
              }
              diffData={ingredientsDiff}
            />
          )}
          {hasStepChanges && stepsDiff && (
            <>
              {hasIngredientChanges && <div className="border-t border-[var(--border)]" />}
              <DiffGroup
                title="Steps"
                icon={
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                  </svg>
                }
                diffData={stepsDiff}
              />
            </>
          )}
        </div>
      )}
    </div>
  );
}

interface DiffGroupProps {
  title: string;
  icon: React.ReactNode;
  diffData: DiffData;
}

function DiffGroup({ title, icon, diffData }: DiffGroupProps) {
  const { added = [], removed = [], modified = [] } = diffData;

  return (
    <div className="p-4">
      {/* Group title */}
      <div className="flex items-center gap-2 text-[var(--text-secondary)] text-sm font-medium mb-3">
        {icon}
        <span>{title}</span>
      </div>

      {/* Added items */}
      {added.length > 0 && (
        <div className="mb-3 bg-[#E8F5E9] rounded-lg overflow-hidden">
          {added.map((item, index) => (
            <div
              key={`added-${index}`}
              className="flex items-start gap-2 px-3 py-2 text-[#27AE60]"
            >
              <span className="font-bold">+</span>
              <span className="text-sm">{item}</span>
            </div>
          ))}
        </div>
      )}

      {/* Modified items */}
      {modified.length > 0 && (
        <div className="mb-3 bg-[#FFF3E0] rounded-lg overflow-hidden">
          {modified.map((item, index) => {
            const from = typeof item === 'object' ? item.from : '';
            const to = typeof item === 'object' ? item.to : String(item);

            return (
              <div
                key={`modified-${index}`}
                className="flex items-start gap-2 px-3 py-2 text-[#F39C12]"
              >
                <span className="font-bold">~</span>
                <span className="text-sm">
                  {from && (
                    <>
                      <span className="line-through">{from}</span>
                      <span className="mx-2">→</span>
                    </>
                  )}
                  <span className="font-medium">{to}</span>
                </span>
              </div>
            );
          })}
        </div>
      )}

      {/* Removed items */}
      {removed.length > 0 && (
        <div className="bg-[#FFEBEE] rounded-lg overflow-hidden">
          {removed.map((item, index) => (
            <div
              key={`removed-${index}`}
              className="flex items-start gap-2 px-3 py-2 text-[#E74C3C]"
            >
              <span className="font-bold">-</span>
              <span className="text-sm line-through">{item}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
