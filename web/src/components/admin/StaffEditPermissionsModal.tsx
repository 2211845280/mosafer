"use client";

import { PermissionMatrix } from "@/components/admin/PermissionMatrix";
import {
  backendFromUiSelection,
  filterAssignableUiActions,
  uiFromBackendPermissionNames,
  ALL_UI_ACTION_IDS,
} from "@/lib/admin/system-permissions";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useState } from "react";

type Props = {
  staffId: number;
  staffName: string;
  initialPermissionNames: string[];
  isSuperAdminViewer: boolean;
  open: boolean;
  onClose: () => void;
  onSaved: () => void;
};

export function StaffEditPermissionsModal({
  staffId,
  staffName,
  initialPermissionNames,
  isSuperAdminViewer,
  open,
  onClose,
  onSaved,
}: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const titleId = "staff-edit-permissions-title";
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    const assignable = new Set(
      filterAssignableUiActions(ALL_UI_ACTION_IDS, isSuperAdminViewer),
    );
    const fromBackend = uiFromBackendPermissionNames(initialPermissionNames);
    setSelected(new Set([...fromBackend].filter((id) => assignable.has(id))));
    setErr(null);
  }, [open, initialPermissionNames, isSuperAdminViewer]);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !saving) onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose, saving]);

  function togglePerm(uiId: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(uiId)) next.delete(uiId);
      else next.add(uiId);
      return next;
    });
  }

  async function onSave() {
    setErr(null);
    if (selected.size === 0) {
      setErr(t("staffPickPermission"));
      return;
    }
    setSaving(true);
    try {
      const res = await fetch(`/api/admin/staff/${staffId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({
          permission_names: backendFromUiSelection(selected),
        }),
      });
      const data = (await res.json().catch(() => ({}))) as { detail?: string };
      if (!res.ok) {
        setErr(typeof data.detail === "string" ? data.detail : t("staffPermissionsSaveError"));
        return;
      }
      onSaved();
      onClose();
    } catch {
      setErr(t("staffPermissionsSaveError"));
    } finally {
      setSaving(false);
    }
  }

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
      role="presentation"
      onClick={() => !saving && onClose()}
    >
      <div
        className="profile-hero max-h-[90vh] w-full max-w-4xl overflow-y-auto"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id={titleId} className="text-lg font-black text-foreground">
          {staffName} — {t("staffEditPermissions")}
        </h2>

        <PermissionMatrix
          selected={selected}
          onToggle={togglePerm}
          isSuperAdminViewer={isSuperAdminViewer}
        />

        {err && (
          <p className="mt-4 text-sm font-semibold text-accent" role="alert">
            {err}
          </p>
        )}

        <div className="mt-6 flex flex-wrap justify-end gap-3">
          <button
            type="button"
            disabled={saving}
            onClick={onClose}
            className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
          >
            {t("close")}
          </button>
          <button
            type="button"
            disabled={saving}
            onClick={() => void onSave()}
            className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
          >
            {saving ? t("loading") : t("staffSavePermissions")}
          </button>
        </div>
      </div>
    </div>
  );
}
