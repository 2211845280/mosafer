"use client";

import { AdminShell } from "@/components/admin/AdminShell";
import { isSuperAdminRole } from "@/lib/admin-roles";
import type { UserProfile } from "@/types/profile";
import { Link, useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useRef, useState } from "react";
import { ProfileBanner } from "./ProfileBanner";
import {
  ProfilePersonalForm,
  type AdminProfileForm,
} from "./ProfilePersonalForm";

type Props = {
  user: UserProfile;
};

function toAdminForm(user: UserProfile): AdminProfileForm {
  const phone = user.passenger?.phone ?? user.admin?.phone ?? "";
  return {
    email: user.email,
    fullName:
      user.admin?.full_name?.trim() ||
      user.passenger?.full_name?.trim() ||
      user.email.split("@")[0],
    phone: phone === "unknown" ? "" : phone,
  };
}

export function AdminProfileView({ user }: Props) {
  const t = useTranslations("profile");
  const locale = useLocale();
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);

  const displayName =
    user.admin?.full_name?.trim() ||
    user.passenger?.full_name?.trim() ||
    user.email.split("@")[0];

  const [hasAvatar, setHasAvatar] = useState(Boolean(user.avatar_path));
  const [avatarVersion, setAvatarVersion] = useState(user.avatar_path ?? user.id);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<AdminProfileForm>(() => toAdminForm(user));
  const [saving, setSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState<"success" | "error" | null>(null);
  const [logoutConfirmOpen, setLogoutConfirmOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  useEffect(() => {
    if (!logoutConfirmOpen) return;
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape" && !loggingOut) setLogoutConfirmOpen(false);
    }
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [logoutConfirmOpen, loggingOut]);

  async function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploadError(null);
    setUploading(true);
    try {
      const body = new FormData();
      body.append("file", file);
      const res = await fetch("/api/users/me/avatar", { method: "POST", body });
      if (!res.ok) {
        setUploadError(t("uploadError"));
        return;
      }
      setHasAvatar(true);
      setAvatarVersion(Date.now());
      router.refresh();
    } catch {
      setUploadError(t("uploadError"));
    } finally {
      setUploading(false);
      if (fileRef.current) fileRef.current.value = "";
    }
  }

  async function saveProfile() {
    setSaving(true);
    setSaveMessage(null);
    try {
      const res = await fetch("/api/users/me", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: form.email.trim(),
          full_name: form.fullName.trim(),
          phone: form.phone.trim() || "unknown",
        }),
      });
      if (!res.ok) {
        setSaveMessage("error");
        return;
      }
      setSaveMessage("success");
      setEditing(false);
      router.refresh();
    } catch {
      setSaveMessage("error");
    } finally {
      setSaving(false);
    }
  }

  async function confirmLogout() {
    setLoggingOut(true);
    try {
      await fetch("/api/auth/logout", { method: "POST" });
      window.location.href = `/${locale}`;
    } finally {
      setLoggingOut(false);
    }
  }

  return (
    <AdminShell
      profile={{
        id: user.id,
        email: user.email,
        displayName,
        avatarPath: user.avatar_path ?? null,
        isSuperAdmin: isSuperAdminRole(user.role_name),
      }}
    >
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-black text-foreground">{t("profileSettings")}</h1>
          <p className="mt-1 text-sm text-muted">{t("profileSettingsSubtitle")}</p>
        </div>

        <ProfileBanner
          displayName={displayName}
          email={user.email}
          hasAvatar={hasAvatar}
          avatarVersion={avatarVersion}
          onAvatarClick={() => !uploading && fileRef.current?.click()}
          uploading={uploading}
        />
        <input
          ref={fileRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          className="hidden"
          onChange={(e) => void onFileChange(e)}
        />
        {uploadError && (
          <p className="text-xs font-semibold text-accent">{uploadError}</p>
        )}

        <ProfilePersonalForm
          form={form}
          editing={editing}
          saving={saving}
          saveMessage={saveMessage}
          onChange={(patch) => setForm((f) => ({ ...f, ...patch }))}
          onEdit={() => {
            setForm(toAdminForm(user));
            setSaveMessage(null);
            setEditing(true);
          }}
          onCancel={() => {
            setForm(toAdminForm(user));
            setSaveMessage(null);
            setEditing(false);
          }}
          onSave={() => void saveProfile()}
        />

        <div className="profile-hero">
          <h2 className="text-lg font-black text-foreground">{t("accountSettings")}</h2>
          <div className="mt-4 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/profile/change-password"
              className="inline-flex flex-1 items-center justify-center rounded-mosafer border border-border-strong px-6 py-3 text-sm font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
            >
              {t("changePassword")}
            </Link>
            <button
              type="button"
              onClick={() => setLogoutConfirmOpen(true)}
              className="inline-flex flex-1 items-center justify-center rounded-mosafer border px-6 py-3 text-sm font-extrabold uppercase tracking-wide transition-colors hover:bg-accent/10"
              style={{
                borderColor: "rgba(255, 169, 130, 0.4)",
                color: "var(--accent)",
              }}
            >
              {t("logout")}
            </button>
          </div>
        </div>
      </div>

      {logoutConfirmOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
          role="presentation"
          onClick={() => !loggingOut && setLogoutConfirmOpen(false)}
        >
          <div
            className="profile-hero w-full max-w-md"
            role="dialog"
            aria-modal="true"
            aria-labelledby="admin-logout-confirm-title"
            onClick={(e) => e.stopPropagation()}
          >
            <h2
              id="admin-logout-confirm-title"
              className="text-lg font-black text-foreground"
            >
              {t("logout")}
            </h2>
            <p className="mt-3 text-sm text-muted">{t("logoutConfirm")}</p>
            <div className="mt-6 flex flex-wrap gap-3">
              <button
                type="button"
                disabled={loggingOut}
                onClick={() => void confirmLogout()}
                className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
              >
                {t("logoutConfirmYes")}
              </button>
              <button
                type="button"
                disabled={loggingOut}
                onClick={() => setLogoutConfirmOpen(false)}
                className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
              >
                {t("cancel")}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}
