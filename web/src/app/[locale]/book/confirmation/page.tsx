"use client";

import { buildMosaferTicketUrl } from "@/lib/app-link";
import { resolveCarrierName } from "@/lib/carriers";
import { Link, useRouter } from "@/i18n/navigation";
import type { ReservationDetail } from "@/types/booking";
import { useLocale, useTranslations } from "next-intl";
import { useSearchParams } from "next/navigation";
import QRCode from "qrcode";
import { Suspense, useEffect, useMemo, useState } from "react";

type PaymentRead = {
  id: number;
  status: string;
  reservation_id: number;
};

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

function ConfirmationFallback() {
  const t = useTranslations("book");
  return <p className="text-center text-muted">{t("processing")}</p>;
}

function ConfirmationInner() {
  const t = useTranslations("confirmation");
  const tTrips = useTranslations("trips");
  const tErr = useTranslations("errors");
  const router = useRouter();
  const locale = useLocale();
  const sp = useSearchParams();
  const ticketNumber = sp.get("ticket_number")?.trim();
  const paymentId = sp.get("payment_id")?.trim();
  const reservationId = sp.get("reservation_id")?.trim();

  const [payment, setPayment] = useState<PaymentRead | null>(null);
  const [ticket, setTicket] = useState<TicketRead | null>(null);
  const [reservation, setReservation] = useState<ReservationDetail | null>(null);
  const [passengerCards, setPassengerCards] = useState<PassengerQrCard[]>([]);
  const [err, setErr] = useState<string | null>(null);

  useEffect(() => {
    if (!paymentId || !reservationId) {
      setErr("missing");
      return;
    }
    let cancelled = false;
    (async () => {
      try {
        const pr = await fetch(`/api/payments/${encodeURIComponent(paymentId)}`, {
          headers: { "Accept-Language": locale },
        });
        if (!pr.ok) {
          if (!cancelled) setErr("load");
          return;
        }
        const pj = (await pr.json()) as PaymentRead;
        if (!cancelled) setPayment(pj);

        const rr = await fetch(`/api/reservations/${reservationId}`, {
          headers: { "Accept-Language": locale },
        });
        let reservationJson: ReservationDetail | null = null;
        if (rr.ok) {
          reservationJson = (await rr.json()) as ReservationDetail;
          if (!cancelled) {
            setReservation(reservationJson);
            if (reservationJson.passenger_details_required) {
              router.replace(
                `/book/passengers?reservation_id=${reservationId}&payment_id=${paymentId}${
                  ticketNumber ? `&ticket_number=${encodeURIComponent(ticketNumber)}` : ""
                }`,
              );
              return;
            }
          }
        }

        let mainTicket: TicketRead | null = null;
        const lookupTicket =
          ticketNumber ?? reservationJson?.ticket_number ?? undefined;
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

        const passengers = reservationJson?.passengers ?? [];
        const cards: PassengerQrCard[] = [];

        for (const [index, passenger] of passengers.entries()) {
          if (!passenger.qr_code) continue;
          const url = await QRCode.toDataURL(passenger.qr_code, { margin: 1, width: 220 });
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
          const url = await QRCode.toDataURL(mainTicket.qr_code, { margin: 1, width: 220 });
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

        if (!cancelled) setPassengerCards(cards);
      } catch {
        if (!cancelled) setErr("load");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [paymentId, reservationId, ticketNumber, locale, router]);

  const airline =
    reservation && reservation.flight
      ? resolveCarrierName(reservation.flight.carrier_code, reservation.carrier_name)
      : "";

  const primaryAppUrl = useMemo(() => {
    const payload = passengerCards[0]?.qrPayload ?? ticket?.qr_code;
    return payload ? buildMosaferTicketUrl(payload) : null;
  }, [passengerCards, ticket]);

  if (!paymentId || !reservationId) {
    return (
      <p className="text-center text-accent">
        <Link href="/" className="font-bold text-primary underline">
          {t("backHome")}
        </Link>
      </p>
    );
  }

  if (err === "missing") {
    return (
      <p className="text-center text-muted">
        <Link href="/" className="font-bold text-primary underline">
          {t("backHome")}
        </Link>
      </p>
    );
  }

  if (err) {
    return <p className="text-center text-sm text-accent">{tErr("generic")}</p>;
  }

  return (
    <div className="content-shell py-12">
      <div className="mx-auto max-w-lg text-center">
        <h1 className="text-2xl font-black text-foreground">{t("title")}</h1>
        <p className="mt-2 text-sm text-muted">{t("subtitle")}</p>
        <dl className="mt-6 space-y-2 rounded-card border border-border-subtle bg-card p-6 text-start text-sm">
          <div className="flex justify-between gap-4">
            <dt className="text-muted">{t("reservation")}</dt>
            <dd className="font-mono font-bold text-foreground">#{reservationId}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-muted">{t("payment")}</dt>
            <dd className="font-mono font-bold text-foreground">#{paymentId}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-muted">{t("status")}</dt>
            <dd className="font-bold uppercase text-primary">{payment?.status ?? "…"}</dd>
          </div>
          {reservation?.pnr && (
            <div className="flex justify-between gap-4">
              <dt className="text-muted">{t("pnr")}</dt>
              <dd className="font-mono font-bold text-foreground" dir="ltr">
                {reservation.pnr}
              </dd>
            </div>
          )}
          {airline && (
            <div className="flex justify-between gap-4">
              <dt className="text-muted">{t("airline")}</dt>
              <dd className="font-bold text-foreground">{airline}</dd>
            </div>
          )}
          {ticket?.ticket_number && passengerCards.length <= 1 && (
            <div className="flex justify-between gap-4">
              <dt className="text-muted">{tTrips("ticket")}</dt>
              <dd className="font-mono font-bold text-foreground">{ticket.ticket_number}</dd>
            </div>
          )}
        </dl>

        {passengerCards.length > 0 && (
          <div className="mt-8 space-y-6">
            {passengerCards.map((card, index) => (
              <div
                key={card.key}
                className="rounded-card border border-border-subtle bg-card p-6 text-center"
              >
                <p className="text-sm font-extrabold uppercase tracking-wide text-primary">
                  {passengerCards.length > 1
                    ? t("travelerTicket", { n: index + 1 })
                    : t("passenger")}
                </p>
                <p className="mt-2 font-bold text-foreground" dir="ltr">
                  {card.label}
                </p>
                {card.seat && (
                  <p className="mt-1 text-sm text-muted">
                    {t("seat")}: <span dir="ltr">{card.seat}</span>
                  </p>
                )}
                {card.ticketNumber && (
                  <p className="mt-1 text-xs text-muted">
                    {t("ticketNumber")}:{" "}
                    <span className="font-mono font-bold text-foreground" dir="ltr">
                      {card.ticketNumber}
                    </span>
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
            <p className="text-xs text-muted">{t("scanHint")}</p>
          </div>
        )}

        <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center">
          {primaryAppUrl && (
            <a
              href={primaryAppUrl}
              className="rounded-mosafer bg-primary px-6 py-3 text-center text-sm font-black uppercase tracking-wide text-primary-foreground"
            >
              {t("openApp")}
            </a>
          )}
          <Link
            href="/"
            className="rounded-mosafer border border-border-strong px-6 py-3 text-center text-sm font-black uppercase tracking-wide text-muted hover:text-primary"
          >
            {t("backHome")}
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function BookConfirmationPage() {
  return (
    <Suspense fallback={<ConfirmationFallback />}>
      <ConfirmationInner />
    </Suspense>
  );
}
