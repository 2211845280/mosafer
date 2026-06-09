"use client";

import { useRouter } from "@/i18n/navigation";
import { useTranslations } from "next-intl";
import { FormEvent, useMemo, useState } from "react";
import { AirportCityInput } from "./AirportCityInput";
import {
  defaultMockSearchDate,
  MOCK_SEARCH_MAX,
  MOCK_SEARCH_MIN,
} from "@/lib/mock-search-dates";

function addDaysIso(iso: string, days: number): string {
  const d = new Date(`${iso}T12:00:00`);
  d.setDate(d.getDate() + days);
  return d.toISOString().slice(0, 10);
}

type TripType = "oneWay" | "roundTrip";

type Props = {
  compact?: boolean;
  initialOrigin?: string;
  initialDestination?: string;
  initialDate?: string;
  initialAdults?: number;
};

export function FlightSearchForm({
  compact = false,
  initialOrigin = "IST",
  initialDestination = "LHR",
  initialDate,
  initialAdults = 1,
}: Props) {
  const t = useTranslations("home");
  const router = useRouter();
  const defaultDate = useMemo(() => initialDate ?? defaultMockSearchDate(), [initialDate]);

  const [tripType, setTripType] = useState<TripType>("oneWay");
  const [origin, setOrigin] = useState(initialOrigin);
  const [destination, setDestination] = useState(initialDestination);
  const [date, setDate] = useState(defaultDate);
  const [returnDate, setReturnDate] = useState(() => addDaysIso(defaultDate, 7));
  const [adults, setAdults] = useState(initialAdults);
  const [dateError, setDateError] = useState<string | null>(null);

  function swapAirports() {
    setOrigin(destination);
    setDestination(origin);
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    setDateError(null);

    if (tripType === "roundTrip" && returnDate < date) {
      setDateError(t("returnDateInvalid"));
      return;
    }

    const qs = new URLSearchParams({
      origin_iata: origin.trim().toUpperCase(),
      destination_iata: destination.trim().toUpperCase(),
      departure_date: date,
      adults: String(adults),
    });
    if (tripType === "roundTrip") {
      qs.set("trip_type", "roundTrip");
      qs.set("return_date", returnDate);
    }
    router.push(`/book/results?${qs.toString()}`);
  }

  return (
    <form
      onSubmit={onSubmit}
      className={`flight-search-card ${compact ? "flight-search-card--compact" : ""}`}
    >
      {!compact && (
        <div className="flex flex-wrap items-center gap-2 border-b border-border-subtle px-4 py-3 sm:px-6">
          <div className="flex rounded-full bg-surface p-1">
            <button
              type="button"
              onClick={() => setTripType("oneWay")}
              className={`rounded-full px-4 py-1.5 text-xs font-bold transition-colors ${
                tripType === "oneWay"
                  ? "bg-primary text-primary-foreground"
                  : "text-muted hover:text-foreground"
              }`}
            >
              {t("oneWay")}
            </button>
            <button
              type="button"
              onClick={() => setTripType("roundTrip")}
              className={`rounded-full px-4 py-1.5 text-xs font-bold transition-colors ${
                tripType === "roundTrip"
                  ? "bg-primary text-primary-foreground"
                  : "text-muted hover:text-foreground"
              }`}
            >
              {t("roundTrip")}
            </button>
          </div>
        </div>
      )}

      <div className="grid gap-0 overflow-visible lg:grid-cols-[1fr_auto_1fr_1fr_auto] lg:items-start">
        <AirportCityInput
          label={t("origin")}
          value={origin}
          onChange={setOrigin}
          ariaLabel={t("origin")}
        />

        <div className="hidden items-center justify-center px-2 lg:flex">
          <button
            type="button"
            onClick={swapAirports}
            className="flex h-10 w-10 items-center justify-center rounded-full border border-border-strong bg-surface text-primary transition-colors hover:border-primary hover:bg-primary/10"
            aria-label={t("swapAirports")}
          >
            ⇄
          </button>
        </div>

        <AirportCityInput
          label={t("destination")}
          value={destination}
          onChange={setDestination}
          ariaLabel={t("destination")}
        />

        <div
          className={`flight-field border-b border-border-subtle lg:border-b-0 lg:border-e ${
            tripType === "roundTrip" ? "flight-date-stack" : ""
          }`}
        >
          <label className="flex flex-col gap-1">
            <span className="flight-field-label">{t("date")}</span>
            <input
              required
              type="date"
              min={MOCK_SEARCH_MIN}
              max={MOCK_SEARCH_MAX}
              value={date}
              onChange={(e) => {
                setDate(e.target.value);
                if (returnDate < e.target.value) {
                  setReturnDate(addDaysIso(e.target.value, 7));
                }
              }}
              className="flight-date-input"
            />
          </label>
          {tripType === "roundTrip" && (
            <label className="mt-3 flex flex-col gap-1">
              <span className="flight-field-label">{t("returnDate")}</span>
              <input
                required
                type="date"
                min={date}
                max={MOCK_SEARCH_MAX}
                value={returnDate}
                onChange={(e) => setReturnDate(e.target.value)}
                className="flight-date-input"
              />
            </label>
          )}
          {dateError && (
            <p className="mt-2 text-xs font-semibold text-accent">{dateError}</p>
          )}
        </div>

        <div className="flight-passengers-actions">
          <label className="flex w-full flex-col gap-1">
            <span className="flight-field-label">{t("adults")}</span>
            <select
              value={adults}
              onChange={(e) => setAdults(Number(e.target.value))}
              className="flight-select"
            >
              {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => (
                <option key={n} value={n}>
                  {n} {n === 1 ? t("traveler") : t("travelers")}
                </option>
              ))}
            </select>
          </label>
          <button type="submit" className="flight-search-btn">
            {t("search")}
          </button>
        </div>
      </div>
    </form>
  );
}
