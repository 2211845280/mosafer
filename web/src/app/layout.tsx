import type { ReactNode } from "react";

/** Root pass-through: localized shell lives under `[locale]` (html/body there). */
export default function RootLayout({ children }: { children: ReactNode }) {
  return children;
}
