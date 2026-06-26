"use client";

import { useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";
import { PasswordInput } from "@/components/auth/PasswordInput";
import { resolveAuthApiError } from "@/lib/auth-errors";
import {
  hasFieldErrors,
  validateRegister,
  type FieldErrors,
} from "@/lib/auth-validation";

export default function RegisterPage() {
  const t = useTranslations("auth");
  const tNav = useTranslations("nav");
  const router = useRouter();
  const locale = useLocale();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
  const [ok, setOk] = useState<string | null>(null);
  const [verifyLink, setVerifyLink] = useState<string | null>(null);
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
    setOk(null);

    const validationErrors = validateRegister(
      name,
      email,
      password,
      confirmPassword,
      t,
    );
    if (hasFieldErrors(validationErrors)) {
      setFieldErrors(validationErrors);
      return;
    }
    setFieldErrors({});

    setLoading(true);
    try {
      const res = await fetch("/api/auth/register", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({ name, email, password }),
      });
      const data = (await res.json().catch(() => ({}))) as {
        detail?: string | { msg?: string }[];
        message?: string;
        verification_link?: string | null;
      };
      if (!res.ok) {
        let detail: string | null = null;
        if (typeof data.detail === "string") {
          detail = data.detail;
        } else if (Array.isArray(data.detail) && data.detail[0]?.msg) {
          detail = data.detail[0].msg;
        }

        if (res.status === 503) {
          setError(t("emailSendFailed"));
        } else if (res.status >= 500 || res.status === 502) {
          setError(t("serverUnavailable"));
        } else {
          setError(resolveAuthApiError(detail, t, "register"));
        }
        return;
      }
      const link =
        typeof data.verification_link === "string"
          ? data.verification_link
          : null;
      setVerifyLink(link);
      setOk(t("registeredVerify"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="text-2xl font-extrabold text-foreground">{t("registerTitle")}</h1>
        <form
          className="mt-6 flex flex-col gap-4"
          noValidate
          onSubmit={(e) => void onSubmit(e)}
        >
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("name")}
            <input
              autoComplete="name"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                clearFieldError("name");
              }}
              aria-invalid={Boolean(fieldErrors.name)}
              className={
                fieldErrors.name ? "form-input form-input-error" : "form-input"
              }
            />
            {fieldErrors.name ? (
              <span className="form-field-error-text normal-case">
                {fieldErrors.name}
              </span>
            ) : null}
          </label>
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
              autoComplete="new-password"
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
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("confirmPassword")}
            <PasswordInput
              autoComplete="new-password"
              value={confirmPassword}
              invalid={Boolean(fieldErrors.confirmPassword)}
              onChange={(e) => {
                setConfirmPassword(e.target.value);
                clearFieldError("confirmPassword");
              }}
              aria-invalid={Boolean(fieldErrors.confirmPassword)}
            />
            {fieldErrors.confirmPassword ? (
              <span className="form-field-error-text normal-case">
                {fieldErrors.confirmPassword}
              </span>
            ) : null}
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
          {verifyLink && (
            <p className="text-xs leading-relaxed text-muted">
              {t("devVerifyHint")}{" "}
              <a
                href={verifyLink}
                className="break-all font-bold text-primary underline"
              >
                {verifyLink}
              </a>
            </p>
          )}
          <button
            type="submit"
            disabled={loading}
            className="rounded-mosafer bg-primary py-3 text-sm font-extrabold uppercase tracking-wide text-primary-foreground disabled:opacity-60"
          >
            {loading ? "…" : t("submitRegister")}
          </button>
        </form>
        <p className="mt-4 text-center text-sm text-muted">
          {t("haveAccount")}{" "}
          <button
            type="button"
            className="font-bold text-primary underline"
            onClick={() => router.push("/login")}
          >
            {tNav("login")}
          </button>
        </p>
      </div>
    </div>
  );
}
