"use client";

import { AIRPORT_LABELS, destinationImage, POPULAR_ROUTES } from "@/lib/airports";
import { defaultMockSearchDate } from "@/lib/mock-search-dates";
import { Link } from "@/i18n/navigation";
import Image from "next/image";
import { useTranslations } from "next-intl";


type RouteCard = { origin: string; dest: string };

function RouteGrid({ routes }: { routes: readonly RouteCard[] }) {
  const t = useTranslations("home");
  const date = defaultMockSearchDate();

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      {routes.map(({ origin, dest }) => {
        const destInfo = AIRPORT_LABELS[dest];
        const imageSrc = destinationImage(dest);
        const href = `/book/results?origin_iata=${origin}&destination_iata=${dest}&departure_date=${date}&adults=1`;
        return (
          <Link
            key={`${origin}-${dest}`}
            href={href}
            className="group overflow-hidden rounded-2xl border border-border-subtle bg-card transition-all hover:border-primary/40 hover:shadow-[0_8px_32px_rgba(74,145,248,0.15)]"
          >
            <div className="relative h-28 overflow-hidden">
              {imageSrc ? (
                <>
                  <Image
                    src={imageSrc}
                    alt={destInfo?.city ?? dest}
                    fill
                    className="object-cover transition-transform duration-300 group-hover:scale-105"
                    sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 25vw"
                  />
                  <div className="absolute inset-0 bg-black/30" aria-hidden />
                </>
              ) : (
                <div className="absolute inset-0 bg-gradient-to-br from-primary/30 via-surface to-accent/20">
                  <div className="absolute inset-0 flex items-center justify-center text-4xl opacity-30">
                    ✈
                  </div>
                </div>
              )}
              <div className="absolute bottom-3 start-4 z-10">
                <span className="rounded-full bg-foreground/80 px-2 py-0.5 text-xs font-bold text-primary-foreground">
                  {origin} → {dest}
                </span>
              </div>
            </div>
            <div className="p-4">
              <p className="font-bold text-foreground group-hover:text-primary">
                {destInfo?.city ?? dest}
              </p>
              <p className="text-sm text-muted">{destInfo?.country}</p>
              <p className="mt-2 text-xs font-semibold text-accent">{t("exploreFlights")}</p>
            </div>
          </Link>
        );
      })}
    </div>
  );
}

export function PopularDestinations() {
  const t = useTranslations("home");

  return (
    <section className="mx-auto w-full max-w-6xl px-4 py-16 sm:px-6">
      <h2 className="mb-2 text-center text-2xl font-extrabold text-foreground sm:text-3xl">
        {t("popularTitle")}
      </h2>
      <p className="mb-10 text-center text-muted">{t("popularSubtitle")}</p>
      <RouteGrid routes={POPULAR_ROUTES} />
    </section>
  );
}
