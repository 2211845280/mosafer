"use client";

import { useLocale, useTranslations } from "next-intl";
import { useState } from "react";

function daysUntilDeparture(iso: string): number {
  const dep = new Date(iso);
  const now = new Date();
  const depDay = new Date(dep.getFullYear(), dep.getMonth(), dep.getDate());
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.floor((depDay.getTime() - today.getTime()) / 86400000);
}

function parseAmount(value: string | null | undefined): number {
  const n = Number.parseFloat(value ?? "");
  return Number.isFinite(n) ? n : 0;
}

export function CancelReservationButton({
  reservationId,
  status,
  departureAt,
  totalPrice,
  currency,
  onCancelSuccess,
}: {
  reservationId: number;
  status: string;
  departureAt: string;
  totalPrice?: string | null;
  currency?: string | null;
  onCancelSuccess?: () => void;
}) {
  const t = useTranslations("trips");
  const locale = useLocale();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);

  const normalized = status.toLowerCase();
  const isCanceled = normalized === "canceled" || normalized === "cancelled";
  const daysLeft = daysUntilDeparture(departureAt);
  const isPast = daysLeft < 0;
  const amount = parseAmount(totalPrice);
  const curr = currency ?? "USD";
  const isPaid = normalized === "paid";
  const partialRefund = isPaid && daysLeft <= 3;
  const refundPreview = isPaid
    ? partialRefund
      ? (amount / 2).toFixed(2)
      : amount.toFixed(2)
    : null;
  const penaltyPreview = isPaid && partialRefund ? (amount / 2).toFixed(2) : null;

  const canCancel =
    !isCanceled &&
    !isPast &&
    (normalized === "paid" || normalized === "booked" || normalized === "pending");

  async function handleCancel() {
    if (!canCancel) return;

    setBusy(true);
    setError(null);
    setSuccess(false);

    try {
      const res = await fetch(`/api/reservations/${reservationId}/cancel`, {
        method: "POST",
        headers: {
          "Accept-Language": locale,
        },
      });

      const data = (await res.json().catch(() => ({}))) as { detail?: string };

      if (!res.ok) {
        setError(typeof data.detail === "string" ? data.detail : t("cancelFailed"));
        return;
      }

      setSuccess(true);
      setConfirmOpen(false);
      onCancelSuccess?.();
    } catch {
      setError(t("cancelFailed"));
    } finally {
      setBusy(false);
    }
  }

  if (isCanceled) {
    return (
      <span className="text-xs text-muted">{t("alreadyCancelled")}</span>
    );
  }

  if (!canCancel) {
    return (
      <span className="text-xs text-muted">
        {isPast ? t("cancelPastFlight") : t("cannotCancel")}
      </span>
    );
  }

  return (
    <>
      <div className="flex flex-col items-end gap-1">
        <button
          type="button"
          onClick={() => setConfirmOpen(true)}
          disabled={busy}
          className="rounded-mosafer border border-accent/40 px-3 py-1.5 text-xs font-black uppercase tracking-wide text-accent transition-colors hover:bg-accent/10 disabled:opacity-50"
        >
          {busy ? t("canceling") : t("cancelBooking")}
        </button>
        {success && (
          <p className="max-w-[220px] text-right text-[10px] font-semibold text-green-400">
            {t("cancelSuccess")}
          </p>
        )}
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
            aria-labelledby="cancel-confirm-title"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="cancel-confirm-title" className="text-lg font-black text-foreground">
              {t("cancelConfirmTitle")}
            </h2>
            <p className="mt-3 text-sm text-muted">
              {isPaid && refundPreview
                ? partialRefund
                  ? t("cancelConfirmPartialRefund", {
                      refund: refundPreview,
                      penalty: penaltyPreview ?? "0",
                      currency: curr,
                    })
                  : t("cancelConfirmFullRefund", {
                      amount: refundPreview,
                      currency: curr,
                    })
                : t("cancelConfirmNoRefund")}
            </p>
            <div className="mt-6 flex flex-wrap gap-3">
              <button
                type="button"
                disabled={busy}
                onClick={() => void handleCancel()}
                className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
              >
                {busy ? t("canceling") : t("cancelBooking")}
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
