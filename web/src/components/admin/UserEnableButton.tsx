"use client";

import { useLocale, useTranslations } from "next-intl";
import { useState } from "react";

type Props = {
  userId: number;
  initialActive: boolean;
  onActiveChange?: (active: boolean) => void;
};

export function UserEnableButton({ userId, initialActive, onActiveChange }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [active, setActive] = useState(initialActive);
  const [busy, setBusy] = useState(false);

  async function patch(next: boolean) {
    setBusy(true);
    try {
      const res = await fetch(`/api/admin/users/${userId}/enable`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({ is_active: next }),
      });
      if (res.ok) {
        setActive(next);
        onActiveChange?.(next);
      }
    } finally {
      setBusy(false);
    }
  }

  if (active) {
    return (
      <button
        type="button"
        disabled={busy}
        onClick={() => void patch(false)}
        className="rounded-mosafer border border-accent/40 px-4 py-2 text-xs font-black uppercase text-accent transition-colors hover:bg-accent/10 disabled:opacity-40"
      >
        {t("toggleDisable")}
      </button>
    );
  }

  return (
    <button
      type="button"
      disabled={busy}
      onClick={() => void patch(true)}
      className="rounded-mosafer bg-primary px-4 py-2 text-xs font-black uppercase text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-40"
    >
      {t("toggleEnable")}
    </button>
  );
}
