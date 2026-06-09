"use client";

import { useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";
import { useSearchParams } from "next/navigation";

export function LoginForm() {
  const t = useTranslations("auth");
  const tNav = useTranslations("nav");
  const router = useRouter();
  const locale = useLocale();
  const searchParams = useSearchParams();
  const nextPath = searchParams.get("next")?.trim() || `/${locale}`;

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({ email, password }),
      });
      const data = (await res.json().catch(() => ({}))) as { detail?: string };
      if (!res.ok) {
        const detail = typeof data.detail === "string" ? data.detail : null;
        if (detail === "Please verify your email before logging in") {
          setError(t("emailNotVerified"));
        } else {
          setError(detail ?? "Login failed");
        }
        return;
      }

      // Fetch profile to check if user is admin
      const sessionRes = await fetch("/api/auth/session", {
        headers: { "Accept-Language": locale },
      });
      const sessionData = (await sessionRes.json().catch(() => ({}))) as {
        profile?: { isAdmin?: boolean } | null;
      };

      const isAdmin = sessionData?.profile?.isAdmin === true;
      if (isAdmin) {
        // Redirect admins to admin panel
        window.location.href = `/${locale}/admin`;
      } else {
        // Regular users go to intended destination
        const dest = nextPath.startsWith("/") ? nextPath : `/${locale}`;
        window.location.href = dest;
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="text-2xl font-extrabold text-foreground">{t("loginTitle")}</h1>
        <p className="mt-2 text-sm text-muted">{t("loginSubtitle")}</p>
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
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("password")}
            <input
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="form-input"
            />
          </label>
          <p className="text-end text-xs">
            <button
              type="button"
              className="font-bold text-primary underline"
              onClick={() => router.push("/forgot-password")}
            >
              {t("forgotPassword")}
            </button>
          </p>
          {error && (
            <p className="text-sm font-semibold text-accent" role="alert">
              {error}
            </p>
          )}
          <button
            type="submit"
            disabled={loading}
            className="rounded-mosafer bg-primary py-3 text-sm font-extrabold uppercase tracking-wide text-primary-foreground disabled:opacity-60"
          >
            {loading ? "…" : t("submitLogin")}
          </button>
        </form>
        <p className="mt-4 text-center text-sm text-muted">
          {t("needAccount")}{" "}
          <button
            type="button"
            className="font-bold text-primary underline"
            onClick={() => router.push("/register")}
          >
            {tNav("register")}
          </button>
        </p>
      </div>
    </div>
  );
}
