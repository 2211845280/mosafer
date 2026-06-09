import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { authCookieBaseOptions } from "@/lib/auth-cookie-options";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const res = await fetch(apiUrl("/auth/login"), {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(body),
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
        { detail: "Invalid login response from API" },
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
  } catch (error) {
    console.error("auth.login.route_failed", error);
    return NextResponse.json(
      { detail: "Login service unavailable. Is the API running?" },
      { status: 502 },
    );
  }
}
