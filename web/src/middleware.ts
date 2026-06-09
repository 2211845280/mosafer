import createMiddleware from "next-intl/middleware";
import { type NextRequest, NextResponse } from "next/server";
import { isAdminRole } from "./lib/admin-roles";
import { apiUrl } from "./lib/api";
import { routing } from "./i18n/routing";

const intlMiddleware = createMiddleware(routing);

function stripLocale(pathname: string): { locale: string; path: string } {
  const match = pathname.match(/^\/(en|ar)(\/.*)?$/);
  if (!match) return { locale: routing.defaultLocale, path: pathname };
  const path = match[2] ?? "";
  return { locale: match[1], path: path === "/" ? "" : path };
}

function isPassengerOnlyPath(path: string): boolean {
  return (
    path === "" ||
    path.startsWith("/book") ||
    path.startsWith("/trips") ||
    path.startsWith("/open")
  );
}

async function resolveIsAdmin(token: string): Promise<boolean | null> {
  try {
    const res = await fetch(apiUrl("/users/me"), {
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
      },
      cache: "no-store",
    });
    if (!res.ok) return null;
    const data = (await res.json()) as {
      role_name?: string | null;
      admin?: unknown | null;
    };
    return isAdminRole(data.role_name, data.admin != null);
  } catch {
    return null;
  }
}

export default async function middleware(request: NextRequest) {
  const token = request.cookies.get("access_token")?.value;
  const { pathname } = request.nextUrl;
  const { locale, path } = stripLocale(pathname);

  let isAdmin: boolean | null = null;
  if (token) {
    isAdmin = await resolveIsAdmin(token);
  }

  if (path === "/login" && isAdmin === true) {
    return NextResponse.redirect(new URL(`/${locale}/admin`, request.url));
  }

  if (isAdmin === true && isPassengerOnlyPath(path)) {
    return NextResponse.redirect(new URL(`/${locale}/admin`, request.url));
  }

  if (path.startsWith("/admin")) {
    if (!token) {
      const loginUrl = new URL(`/${locale}/login`, request.url);
      loginUrl.searchParams.set("next", `/${locale}${path}`);
      return NextResponse.redirect(loginUrl);
    }
    if (isAdmin === false) {
      return NextResponse.redirect(new URL(`/${locale}`, request.url));
    }
  }

  return intlMiddleware(request);
}

export const config = {
  matcher: ["/", "/(en|ar)/:path*", "/((?!api|_next|_vercel|.*\\..*).*)"],
};
