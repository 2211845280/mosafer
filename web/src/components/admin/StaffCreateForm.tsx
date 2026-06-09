"use client";

import { PermissionMatrix } from "@/components/admin/PermissionMatrix";
import { backendFromUiSelection } from "@/lib/admin/system-permissions";
import { Link, useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";

type Props = {
  isSuperAdminViewer: boolean;
};

export function StaffCreatePage({ isSuperAdminViewer }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const router = useRouter();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  function togglePerm(uiId: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(uiId)) next.delete(uiId);
      else next.add(uiId);
      return next;
    });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setErr(null);
    if (selected.size === 0) {
      setErr(t("staffPickPermission"));
      return;
    }
    setSaving(true);
    try {
      const res = await fetch("/api/admin/staff", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({
          email,
          password,
          full_name: fullName,
          phone: phone || "unknown",
          permission_names: backendFromUiSelection(selected),
        }),
      });
      const data = (await res.json().catch(() => ({}))) as { detail?: string };
      if (!res.ok) {
        setErr(typeof data.detail === "string" ? data.detail : t("staffCreateError"));
        return;
      }
      router.push("/admin/staff");
    } finally {
      setSaving(false);
    }
  }

  const labelClass = "profile-field-label";

  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-black text-foreground">{t("staffAdd")}</h1>
        <Link
          href="/admin/staff"
          className="rounded-mosafer border border-border-strong px-4 py-2 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
        >
          {t("staffBack")}
        </Link>
      </div>

      <form onSubmit={(e) => void onSubmit(e)} className="mt-6 space-y-4">
        <div className="profile-hero">
          <h2 className="text-lg font-black text-foreground">{t("staffCreateSubtitle")}</h2>
          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            <div className="profile-field">
              <label className={labelClass} htmlFor="staff-name">
                {t("staffFullName")}
              </label>
              <input
                id="staff-name"
                required
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                className="form-input mt-1 w-full"
              />
            </div>
            <div className="profile-field">
              <label className={labelClass} htmlFor="staff-email">
                {t("email")}
              </label>
              <input
                id="staff-email"
                required
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="form-input mt-1 w-full"
                dir="ltr"
              />
            </div>
            <div className="profile-field">
              <label className={labelClass} htmlFor="staff-password">
                {t("staffPassword")}
              </label>
              <input
                id="staff-password"
                required
                type="password"
                minLength={8}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="form-input mt-1 w-full"
              />
            </div>
            <div className="profile-field">
              <label className={labelClass} htmlFor="staff-phone">
                {t("staffPhone")}
              </label>
              <input
                id="staff-phone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="form-input mt-1 w-full"
                dir="ltr"
              />
            </div>
          </div>
        </div>

        <fieldset className="profile-hero">
          <legend className="text-lg font-black text-foreground">{t("staffPermissions")}</legend>
          <PermissionMatrix
            selected={selected}
            onToggle={togglePerm}
            isSuperAdminViewer={isSuperAdminViewer}
          />
        </fieldset>

        {err && (
          <p className="text-sm font-semibold text-accent" role="alert">
            {err}
          </p>
        )}

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={saving}
            className="rounded-mosafer bg-primary px-8 py-3 text-sm font-black uppercase text-primary-foreground transition-transform hover:scale-[1.02] disabled:opacity-60"
          >
            {saving ? t("loading") : t("staffCreate")}
          </button>
        </div>
      </form>
    </div>
  );
}

/** @deprecated Use StaffCreatePage — kept for import compatibility */
export const StaffCreateForm = StaffCreatePage;
