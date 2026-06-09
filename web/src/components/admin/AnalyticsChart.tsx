"use client";

import { useMemo, useState } from "react";

type ChartPoint = {
  label: string;
  bookings: number;
  amount: number;
};

type Props = {
  data: ChartPoint[];
  formatAmount: (value: number) => string;
  bookingsLabel: string;
  scaleBy?: "bookings" | "amount";
  /** Shared Y-axis cap (e.g. max ticket revenue across paired charts). */
  maxScale?: number;
  /** Minimum bar height in px; default 32 without axes, 0 with axes. */
  minBarHeightPx?: number;
  barClassName?: string;
  /** Inline fill color; overrides Tailwind when set. */
  barColor?: string;
  tooltipAmountClassName?: string;
  activeRingClassName?: string;
  heightClassName?: string;
  emptyHint?: string;
  showAxes?: boolean;
  xAxisLabel?: string;
  yAxisLabel?: string;
  formatYTick?: (value: number) => string;
  axisLocale?: "ar" | "en";
};

/** Plot area height in px — bar heights are computed from this, not %. */
const PLOT_HEIGHT_PX = 148;
const BAR_MIN_HEIGHT_PX = 32;
const BAR_WIDTH_PX = 56;
const Y_AXIS_WIDTH_PX = 48;
const Y_TICK_STEPS = 4;

const CHART_TICK_CLASS = "font-normal tabular-nums leading-none text-muted/80";
const CHART_AXIS_TITLE_CLASS = "font-medium text-muted/70";
/** Inline px — avoids browser/Tailwind min-font bump on axis labels. */
const CHART_TICK_STYLE = {
  fontSize: 10,
  lineHeight: 1,
  WebkitTextSizeAdjust: "none",
  textSizeAdjust: "none",
} as const;
const CHART_AXIS_TITLE_STYLE = {
  fontSize: 10,
  lineHeight: 1,
  WebkitTextSizeAdjust: "none",
  textSizeAdjust: "none",
} as const;

function buildYTicks(maxScale: number, steps = Y_TICK_STEPS): number[] {
  if (maxScale <= 0) return [0];
  const ticks: number[] = [];
  for (let i = 0; i <= steps; i += 1) {
    ticks.push((maxScale * i) / steps);
  }
  return ticks;
}

