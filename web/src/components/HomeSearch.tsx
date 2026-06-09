"use client";

import { defaultMockSearchDate, MOCK_SEARCH_MAX, MOCK_SEARCH_MIN } from "@/lib/mock-search-dates";
import { useRouter } from "@/i18n/navigation";
import { useTranslations } from "next-intl";
import { FormEvent, useMemo, useState } from "react";

export function HomeSearch() {
  const t = useTranslations("home");
  const router = useRouter();
  const defaultDate = useMemo(() => defaultMockSearchDate(), []);
  const [origin, setOrigin] = useState("CAI");
  const [destination, setDestination] = useState("DXB");
  const [date, setDate] = useState(defaultDate);
  const [adults, setAdults] = useState(1);

  function onSubmit(e: FormEvent) {
    e.preventDefault();
    const qs = new URLSearchParams({
      origin_iata: origin.trim().toUpperCase(),
      destination_iata: destination.trim().toUpperCase(),
      departure_date: date,
      adults: String(adults),
    });
    router.push(`/book/results?${qs.toString()}`);
  }

  return (
    <form
      onSubmit={onSubmit}
      className="mt-8 grid gap-4 rounded-card border border-border-subtle bg-card p-6 md:grid-cols-2"
    >
      <label className="flex flex-col gap-2 text-xs font-black uppercase tracking-wide text-muted">
        {t("origin")}
        <input
          required
          maxLength={3}
          minLength={3}
          value={origin}
          onChange={(e) => setOrigin(e.target.value)}
          className="rounded-mosafer border border-border-subtle bg-surface px-3 py-3 text-sm font-bold uppercase text-foreground outline-none ring-primary focus:ring-2"
          dir="ltr"
        />
      </label>
      <label className="flex flex-col gap-2 text-xs font-black uppercase tracking-wide text-muted">
        {t("destination")}
        <input
          required
          maxLength={3}
          minLength={3}
          value={destination}
          onChange={(e) => setDestination(e.target.value)}
          className="rounded-mosafer border border-border-subtle bg-surface px-3 py-3 text-sm font-bold uppercase text-foreground outline-none ring-primary focus:ring-2"
          dir="ltr"
        />
      </label>
      <label className="flex flex-col gap-2 text-xs font-black uppercase tracking-wide text-muted">
        {t("date")}
        <input
          required
          type="date"
          min={MOCK_SEARCH_MIN}
          max={MOCK_SEARCH_MAX}
          value={date}
          onChange={(e) => setDate(e.target.value)}
          className="rounded-mosafer border border-border-subtle bg-surface px-3 py-3 text-sm font-bold text-foreground outline-none ring-primary focus:ring-2"
        />
      </label>
      <label className="flex flex-col gap-2 text-xs font-black uppercase tracking-wide text-muted">
        {t("adults")}
        <input
          required
          type="number"
          min={1}
          max={9}
          value={adults}
          onChange={(e) => setAdults(Number(e.target.value))}
          className="rounded-mosafer border border-border-subtle bg-surface px-3 py-3 text-sm font-bold text-foreground outline-none ring-primary focus:ring-2"
        />
      </label>
      <div className="md:col-span-2">
        <button
          type="submit"
          className="w-full rounded-mosafer bg-primary py-4 text-sm font-black uppercase tracking-wide text-primary-foreground"
        >
          {t("search")}
        </button>
      </div>
    </form>
  );
}
