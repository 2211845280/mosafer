import { NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";

export async function POST() {
  const token = await getAccessToken();
  if (token) {
    await fetch(apiUrl("/auth/logout"), {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
      cache: "no-store",
    }).catch(() => undefined);
  }
  const res = NextResponse.json({ ok: true });
  res.cookies.set("access_token", "", { path: "/", maxAge: 0 });
  res.cookies.set("refresh_token", "", { path: "/", maxAge: 0 });
  return res;
}
