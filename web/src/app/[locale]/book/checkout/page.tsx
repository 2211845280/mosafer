"use client";

import { SeatMap } from "@/components/booking/SeatMap";
import { Link, useRouter } from "@/i18n/navigation";
import { resolveBookingError } from "@/lib/booking-errors";
import {
  formatCabinPrice,
  highestCabinForSeats,
  totalPriceForSeats,
  type SeatCabin,
} from "@/lib/seat-cabin";
import type { FlightOffer } from "@/types/booking";
import { PENDING_ADULTS_STORAGE_KEY, PENDING_OFFER_STORAGE_KEY } from "@/types/booking";
import { airportSubtitle } from "@/lib/airports";
import { resolveCarrierName } from "@/lib/carriers";
import { formatTableDateTime } from "@/lib/format-datetime";
import { useLocale, useTranslations } from "next-intl";
import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";

type CheckoutSessionCreated = {
  id: number;
  seats: string[];
  status: string;
};

type SeatAvailability = {
  provider_flight_id: string;
  rows: number;
  columns: string[];
  available_seats: string[];
  taken_seats: string[];
};

type ApiErrorBody = {
  detail?: string | { msg?: string }[];
};

function cabinLabel(
  cabin: SeatCabin | "Mixed" | null,
  t: ReturnType<typeof useTranslations<"book">>,
): string {
  if (!cabin) return t("selectSeatForClass");
  if (cabin === "Mixed") return t("mixedCabin");
  if (cabin === "First") return t("firstClass");
  if (cabin === "Business") return t("cabinSectionBusiness");
  return t("cabinSectionEconomy");
}

