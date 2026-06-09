"use client";

import { useLocale, useTranslations } from "next-intl";
import { useState } from "react";

export function HideTripButton({
  reservationId,
  onHideSuccess,
}: {
  reservationId: number;
  onHideSuccess?: () => void;
}) {
  const t = useTranslations("trips");
  const locale = useLocale();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);

  async function handleHide() {
    setBusy(true);
    setError(null);

    try {
      const res = await fetch(`/api/reservations/${reservationId}/hide`, {
        method: "POST",
        headers: {
          "Accept-Language": locale,
        },
      });

      if (!res.ok) {
        const data = (await res.json().catch(() => ({}))) as { detail?: string };
        setError(typeof data.detail === "string" ? data.detail : t("hideFailed"));
        return;
      }

      setConfirmOpen(false);
      onHideSuccess?.();
    } catch {
      setError(t("hideFailed"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <div className="flex flex-col items-end gap-1">
        <button
          type="button"
          onClick={() => setConfirmOpen(true)}
          disabled={busy}
          className="rounded-mosafer border border-border-strong px-3 py-1.5 text-xs font-black uppercase tracking-wide text-muted transition-colors hover:border-primary hover:text-primary disabled:opacity-50"
        >
          {busy ? t("hiding") : t("hideTrip")}
        </button>
        {error && (
          <p className="max-w-[220px] text-right text-[10px] text-accent">{error}</p>
        )}
      </div>

      {confirmOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
          role="presentation"
          onClick={() => !busy && setConfirmOpen(false)}
        >
          <div
            className="profile-hero w-full max-w-md"
            role="dialog"
            aria-modal="true"
            aria-labelledby="hide-confirm-title"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="hide-confirm-title" className="text-lg font-black text-foreground">
              {t("hideConfirmTitle")}
            </h2>
            <p className="mt-3 text-sm text-muted">{t("hideConfirmBody")}</p>
            <div className="mt-6 flex flex-wrap gap-3">
              <button
                type="button"
                disabled={busy}
                onClick={() => void handleHide()}
                className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
              >
                {busy ? t("hiding") : t("hideTrip")}
              </button>
              <button
                type="button"
                disabled={busy}
                onClick={() => setConfirmOpen(false)}
                className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
              >
                {t("cancel")}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
