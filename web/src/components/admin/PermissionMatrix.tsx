"use client";

import {
  actionLabelKey,
  groupLabelKey,
  visiblePermissionGroups,
} from "@/lib/admin/system-permissions";
import { useLocale, useMessages } from "next-intl";

type Props = {
  selected: Set<string>;
  onToggle: (uiId: string) => void;
  isSuperAdminViewer: boolean;
};

export function PermissionMatrix({ selected, onToggle, isSuperAdminViewer }: Props) {
  const locale = useLocale();
  const adminMessages = (useMessages().admin ?? {}) as Record<string, string>;
  const groups = visiblePermissionGroups(isSuperAdminViewer);
  const isRtl = locale === "ar";

  function labelForGroup(groupId: string, titleKey: string): string {
    const key = groupLabelKey(groupId);
    return adminMessages[key] ?? adminMessages[titleKey] ?? groupId;
  }

  function labelForAction(actionId: string, labelKey: string): string {
    const key = actionLabelKey(actionId);
    return adminMessages[key] ?? adminMessages[labelKey] ?? actionId;
  }

  return (
    <div
      className="mt-4 grid grid-cols-1 gap-4 md:grid-cols-2"
      dir={isRtl ? "rtl" : "ltr"}
    >
      {groups.map((group) => (
        <div
          key={group.id}
          className="rounded-card border border-border-subtle bg-card p-5 transition-colors hover:border-border-strong"
        >
          <h3 className="border-b border-border-subtle pb-2 text-base font-black text-primary">
            {labelForGroup(group.id, group.titleKey)}
          </h3>
          <div className="mt-4 space-y-3">
            {group.actions.map((action) => {
              const isChecked = selected.has(action.id);
              const label = labelForAction(action.id, action.labelKey);
              return (
                <label
                  key={action.id}
                  className="flex cursor-pointer items-center gap-3"
                >
                  <input
                    type="checkbox"
                    checked={isChecked}
                    onChange={() => onToggle(action.id)}
                    className="h-5 w-5 shrink-0 rounded border-border-strong accent-primary"
                    aria-label={label}
                  />
                  <span
                    className={`text-sm ${
                      isChecked ? "font-bold text-foreground" : "text-muted"
                    }`}
                  >
                    {label}
                  </span>
                </label>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
