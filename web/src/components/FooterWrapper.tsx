"use client";

import { usePathname } from "next/navigation";
import { AppFooter } from "./AppFooter";

export function FooterWrapper() {
  const pathname = usePathname();
  if (pathname.includes("/admin")) return null;
  return <AppFooter />;
}
