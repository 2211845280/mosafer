import { StaffCreatePage } from "@/components/admin/StaffCreateForm";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getLocale } from "next-intl/server";

export default async function AdminStaffNewPage() {
  const token = await getAccessToken();
  const locale = await getLocale();
  const profile = token ? await fetchProfile(token, locale) : null;

  return <StaffCreatePage isSuperAdminViewer={profile?.isSuperAdmin ?? false} />;
}
