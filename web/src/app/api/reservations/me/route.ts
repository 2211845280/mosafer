import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";
import { acceptLanguageFromRequest } from "@/lib/route-utils";

export async function GET(req: NextRequest) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }
  const qs = new URL(req.url).searchParams.toString();
  const res = await fetch(`${apiUrl("/reservations/me")}?${qs}`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Accept-Language": acceptLanguageFromRequest(req),
    },
    cache: "no-store",
  });
  const text = await res.text();
  return new NextResponse(text, {
    status: res.status,
    headers: { "Content-Type": "application/json" },
  });
}