function formatAxisAmount(value: number, locale: "ar" | "en"): string {
  if (value === 0) return "0";
  return new Intl.NumberFormat(locale === "ar" ? "ar-LY" : "en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value);
}

export function AnalyticsChart({
  data,
  formatAmount,
  bookingsLabel,
  scaleBy = "bookings",
  maxScale: maxScaleProp,
  minBarHeightPx: minBarHeightPxProp,
  barClassName = "bg-primary",
  barColor,
  tooltipAmountClassName = "text-primary",
  activeRingClassName = "ring-white/50",
  heightClassName = "h-64",
  emptyHint,
  showAxes = true,
  xAxisLabel,
  yAxisLabel,
  formatYTick,
  axisLocale = "en",
}: Props) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const minBarHeightPx =
    minBarHeightPxProp ?? (showAxes ? 0 : BAR_MIN_HEIGHT_PX);

  const scaleValues = useMemo(
    () =>
      data.map((point) =>
        scaleBy === "amount" ? Math.max(point.amount, 0) : Math.max(point.bookings, 0),
      ),
    [data, scaleBy],
  );

  const computedMaxScale = useMemo(() => Math.max(...scaleValues, 1), [scaleValues]);
  const maxScale = maxScaleProp ?? computedMaxScale;
  const hasAnyValue = scaleValues.some((v) => v > 0);

  const yTicks = useMemo(() => buildYTicks(maxScale), [maxScale]);

  const formatTick = useMemo(() => {
    if (formatYTick) return formatYTick;
    if (scaleBy === "amount") {
      return (value: number) => formatAxisAmount(value, axisLocale);
    }
    return (value: number) => String(Math.round(value));
  }, [formatYTick, scaleBy, axisLocale]);

  const yTickLabels = useMemo(
    () => [...yTicks].reverse().map((tick) => formatTick(tick)),
    [yTicks, formatTick],
  );

  if (!data.length) {
    return (
      <div
        className={`flex ${heightClassName} items-center justify-center rounded-mosafer border border-border-subtle bg-surface text-sm text-muted`}
      >
        {emptyHint ?? "—"}
      </div>
    );
  }

  const barHeightFor = (scaleValue: number) => {
    if (scaleValue === 0) return 0;
    const proportionalHeight = (scaleValue / maxScale) * PLOT_HEIGHT_PX;
    return minBarHeightPx > 0
      ? Math.max(minBarHeightPx, proportionalHeight)
      : proportionalHeight;
  };

  const renderTooltip = () => {
    if (activeIndex === null || !data[activeIndex]) return null;
    const point = data[activeIndex];
    return (
      <div className="pointer-events-none absolute left-1/2 top-2 z-10 -translate-x-1/2 rounded-mosafer border border-border-strong bg-surface px-2 py-1.5 text-center text-[9px] shadow-lg">
        <p className="font-medium text-foreground">{point.label}</p>
        <p className={`mt-0.5 font-semibold ${tooltipAmountClassName}`}>
          {formatAmount(point.amount)}
        </p>
        <p className="mt-0.5 text-[8px] text-muted">
          {point.bookings} {bookingsLabel}
        </p>
      </div>
    );
  };

  const renderBars = () =>
    data.map((point, index) => {
      const scaleValue = scaleValues[index] ?? 0;
      const barHeightPx = barHeightFor(scaleValue);
      const isActive = activeIndex === index;

      return (
        <button
          key={`${point.label}-${index}`}
          type="button"
          className="group flex shrink-0 flex-col items-center focus:outline-none"
          style={{ width: BAR_WIDTH_PX }}
          onMouseEnter={() => setActiveIndex(index)}
          onMouseLeave={() => setActiveIndex(null)}
          onFocus={() => setActiveIndex(index)}
          onBlur={() => setActiveIndex(null)}
          aria-label={`${point.label}: ${formatAmount(point.amount)}, ${point.bookings} ${bookingsLabel}`}
        >
          <div
            className={`rounded-t-md shadow-md transition-shadow ${barClassName} ${
              isActive ? `ring-2 ${activeRingClassName}` : ""
            }`}
            style={{
              width: BAR_WIDTH_PX,
              height: barHeightPx,
              ...(barColor ? { backgroundColor: barColor } : {}),
            }}
          />
        </button>
      );
    });

  const renderXLabels = () => (
    <>
      <div className="mt-2 flex justify-center gap-10">
        {data.map((point, index) => (
          <span
            key={`label-${point.label}-${index}`}
            className={`shrink-0 truncate text-center ${CHART_TICK_CLASS}`}
            style={{ ...CHART_TICK_STYLE, width: BAR_WIDTH_PX }}
          >
            {point.label}
          </span>
        ))}
      </div>
      {xAxisLabel ? (
        <p className={`mt-1 text-center ${CHART_AXIS_TITLE_CLASS}`} style={CHART_AXIS_TITLE_STYLE}>
          {xAxisLabel}
        </p>
      ) : null}
    </>
  );

  if (!showAxes) {
    return (
      <div
        className={`relative rounded-mosafer border border-border-subtle bg-surface/60 p-4 ${heightClassName}`}
      >
        {renderTooltip()}

        <div className="relative pt-8">
          <div
            className="pointer-events-none absolute inset-x-2 top-8 flex flex-col justify-between"
            style={{ height: PLOT_HEIGHT_PX }}
          >
            {[0, 1, 2, 3].map((line) => (
              <div key={line} className="border-t border-border-subtle" />
            ))}
          </div>

          {!hasAnyValue && emptyHint ? (
            <p
              className="flex items-center justify-center text-sm text-muted"
              style={{ height: PLOT_HEIGHT_PX + 28 }}
            >
              {emptyHint}
            </p>
          ) : (
            <div
              className="flex items-end justify-center gap-10"
              style={{ height: PLOT_HEIGHT_PX }}
            >
              {renderBars()}
            </div>
          )}

          {renderXLabels()}
        </div>
      </div>
    );
  }

  return (
    <div
      className={`relative rounded-mosafer border border-border-subtle bg-surface/60 p-4 ${heightClassName}`}
    >
      {renderTooltip()}

      <div className="relative pt-6">
        <div dir="ltr" className="flex items-stretch gap-1">
          {yAxisLabel ? (
            <p
              className={`flex shrink-0 items-center justify-center ${CHART_AXIS_TITLE_CLASS}`}
              style={{
                ...CHART_AXIS_TITLE_STYLE,
                writingMode: "vertical-rl",
                transform: "rotate(180deg)",
              }}
            >
              {yAxisLabel}
            </p>
          ) : null}

          <div
            className="flex shrink-0 flex-col justify-between pe-0.5 text-end"
            style={{ width: Y_AXIS_WIDTH_PX, height: PLOT_HEIGHT_PX }}
            aria-hidden
          >
            {yTickLabels.map((label, index) => (
              <span key={`y-tick-${index}`} className={CHART_TICK_CLASS} style={CHART_TICK_STYLE}>
                {label}
              </span>
            ))}
          </div>

          <div className="min-w-0 flex-1">
            {!hasAnyValue && emptyHint ? (
              <div
                className="flex items-center justify-center border-s border-b border-border-strong text-sm text-muted"
                style={{ height: PLOT_HEIGHT_PX }}
              >
                {emptyHint}
              </div>
            ) : (
              <div
                className="relative border-s border-b border-border-strong"
                style={{ height: PLOT_HEIGHT_PX }}
              >
                <div
                  className="pointer-events-none absolute inset-0 flex flex-col justify-between"
                  aria-hidden
                >
                  {yTicks.map((tick) => (
                    <div key={`grid-${tick}`} className="border-t border-border-subtle" />
                  ))}
                </div>

                <div className="relative flex h-full items-end justify-center gap-10">
                  {renderBars()}
                </div>
              </div>
            )}

            {renderXLabels()}
          </div>
        </div>
      </div>
    </div>
  );
}
