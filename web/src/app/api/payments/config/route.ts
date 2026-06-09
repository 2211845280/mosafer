import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { acceptLanguageFromRequest } from "@/lib/route-utils";

export async function GET(req: NextRequest) {
  const res = await fetch(apiUrl("/payments/config"), {
    headers: {
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
