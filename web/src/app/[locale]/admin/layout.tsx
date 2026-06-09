import { AdminShell } from "@/components/admin/AdminShell";
import { Link } from "@/i18n/navigation";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getTranslations } from "next-intl/server";
import type { ReactNode } from "react";

export default async function AdminLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const t = await getTranslations("admin");
  const token = await getAccessToken();
  if (!token) {
    return (
      <div className="rounded-card border border-border-subtle bg-card p-8 text-center text-muted">
        <p>{t("noAccess")}</p>
        <Link
          href={`/login?next=${encodeURIComponent(`/${locale}/admin`)}`}
          className="mt-4 inline-block font-bold text-primary underline"
        >
          {(await getTranslations("nav"))("login")}
        </Link>
      </div>
    );
  }
  const profile = await fetchProfile(token);
  if (token && !profile) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-8 text-center text-sm text-accent">
        <p>{t("analyticsLoadError")}</p>
        <Link href="/admin" className="mt-4 inline-block font-bold text-primary underline">
          {t("dashboard")}
        </Link>
      </div>
    );
  }
  if (!profile?.isAdmin) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-8 text-center">
        <p className="font-bold text-accent">{t("noAccess")}</p>
        <Link href="/" className="mt-4 inline-block font-bold text-primary underline">
          {(await getTranslations("nav"))("home")}
        </Link>
      </div>
    );
  }

  return (
    <AdminShell
      profile={{
        id: profile.id,
        email: profile.email,
        displayName: profile.displayName,
        avatarPath: profile.avatarPath,
        isSuperAdmin: profile.isSuperAdmin,
      }}
    >
      {children}
    </AdminShell>
  );
}
