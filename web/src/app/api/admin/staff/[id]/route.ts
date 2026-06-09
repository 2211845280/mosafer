import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";
import { acceptLanguageFromRequest } from "@/lib/route-utils";

async function proxyStaff(
  req: NextRequest,
  id: string,
  method: "PATCH" | "DELETE",
  body?: string,
) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }
  const res = await fetch(apiUrl(`/admin/staff/${encodeURIComponent(id)}`), {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Accept-Language": acceptLanguageFromRequest(req),
      ...(body ? { "Content-Type": "application/json" } : {}),
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

export async function PATCH(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  const body = await req.text();
  return proxyStaff(req, id, "PATCH", body);
}

export async function DELETE(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
) {
  const { id } = await ctx.params;
  return proxyStaff(req, id, "DELETE");
}
