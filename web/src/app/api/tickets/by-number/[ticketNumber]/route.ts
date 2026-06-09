import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";
import { acceptLanguageFromRequest } from "@/lib/route-utils";

export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ ticketNumber: string }> },
) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }
  const { ticketNumber } = await ctx.params;
  const encoded = encodeURIComponent(ticketNumber);
  const res = await fetch(apiUrl(`/tickets/${encoded}`), {
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
