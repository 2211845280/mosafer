import { AdminShell } from "@/components/admin/AdminShell";
import { ChangePasswordForm } from "@/components/profile/ChangePasswordForm";
import { apiUrl } from "@/lib/api";
import { isAdminRole, isSuperAdminRole } from "@/lib/admin-roles";
import { Link } from "@/i18n/navigation";
import { getAccessToken } from "@/lib/server-session";
import type { UserProfile } from "@/types/profile";
import { getLocale, getTranslations } from "next-intl/server";

export async function generateMetadata() {
  const t = await getTranslations("profile");
  return { title: t("changePassword") };
}

export default async function ChangePasswordPage() {
  const t = await getTranslations("profile");
  const tNav = await getTranslations("nav");
  const locale = await getLocale();
  const token = await getAccessToken();

  if (!token) {
    return (
      <div className="mx-auto max-w-2xl">
        <div className="rounded-card border border-border-subtle bg-card p-8 text-center">
          <p className="text-muted">{t("pleaseLogin")}</p>
          <Link
            href="/login"
            className="mt-4 inline-block rounded-mosafer bg-primary px-6 py-2 text-sm font-black uppercase tracking-wide text-primary-foreground"
          >
            {tNav("login")}
          </Link>
        </div>
      </div>
    );
  }

  const res = await fetch(apiUrl("/users/me"), {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Accept-Language": locale,
    },
    cache: "no-store",
  });

  const user = res.ok ? ((await res.json()) as UserProfile) : null;
  const isAdmin = user ? isAdminRole(user.role_name, user.admin != null) : false;

  const backLink = (
    <Link
      href="/profile"
      className="text-sm font-semibold text-primary transition-colors hover:text-primary/80"
    >
      ← {t("backToProfile")}
    </Link>
  );

  const formContent = (
    <div className={isAdmin ? "mx-auto max-w-2xl space-y-6" : "mx-auto max-w-2xl"}>
      {backLink}
      <ChangePasswordForm />
    </div>
  );

  if (isAdmin && user) {
    const displayName =
      user.admin?.full_name?.trim() ||
      user.passenger?.full_name?.trim() ||
      user.email.split("@")[0];

    return (
      <AdminShell
        profile={{
          id: user.id,
          email: user.email,
          displayName,
          avatarPath: user.avatar_path ?? null,
          isSuperAdmin: isSuperAdminRole(user.role_name),
        }}
      >
        {formContent}
      </AdminShell>
    );
  }

  return formContent;
}
