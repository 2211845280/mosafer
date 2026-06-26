"use client";

import { useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";
import { useSearchParams } from "next/navigation";
import { PasswordInput } from "@/components/auth/PasswordInput";
import { resolveAuthApiError } from "@/lib/auth-errors";
import {
  hasFieldErrors,
  validateLogin,
  type FieldErrors,
} from "@/lib/auth-validation";

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
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const [loading, setLoading] = useState(false);

  function clearFieldError(field: string) {
    setFieldErrors((current) => {
      if (!current[field]) return current;
      const next = { ...current };
      delete next[field];
      return next;
    });
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    const validationErrors = validateLogin(email, password, t);
    if (hasFieldErrors(validationErrors)) {
      setFieldErrors(validationErrors);
      return;
    }
    setFieldErrors({});

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
        setError(resolveAuthApiError(detail, t, "login"));
        return;
      }

      const sessionRes = await fetch("/api/auth/session", {
        headers: { "Accept-Language": locale },
      });
      const sessionData = (await sessionRes.json().catch(() => ({}))) as {
        profile?: { isAdmin?: boolean } | null;
      };

      const isAdmin = sessionData?.profile?.isAdmin === true;
      if (isAdmin) {
        window.location.href = `/${locale}/admin`;
      } else {
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
        <form
          className="mt-6 flex flex-col gap-4"
          noValidate
          onSubmit={(e) => void onSubmit(e)}
        >
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("email")}
            <input
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                clearFieldError("email");
              }}
              aria-invalid={Boolean(fieldErrors.email)}
              className={
                fieldErrors.email ? "form-input form-input-error" : "form-input"
              }
            />
            {fieldErrors.email ? (
              <span className="form-field-error-text normal-case">
                {fieldErrors.email}
              </span>
            ) : null}
          </label>
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("password")}
            <PasswordInput
              autoComplete="current-password"
              value={password}
              invalid={Boolean(fieldErrors.password)}
              onChange={(e) => {
                setPassword(e.target.value);
                clearFieldError("password");
              }}
              aria-invalid={Boolean(fieldErrors.password)}
            />
            {fieldErrors.password ? (
              <span className="form-field-error-text normal-case">
                {fieldErrors.password}
              </span>
            ) : null}
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
