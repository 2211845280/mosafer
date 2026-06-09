"use client";

import { AdminProfileView } from "@/components/profile/AdminProfileView";
import { ProfileAvatar } from "@/components/profile/ProfileAvatar";
import { Link, useRouter } from "@/i18n/navigation";
import { hasRealPassportImage } from "@/lib/passport-image";
import { hasPassportDetails } from "@/lib/passport-details";
import { formatAccountStatus } from "@/lib/profile-formatters";
import { isAdminRole } from "@/lib/admin-roles";
import type { UserProfile } from "@/types/profile";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useRef, useState } from "react";

type Props = {
  user: UserProfile;
  formattedMemberSince: string;
};

type EditForm = {
  email: string;
  fullName: string;
  phone: string;
};

function toEditForm(user: UserProfile): EditForm {
  const phone = user.passenger?.phone ?? "";
  return {
    email: user.email,
    fullName: user.passenger?.full_name?.trim() || user.email.split("@")[0],
    phone: phone === "unknown" ? "" : phone,
  };
}

function formatPhoneDisplay(phone: string | null | undefined): string {
  return phone && phone !== "unknown" ? phone : "—";
}

export function ProfileClient({ user, formattedMemberSince }: Props) {
  const t = useTranslations("profile");
  const locale = useLocale();
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const passportFileRef = useRef<HTMLInputElement>(null);
  const [hasAvatar, setHasAvatar] = useState(Boolean(user.avatar_path));
  const [avatarVersion, setAvatarVersion] = useState(user.avatar_path ?? user.id);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [hasPassport, setHasPassport] = useState(
    hasRealPassportImage(user.passenger?.passport_image),
  );
  const [passportVersion, setPassportVersion] = useState(
    user.passenger?.passport_image ?? user.id,
  );
  const [passportUploading, setPassportUploading] = useState(false);
  const [passportUploadError, setPassportUploadError] = useState<string | null>(
    null,
  );
  const [passportUploadMessage, setPassportUploadMessage] = useState<string | null>(
    null,
  );
  const [savedPassportDetails, setSavedPassportDetails] = useState(
    user.passenger?.passport_details ?? null,
  );

  const [editing, setEditing] = useState(false);
  const [form, setForm] = useState<EditForm>(() => toEditForm(user));
  const [saving, setSaving] = useState(false);
  const [saveMessage, setSaveMessage] = useState<"success" | "error" | null>(
    null,
  );
  const [logoutConfirmOpen, setLogoutConfirmOpen] = useState(false);
  const [loggingOut, setLoggingOut] = useState(false);

  const displayName =
    user.passenger?.full_name?.trim() || user.email.split("@")[0];
  const headerName = editing
    ? form.fullName.trim() || user.email.split("@")[0]
    : displayName;
  const accountStatus = user.passenger?.account_status ?? "active";
  const isAdminProfile = isAdminRole(user.role_name, user.admin != null);

  useEffect(() => {
    setHasPassport(hasRealPassportImage(user.passenger?.passport_image));
    if (hasRealPassportImage(user.passenger?.passport_image)) {
      setPassportVersion(user.passenger?.passport_image ?? user.id);
    }
    setSavedPassportDetails(user.passenger?.passport_details ?? null);
  }, [user]);

  useEffect(() => {
    if (!editing) {
      setForm(toEditForm(user));
    }
  }, [user, editing]);

  useEffect(() => {
    if (!logoutConfirmOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setLogoutConfirmOpen(false);
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [logoutConfirmOpen]);

  async function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    setUploadError(null);
    setUploading(true);
    try {
      const body = new FormData();
      body.append("file", file);
      const res = await fetch("/api/users/me/avatar", {
        method: "POST",
        body,
      });
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

  async function onPassportFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    setPassportUploadError(null);
    setPassportUploadMessage(null);
    setPassportUploading(true);
    try {
      const body = new FormData();
      body.append("file", file);
      const res = await fetch("/api/users/me/passport", {
        method: "POST",
        body,
      });
      if (!res.ok) {
        setPassportUploadError(t("passportUploadError"));
        return;
      }
      const profile = (await res.json()) as UserProfile;
      const details = profile.passenger?.passport_details;
      setSavedPassportDetails(details ?? null);
      setPassportUploadMessage(
        hasPassportDetails(details)
          ? t("passportExtractSuccess")
          : t("passportExtractPartial"),
      );
      setHasPassport(true);
      setPassportVersion(Date.now());
      router.refresh();
    } catch {
      setPassportUploadError(t("passportUploadError"));
    } finally {
      setPassportUploading(false);
      if (passportFileRef.current) passportFileRef.current.value = "";
    }
  }

  function startEdit() {
    setForm(toEditForm(user));
    setSaveMessage(null);
    setEditing(true);
  }

  function cancelEdit() {
    setForm(toEditForm(user));
    setSaveMessage(null);
    setEditing(false);
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

  const inputClass = (editable: boolean) =>
    editable
      ? "form-input mt-1 w-full"
      : "form-input form-input-readonly mt-1 w-full";

  const fieldDir = locale === "ar" ? "rtl" : "ltr";

  if (isAdminProfile) {
    return <AdminProfileView user={user} />;
  }

  return (
    <div className="mx-auto max-w-2xl">
      <h1 className="text-2xl font-black text-foreground">{t("title")}</h1>

      <div className="profile-hero mt-6">
        <div className="flex flex-col items-center gap-6 sm:flex-row sm:items-start">
          <div className="relative shrink-0">
            <ProfileAvatar
              size="lg"
              hasAvatar={hasAvatar}
              displayName={headerName}
              cacheKey={avatarVersion}
              editable
              editLabel={t("changePhoto")}
              onEditClick={() => !uploading && fileRef.current?.click()}
            />
            <input
              ref={fileRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(e) => void onFileChange(e)}
            />
            {uploading && (
              <p className="mt-2 text-center text-xs font-semibold text-muted">
                {t("uploading")}
              </p>
            )}
          </div>

          <div className="min-w-0 flex-1 text-center sm:text-start">
            <p className="text-xl font-black text-foreground">{headerName}</p>

            <p className="mt-3 text-xs text-muted">
              {t("memberSince")}: {formattedMemberSince}
            </p>

            {uploadError && (
              <p className="mt-2 text-xs font-semibold text-accent">{uploadError}</p>
            )}
          </div>
        </div>
      </div>

      <div className="profile-hero mt-4">
        <div className="flex items-center justify-between gap-3">
          <h2 className="text-lg font-black text-foreground">{t("personalInfo")}</h2>
          {!editing && (
            <button
              type="button"
              onClick={startEdit}
              className="rounded-mosafer border border-border-strong px-4 py-1.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
            >
              {t("edit")}
            </button>
          )}
        </div>

        <div className="mt-4 space-y-4">
          <div className="profile-field">
            <label className="profile-field-label" htmlFor="profile-email">
              {t("email")}
            </label>
            <input
              id="profile-email"
              type="email"
              value={editing ? form.email : user.email}
              onChange={(e) =>
                setForm((f) => ({ ...f, email: e.target.value }))
              }
              readOnly={!editing}
              tabIndex={editing ? 0 : -1}
              className={inputClass(editing)}
              dir={fieldDir}
              required={editing}
            />
          </div>

          <div className="profile-field">
            <label className="profile-field-label" htmlFor="profile-name">
              {t("fullName")}
            </label>
            <input
              id="profile-name"
              type="text"
              value={editing ? form.fullName : displayName}
              onChange={(e) =>
                setForm((f) => ({ ...f, fullName: e.target.value }))
              }
              readOnly={!editing}
              tabIndex={editing ? 0 : -1}
              className={inputClass(editing)}
              dir={fieldDir}
              required={editing}
            />
          </div>

          <div className="profile-field">
            <label className="profile-field-label" htmlFor="profile-phone">
              {t("phone")}
            </label>
            <input
              id="profile-phone"
              type="tel"
              value={
                editing ? form.phone : formatPhoneDisplay(user.passenger?.phone)
              }
              onChange={(e) =>
                setForm((f) => ({ ...f, phone: e.target.value }))
              }
              readOnly={!editing}
              tabIndex={editing ? 0 : -1}
              className={inputClass(editing)}
              dir={fieldDir}
            />
          </div>

          <div className="profile-field">
            <p className="profile-field-label">{t("accountStatus")}</p>
            <p className="mt-0.5">
              <span
                className={`profile-badge ${
                  accountStatus.toLowerCase() === "active"
                    ? "bg-primary/20 text-primary"
                    : "bg-accent/20 text-accent"
                }`}
              >
                {formatAccountStatus(accountStatus, (key) => t(key))}
              </span>
            </p>
          </div>
        </div>

        {editing && (
          <div className="mt-4 flex flex-wrap gap-3">
            <button
              type="button"
              disabled={saving}
              onClick={() => void saveProfile()}
              className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
            >
              {saving ? t("saving") : t("save")}
            </button>
            <button
              type="button"
              disabled={saving}
              onClick={cancelEdit}
              className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
            >
              {t("cancel")}
            </button>
          </div>
        )}

        {saveMessage === "success" && (
          <p className="mt-3 text-xs font-semibold text-green-400">{t("saveSuccess")}</p>
        )}
        {saveMessage === "error" && (
          <p className="mt-3 text-xs font-semibold text-accent">{t("saveError")}</p>
        )}
      </div>

      {!isAdminProfile && (
        <div className="profile-hero mt-4">
          <h2 className="text-lg font-black text-foreground">{t("passportPhoto")}</h2>
          <p className="mt-1 text-xs text-muted">{t("passportPhotoHint")}</p>

          <div className="mt-4">
            <div className="relative mx-auto w-full max-w-sm overflow-hidden rounded-mosafer border border-border-subtle bg-foreground/10 aspect-[3/2]">
              {hasPassport ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={`/api/users/me/passport?t=${encodeURIComponent(String(passportVersion))}`}
                  alt={t("passportPhoto")}
                  className="h-full w-full object-cover"
                />
              ) : (
                <div className="flex h-full flex-col items-center justify-center gap-2 px-4 text-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    className="h-10 w-10 text-muted"
                    aria-hidden
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                    />
                  </svg>
                  <p className="text-xs text-muted">{t("noPassportPhoto")}</p>
                </div>
              )}
            </div>

            <input
              ref={passportFileRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(e) => void onPassportFileChange(e)}
            />

            <div className="mt-4 flex flex-col items-center gap-2 sm:items-start">
              <button
                type="button"
                disabled={passportUploading}
                onClick={() => !passportUploading && passportFileRef.current?.click()}
                className="rounded-mosafer border border-border-strong px-4 py-2 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
              >
                {hasPassport ? t("changePassportPhoto") : t("addPassportPhoto")}
              </button>
              {passportUploading && (
                <p className="text-xs font-semibold text-muted">{t("passportExtracting")}</p>
              )}
              {passportUploadMessage && !passportUploading && (
                <p className="text-xs font-semibold text-green-400">{passportUploadMessage}</p>
              )}
              {passportUploadError && (
                <p className="text-xs font-semibold text-accent">{passportUploadError}</p>
              )}
            </div>

            {hasPassportDetails(savedPassportDetails) && (
              <dl className="mt-4 grid gap-2 text-xs sm:grid-cols-2">
                {savedPassportDetails.given_name && (
                  <div>
                    <dt className="font-bold uppercase text-muted">{t("fullName")}</dt>
                    <dd className="mt-0.5 text-foreground" dir="ltr">
                      {savedPassportDetails.family_name} / {savedPassportDetails.given_name}
                    </dd>
                  </div>
                )}
                {savedPassportDetails.passport_number && (
                  <div>
                    <dt className="font-bold uppercase text-muted">{t("passportNumberLabel")}</dt>
                    <dd className="mt-0.5 text-foreground" dir="ltr">
                      {savedPassportDetails.passport_number}
                    </dd>
                  </div>
                )}
                {savedPassportDetails.passport_expiry && (
                  <div>
                    <dt className="font-bold uppercase text-muted">{t("passportExpiryLabel")}</dt>
                    <dd className="mt-0.5 text-foreground" dir="ltr">
                      {savedPassportDetails.passport_expiry}
                    </dd>
                  </div>
                )}
                {savedPassportDetails.nationality && (
                  <div>
                    <dt className="font-bold uppercase text-muted">{t("nationalityLabel")}</dt>
                    <dd className="mt-0.5 text-foreground" dir="ltr">
                      {savedPassportDetails.nationality}
                    </dd>
                  </div>
                )}
              </dl>
            )}
          </div>
        </div>
      )}

      <div className="profile-hero mt-4">
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
            aria-labelledby="logout-confirm-title"
            onClick={(e) => e.stopPropagation()}
          >
            <h2
              id="logout-confirm-title"
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
    </div>
  );
}
