"use client";

import { useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";
import { useSearchParams } from "next/navigation";

export function ResetPasswordForm() {
  const t = useTranslations("auth");
  const router = useRouter();
  const locale = useLocale();
  const searchParams = useSearchParams();
  const token = searchParams.get("token")?.trim() ?? "";

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState(false);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    if (!token) {
      setError(t("resetPasswordInvalidLink"));
      return;
    }
    if (password !== confirmPassword) {
      setError(t("passwordsDoNotMatch"));
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({ token, new_password: password }),
      });
      const data = (await res.json().catch(() => ({}))) as { detail?: string };
      if (!res.ok) {
        setError(
          typeof data.detail === "string"
            ? data.detail
            : t("resetPasswordInvalidLink"),
        );
        return;
      }
      setOk(true);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="text-2xl font-extrabold text-foreground">
          {t("resetPasswordTitle")}
        </h1>
        {ok ? (
          <div className="mt-6 flex flex-col gap-4">
            <p className="text-sm font-semibold text-primary">{t("resetPasswordSuccess")}</p>
            <button
              type="button"
              className="rounded-mosafer bg-primary py-3 text-sm font-extrabold uppercase tracking-wide text-primary-foreground"
              onClick={() => router.push("/login")}
            >
              {t("backToLogin")}
            </button>
          </div>
        ) : (
          <>
            <p className="mt-2 text-sm text-muted">{t("resetPasswordSubtitle")}</p>
            {!token && (
              <p className="mt-4 text-sm font-semibold text-accent" role="alert">
                {t("resetPasswordInvalidLink")}
              </p>
            )}
            <form className="mt-6 flex flex-col gap-4" onSubmit={(e) => void onSubmit(e)}>
              <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
                {t("newPassword")}
                <input
                  type="password"
                  required
                  minLength={8}
                  autoComplete="new-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="form-input"
                  disabled={!token}
                />
              </label>
              <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
                {t("confirmPassword")}
                <input
                  type="password"
                  required
                  minLength={8}
                  autoComplete="new-password"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="form-input"
                  disabled={!token}
                />
              </label>
              {error && (
                <p className="text-sm font-semibold text-accent" role="alert">
                  {error}
                </p>
              )}
              <button
                type="submit"
                disabled={loading || !token}
                className="rounded-mosafer bg-primary py-3 text-sm font-extrabold uppercase tracking-wide text-primary-foreground disabled:opacity-60"
              >
                {loading ? "…" : t("resetPasswordSubmit")}
              </button>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
