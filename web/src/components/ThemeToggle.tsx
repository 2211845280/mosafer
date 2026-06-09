"use client";

import { useTheme } from "@/components/ThemeProvider";
import { useTranslations } from "next-intl";
import { useEffect, useState } from "react";

export function ThemeToggle() {
  const { theme, toggleTheme } = useTheme();
  const t = useTranslations("nav");
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Match SSR (always dark) until mounted to avoid hydration mismatch in Firefox.
  const isLight = mounted ? theme === "light" : false;
  const ariaLabel = isLight ? t("themeDark") : t("themeLight");

  return (
    <button
      type="button"
      onClick={toggleTheme}
      className={`rounded-full border border-border-subtle p-2 text-muted transition-colors hover:border-primary hover:text-primary${isLight ? " bg-surface" : ""}`}
      aria-label={ariaLabel}
      aria-pressed={isLight}
      title={ariaLabel}
    >
      {!mounted ? (
        <span className="inline-block h-4 w-4" aria-hidden />
      ) : isLight ? (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
          <path
            d="M21 14.5A7.5 7.5 0 1110.5 4a6 6 0 0010.5 10.5z"
            stroke="currentColor"
            strokeWidth="1.75"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      ) : (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden>
          <circle cx="12" cy="12" r="4" stroke="currentColor" strokeWidth="1.75" />
          <path
            d="M12 2v2M12 20v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M2 12h2M20 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"
            stroke="currentColor"
            strokeWidth="1.75"
            strokeLinecap="round"
          />
        </svg>
      )}
    </button>
  );
}
