"use client";

import { useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useState } from "react";

export default function RegisterPage() {
  const t = useTranslations("auth");
  const tNav = useTranslations("nav");
  const router = useRouter();
  const locale = useLocale();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);
  const [verifyLink, setVerifyLink] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setOk(null);
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
        let detail = "Registration failed";
        if (typeof data.detail === "string") {
          detail = data.detail;
        } else if (Array.isArray(data.detail) && data.detail[0]?.msg) {
          detail = data.detail[0].msg;
        } else if (res.status === 503) {
          detail = t("emailSendFailed");
        } else if (res.status >= 500) {
          detail =
            locale === "ar"
              ? "خطأ في الخادم. تأكد من تشغيل قاعدة البيانات والـ API."
              : "Server error. Ensure the API and database are running.";
        }
        setError(detail);
        return;
      }
      const link =
        typeof data.verification_link === "string"
          ? data.verification_link
          : null;
      setVerifyLink(link);
      setOk(
        link
          ? t("registered")
          : typeof data.message === "string"
            ? data.message
            : t("registeredVerify"),
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-shell">
      <div className="auth-card">
        <h1 className="text-2xl font-extrabold text-foreground">{t("registerTitle")}</h1>
        <form className="mt-6 flex flex-col gap-4" onSubmit={(e) => void onSubmit(e)}>
          <label className="flex flex-col gap-2 text-xs font-bold uppercase text-muted">
            {t("name")}
            <input
              required
              autoComplete="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="form-input"
            />
          </label>
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
              autoComplete="new-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
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