export default function BookCheckoutPage() {
  const t = useTranslations("book");
  const router = useRouter();
  const locale = useLocale();
  const [offer, setOffer] = useState<FlightOffer | null | undefined>(undefined);
  const [seats, setSeats] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [adults, setAdults] = useState(1);
  const [seatAvailability, setSeatAvailability] = useState<SeatAvailability | null>(null);
  const [seatsLoading, setSeatsLoading] = useState(false);
  const [seatsError, setSeatsError] = useState<string | null>(null);
  const [seatsReloadKey, setSeatsReloadKey] = useState(0);

  const [busy, setBusy] = useState(false);

  useEffect(() => {
    try {
      const a = sessionStorage.getItem(PENDING_ADULTS_STORAGE_KEY);
      if (a) setAdults(Math.max(1, Number(a) || 1));
      const raw = sessionStorage.getItem(PENDING_OFFER_STORAGE_KEY);
      if (!raw) {
        setOffer(null);
        return;
      }
      setOffer(JSON.parse(raw) as FlightOffer);
    } catch {
      setOffer(null);
    }
  }, []);

  const redirectToLogin = useCallback(() => {
    window.location.href = `/${locale}/login?next=${encodeURIComponent(`/${locale}/book/checkout`)}`;
  }, [locale]);

  const loadSeats = useCallback(
    async (currentOffer: FlightOffer, signal?: { cancelled: boolean }) => {
      setSeatsLoading(true);
      setSeatsError(null);
      setSeats([]);
      setSeatAvailability(null);
      try {
        const params = new URLSearchParams({
          provider_flight_id: currentOffer.provider_flight_id,
          departure_at: currentOffer.departure_at,
        });
        const res = await fetch(`/api/flights/available-seats?${params.toString()}`, {
          headers: { "Accept-Language": locale },
        });
        if (res.status === 401) {
          redirectToLogin();
          return;
        }
        const json = (await res.json().catch(() => ({}))) as SeatAvailability & ApiErrorBody;
        if (!res.ok) {
          if (!signal?.cancelled) {
            setSeatsError(
              resolveBookingError(json.detail, t, t("seatsLoadError")),
            );
          }
          return;
        }
        if (!signal?.cancelled) setSeatAvailability(json);
      } catch {
        if (!signal?.cancelled) setSeatsError(t("seatsLoadError"));
      } finally {
        if (!signal?.cancelled) setSeatsLoading(false);
      }
    },
    [locale, redirectToLogin, t],
  );

  useEffect(() => {
    if (!offer) return;
    const signal = { cancelled: false };
    void loadSeats(offer, signal);
    return () => {
      signal.cancelled = true;
    };
  }, [offer, loadSeats, seatsReloadKey]);

  const economyBasePrice = useMemo(() => {
    if (!offer?.total_price) return null;
    const parsed = Number(offer.total_price);
    return Number.isFinite(parsed) ? parsed : null;
  }, [offer]);

  const selectedCabin = useMemo((): SeatCabin | "Mixed" | null => {
    if (seats.length === 0 || !seatAvailability) return null;
    return highestCabinForSeats(seats, seatAvailability.rows);
  }, [seats, seatAvailability]);

  const displayPrice = useMemo(() => {
    if (!economyBasePrice || seats.length === 0 || !seatAvailability) return null;
    return totalPriceForSeats(economyBasePrice, seats, seatAvailability.rows);
  }, [economyBasePrice, seats, seatAvailability]);

  const cabinClassLabel = useMemo(
    () => cabinLabel(selectedCabin, t),
    [selectedCabin, t],
  );

  const priceLabel = useMemo(() => {
    if (!offer) return "—";
    if (displayPrice !== null) {
      return formatCabinPrice(offer.currency, displayPrice);
    }
    if (economyBasePrice !== null) {
      return formatCabinPrice(offer.currency, economyBasePrice * adults);
    }
    return `${offer.currency ?? ""} ${offer.total_price ?? "—"}`.trim();
  }, [offer, displayPrice, economyBasePrice, adults]);

  const seatsComplete = seats.length === adults;
  const primaryCabin = useMemo((): SeatCabin => {
    if (!selectedCabin || selectedCabin === "Mixed") {
      if (seats.length === 0 || !seatAvailability) return "Economy";
      const first = highestCabinForSeats([seats[0]], seatAvailability.rows);
      return first && first !== "Mixed" ? first : "Economy";
    }
    return selectedCabin;
  }, [selectedCabin, seats, seatAvailability]);

  const airline = offer
    ? resolveCarrierName(offer.carrier_code, offer.carrier_name)
    : "";

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!offer || !seatsComplete) return;
    setError(null);
    setBusy(true);
    try {
      const normalizedSeats = seats.map((s) => s.trim().toUpperCase());
      const body = {
        provider_flight_id: offer.provider_flight_id,
        origin_iata: offer.origin_iata,
        destination_iata: offer.destination_iata,
        carrier_code: offer.carrier_code,
        flight_number: offer.flight_number,
        departure_at: offer.departure_at,
        arrival_at: offer.arrival_at,
        base_price: offer.total_price,
        currency: offer.currency,
        total_price: displayPrice ?? offer.total_price,
        seat: normalizedSeats[0],
        seats: normalizedSeats,
        adults,
        cabin_class: primaryCabin,
      };

      const resR = await fetch("/api/checkout-sessions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify(body),
      });
      if (resR.status === 401) {
        redirectToLogin();
        return;
      }
      const resJson = (await resR.json().catch(() => ({}))) as CheckoutSessionCreated & ApiErrorBody;
      if (!resR.ok) {
        setError(resolveBookingError(resJson.detail, t, t("reservationFailed")));
        return;
      }

      sessionStorage.removeItem(PENDING_OFFER_STORAGE_KEY);
      sessionStorage.removeItem(PENDING_ADULTS_STORAGE_KEY);
      router.push(`/book/passengers?checkout_session_id=${resJson.id}`);
    } finally {
      setBusy(false);
    }
  }

  if (offer === undefined) {
    return (
      <div className="content-shell flex justify-center py-16">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (!offer) {
    return (
      <div className="content-shell">
        <div className="mx-auto max-w-lg rounded-2xl border border-border-subtle bg-card p-8 text-center">
          <p className="text-muted">{t("noOffer")}</p>
          <Link
            href="/"
            className="mt-4 inline-block rounded-mosafer bg-primary px-6 py-2 text-xs font-extrabold uppercase text-primary-foreground"
          >
            {t("backToSearch")}
          </Link>
        </div>
      </div>
    );
  }

  const seatMapMode = adults > 1 ? "multi" as const : "single" as const;

  return (
    <div className="content-shell pb-16">
      <h1 className="mb-8 text-2xl font-extrabold text-foreground">{t("checkoutTitle")}</h1>

      <div className="grid gap-8 lg:grid-cols-[1fr_380px]">
        <form
          className="rounded-2xl border border-border-subtle bg-card p-6 sm:p-8"
          onSubmit={(e) => void onSubmit(e)}
        >
          <h2 className="text-sm font-extrabold uppercase tracking-wide text-muted">
            {t("seatSelection")}
          </h2>

          {seatsLoading && (
            <div className="mt-6 flex justify-center py-8">
              <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
              <span className="sr-only">{t("seatsLoading")}</span>
            </div>
          )}

          {!seatsLoading && seatsError && (
            <div className="mt-4 flex flex-wrap items-center gap-3">
              <p className="text-sm font-semibold text-accent" role="alert">
                {seatsError}
              </p>
              <button
                type="button"
                onClick={() => setSeatsReloadKey((k) => k + 1)}
                className="rounded-mosafer border border-border-strong px-4 py-2 text-xs font-extrabold uppercase text-foreground hover:bg-foreground/5"
              >
                {t("retryLoadSeats")}
              </button>
            </div>
          )}

          {!seatsLoading && !seatsError && seatAvailability && (
            <>
              {seatAvailability.available_seats.length === 0 ? (
                <p className="mt-4 text-sm text-muted">{t("noSeatsAvailable")}</p>
              ) : seatMapMode === "multi" ? (
                <SeatMap
                  mode="multi"
                  rows={seatAvailability.rows}
                  columns={seatAvailability.columns}
                  availableSeats={seatAvailability.available_seats}
                  takenSeats={seatAvailability.taken_seats}
                  value={seats}
                  maxSelections={adults}
                  onChange={setSeats}
                  labels={{
                    seatTaken: t("seatTaken"),
                    seatAvailable: t("seatAvailable"),
                    selectedSeat: t("selectedSeat"),
                    selectedSeats: t("selectedSeats"),
                    pickSeatHint: t("pickSeatHint"),
                    selectSeatsCount: t("selectSeatsCount", {
                      selected: seats.length,
                      total: adults,
                    }),
                    cabinLegend: t("cabinLegend"),
                    cabinSectionFirst: t("cabinSectionFirst"),
                    cabinSectionBusiness: t("cabinSectionBusiness"),
                    cabinSectionEconomy: t("cabinSectionEconomy"),
                  }}
                />
              ) : (
                <SeatMap
                  rows={seatAvailability.rows}
                  columns={seatAvailability.columns}
                  availableSeats={seatAvailability.available_seats}
                  takenSeats={seatAvailability.taken_seats}
                  value={seats[0] ?? ""}
                  onChange={(seat) => setSeats(seat ? [seat] : [])}
                  labels={{
                    seatTaken: t("seatTaken"),
                    seatAvailable: t("seatAvailable"),
                    selectedSeat: t("selectedSeat"),
                    pickSeatHint: t("pickSeatHint"),
                    cabinLegend: t("cabinLegend"),
                    cabinSectionFirst: t("cabinSectionFirst"),
                    cabinSectionBusiness: t("cabinSectionBusiness"),
                    cabinSectionEconomy: t("cabinSectionEconomy"),
                  }}
                />
              )}
            </>
          )}

          {!seatsComplete && seats.length > 0 && adults > 1 && (
            <p className="mt-4 text-sm text-accent" role="status">
              {t("seatsRequired", { count: adults })}
            </p>
          )}

          {error && (
            <p className="mt-4 text-sm font-semibold text-accent" role="alert">
              {error}
            </p>
          )}
          <button
            type="submit"
            disabled={busy || seatsLoading || !seatsComplete}
            className="mt-8 w-full rounded-mosafer bg-accent py-4 text-sm font-extrabold uppercase tracking-wide text-primary-foreground disabled:opacity-60"
          >
            {busy ? t("processing") : t("continueToPassengers")}
          </button>
        </form>

        <aside className="h-fit rounded-2xl border border-border-subtle bg-card p-6">
          <p className="text-xs font-extrabold uppercase tracking-wide text-muted">{t("summary")}</p>

          <div className="mt-4 flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/15 text-xs font-extrabold text-primary">
              {offer.carrier_code}
            </div>
            <div className="flex-1">
              <p className="font-extrabold text-foreground">{airline}</p>
              <p className="text-xs text-muted">
                {offer.origin_iata} → {offer.destination_iata} · {offer.flight_number}
              </p>
            </div>
          </div>

          <div className="mt-4 flex items-center gap-3 rounded-lg border border-border-subtle bg-surface p-3">
            <div className="flex-1">
              <p className="text-xs font-bold uppercase text-muted">{t("cabinClassLabel")}</p>
              <p className="font-bold text-foreground">{cabinClassLabel}</p>
            </div>
            <div className="h-8 w-px bg-foreground/10" />
            <div className="flex-1">
              <p className="text-xs font-bold uppercase text-muted">{t("travelersLabel")}</p>
              <p className="font-bold text-foreground">
                {adults} {adults === 1 ? t("oneTraveler") : t("manyTravelers")}
              </p>
            </div>
          </div>

          <div className="mt-4 space-y-2 text-sm">
            <p className="text-muted">
              {airportSubtitle(offer.origin_iata)} → {airportSubtitle(offer.destination_iata)}
            </p>
            <p className="text-muted">{t("departure")}: {formatTableDateTime(offer.departure_at)}</p>
            <p className="text-muted">{t("arrival")}: {formatTableDateTime(offer.arrival_at)}</p>
          </div>

          <div className="mt-6 border-t border-border-subtle pt-4">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted">{t("total")}</span>
              <span className="text-xl font-extrabold text-foreground" dir="ltr">
                {priceLabel}
              </span>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}
