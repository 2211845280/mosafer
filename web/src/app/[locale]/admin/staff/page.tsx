import { StaffListClient } from "@/components/admin/StaffListClient";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getLocale } from "next-intl/server";

export default async function AdminStaffPage() {
  const token = await getAccessToken();
  const locale = await getLocale();
  const profile = token ? await fetchProfile(token, locale) : null;

  return (
    <StaffListClient
      currentUserId={profile?.id ?? 0}
      isSuperAdmin={profile?.isSuperAdmin ?? false}
    />
  );
}
