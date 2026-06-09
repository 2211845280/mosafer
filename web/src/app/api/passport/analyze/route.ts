import { apiUrl } from "@/lib/api";
import { acceptLanguageFromRequest } from "@/lib/route-utils";
import { getAccessToken } from "@/lib/server-session";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }

  const formData = await req.formData();
  const file = formData.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ detail: "Missing file" }, { status: 400 });
  }

  const body = new FormData();
  body.append("file", file, file.name);

  const upstream = await fetch(apiUrl("/passport/analyze"), {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
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
