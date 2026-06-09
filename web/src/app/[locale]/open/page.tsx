"use client";

import { buildMosaferTicketUrl } from "@/lib/app-link";
import { useTranslations } from "next-intl";
import { useSearchParams } from "next/navigation";
import { Suspense, useMemo, useState } from "react";

function OpenFallback() {
  const t = useTranslations("open");
  return (
    <div className="content-shell py-12 sm:py-16">
      <p className="text-center text-muted">{t("title")}…</p>
    </div>
  );
}

function OpenInner() {
  const t = useTranslations("open");
  const sp = useSearchParams();
  const raw = sp.get("d") ?? sp.get("ticket") ?? "";
  const payload = useMemo(() => raw.trim(), [raw]);
  const appUrl = payload ? buildMosaferTicketUrl(payload) : null;
  const [copied, setCopied] = useState(false);

  async function copyPayload() {
    if (!payload) return;
    try {
      await navigator.clipboard.writeText(payload);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* ignore */
    }
  }

  return (
    <div className="content-shell py-12 sm:py-16">
      <div className="mx-auto max-w-md rounded-card border border-border-subtle bg-card p-8 text-center">
      <h1 className="text-2xl font-black text-foreground">{t("title")}</h1>
      <p className="mt-3 text-sm leading-relaxed text-muted">{t("body")}</p>
      {appUrl && (
        <a
          href={appUrl}
          className="mt-6 inline-block rounded-mosafer bg-primary px-6 py-3 text-sm font-black uppercase tracking-wide text-primary-foreground"
        >
          {t("title")}
        </a>
      )}
      {payload && (
        <button
          type="button"
          onClick={() => void copyPayload()}
          className="mt-4 block w-full rounded-mosafer border border-border-strong px-4 py-3 text-sm font-bold text-foreground hover:border-primary"
        >
          {copied ? "✓" : t("copyPayload")}
        </button>
      )}
      </div>
    </div>
  );
}

export default function OpenAppPage() {
  return (
    <Suspense fallback={<OpenFallback />}>
      <OpenInner />
    </Suspense>
  );
}
