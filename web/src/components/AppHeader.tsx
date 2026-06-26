"use client";

import { ProfileAvatar } from "@/components/profile/ProfileAvatar";
import { ThemeToggle } from "@/components/ThemeToggle";
import { useLocale, useTranslations } from "next-intl";
import { Link, usePathname } from "@/i18n/navigation";
import { useEffect, useState } from "react";

type SessionProfile = {
  id: number;
  email: string;
  isAdmin: boolean;
  avatarPath: string | null;
  displayName: string;
};

function AuthBlock({
  profile,
  otherLocale,
  pathname,
  locale,
  t,
}: {
  profile: SessionProfile | null | undefined;
  otherLocale: string;
  pathname: string;
  locale: string;
  t: ReturnType<typeof useTranslations<"nav">>;
}) {
  return (
    <div
      dir={locale === "ar" ? "rtl" : "ltr"}
      className="flex flex-wrap items-center gap-2 sm:gap-3"
    >
      {!profile && profile !== undefined ? (
        <Link
          href="/login"
          className="rounded-mosafer border border-border-strong px-4 py-2 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
        >
          {t("login")}
        </Link>
      ) : null}

      <ThemeToggle />
      <Link
        href={pathname}
        locale={otherLocale}
        className="rounded-full border border-border-subtle px-3 py-1 text-xs font-extrabold uppercase tracking-wide text-muted transition-colors hover:border-primary hover:text-primary"
      >
        {otherLocale === "ar" ? "العربية" : "EN"}
      </Link>

      {profile === undefined ? (
        <span className="px-2 text-xs text-muted">…</span>
      ) : profile ? (
        <Link
          href="/profile"
          className="flex items-center gap-2 rounded-mosafer px-1 py-1 transition-colors hover:bg-foreground/5"
        >
          <ProfileAvatar
            size="sm"
            hasAvatar={Boolean(profile.avatarPath)}
            displayName={profile.displayName}
            cacheKey={profile.avatarPath ?? profile.id}
          />
          <span className="text-xs font-semibold text-muted">{profile.displayName}</span>
        </Link>
      ) : null}
    </div>
  );
}

function NavBrandBlock({
  profile,
  pathname,
  locale,
  t,
  tRoot,
  navLinkClass,
  isActive,
  brandFirst,
}: {
  profile: SessionProfile | null | undefined;
  pathname: string;
  locale: string;
  t: ReturnType<typeof useTranslations<"nav">>;
  tRoot: ReturnType<typeof useTranslations>;
  navLinkClass: (active: boolean) => string;
  isActive: (href: string) => boolean;
  brandFirst: boolean;
}) {
  const brand = (
    <Link href="/" className="flex items-center gap-2">
      <span className="text-lg font-extrabold tracking-tight text-foreground">
        {tRoot("brand")}
      </span>
      <img
        src="/brand/mosafer-logo.png"
        alt=""
        width={32}
        height={32}
        className="h-8 w-8 object-contain"
        decoding="async"
      />
    </Link>
  );

  const divider = (
    <span className="mx-1 hidden h-6 w-px bg-foreground/10 sm:block" aria-hidden />
  );

  const homeLink = (
    <Link
      href="/"
      className={navLinkClass(
        pathname === "/" || pathname === "" || pathname.startsWith("/book"),
      )}
    >
      {t("home")}
    </Link>
  );

  const tripsLink = profile ? (
    <Link href="/trips" className={navLinkClass(isActive("/trips"))}>
      {t("myTrips")}
    </Link>
  ) : null;

  const profileLink = profile ? (
    <Link href="/profile" className={navLinkClass(isActive("/profile"))}>
      {t("profile")}
    </Link>
  ) : null;

  const adminNav = profile?.isAdmin ? (
    <>
      <Link
        href="/admin"
        className={`rounded-mosafer px-3 py-2 transition-colors ${
          pathname.startsWith("/admin")
            ? "bg-accent/20 text-accent"
            : "text-accent hover:bg-accent/10 hover:text-foreground"
        }`}
      >
        {t("admin")}
      </Link>
      <Link href="/profile" className={navLinkClass(isActive("/profile"))}>
        {t("profile")}
      </Link>
    </>
  ) : null;

  const userNav = profile?.isAdmin ? null : (
    <>
      {homeLink}
      {tripsLink}
      {profileLink}
    </>
  );

  const nav = (
    <nav
      className={`flex flex-wrap items-center gap-1 text-sm font-bold ${
        locale === "ar" && !profile?.isAdmin ? "flex-row-reverse" : ""
      }`}
    >
      {profile?.isAdmin ? adminNav : userNav}
    </nav>
  );

  return (
    <div className="flex flex-wrap items-center gap-1 sm:gap-2">
      {brandFirst ? (
        <>
          {brand}
          {divider}
          {nav}
        </>
      ) : (
        <>
          {nav}
          {divider}
          {brand}
        </>
      )}
    </div>
  );
}

export function AppHeader() {
  const t = useTranslations("nav");
  const tRoot = useTranslations();
  const locale = useLocale();
  const pathname = usePathname();
  const [profile, setProfile] = useState<SessionProfile | null | undefined>(
    undefined,
  );
  const isAdminRoute = pathname.startsWith("/admin");
  const isEnglish = locale === "en";

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/auth/session", {
          headers: { "Accept-Language": locale },
        });
        if (!res.ok) {
          if (!cancelled) setProfile(null);
          return;
        }
        const data = (await res.json()) as { profile: SessionProfile };
        if (!cancelled) setProfile(data.profile);
      } catch {
        if (!cancelled) setProfile(null);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locale, pathname]);

  const otherLocale = locale === "ar" ? "en" : "ar";
  const isActive = (href: string) =>
    pathname === href || pathname.startsWith(`${href}/`);

  const navLinkClass = (active: boolean) =>
    `rounded-mosafer px-3 py-2 transition-colors ${
      active
        ? "bg-foreground/10 text-foreground"
        : "text-muted hover:bg-foreground/5 hover:text-foreground"
    }`;

  const authBlock = (
    <AuthBlock
      profile={profile}
      otherLocale={otherLocale}
      pathname={pathname}
      locale={locale}
      t={t}
    />
  );

  const navBrandBlock = (
    <NavBrandBlock
      profile={profile}
      pathname={pathname}
      locale={locale}
      t={t}
      tRoot={tRoot}
      navLinkClass={navLinkClass}
      isActive={isActive}
      brandFirst={isEnglish}
    />
  );

  return (
    <header
      className={`sticky top-0 z-50 border-b backdrop-blur-md ${
        isAdminRoute
          ? "border-border-subtle bg-shell/95"
          : "border-border-subtle bg-background/85"
      }`}
    >
      <div
        dir="ltr"
        className="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:px-6"
      >
        {isEnglish ? (
          <>
            {navBrandBlock}
            {authBlock}
          </>
        ) : (
          <>
            {authBlock}
            {navBrandBlock}
          </>
        )}
      </div>
    </header>
  );
}
