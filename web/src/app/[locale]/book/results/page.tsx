"use client";

import { FlightResultCard } from "@/components/flight/FlightResultCard";
import { FlightHeroSection } from "@/components/flight/FlightHeroSection";
import { Link, useRouter } from "@/i18n/navigation";
import {
  PENDING_ADULTS_STORAGE_KEY,
  PENDING_OFFER_STORAGE_KEY,
  type FlightOffer,
  type FlightSearchResponse,
} from "@/types/booking";
import { useLocale, useTranslations } from "next-intl";
import { useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";

function ResultsBody() {
  const t = useTranslations("book");
  const router = useRouter();
  const locale = useLocale();
  const sp = useSearchParams();
  const origin = sp.get("origin_iata")?.trim();
  const dest = sp.get("destination_iata")?.trim();
  const dep = sp.get("departure_date")?.trim();
  const adults = sp.get("adults") ?? "1";

  const [data, setData] = useState<FlightSearchResponse | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!origin || !dest || !dep) {
      setLoading(false);
      setErr("missing");
      return;
    }
    let cancelled = false;
    (async () => {
      setLoading(true);
      setErr(null);
      const qs = new URLSearchParams({
        origin_iata: origin.toUpperCase(),
        destination_iata: dest.toUpperCase(),
        departure_date: dep,
        adults,
      });
      try {
        const res = await fetch(`/api/flights/search?${qs}`, {
          headers: { "Accept-Language": locale },
        });
        if (res.status === 401) {
          window.location.href = `/${locale}/login?next=${encodeURIComponent(
            `/${locale}/book/results?${qs.toString()}`,
          )}`;
          return;
        }
        const json = (await res.json()) as FlightSearchResponse & { detail?: string };
        if (!res.ok) {
          if (!cancelled) {
            setErr(typeof json.detail === "string" ? json.detail : t("loadError"));
            setData(null);
          }
          return;
        }
        if (!cancelled) setData(json);
      } catch {
        if (!cancelled) setErr(t("loadError"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [origin, dest, dep, adults, locale, t]);

  function selectOffer(offer: FlightOffer) {
    try {
      sessionStorage.setItem(PENDING_OFFER_STORAGE_KEY, JSON.stringify(offer));
      sessionStorage.setItem(PENDING_ADULTS_STORAGE_KEY, adults);
    } catch {
      /* ignore */
    }
    router.push("/book/checkout");
  }

  if (!origin || !dest || !dep) {
    return (
      <div className="rounded-2xl border border-accent/30 bg-card p-6 text-sm font-semibold text-accent">
        {t("missingParams")}{" "}
        <Link href="/" className="font-bold text-primary underline">
          {t("backToSearch")}
        </Link>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center gap-4 py-16">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        <p className="text-muted">{t("processing")}</p>
      </div>
    );
  }

  if (err) {
    return (
      <p
        className="rounded-2xl border border-accent/30 bg-card p-6 text-sm font-semibold text-accent"
        role="alert"
      >
        {err === "missing" ? t("missingParams") : err}
      </p>
    );
  }

  if (!data?.items.length) {
    return (
      <div className="rounded-2xl border border-border-subtle bg-card p-8 text-center">
        <p className="text-lg font-bold text-foreground">{t("noResults")}</p>
        <p className="mt-2 text-sm text-muted">{t("noResultsHint")}</p>
        <Link
          href="/"
          className="mt-6 inline-block rounded-mosafer bg-primary px-6 py-2 text-xs font-extrabold uppercase text-primary-foreground"
        >
          {t("backToSearch")}
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-muted">{t("resultsCount", { count: data.items.length })}</p>
      {data.items.map((offer) => (
        <FlightResultCard
          key={offer.offer_id}
          offer={offer}
          locale={locale}
          onSelect={() => selectOffer(offer)}
          selectLabel={t("bookCta")}
          perPersonLabel={t("perPerson")}
          directLabel={t("direct")}
        />
      ))}
    </div>
  );
}

function ResultsPageContent() {
  const sp = useSearchParams();
  const origin = sp.get("origin_iata") ?? "MJI";
  const dest = sp.get("destination_iata") ?? "CAI";
  const dep = sp.get("departure_date") ?? undefined;
  const adults = Number(sp.get("adults") ?? "1");

  return (
    <>
      <FlightHeroSection
        compact
        initialOrigin={origin}
        initialDestination={dest}
        initialDate={dep}
        initialAdults={adults}
      />
      <div className="content-shell pb-16">
        <ResultsBody />
      </div>
    </>
  );
}

export default function BookResultsPage() {
  return (
    <Suspense
      fallback={
        <div className="flex justify-center py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      }
    >
      <ResultsPageContent />
    </Suspense>
  );
}
