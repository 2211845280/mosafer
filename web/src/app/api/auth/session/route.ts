import { NextResponse } from "next/server";
import { acceptLanguageFromRequest } from "@/lib/route-utils";
import { fetchProfile, getAccessToken } from "@/lib/server-session";

export async function GET(req: Request) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ profile: null }, { status: 401 });
  }
  const profile = await fetchProfile(token, acceptLanguageFromRequest(req));
  if (!profile) {
    return NextResponse.json({ profile: null }, { status: 401 });
  }
  return NextResponse.json({ profile });
}
