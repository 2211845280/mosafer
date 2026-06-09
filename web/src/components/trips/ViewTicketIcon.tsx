"use client";

import { Link } from "@/i18n/navigation";
import { useTranslations } from "next-intl";

export function ViewTicketIcon({
  reservationId,
  ticketNumber,
}: {
  reservationId: number;
  ticketNumber: string;
}) {
  const t = useTranslations("trips");
  const params = new URLSearchParams({
    reservation_id: String(reservationId),
    ticket_number: ticketNumber,
  });
  const href = `/trips/ticket?${params.toString()}`;

  return (
    <Link
      href={href}
      aria-label={t("viewTicket")}
      className="flex h-11 w-11 shrink-0 items-center justify-center rounded-mosafer bg-primary text-primary-foreground transition-opacity hover:opacity-90"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="currentColor"
        className="h-6 w-6"
        aria-hidden
      >
        <path d="M3 3h8v8H3V3zm2 2v4h4V5H5zm8-2h8v8h-8V3zm2 2v4h4V5h-4zM3 13h8v8H3v-8zm2 2v4h4v-4H5zm13-2h2v2h-2v-2zm-2 2h2v2h-2v-2zm2 2h2v2h-2v-2zm-2 2h2v2h-2v-2zm2 2h2v2h-2v-2zM19 13h2v2h-2v-2z" />
      </svg>
    </Link>
  );
}
