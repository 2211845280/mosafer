import { DEFAULT_THEME, THEME_STORAGE_KEY } from "@/lib/theme";

const themeScript = `(function(){try{var t=localStorage.getItem("${THEME_STORAGE_KEY}");var theme=t==="light"||t==="dark"?t:"${DEFAULT_THEME}";document.documentElement.setAttribute("data-theme",theme);}catch(e){document.documentElement.setAttribute("data-theme","${DEFAULT_THEME}");}})();`;

/** Blocking inline script for <head> — runs before paint to avoid theme flash. */
export function ThemeScript() {
  return (
    <script
      id="mosafer-theme-init"
      suppressHydrationWarning
      dangerouslySetInnerHTML={{ __html: themeScript }}
    />
  );
}
