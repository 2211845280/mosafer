import { NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { authCookieBaseOptions } from "@/lib/auth-cookie-options";
import { getRefreshToken } from "@/lib/server-session";

export async function POST() {
  const refresh = await getRefreshToken();
  if (!refresh) {
    return NextResponse.json({ detail: "No refresh token" }, { status: 401 });
  }

  const res = await fetch(apiUrl("/auth/refresh"), {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ refresh_token: refresh }),
    cache: "no-store",
  });
  const data = (await res.json().catch(() => ({}))) as {
    access_token?: string;
    refresh_token?: string;
    detail?: string;
  };
  if (!res.ok) {
    return NextResponse.json(data, { status: res.status });
  }
  if (!data.access_token || !data.refresh_token) {
    return NextResponse.json(
      { detail: "Invalid refresh response from API" },
      { status: 502 },
    );
  }

  const out = NextResponse.json({ ok: true });
  out.cookies.set(
    "access_token",
    data.access_token,
    authCookieBaseOptions(60 * 30),
  );
  out.cookies.set(
    "refresh_token",
    data.refresh_token,
    authCookieBaseOptions(60 * 60 * 24 * 7),
  );
  return out;
}
