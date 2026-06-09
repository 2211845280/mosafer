"use client";

import { buildMosaferTicketUrl } from "@/lib/app-link";
import { ticketQrDataUrl } from "@/lib/ticket-qr";
import { Link } from "@/i18n/navigation";
import type { ReservationDetail } from "@/types/booking";
import { useLocale, useTranslations } from "next-intl";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useMemo, useState } from "react";

type TicketRead = {
  ticket_number: string;
  qr_code: string;
  status: string;
};

type PassengerQrCard = {
  key: string;
  label: string;
  seat: string | null;
  ticketNumber: string | null;
  qrDataUrl: string;
  qrPayload: string;
};

function TicketFallback() {
  const t = useTranslations("trips");
  return (
    <div className="content-shell py-12">
      <p className="text-center text-muted">{t("ticketPageTitle")}…</p>
    </div>
  );
}

function TicketInner() {
  const t = useTranslations("trips");
  const tConfirm = useTranslations("confirmation");
  const tErr = useTranslations("errors");
  const locale = useLocale();
  const sp = useSearchParams();
  const reservationId = sp.get("reservation_id")?.trim() ?? "";
  const ticketNumber = sp.get("ticket_number")?.trim() ?? "";

  const [ticket, setTicket] = useState<TicketRead | null>(null);
  const [passengerCards, setPassengerCards] = useState<PassengerQrCard[]>([]);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!reservationId && !ticketNumber) {
      setErr("missing");
      return;
    }
    let cancelled = false;
    (async () => {
      try {
        let mainTicket: TicketRead | null = null;
        let reservation: ReservationDetail | null = null;

        if (reservationId) {
          const rr = await fetch(`/api/reservations/${encodeURIComponent(reservationId)}`, {
            headers: { "Accept-Language": locale },
          });
          if (rr.ok) {
            reservation = (await rr.json()) as ReservationDetail;
          }
        }

        const lookupTicket =
          ticketNumber ?? reservation?.ticket_number ?? undefined;
        if (lookupTicket) {
          const tr = await fetch(
            `/api/tickets/by-number/${encodeURIComponent(lookupTicket)}`,
            { headers: { "Accept-Language": locale } },
          );
          if (tr.ok) {
            mainTicket = (await tr.json()) as TicketRead;
            if (!cancelled) setTicket(mainTicket);
          }
        }

        const passengers = reservation?.passengers ?? [];
        const cards: PassengerQrCard[] = [];

        for (const [index, passenger] of passengers.entries()) {
          if (!passenger.qr_code) continue;
          const url = await ticketQrDataUrl(passenger.qr_code, 220);
          cards.push({
            key: passenger.passenger_ticket_number ?? `p-${index}`,
            label: `${passenger.family_name}/${passenger.given_name}`,
            seat: passenger.seat ?? null,
            ticketNumber: passenger.passenger_ticket_number ?? null,
            qrDataUrl: url,
            qrPayload: passenger.qr_code,
          });
        }

        if (cards.length === 0 && mainTicket?.qr_code) {
          const url = await ticketQrDataUrl(mainTicket.qr_code, 220);
          cards.push({
            key: mainTicket.ticket_number,
            label: passengers[0]
              ? `${passengers[0].family_name}/${passengers[0].given_name}`
              : mainTicket.ticket_number,
            seat: passengers[0]?.seat ?? null,
            ticketNumber: mainTicket.ticket_number,
            qrDataUrl: url,
            qrPayload: mainTicket.qr_code,
          });
        }

        if (cancelled) return;
        if (cards.length === 0 && !mainTicket) {
          setErr("load");
          return;
        }
        setPassengerCards(cards);
      } catch {
        if (!cancelled) setErr("load");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [reservationId, ticketNumber, locale]);

  const primaryAppUrl = useMemo(() => {
    const payload = passengerCards[0]?.qrPayload ?? ticket?.qr_code;
    return payload ? buildMosaferTicketUrl(payload) : null;
  }, [passengerCards, ticket]);

  if (!reservationId && !ticketNumber) {
    return (
      <div className="content-shell py-12 text-center">
        <p className="text-muted">{tErr("generic")}</p>
        <Link href="/trips" className="mt-4 inline-block font-bold text-primary underline">
          {t("backToTrips")}
        </Link>
      </div>
    );
  }

  if (err) {
    return (
      <div className="content-shell py-12 text-center">
        <p className="text-accent">{tErr("generic")}</p>
        <Link href="/trips" className="mt-4 inline-block font-bold text-primary underline">
          {t("backToTrips")}
        </Link>
      </div>
    );
  }

  return (
    <div className="content-shell py-12">
      <div className="mx-auto max-w-lg text-center">
        <h1 className="text-2xl font-black text-foreground">{t("ticketPageTitle")}</h1>

        {passengerCards.length > 0 ? (
          <div className="mt-8 space-y-6">
            {passengerCards.map((card, index) => (
              <div
                key={card.key}
                className="rounded-card border border-border-subtle bg-card p-6 text-center"
              >
                <p className="text-sm font-extrabold uppercase tracking-wide text-primary">
                  {passengerCards.length > 1
                    ? tConfirm("travelerTicket", { n: index + 1 })
                    : tConfirm("passenger")}
                </p>
                {card.ticketNumber && (
                  <p className="mt-2 font-mono text-xl font-bold text-foreground" dir="ltr">
                    {card.ticketNumber}
                  </p>
                )}
                {card.label !== card.ticketNumber && (
                  <p className="mt-2 font-bold text-foreground" dir="ltr">
                    {card.label}
                  </p>
                )}
                {card.seat && (
                  <p className="mt-1 text-sm text-muted">
                    {tConfirm("seat")}: <span dir="ltr">{card.seat}</span>
                  </p>
                )}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={card.qrDataUrl}
                  alt="Ticket QR"
                  className="mx-auto mt-4 rounded-mosafer border border-border-subtle bg-white p-2"
                />
              </div>
            ))}
            <p className="text-xs text-muted">{tConfirm("scanHint")}</p>
          </div>
        ) : (
          <p className="mt-8 text-sm text-muted">{t("ticketPageTitle")}…</p>
        )}

        <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center">
          {primaryAppUrl && (
            <a
              href={primaryAppUrl}
              className="rounded-mosafer bg-primary px-6 py-3 text-center text-sm font-black uppercase tracking-wide text-primary-foreground"
            >
              {tConfirm("openApp")}
            </a>
          )}
          <Link
            href="/trips"
            className="rounded-mosafer border border-border-strong px-6 py-3 text-center text-sm font-black uppercase tracking-wide text-muted hover:text-primary"
          >
            {t("backToTrips")}
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function TripTicketPage() {
  return (
    <Suspense fallback={<TicketFallback />}>
      <TicketInner />
    </Suspense>
  );
}
