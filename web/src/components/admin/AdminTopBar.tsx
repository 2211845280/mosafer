"use client";

import { ThemeToggle } from "@/components/ThemeToggle";
import { Link, usePathname } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import type { AdminShellProfile } from "./admin-shell-types";

type Props = {
  profile: AdminShellProfile;
  sidebarExpanded: boolean;
  onSidebarToggle?: () => void;
};

export function AdminTopBar({ profile, sidebarExpanded, onSidebarToggle }: Props) {
  const t = useTranslations("nav");
  const tAdmin = useTranslations("admin");
  const locale = useLocale();
  const pathname = usePathname();
  const otherLocale = locale === "ar" ? "en" : "ar";

  const pageTitle = (() => {
    if (pathname === "/admin" || pathname.startsWith("/admin/analytics")) {
      return pathname.includes("/analytics/revenue")
        ? tAdmin("totalRevenue")
        : pathname.includes("/analytics/profit")
          ? tAdmin("platformProfit")
          : tAdmin("dashboard");
    }
    if (pathname.startsWith("/admin/users")) return tAdmin("users");
    if (pathname.startsWith("/admin/bookings")) return tAdmin("bookings");
    if (pathname === "/admin/staff/new") return tAdmin("staffAdd");
    if (pathname.startsWith("/admin/staff")) return tAdmin("staffNav");
    if (pathname.startsWith("/profile")) return t("profile");
    return tAdmin("title");
  })();

  return (
    <header className="z-30 flex h-16 shrink-0 items-center border-b border-border-subtle bg-shell">
      <div className="flex w-full items-center justify-between gap-3 px-4 sm:px-6 lg:px-8">
        <div className="flex items-center gap-3">
          <button
            type="button"
            className="rounded-mosafer border border-border-strong p-2 text-muted transition-colors hover:border-primary hover:text-primary md:hidden"
            aria-label={
              sidebarExpanded ? tAdmin("collapseSidebar") : tAdmin("expandSidebar")
            }
            aria-expanded={sidebarExpanded}
            onClick={onSidebarToggle}
          >
            {sidebarExpanded ? (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
                <path
                  d="M15 6l-6 6 6 6"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                />
              </svg>
            ) : (
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
                <path
                  d="M4 6h16M4 12h16M4 18h16"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                />
              </svg>
            )}
          </button>
          <div>
            <h1 className="text-sm font-black text-foreground sm:text-base">{pageTitle}</h1>
            <p className="hidden text-xs text-muted sm:block">{profile.displayName}</p>
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-3">
          <ThemeToggle />
          <Link
            href={pathname}
            locale={otherLocale}
            className="rounded-full border border-border-subtle px-3 py-1 text-xs font-extrabold uppercase tracking-wide text-muted transition-colors hover:border-primary hover:text-primary"
          >
            {otherLocale === "ar" ? "العربية" : "EN"}
          </Link>
        </div>
      </div>
    </header>
  );
}
