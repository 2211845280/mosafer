import { ProfileClient } from "@/app/[locale]/profile/ProfileClient";
import { apiUrl } from "@/lib/api";
import { formatProfileDate } from "@/lib/profile-formatters";
import { getAccessToken } from "@/lib/server-session";
import type { UserProfile } from "@/types/profile";
import { getLocale, getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";

export default async function ProfilePage() {
  const t = await getTranslations("profile");
  const tNav = await getTranslations("nav");
  const locale = await getLocale();
  const token = await getAccessToken();

  if (!token) {
    return (
      <div className="rounded-card border border-border-subtle bg-card p-8 text-center">
        <p className="text-muted">{t("pleaseLogin")}</p>
        <Link
          href="/login"
          className="mt-4 inline-block rounded-mosafer bg-primary px-6 py-2 text-sm font-black uppercase tracking-wide text-primary-foreground"
        >
          {tNav("login")}
        </Link>
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

  if (!res.ok) {
    const errorT = await getTranslations("errors");
    return (
      <div className="rounded-card border border-accent/30 bg-card p-8">
        <p className="text-accent">{errorT("generic")}</p>
      </div>
    );
  }

  const user = (await res.json()) as UserProfile;

  return (
    <ProfileClient
      user={user}
      formattedMemberSince={formatProfileDate(
        user.created_at,
        locale,
        t("dateUnknown"),
      )}
    />
  );
}
