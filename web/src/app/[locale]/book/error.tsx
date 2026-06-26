"use client";

import { Link } from "@/i18n/navigation";
import { useTranslations } from "next-intl";

type Props = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function BookError({ error, reset }: Props) {
  const t = useTranslations("book");

  return (
    <div className="content-shell py-16">
      <div
        className="rounded-2xl border border-accent/30 bg-card p-8 text-center"
        role="alert"
      >
        <p className="text-lg font-bold text-foreground">{t("loadError")}</p>
        <p className="mt-2 text-sm text-muted">
          {error.message || "Internal Server Error"}
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          <button
            type="button"
            onClick={reset}
            className="rounded-mosafer bg-primary px-6 py-2 text-xs font-extrabold uppercase text-primary-foreground"
          >
            {t("retryPayment")}
          </button>
          <Link
            href="/"
            className="inline-block rounded-mosafer border border-border-subtle px-6 py-2 text-xs font-extrabold uppercase text-foreground"
          >
            {t("backToSearch")}
          </Link>
        </div>
      </div>
    </div>
  );
}
