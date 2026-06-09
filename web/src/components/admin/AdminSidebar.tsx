"use client";

import { AdminNavIcon, type NavIconKey } from "@/components/admin/admin-nav-icons";
import { ProfileAvatar } from "@/components/profile/ProfileAvatar";
import { Link, usePathname } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import type { AdminShellProfile } from "./admin-shell-types";

type NavItem = {
  href: string;
  labelKey: NavIconKey;
  superAdminOnly?: boolean;
};

const NAV_ITEMS: NavItem[] = [
  { href: "/admin", labelKey: "dashboard" },
  { href: "/admin/users", labelKey: "users" },
  { href: "/admin/bookings", labelKey: "bookings" },
  { href: "/admin/staff", labelKey: "staffNav" },
  { href: "/admin/analytics/revenue", labelKey: "totalRevenue", superAdminOnly: true },
  { href: "/admin/analytics/profit", labelKey: "platformProfit", superAdminOnly: true },
];

type Props = {
  profile: AdminShellProfile;
  expanded: boolean;
  onToggle: () => void;
};

export function AdminSidebar({ profile, expanded, onToggle }: Props) {
  const t = useTranslations("admin");
  const tProfile = useTranslations("profile");
  const pathname = usePathname();
  const locale = useLocale();

  const isActive = (href: string) => {
    if (href === "/admin") return pathname === "/admin";
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const navLinkClass = (active: boolean) =>
    `flex items-center gap-3 rounded-mosafer py-2.5 text-sm font-bold transition-colors ${
      expanded ? "px-3" : "justify-center px-2"
    } ${
      active
        ? "bg-foreground/10 text-foreground"
        : "text-muted hover:bg-foreground/5 hover:text-foreground"
    }`;

  const navItems = NAV_ITEMS.filter(
    (item) => !item.superAdminOnly || profile.isSuperAdmin,
  );

  const profileActive = pathname.startsWith("/profile");

  return (
    <aside
      className={`fixed right-0 top-0 z-40 flex h-screen flex-col border-l border-border-subtle bg-shell shadow-xl transition-[width] duration-300 ease-in-out ${
        expanded ? "w-64" : "w-16"
      }`}
      dir={locale === "ar" ? "rtl" : "ltr"}
    >
      <div
        className={`flex h-16 shrink-0 items-center border-b border-border-subtle ${
          expanded ? "px-4" : "justify-center px-2"
        }`}
      >
        {expanded ? (
          <p className="truncate text-lg font-black text-primary">{t("title")}</p>
        ) : (
          <span className="text-sm font-black text-primary" title={t("title")}>
            M
          </span>
        )}
      </div>

      <nav className="flex-1 overflow-x-hidden overflow-y-auto px-2 py-4">
        <ul className="space-y-1">
          {navItems.map((item) => (
            <li key={item.href}>
              <Link
                href={item.href}
                className={navLinkClass(isActive(item.href))}
                title={!expanded ? t(item.labelKey) : undefined}
              >
                <AdminNavIcon name={item.labelKey} className="h-5 w-5 shrink-0" />
                <span
                  className={`truncate transition-all duration-300 ${
                    expanded ? "w-auto opacity-100" : "w-0 overflow-hidden opacity-0"
                  }`}
                >
                  {t(item.labelKey)}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </nav>

      <div className={`shrink-0 border-t border-border-subtle ${expanded ? "p-4" : "p-2"}`}>
        <button
          type="button"
          className={`mb-3 flex items-center justify-center rounded-mosafer border border-border-strong text-muted transition-colors hover:border-primary hover:text-primary ${
            expanded ? "w-full py-2" : "mx-auto p-1.5"
          }`}
          aria-label={expanded ? t("collapseSidebar") : t("expandSidebar")}
          aria-expanded={expanded}
          onClick={onToggle}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden>
            {expanded ? (
              <path
                d="M9 6l6 6-6 6"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            ) : (
              <path
                d="M15 6l-6 6 6 6"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            )}
          </svg>
        </button>

        <Link
          href="/profile"
          className={`block rounded-card border transition-colors ${
            profileActive
              ? "border-primary/40 bg-foreground/5"
              : "border-border-subtle bg-card hover:border-primary/40"
          } ${expanded ? "p-3" : "flex justify-center p-2"}`}
          title={!expanded ? profile.displayName : undefined}
        >
          {expanded ? (
            <div className="flex items-center gap-3">
              <ProfileAvatar
                size="sm"
                hasAvatar={Boolean(profile.avatarPath)}
                displayName={profile.displayName}
                cacheKey={profile.avatarPath ?? profile.id}
              />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-bold text-foreground">
                  {profile.displayName}
                </p>
                <p className="truncate text-xs text-muted" dir="ltr">
                  {profile.email}
                </p>
                <span className="mt-1 inline-block rounded-full bg-primary/20 px-2 py-0.5 text-[10px] font-black uppercase text-primary">
                  {tProfile("adminBadge")}
                </span>
              </div>
            </div>
          ) : (
            <ProfileAvatar
              size="sm"
              hasAvatar={Boolean(profile.avatarPath)}
              displayName={profile.displayName}
              cacheKey={profile.avatarPath ?? profile.id}
            />
          )}
        </Link>
      </div>
    </aside>
  );
}
