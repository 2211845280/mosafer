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

export function canAdminCancelBooking(status: string, departureAt: string): boolean {
  const normalized = status.toLowerCase();
  const isCanceled = normalized === "canceled" || normalized === "cancelled";
  const isPast = daysUntilDeparture(departureAt) < 0;
  return !isCanceled && !isPast && normalized === "confirmed";
}

type Props = {
  open: boolean;
  onClose: () => void;
  reservationId: number;
  status: string;
  departureAt: string;
  totalPrice?: string | null;
  currency?: string | null;
  onCanceled?: () => void;
};

export function AdminCancelBookingDialog({
  open,
  onClose,
  reservationId,
  status,
  departureAt,
  totalPrice,
  currency,
  onCanceled,
}: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const titleId = `admin-cancel-dialog-${reservationId}`;

  const normalized = status.toLowerCase();
  const daysLeft = daysUntilDeparture(departureAt);
  const amount = parseAmount(totalPrice);
  const curr = currency ?? "USD";
  const isPaid = normalized === "confirmed" || normalized === "paid";
  const partialRefund = isPaid && daysLeft <= 3;
  const refundPreview = isPaid
    ? partialRefund
      ? (amount / 2).toFixed(2)
      : amount.toFixed(2)
    : null;
  const penaltyPreview = isPaid && partialRefund ? (amount / 2).toFixed(2) : null;

  const canCancel = canAdminCancelBooking(status, departureAt);

  async function handleCancel() {
    if (!canCancel) return;

    setBusy(true);
    setError(null);

    try {
      const res = await fetch(`/api/reservations/${reservationId}/cancel`, {
        method: "POST",
        headers: {
          "Accept-Language": locale,
        },
      });

      const data = (await res.json().catch(() => ({}))) as { detail?: string };

      if (!res.ok) {
        if (res.status === 403) {
          setError(t("adminCancelNoPermission"));
        } else {
          setError(typeof data.detail === "string" ? data.detail : t("adminCancelFailed"));
        }
        return;
      }

      onClose();
      onCanceled?.();
    } catch {
      setError(t("adminCancelFailed"));
    } finally {
      setBusy(false);
    }
  }

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      role="presentation"
      onClick={() => !busy && onClose()}
    >
      <div
        className="profile-hero w-full max-w-md"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id={titleId} className="text-lg font-black text-foreground">
          {t("adminCancelConfirmTitle")}
        </h2>
        <p className="mt-3 text-sm text-muted">
          {isPaid && refundPreview
            ? partialRefund
              ? t("adminCancelConfirmPartialRefund", {
                  refund: refundPreview,
                  penalty: penaltyPreview ?? "0",
                  currency: curr,
                })
              : t("adminCancelConfirmFullRefund", {
                  amount: refundPreview,
                  currency: curr,
                })
            : t("adminCancelConfirmNoRefund")}
        </p>
        {error && (
          <p className="mt-3 text-sm font-semibold text-accent" role="alert">
            {error}
          </p>
        )}
        <div className="mt-6 flex flex-wrap gap-3">
          <button
            type="button"
            disabled={busy}
            onClick={() => void handleCancel()}
            className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
          >
            {busy ? t("adminCanceling") : t("adminCancelBooking")}
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={onClose}
            className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
          >
            {t("close")}
          </button>
        </div>
      </div>
    </div>
  );
}
