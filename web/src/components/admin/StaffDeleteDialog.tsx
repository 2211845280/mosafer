"use client";

import { useLocale, useTranslations } from "next-intl";
import { useEffect, useState } from "react";

type Props = {
  staffId: number;
  staffName: string;
  open: boolean;
  onClose: () => void;
  onDeleted: (staffId: number) => void;
};

type ApiErrorDetail =
  | string
  | Array<{ msg?: string }>
  | undefined;

function extractDetailMessage(detail: ApiErrorDetail): string | undefined {
  if (typeof detail === "string" && detail.trim()) {
    return detail;
  }
  if (Array.isArray(detail)) {
    const first = detail.find((item) => typeof item.msg === "string")?.msg;
    return first?.trim() || undefined;
  }
  return undefined;
}

function resolveDeleteError(
  status: number,
  detail: ApiErrorDetail,
  t: (key: string) => string,
): string {
  const message = extractDetailMessage(detail);
  if (status === 403 || message === "Insufficient permissions") {
    return t("staffDeleteNoPermission");
  }
  if (status === 500) {
    return t("staffDeleteServerError");
  }
  if (status === 409 || message === "Could not delete admin staff due to related records") {
    return t("staffDeleteConflict");
  }
  if (message === "You cannot delete your own account") {
    return t("staffDeleteSelfForbidden");
  }
  if (message === "Superadmin account cannot be deleted") {
    return t("staffDeleteSuperadminForbidden");
  }
  if (message) {
    return message;
  }
  return t("staffDeleteError");
}

export function StaffDeleteDialog({
  staffId,
  staffName,
  open,
  onClose,
  onDeleted,
}: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const titleId = "staff-delete-title";
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setErr(null);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !busy) onClose();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose, busy]);

  async function handleDelete() {
    setBusy(true);
    setErr(null);
    try {
      const res = await fetch(`/api/admin/staff/${staffId}`, {
        method: "DELETE",
        headers: { "Accept-Language": locale },
      });
      const data = (await res.json().catch(() => ({}))) as {
        detail?: ApiErrorDetail;
      };
      if (!res.ok) {
        setErr(resolveDeleteError(res.status, data.detail, t));
        return;
      }
      onDeleted(staffId);
      onClose();
    } catch {
      setErr(t("staffDeleteError"));
    } finally {
      setBusy(false);
    }
  }

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      role="presentation"
      onClick={() => !busy && onClose()}
    >
      <div
        className="profile-hero w-full max-w-md"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id={titleId} className="text-lg font-black text-foreground">
          {t("staffDelete")}
        </h2>
        <p className="mt-3 text-sm text-muted">{t("staffDeleteConfirm", { name: staffName })}</p>

        {err && (
          <p className="mt-3 text-sm font-semibold text-accent" role="alert">
            {err}
          </p>
        )}

        <div className="mt-6 flex flex-wrap gap-3">
          <button
            type="button"
            disabled={busy}
            onClick={() => void handleDelete()}
            className="rounded-mosafer bg-accent px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:opacity-90 disabled:opacity-60"
          >
            {busy ? t("loading") : t("staffDelete")}
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={onClose}
            className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
          >
            {t("close")}
          </button>
        </div>
      </div>
    </div>
  );
}
