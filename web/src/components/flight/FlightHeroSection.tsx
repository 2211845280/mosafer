"use client";

import { FlightSearchForm } from "@/components/flight/FlightSearchForm";
import { useTranslations } from "next-intl";

type Props = {
  compact?: boolean;
  initialOrigin?: string;
  initialDestination?: string;
  initialDate?: string;
  initialAdults?: number;
};

export function FlightHeroSection({
  compact = false,
  initialOrigin,
  initialDestination,
  initialDate,
  initialAdults,
}: Props) {
  const t = useTranslations("home");

  return (
    <section className={compact ? "flight-hero flight-hero--compact" : "flight-hero"}>
      <div className="flight-hero-bg" aria-hidden />
      {!compact && (
        <div className="relative z-10 mx-auto max-w-4xl px-4 pt-16 text-center sm:px-6 sm:pt-24">
          <div className="hero-title-stage relative mx-auto max-w-3xl px-2 pb-2 sm:px-4">
            <h1 className="hero-fade-up relative z-10 text-3xl font-extrabold leading-tight text-foreground sm:text-5xl lg:text-6xl">
              {t("heroTitle")}
            </h1>
            <p className="hero-fade-up hero-fade-up--delay-1 relative z-10 mx-auto mt-4 max-w-2xl text-base text-muted sm:text-lg">
              {t("heroSubtitle")}
            </p>
          </div>
        </div>
      )}
      <div
        className={`relative z-10 mx-auto w-full max-w-5xl px-4 sm:px-6 ${compact ? "py-6" : "hero-fade-up hero-fade-up--delay-2 pb-20 pt-8 sm:pb-24 sm:pt-10"}`}
      >
        <FlightSearchForm
          compact={compact}
          initialOrigin={initialOrigin}
          initialDestination={initialDestination}
          initialDate={initialDate}
          initialAdults={initialAdults}
        />
      </div>
    </section>
  );
}
