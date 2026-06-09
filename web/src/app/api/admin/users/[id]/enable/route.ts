import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";
import { acceptLanguageFromRequest } from "@/lib/route-utils";

export async function PATCH(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }
  const { id } = await ctx.params;
  const body = await req.text();
  const res = await fetch(apiUrl(`/users/admin/${id}/enable`), {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      Accept: "application/json",
      "Accept-Language": acceptLanguageFromRequest(req),
    },
    body,
    cache: "no-store",
  });
  const text = await res.text();
  return new NextResponse(text, {
    status: res.status,
    headers: { "Content-Type": "application/json" },
  });
}
