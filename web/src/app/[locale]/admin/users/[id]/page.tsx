import { TravelerDetailView } from "@/components/admin/TravelerDetailView";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";
import { getLocale } from "next-intl/server";
import { notFound } from "next/navigation";

type AdminUser = {
  id: number;
  email: string;
  is_active: boolean;
  is_email_verified?: boolean;
  created_at?: string;
  passenger?: {
    full_name: string;
    phone?: string | null;
    account_status: string;
    passport_details?: {
      passport_number?: string | null;
    } | null;
  } | null;
  admin?: { id: number } | null;
};

export default async function AdminUserDetailPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { id } = await params;
  const locale = await getLocale();
  const token = await getAccessToken();
  if (!token) notFound();

  const res = await fetch(apiUrl(`/users/admin/${encodeURIComponent(id)}`), {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Accept-Language": locale,
    },
    cache: "no-store",
  });
  if (!res.ok) notFound();
  const user = (await res.json()) as AdminUser;

  if (user.admin) notFound();

  return <TravelerDetailView user={user} />;
}
