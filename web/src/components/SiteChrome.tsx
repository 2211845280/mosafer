"use client";

import dynamic from "next/dynamic";
import { FooterWrapper } from "@/components/FooterWrapper";
import { usePathname } from "@/i18n/navigation";
import { useLocale } from "next-intl";
import { useEffect, useState, type ReactNode } from "react";

const AppHeader = dynamic(
  () => import("@/components/AppHeader").then((mod) => mod.AppHeader),
  { ssr: false },
);

type SessionProfile = {
  isAdmin: boolean;
};

type Props = {
  children: ReactNode;
};

export function SiteChrome({ children }: Props) {
  const pathname = usePathname();
  const locale = useLocale();
  const [profile, setProfile] = useState<SessionProfile | null | undefined>(undefined);

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
        const data = (await res.json()) as { profile: SessionProfile | null };
        if (!cancelled) setProfile(data.profile);
      } catch {
        if (!cancelled) setProfile(null);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locale, pathname]);

  const isAdminRoute = pathname.startsWith("/admin");
  const isAdminProfile =
    pathname.startsWith("/profile") && profile?.isAdmin === true;
  const hideSiteChrome = isAdminRoute || isAdminProfile;

  if (hideSiteChrome) {
    return <>{children}</>;
  }

  return (
    <>
      <AppHeader />
      <main className="flex-1">{children}</main>
      <FooterWrapper />
    </>
  );
}
