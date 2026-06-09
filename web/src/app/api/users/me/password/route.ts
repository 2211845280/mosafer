import { apiUrl } from "@/lib/api";
import { acceptLanguageFromRequest } from "@/lib/route-utils";
import { getAccessToken } from "@/lib/server-session";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }

  const body = await req.text();

  const upstream = await fetch(apiUrl("/users/me/password"), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      Accept: "application/json",
      "Accept-Language": acceptLanguageFromRequest(req),
    },
    body,
    cache: "no-store",
  });

  const text = await upstream.text();
  return new NextResponse(text, {
    status: upstream.status,
    headers: {
      "Content-Type": upstream.headers.get("content-type") ?? "application/json",
    },
  });
}
