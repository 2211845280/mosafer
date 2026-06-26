"use client";

import { UserStatusBadge } from "@/components/admin/UserStatusBadge";
import { Link } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useState } from "react";

export type AdminUserRow = {
  id: number;
  email: string;
  is_active: boolean;
  is_email_verified?: boolean;
  role_id: number | null;
  created_at?: string;
  passenger?: {
    full_name: string;
    phone?: string | null;
    account_status: string;
    passport_details?: {
      passport_number?: string | null;
    } | null;
  } | null;
  admin?: { id: number } | null;
};

type PageResp = {
  items: AdminUserRow[];
  total: number;
};

type FilterStatus = "all" | "active" | "inactive";

function formatPhone(phone: string | null | undefined): string {
  return phone && phone !== "unknown" ? phone : "—";
}

function EyeIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5" />
    </svg>
  );
}

export function AdminUsersClient() {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [rows, setRows] = useState<AdminUserRow[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState<FilterStatus>("all");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(
          "/api/admin/users?page=1&page_size=100&passengers_only=true",
          { headers: { "Accept-Language": locale } },
        );
        const data = (await res.json()) as PageResp & { detail?: string };
        if (!res.ok) {
          if (!cancelled) {
            setErr(typeof data.detail === "string" ? data.detail : t("loadUsersError"));
          }
          return;
        }
        if (!cancelled) {
          setRows((data.items ?? []).filter((u) => !u.admin));
        }
      } catch {
        if (!cancelled) setErr(t("loadUsersError"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locale]);

  const filteredRows = useMemo(() => {
    return rows.filter((u) => {
      if (u.admin) return false;
      if (filterStatus === "active" && !u.is_active) return false;
      if (filterStatus === "inactive" && u.is_active) return false;
      if (!search.trim()) return true;
      const query = search.toLowerCase();
      return (
        u.email.toLowerCase().includes(query) ||
        (u.passenger?.full_name ?? "").toLowerCase().includes(query) ||
        (u.passenger?.phone ?? "").toLowerCase().includes(query) ||
        (u.passenger?.passport_details?.passport_number ?? "")
          .toLowerCase()
          .includes(query)
      );
    });
  }, [rows, search, filterStatus]);

  const stats = useMemo(
    () => ({
      total: rows.length,
      active: rows.filter((u) => u.is_active).length,
      inactive: rows.filter((u) => !u.is_active).length,
    }),
    [rows],
  );

  const pillClass = (active: boolean) =>
    `rounded-mosafer px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors ${
      active
        ? "bg-foreground/10 text-foreground"
        : "border border-border-strong text-muted hover:text-foreground"
    }`;

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
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-black text-foreground">{t("users")}</h1>
        <div className="flex flex-wrap gap-3 text-xs font-bold">
          <span className="rounded-full bg-foreground/10 px-3 py-1 text-muted">
            {t("total")}: {stats.total}
          </span>
          <span className="rounded-full bg-primary/20 px-3 py-1 text-primary">
            {t("active")}: {stats.active}
          </span>
          <span className="rounded-full bg-accent/20 px-3 py-1 text-accent">
            {t("inactive")}: {stats.inactive}
          </span>
        </div>
      </div>

      <div className="mt-6 rounded-card border border-border-subtle bg-card p-6">
        <div className="flex flex-wrap items-center gap-3">
          <div className="min-w-[200px] flex-1">
            <input
              type="text"
              placeholder={t("searchPlaceholder")}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="form-input w-full"
            />
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setFilterStatus("all")}
              className={pillClass(filterStatus === "all")}
            >
              {t("all")}
            </button>
            <button
              type="button"
              onClick={() => setFilterStatus("active")}
              className={pillClass(filterStatus === "active")}
            >
              {t("active")}
            </button>
            <button
              type="button"
              onClick={() => setFilterStatus("inactive")}
              className={pillClass(filterStatus === "inactive")}
            >
              {t("inactive")}
            </button>
          </div>
        </div>

        <div className="mt-4 overflow-x-auto rounded-mosafer border border-border-subtle">
          <table className="w-full min-w-[900px] table-fixed text-center text-sm">
            <thead>
              <tr className="border-b border-border-subtle bg-surface text-xs font-black uppercase text-muted">
                <th className="px-4 py-3 text-center">{t("fullName")}</th>
                <th className="px-4 py-3 text-center">{t("email")}</th>
                <th className="px-4 py-3 text-center">{t("phone")}</th>
                <th className="px-4 py-3 text-center">{t("passportNumber")}</th>
                <th className="px-4 py-3 text-center">{t("status")}</th>
                <th className="px-4 py-3 text-center">{t("actions")}</th>
              </tr>
            </thead>
            <tbody>
              {filteredRows.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-muted">
                    {t("noUsersFound")}
                  </td>
                </tr>
              ) : (
                filteredRows.map((u) => (
                  <tr
                    key={u.id}
                    className="border-b border-border-subtle transition-colors hover:bg-foreground/5"
                  >
                    <td className="px-4 py-3 text-center font-bold text-foreground">
                      {u.passenger?.full_name ?? "—"}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <div className="inline-flex flex-col items-center gap-2">
                        <span className="font-mono text-xs text-foreground" dir="ltr">
                          {u.email}
                        </span>
                        {u.is_email_verified && (
                          <span className="rounded-full bg-green-500/20 px-2 py-0.5 text-[10px] font-black uppercase text-green-400">
                            {t("verified")}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3 text-center text-xs text-foreground" dir="ltr">
                      {formatPhone(u.passenger?.phone)}
                    </td>
                    <td className="px-4 py-3 text-center font-mono text-xs text-foreground" dir="ltr">
                      {u.passenger?.passport_details?.passport_number ?? "—"}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <UserStatusBadge isActive={u.is_active} />
                    </td>
                    <td className="px-4 py-3 text-center">
                      <Link
                        href={`/admin/users/${u.id}`}
                        className="inline-flex items-center justify-center rounded-mosafer border border-border-strong p-2 text-primary transition-colors hover:border-primary hover:bg-primary/10"
                        aria-label={t("viewDetails")}
                        title={t("viewDetails")}
                      >
                        <EyeIcon />
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
