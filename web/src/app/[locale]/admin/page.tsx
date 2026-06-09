import { AdminDashboardClient } from "@/components/admin/AdminDashboardClient";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getLocale } from "next-intl/server";

export default async function AdminHomePage() {
  const token = await getAccessToken();
  const locale = await getLocale();
  const profile = token ? await fetchProfile(token, locale) : null;

  return <AdminDashboardClient isSuperAdmin={profile?.isSuperAdmin ?? false} />;
}
