"use client";

import { useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";

export function ForgotPasswordForm() {
  const t = useTranslations("auth");
  const router = useRouter();
  const locale = useLocale();
  const [email, setEmail] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);
  const [resetLink, setResetLink] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setOk(null);
    setResetLink(null);
    setLoading(true);
    try {
      const res = await fetch("/api/auth/forgot-password", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({ email }),
      });
      const data = (await res.json().catch(() => ({}))) as {
        detail?: string;
        message?: string;
        reset_link?: string | null;
      };
      if (!res.ok) {
        setError(
          typeof data.detail === "string" ? data.detail : t("forgotPasswordFailed"),
        );
        return;
      }
      setOk(data.message ?? t("forgotPasswordSuccess"));
      if (typeof data.reset_link === "string") {
        setResetLink(data.reset_link);
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="text-2xl font-extrabold text-foreground">
          {t("forgotPasswordTitle")}
        </h1>
        <p className="mt-2 text-sm text-muted">{t("forgotPasswordSubtitle")}</p>
        <form className="mt-6 flex flex-col gap-4" onSubmit={(e) => void onSubmit(e)}>
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("email")}
            <input
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="form-input"
            />
          </label>
          {error && (
            <p className="text-sm font-semibold text-accent" role="alert">
              {error}
            </p>
          )}
          {ok && (
            <p className="text-sm font-semibold text-primary" role="status">
              {ok}
            </p>
          )}
          {resetLink && (
            <p className="break-all text-xs text-muted">
              {t("devResetHint")}{" "}
              <a href={resetLink} className="text-primary underline">
                {resetLink}
              </a>
            </p>
          )}
          <button
            type="submit"
            disabled={loading}
            className="rounded-mosafer bg-primary py-3 text-sm font-extrabold uppercase tracking-wide text-primary-foreground disabled:opacity-60"
          >
            {loading ? "…" : t("forgotPasswordSubmit")}
          </button>
        </form>
        <p className="mt-4 text-center text-sm text-muted">
          <button
            type="button"
            className="font-bold text-primary underline"
            onClick={() => router.push("/login")}
          >
            {t("backToLogin")}
          </button>
        </p>
      </div>
    </div>
  );
}
