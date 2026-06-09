"use client";

import {
  actionLabelKey,
  groupLabelKey,
  uiFromBackendPermissionNames,
  visiblePermissionGroups,
} from "@/lib/admin/system-permissions";
import { useLocale, useMessages, useTranslations } from "next-intl";
import { useEffect, useMemo } from "react";

type Props = {
  staffName: string;
  permissionNames: string[];
  open: boolean;
  onClose: () => void;
};

export function StaffPermissionsModal({
  staffName,
  permissionNames,
  open,
  onClose,
}: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const adminMessages = (useMessages().admin ?? {}) as Record<string, string>;
  const titleId = "staff-permissions-modal-title";
  const isRtl = locale === "ar";

  const selectedUi = useMemo(
    () => uiFromBackendPermissionNames(permissionNames),
    [permissionNames],
  );

  const groupsWithActions = useMemo(() => {
    const groups = visiblePermissionGroups(true);
    return groups
      .map((group) => ({
        ...group,
        actions: group.actions.filter((action) => selectedUi.has(action.id)),
      }))
      .filter((group) => group.actions.length > 0);
  }, [selectedUi]);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

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
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      role="presentation"
      onClick={onClose}
    >
      <div
        className="profile-hero max-h-[85vh] w-full max-w-lg overflow-y-auto"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
        dir={isRtl ? "rtl" : "ltr"}
      >
        <h2 id={titleId} className="text-lg font-black text-foreground">
          {staffName} — {t("staffPermissions")}
        </h2>

        {groupsWithActions.length === 0 ? (
          <p className="mt-4 text-sm text-muted">{t("staffNoPermissions")}</p>
        ) : (
          <div className="mt-4 space-y-4">
            {groupsWithActions.map((group) => (
              <div key={group.id}>
                <p className="text-sm font-black text-foreground">
                  {labelForGroup(group.id, group.titleKey)}
                </p>
                <div className="my-2 border-b border-border-subtle" />
                <div className="flex flex-wrap gap-2">
                  {group.actions.map((action) => (
                    <span
                      key={action.id}
                      className="rounded-mosafer bg-primary/15 px-2.5 py-1 text-xs font-bold text-primary"
                    >
                      {labelForAction(action.id, action.labelKey)}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="mt-6 flex justify-end">
          <button
            type="button"
            onClick={onClose}
            className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
          >
            {t("close")}
          </button>
        </div>
      </div>
    </div>
  );
}
