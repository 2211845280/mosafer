"use client";

import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";

export function ChangePasswordForm() {
  const t = useTranslations("profile");
  const tAuth = useTranslations("auth");
  const locale = useLocale();
  const fieldDir = locale === "ar" ? "rtl" : "ltr";

  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSuccess(false);

    if (newPassword !== confirmPassword) {
      setError(tAuth("passwordsDoNotMatch"));
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/users/me/password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          current_password: currentPassword,
          new_password: newPassword,
        }),
      });

      if (res.status === 400) {
        setError(t("currentPasswordIncorrect"));
        return;
      }

      if (!res.ok) {
        setError(t("passwordChangeError"));
        return;
      }

      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      setSuccess(true);
    } catch {
      setError(t("passwordChangeError"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="profile-hero mt-4">
      <h2 className="text-lg font-black text-foreground">{t("changePassword")}</h2>

      <form className="mt-4 space-y-4" onSubmit={(e) => void onSubmit(e)}>
        <div className="profile-field">
          <label className="profile-field-label" htmlFor="profile-current-password">
            {t("currentPassword")}
          </label>
          <input
            id="profile-current-password"
            type="password"
            value={currentPassword}
            onChange={(e) => setCurrentPassword(e.target.value)}
            autoComplete="current-password"
            required
            className="form-input mt-1 w-full"
            dir={fieldDir}
          />
        </div>

        <div className="profile-field">
          <label className="profile-field-label" htmlFor="profile-new-password">
            {tAuth("newPassword")}
          </label>
          <input
            id="profile-new-password"
            type="password"
            value={newPassword}
            onChange={(e) => setNewPassword(e.target.value)}
            autoComplete="new-password"
            minLength={8}
            required
            className="form-input mt-1 w-full"
            dir={fieldDir}
          />
        </div>

        <div className="profile-field">
          <label className="profile-field-label" htmlFor="profile-confirm-password">
            {tAuth("confirmPassword")}
          </label>
          <input
            id="profile-confirm-password"
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            autoComplete="new-password"
            minLength={8}
            required
            className="form-input mt-1 w-full"
            dir={fieldDir}
          />
        </div>

        {error && (
          <p className="text-xs font-semibold text-accent" role="alert">
            {error}
          </p>
        )}
        {success && (
          <p className="text-xs font-semibold text-green-400">{t("passwordChangedSuccess")}</p>
        )}

        <button
          type="submit"
          disabled={loading}
          className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
        >
          {loading ? t("updatingPassword") : t("updatePassword")}
        </button>
      </form>
    </div>
  );
}
