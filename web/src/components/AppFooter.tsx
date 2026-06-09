"use client";

import { Link } from "@/i18n/navigation";
import { useTranslations } from "next-intl";

export function AppFooter() {
  const t = useTranslations("footer");
  const year = new Date().getFullYear();

  return (
    <footer className="mt-auto border-t border-border-subtle bg-shell">
      <div className="mx-auto grid max-w-6xl gap-10 px-4 py-12 sm:px-6 md:grid-cols-2">
        <div>
          <p className="text-xl font-extrabold text-primary">Mosafer</p>
          <p className="mt-3 max-w-xs text-sm leading-relaxed text-muted">{t("tagline")}</p>
        </div>
        <div>
          <p className="mb-3 text-sm font-bold uppercase tracking-wide text-foreground">
            {t("travel")}
          </p>
          <ul className="space-y-2 text-sm text-muted">
            <li>
              <Link href="/" className="hover:text-primary">
                {t("searchFlights")}
              </Link>
            </li>
            <li>
              <Link href="/trips" className="hover:text-primary">
                {t("myTrips")}
              </Link>
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-border-subtle py-4 text-center text-xs text-muted">
        © {year} Mosafer. {t("rights")}
      </div>
    </footer>
  );
}
