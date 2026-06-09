"use client";

import { finalizePaymentReturn, waitForPaymentCompleted } from "@/lib/payment";
import { Link, useRouter } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";

function PaymentReturnInner() {
  const t = useTranslations("book");
  const router = useRouter();
  const locale = useLocale();
  const sp = useSearchParams();
  const checkoutSessionId = sp.get("checkout_session_id")?.trim();
  const paymentId = sp.get("payment_id")?.trim();
  const sessionId = sp.get("session_id")?.trim();
  const isMock = sp.get("mock") === "1";
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!paymentId) {
      setError(t("paymentFailed"));
      return;
    }

    let cancelled = false;
    (async () => {
      try {
        const finalized = await finalizePaymentReturn({
          paymentId,
          sessionId,
          mock: isMock,
          locale,
        });
        const payment =
          finalized.reservation_id != null
            ? finalized
            : await waitForPaymentCompleted(paymentId, locale);
        if (cancelled) return;
        if (!payment?.reservation_id) {
          setError(t("paymentFailed"));
          return;
        }
        router.replace(
          `/book/confirmation?reservation_id=${payment.reservation_id}&payment_id=${paymentId}`,
        );
      } catch {
        if (!cancelled) setError(t("paymentFailed"));
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [checkoutSessionId, paymentId, sessionId, isMock, locale, router, t]);

  if (error) {
    return (
      <div className="content-shell py-16 text-center">
        <p className="text-sm font-semibold text-accent">{error}</p>
        <Link
          href={`/book/passengers?checkout_session_id=${checkoutSessionId ?? ""}`}
          className="mt-6 inline-block rounded-mosafer bg-primary px-6 py-3 text-sm font-extrabold uppercase text-primary-foreground"
        >
          {t("retryPayment")}
        </Link>
      </div>
    );
  }

  return (
    <div className="content-shell flex flex-col items-center justify-center py-24">
      <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      <p className="mt-4 text-sm text-muted">{t("processingPayment")}</p>
    </div>
  );
}

export default function PaymentReturnPage() {
  return (
    <Suspense
      fallback={
        <div className="content-shell flex justify-center py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      }
    >
      <PaymentReturnInner />
    </Suspense>
  );
}
