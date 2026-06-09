"use client";

import {
  formatBookingStatusLabel,
  statusBadgeClass,
} from "@/lib/admin/booking-status";
import { useTranslations } from "next-intl";

type Props = {
  status: string;
};

export function StatusBadge({ status }: Props) {
  const t = useTranslations("admin");
  return (
    <span className={statusBadgeClass(status)}>
      {formatBookingStatusLabel(status, t)}
    </span>
  );
}
