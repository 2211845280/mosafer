import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const res = await fetch(apiUrl("/auth/register"), {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(body),
      cache: "no-store",
    });
    const text = await res.text();
    return new NextResponse(text, {
      status: res.status,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("auth.register.route_failed", error);
    return NextResponse.json(
      { detail: "Registration service unavailable. Is the API running?" },
      { status: 502 },
    );
  }
}
