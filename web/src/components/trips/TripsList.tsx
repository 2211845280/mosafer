"use client";

import { formatTableDate, formatTableDateTime } from "@/lib/format-datetime";
import { useTranslations } from "next-intl";
import { useState } from "react";
import { CancelReservationButton } from "./CancelReservationButton";
import { HideTripButton } from "./HideTripButton";
import { ViewTicketIcon } from "./ViewTicketIcon";

type FlightRead = {
  origin_iata: string;
  destination_iata: string;
  carrier_code: string;
  flight_number: string;
  departure_at: string;
  arrival_at?: string;
};

type ReservationRow = {
  id: number;
  seat: string;
  seats?: string[];
  status: string;
  ticket_number?: string | null;
  qr_code?: string | null;
  flight: FlightRead;
  total_price?: string | null;
  currency?: string | null;
  created_at?: string;
};

function getStatusColor(status: string): string {
  switch (status.toLowerCase()) {
    case "confirmed":
    case "completed":
      return "bg-green-500/20 text-green-400";
    case "pending":
      return "bg-yellow-500/20 text-yellow-400";
    case "cancelled":
    case "canceled":
      return "bg-accent/20 text-accent";
    default:
      return "bg-foreground/10 text-muted";
  }
}

function displaySeats(row: ReservationRow): string {
  if (row.seats && row.seats.length > 0) {
    return row.seats.join(", ");
  }
  return row.seat;
}

function seatCount(row: ReservationRow): number {
  if (row.seats && row.seats.length > 0) {
    return row.seats.length;
  }
  return row.seat ? 1 : 0;
}

function daysUntilDeparture(iso: string): number {
  const dep = new Date(iso);
  const now = new Date();
  const depDay = new Date(dep.getFullYear(), dep.getMonth(), dep.getDate());
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.floor((depDay.getTime() - today.getTime()) / 86400000);
}

function isCanceledStatus(status: string): boolean {
  const normalized = status.toLowerCase();
  return normalized === "canceled" || normalized === "cancelled";
}

function canHideTrip(row: ReservationRow): boolean {
  return isCanceledStatus(row.status) || daysUntilDeparture(row.flight.departure_at) < 0;
}

export function TripsList({ initialItems, locale }: { initialItems: ReservationRow[]; locale: string }) {
  const t = useTranslations("trips");
  const [items, setItems] = useState(initialItems);

  // Sort by departure date (latest departure first)
  const sortedItems = [...items].sort((a, b) => {
    return (
      new Date(b.flight.departure_at).getTime() -
      new Date(a.flight.departure_at).getTime()
    );
  });

  function handleCancelSuccess(reservationId: number) {
    setItems((prev) =>
      prev.map((item) =>
        item.id === reservationId ? { ...item, status: "canceled" } : item
      )
    );
  }

  function handleHideSuccess(reservationId: number) {
    setItems((prev) => prev.filter((item) => item.id !== reservationId));
  }

  if (items.length === 0) {
    return (
      <div className="mt-8 rounded-card border border-border-subtle bg-card p-8 text-center">
        <p className="text-muted">{t("empty")}</p>
      </div>
    );
  }

  return (
    <div className="mt-6 space-y-4">
      {sortedItems.map((row) => (
        <article
          key={row.id}
          className="flight-result-card text-sm"
        >
          {/* Flight Header */}
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-xs font-black uppercase tracking-wide text-muted">
                {row.flight.carrier_code}
                {row.flight.flight_number}
              </p>
              <p className="mt-1 text-xl font-black text-foreground">
                {row.flight.origin_iata} → {row.flight.destination_iata}
              </p>
            </div>
            <div className="flex items-center gap-2">
              <span className={`rounded-full px-3 py-1 text-xs font-black uppercase ${getStatusColor(row.status)}`}>
                {row.status}
              </span>
              {canHideTrip(row) ? (
                <HideTripButton
                  reservationId={row.id}
                  onHideSuccess={() => handleHideSuccess(row.id)}
                />
              ) : (
                <CancelReservationButton
                  reservationId={row.id}
                  status={row.status}
                  departureAt={row.flight.departure_at}
                  totalPrice={row.total_price}
                  currency={row.currency}
                  onCancelSuccess={() => handleCancelSuccess(row.id)}
                />
              )}
            </div>
          </div>

          {/* Flight Details — dir=ltr locks column order: departure | seats | price */}
          <div
            className="mt-4 grid gap-4 border-t border-border-subtle pt-4 sm:grid-cols-3"
            dir="ltr"
          >
            <div dir={locale === "ar" ? "rtl" : "ltr"}>
              <p className="text-xs font-black uppercase text-muted">{t("departure")}</p>
              <p className="mt-1 font-bold text-foreground">
                {formatTableDateTime(row.flight.departure_at)}
              </p>
            </div>
            <div dir={locale === "ar" ? "rtl" : "ltr"}>
              <p className="text-xs font-black uppercase text-muted">
                {seatCount(row) > 1 ? t("seats") : t("seat")}
              </p>
              <p className="mt-1 font-bold text-foreground">
                <span dir="ltr">{displaySeats(row)}</span>
              </p>
            </div>
            <div dir={locale === "ar" ? "rtl" : "ltr"}>
              <p className="text-xs font-black uppercase text-muted">{t("price")}</p>
              <p className="mt-1 font-bold text-primary">
                {row.total_price ? (
                  <>
                    {row.total_price} {row.currency}
                  </>
                ) : (
                  <span className="text-muted">—</span>
                )}
              </p>
            </div>
          </div>

          {/* Ticket Information */}
          {row.ticket_number && (
            <div className="mt-4 flex items-center gap-3 rounded-mosafer bg-surface p-3">
              <div className="flex-1">
                <p className="text-xs font-black uppercase text-muted">{t("ticketNumber")}</p>
                <p className="mt-1 font-mono text-sm text-foreground">{row.ticket_number}</p>
              </div>
              <ViewTicketIcon
                reservationId={row.id}
                ticketNumber={row.ticket_number}
              />
            </div>
          )}

          {row.created_at && (
            <div className="mt-3 text-xs text-muted">
              <span>{t("booked")}: {formatTableDate(row.created_at, locale)}</span>
            </div>
          )}
        </article>
      ))}
    </div>
  );
}
