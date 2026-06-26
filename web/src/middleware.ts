import createMiddleware from "next-intl/middleware";
import { type NextRequest, NextResponse } from "next/server";
import { isAdminRole } from "./lib/admin-roles";
import { apiUrl } from "./lib/api";
import {
  apiFetch,
  applyAuthCookiesToResponse,
  clearAuthCookies,
  refreshTokensFromApi,
  type RefreshedTokens,
} from "./lib/auth-refresh";
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
    const res = await apiFetch(apiUrl("/users/me"), {
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

async function resolveAdminWithRefresh(
  request: NextRequest,
): Promise<{ isAdmin: boolean | null; refreshedTokens: RefreshedTokens | null }> {
  let token = request.cookies.get("access_token")?.value;
  if (!token) {
    return { isAdmin: null, refreshedTokens: null };
  }

  let isAdmin = await resolveIsAdmin(token);
  if (isAdmin !== null) {
    return { isAdmin, refreshedTokens: null };
  }

  const refreshCookie = request.cookies.get("refresh_token")?.value;
  if (!refreshCookie) {
    return { isAdmin: null, refreshedTokens: null };
  }

  const refreshedTokens = await refreshTokensFromApi(refreshCookie);
  if (!refreshedTokens) {
    return { isAdmin: null, refreshedTokens: null };
  }

  isAdmin = await resolveIsAdmin(refreshedTokens.access_token);
  return { isAdmin, refreshedTokens };
}

function loginRedirect(
  request: NextRequest,
  locale: string,
  nextPath: string,
  clearCookies: boolean,
): NextResponse {
  const loginUrl = new URL(`/${locale}/login`, request.url);
  loginUrl.searchParams.set("next", nextPath);
  const response = NextResponse.redirect(loginUrl);
  if (clearCookies) {
    clearAuthCookies(response);
  }
  return response;
}

export default async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const { locale, path } = stripLocale(pathname);
  const fullPath = `/${locale}${path}`;

  const { isAdmin, refreshedTokens } = await resolveAdminWithRefresh(request);

  if (path === "/login" && isAdmin === true) {
    const response = NextResponse.redirect(new URL(`/${locale}/admin`, request.url));
    if (refreshedTokens) applyAuthCookiesToResponse(response, refreshedTokens);
    return response;
  }

  if (isAdmin === true && isPassengerOnlyPath(path)) {
    const response = NextResponse.redirect(new URL(`/${locale}/admin`, request.url));
    if (refreshedTokens) applyAuthCookiesToResponse(response, refreshedTokens);
    return response;
  }

  if (path.startsWith("/admin")) {
    const token = request.cookies.get("access_token")?.value;
    if (!token && !refreshedTokens) {
      return loginRedirect(request, locale, fullPath, false);
    }
    if (isAdmin === false) {
      const response = NextResponse.redirect(new URL(`/${locale}`, request.url));
      if (refreshedTokens) applyAuthCookiesToResponse(response, refreshedTokens);
      return response;
    }
    if (isAdmin === null) {
      return loginRedirect(request, locale, fullPath, true);
    }
  }

  const response = intlMiddleware(request);
  if (refreshedTokens) {
    applyAuthCookiesToResponse(response, refreshedTokens);
  }
  return response;
}

export const config = {
  matcher: ["/", "/(en|ar)/:path*", "/((?!api|_next|_vercel|.*\\..*).*)"],
};
