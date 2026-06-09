import { ProfitAnalyticsClient } from "@/components/admin/ProfitAnalyticsClient";
import { Link } from "@/i18n/navigation";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getLocale, getTranslations } from "next-intl/server";

export default async function ProfitAnalyticsPage() {
  const t = await getTranslations("admin");
  const locale = await getLocale();
  const token = await getAccessToken();
  const profile = token ? await fetchProfile(token, locale) : null;

  if (token && !profile) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-6 text-sm text-accent">
        {t("analyticsLoadError")}
      </div>
    );
  }

  if (!profile?.isSuperAdmin) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-8 text-center">
        <p className="font-bold text-accent">{t("analyticsNoAccess")}</p>
        <Link href="/admin" className="mt-4 inline-block font-bold text-primary underline">
          {t("dashboard")}
        </Link>
      </div>
    );
  }

  return <ProfitAnalyticsClient />;
}
