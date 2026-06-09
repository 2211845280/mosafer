"use client";

import {
  formatPaymentStatusLabel,
  paymentBadgeClass,
} from "@/lib/admin/booking-status";
import { useTranslations } from "next-intl";

type Props = {
  status: string;
};

export function PaymentBadge({ status }: Props) {
  const t = useTranslations("admin");
  return (
    <span className={paymentBadgeClass(status)}>
      {formatPaymentStatusLabel(status, t)}
    </span>
  );
}
