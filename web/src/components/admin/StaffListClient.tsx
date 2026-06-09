"use client";

import { StaffDeleteDialog } from "@/components/admin/StaffDeleteDialog";
import { StaffEditPermissionsModal } from "@/components/admin/StaffEditPermissionsModal";
import { StaffPermissionsModal } from "@/components/admin/StaffPermissionsModal";
import {
  formatStaffRoleLabel,
  isSuperAdminStaff,
} from "@/lib/admin/staff-role-label";
import { Link } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useCallback, useEffect, useState } from "react";

export type StaffRow = {
  id: number;
  email: string;
  full_name: string;
  phone: string;
  is_active: boolean;
  role_name: string;
  permission_names: string[];
};

type Props = {
  currentUserId: number;
  isSuperAdmin: boolean;
};

function formatPhone(phone: string | null | undefined): string {
  return phone && phone !== "unknown" ? phone : "—";
}

function canManageStaffRow(row: StaffRow, currentUserId: number): boolean {
  return !isSuperAdminStaff(row.role_name) && row.id !== currentUserId;
}

export function StaffListClient({ currentUserId, isSuperAdmin }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [staff, setStaff] = useState<StaffRow[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [viewPermissionsStaff, setViewPermissionsStaff] = useState<StaffRow | null>(null);
  const [editPermissionsStaff, setEditPermissionsStaff] = useState<StaffRow | null>(null);
  const [deleteStaff, setDeleteStaff] = useState<StaffRow | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setErr(null);
    try {
      const res = await fetch("/api/admin/staff", {
        headers: { "Accept-Language": locale },
      });
      if (!res.ok) {
        setErr(t("staffLoadError"));
        return;
      }
      setStaff((await res.json()) as StaffRow[]);
    } catch {
      setErr(t("staffLoadError"));
    } finally {
      setLoading(false);
    }
  }, [locale, t]);

  useEffect(() => {
    void load();
  }, [load]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <p className="text-muted">{t("loading")}…</p>
      </div>
    );
  }

  if (err) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-6">
        <p className="text-accent">{err}</p>
      </div>
    );
  }

  return (
    <div>
      <div>
        <h1 className="text-2xl font-black text-foreground">{t("staffTitle")}</h1>
        <p className="mt-1 text-sm text-muted">{t("staffSubtitle")}</p>
      </div>

      <div className="mt-6 rounded-card border border-border-subtle bg-card p-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h2 className="text-lg font-black text-foreground">{t("staffListTitle")}</h2>
          <Link
            href="/admin/staff/new"
            className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-black uppercase text-primary-foreground transition-transform hover:scale-[1.02]"
          >
            {t("staffAdd")}
          </Link>
        </div>

        <div className="mt-4 overflow-x-auto rounded-mosafer border border-border-subtle">
          <table className="w-full min-w-[1000px] table-fixed text-center text-sm">
            <thead>
              <tr className="border-b border-border-subtle bg-surface text-xs font-black uppercase text-muted">
                <th className="px-4 py-3 text-center">{t("staffFullName")}</th>
                <th className="px-4 py-3 text-center">{t("email")}</th>
                <th className="px-4 py-3 text-center">{t("staffPhone")}</th>
                <th className="px-4 py-3 text-center">{t("role")}</th>
                <th className="px-4 py-3 text-center">{t("staffPermissions")}</th>
                <th className="px-4 py-3 text-center">{t("staffActions")}</th>
              </tr>
            </thead>
            <tbody>
              {staff.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-muted">
                    {t("staffListEmpty")}
                  </td>
                </tr>
              ) : (
                staff.map((row) => {
                  const manageable = canManageStaffRow(row, currentUserId);
                  return (
                    <tr
                      key={row.id}
                      className="border-b border-border-subtle transition-colors hover:bg-foreground/5"
                    >
                      <td className="px-4 py-3 text-center font-bold text-foreground">
                        {row.full_name}
                      </td>
                      <td
                        className="px-4 py-3 text-center font-mono text-xs text-foreground"
                        dir="ltr"
                      >
                        {row.email}
                      </td>
                      <td className="px-4 py-3 text-center text-xs text-foreground" dir="ltr">
                        {formatPhone(row.phone)}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span
                          className={`inline-flex rounded-mosafer px-2.5 py-1 text-xs font-medium ${
                            isSuperAdminStaff(row.role_name)
                              ? "bg-primary/15 text-primary"
                              : "bg-foreground/10 text-muted"
                          }`}
                        >
                          {formatStaffRoleLabel(row.role_name, t)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-center">
                        {row.permission_names.length === 0 ? (
                          <span className="text-xs text-muted">—</span>
                        ) : (
                          <button
                            type="button"
                            onClick={() => setViewPermissionsStaff(row)}
                            className="rounded-mosafer border border-border-strong px-3 py-1.5 text-xs font-bold text-primary transition-colors hover:border-primary hover:bg-primary/10"
                          >
                            {t("staffViewPermissions")}
                          </button>
                        )}
                      </td>
                      <td className="px-4 py-3 text-center">
                        {manageable ? (
                          <div className="flex flex-wrap items-center justify-center gap-2">
                            <button
                              type="button"
                              onClick={() => setEditPermissionsStaff(row)}
                              className="rounded-mosafer border border-border-strong px-3 py-1.5 text-xs font-bold text-foreground transition-colors hover:border-primary hover:text-primary"
                            >
                              {t("staffEditPermissions")}
                            </button>
                            <button
                              type="button"
                              onClick={() => setDeleteStaff(row)}
                              className="rounded-mosafer border border-accent/40 px-3 py-1.5 text-xs font-bold text-accent transition-colors hover:border-accent hover:bg-accent/10"
                            >
                              {t("staffDelete")}
                            </button>
                          </div>
                        ) : (
                          <span className="text-xs text-muted">—</span>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {viewPermissionsStaff && (
        <StaffPermissionsModal
          staffName={viewPermissionsStaff.full_name}
          permissionNames={viewPermissionsStaff.permission_names}
          open
          onClose={() => setViewPermissionsStaff(null)}
        />
      )}

      {editPermissionsStaff && (
        <StaffEditPermissionsModal
          staffId={editPermissionsStaff.id}
          staffName={editPermissionsStaff.full_name}
          initialPermissionNames={editPermissionsStaff.permission_names}
          isSuperAdminViewer={isSuperAdmin}
          open
          onClose={() => setEditPermissionsStaff(null)}
          onSaved={() => void load()}
        />
      )}

      {deleteStaff && (
        <StaffDeleteDialog
          staffId={deleteStaff.id}
          staffName={deleteStaff.full_name}
          open
          onClose={() => setDeleteStaff(null)}
          onDeleted={() => void load()}
        />
      )}
    </div>
  );
}
