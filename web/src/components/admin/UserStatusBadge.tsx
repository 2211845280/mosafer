"use client";

import { useTranslations } from "next-intl";

const PILL_BASE =
  "inline-flex items-center rounded-md px-3 py-1 text-xs font-semibold whitespace-nowrap";

type Props = {
  isActive: boolean;
};

export function UserStatusBadge({ isActive }: Props) {
  const t = useTranslations("admin");
  return (
    <span
      className={`${PILL_BASE} ${
        isActive ? "bg-primary/15 text-primary" : "bg-accent/15 text-accent"
      }`}
    >
      {isActive ? t("active") : t("inactive")}
    </span>
  );
}
