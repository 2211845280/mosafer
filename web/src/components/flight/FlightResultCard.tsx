import type { FlightOffer } from "@/types/booking";
import { resolveCarrierName } from "@/lib/carriers";

type Props = {
  offer: FlightOffer;
  locale: string;
  onSelect: () => void;
  selectLabel: string;
  perPersonLabel: string;
  directLabel: string;
};

function formatTime(iso: string, locale: string) {
  try {
    return new Date(iso).toLocaleTimeString(locale === "ar" ? "ar" : "en-GB", {
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return iso;
  }
}

function durationMinutes(dep: string, arr: string): number {
  try {
    return Math.max(0, Math.round((new Date(arr).getTime() - new Date(dep).getTime()) / 60000));
  } catch {
    return 0;
  }
}

function formatDuration(minutes: number) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m}m`;
  return `${h}h ${m > 0 ? `${m}m` : ""}`.trim();
}

export function FlightResultCard({
  offer,
  locale,
  onSelect,
  selectLabel,
  perPersonLabel,
  directLabel,
}: Props) {
  const duration = durationMinutes(offer.departure_at, offer.arrival_at);
  const price = offer.total_price ?? "—";
  const currency = offer.currency ?? "USD";
  const airline = resolveCarrierName(offer.carrier_code, offer.carrier_name);

  return (
    <article className="flight-result-card group">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex flex-1 flex-col gap-4 sm:flex-row sm:items-center">
          <div className="flex h-12 w-12 shrink-0 flex-col items-center justify-center rounded-xl bg-primary/15 text-[10px] font-extrabold leading-tight text-primary">
            <span>{offer.carrier_code}</span>
          </div>
          <div className="hidden min-w-[120px] sm:block">
            <p className="text-sm font-extrabold text-foreground">{airline}</p>
            <p className="text-xs text-muted">
              {offer.flight_number} · {offer.cabin_class ?? "Economy"}
            </p>
          </div>

          <div className="flex flex-1 items-center gap-4 sm:gap-8">
            <div className="text-center sm:text-start">
              <p className="text-xl font-extrabold text-foreground" dir="ltr">
                {formatTime(offer.departure_at, locale)}
              </p>
              <p className="text-sm font-bold text-primary">{offer.origin_iata}</p>
            </div>

            <div className="flex flex-1 flex-col items-center gap-1 px-2">
              <p className="text-xs text-muted">{formatDuration(duration)}</p>
              <div className="relative flex w-full max-w-[120px] items-center">
                <div className="h-px flex-1 bg-foreground/10" />
                <span className="mx-1 text-primary">✈</span>
                <div className="h-px flex-1 bg-foreground/10" />
              </div>
              <p className="text-xs text-muted">{directLabel}</p>
            </div>

            <div className="text-center sm:text-end">
              <p className="text-xl font-extrabold text-foreground" dir="ltr">
                {formatTime(offer.arrival_at, locale)}
              </p>
              <p className="text-sm font-bold text-primary">{offer.destination_iata}</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between gap-4 border-t border-border-subtle pt-4 lg:flex-col lg:items-end lg:border-t-0 lg:border-s lg:ps-6 lg:pt-0">
          <div className="text-end">
            <p className="text-2xl font-extrabold text-foreground" dir="ltr">
              {currency} {price}
            </p>
            <p className="text-xs text-muted">{perPersonLabel}</p>
          </div>
          <button type="button" onClick={onSelect} className="flight-select-btn">
            {selectLabel}
          </button>
        </div>
      </div>

      <div className="mt-3 flex flex-wrap gap-2 border-t border-border-subtle pt-3 text-xs text-muted">
        <span className="rounded-full bg-foreground/5 px-2 py-0.5">{airline}</span>
        <span className="rounded-full bg-foreground/5 px-2 py-0.5">
          {offer.carrier_code} {offer.flight_number}
        </span>
        {offer.baggage_allowance && (
          <span className="rounded-full bg-foreground/5 px-2 py-0.5">🧳 {offer.baggage_allowance}</span>
        )}
      </div>
    </article>
  );
}
