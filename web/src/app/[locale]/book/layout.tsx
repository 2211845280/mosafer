import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { redirect } from "next/navigation";
import type { ReactNode } from "react";

export default async function BookLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const token = await getAccessToken();
  if (!token) {
    redirect(`/${locale}/login?next=${encodeURIComponent(`/${locale}/book/results`)}`);
  }

  // Redirect admins to admin panel - booking is for regular users only
  const profile = await fetchProfile(token);
  if (profile?.isAdmin) {
    redirect(`/${locale}/admin`);
  }

  return children;
}
