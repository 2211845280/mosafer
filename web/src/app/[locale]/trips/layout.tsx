import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { redirect } from "next/navigation";
import type { ReactNode } from "react";

export default async function TripsLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const token = await getAccessToken();
  if (!token) {
    redirect(`/${locale}/login?next=${encodeURIComponent(`/${locale}/trips`)}`);
  }
  const profile = await fetchProfile(token);
  if (profile?.isAdmin) {
    redirect(`/${locale}/admin`);
  }
  return children;
}
