"use client";

import { AnalyticsChart } from "@/components/admin/AnalyticsChart";
import { Link } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useState } from "react";

type ProfitData = {
  total_revenue: string;
  platform_profit: string;
  profit_margin_pct: string;
  revenue_this_month: string;
  profit_this_month: string;
  monthly_revenue: { month: string; revenue: string; bookings: number }[];
  monthly_profit: { month: string; revenue: string; bookings: number }[];
  top_routes: {
    origin_iata: string;
    destination_iata: string;
    bookings: number;
    revenue: string;
  }[];
};

function money(value: string, locale: string) {
  const n = Number(value);
  if (Number.isNaN(n)) return value;
  return new Intl.NumberFormat(locale === "ar" ? "ar-LY" : "en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(n);
}

function formatMonth(ym: string, locale: string) {
  const [y, m] = ym.split("-");
  const d = new Date(Number(y), Number(m) - 1, 1);
  return d.toLocaleDateString(locale === "ar" ? "ar" : "en-GB", {
    month: "short",
    year: "2-digit",
  });
}

export function ProfitAnalyticsClient() {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [data, setData] = useState<ProfitData | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/admin/analytics/profit", {
          headers: { "Accept-Language": locale },
        });
        const json = (await res.json()) as ProfitData & { detail?: string };
        if (!res.ok) {
          if (!cancelled) {
            setErr(typeof json.detail === "string" ? json.detail : t("analyticsLoadError"));
          }
          return;
        }
        if (!cancelled) setData(json);
      } catch {
        if (!cancelled) setErr(t("analyticsLoadError"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locale]);

  const profitChartData = useMemo(
    () =>
      (data?.monthly_profit ?? []).map((m) => ({
        label: formatMonth(m.month, locale),
        bookings: m.bookings,
        amount: Number(m.revenue),
      })),
    [data, locale],
  );

  const revenueChartData = useMemo(
    () =>
      (data?.monthly_revenue ?? []).map((m) => ({
        label: formatMonth(m.month, locale),
        bookings: m.bookings,
        amount: Number(m.revenue),
      })),
    [data, locale],
  );

  const chartMaxAmount = useMemo(() => {
    const amounts = (data?.monthly_revenue ?? []).map((m) => Number(m.revenue));
    return Math.max(...amounts, 1);
  }, [data]);

  if (loading) return <p className="text-muted">{t("loading")}…</p>;
  if (err || !data) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-6 text-sm text-accent">
        {err ?? t("analyticsLoadError")}
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-center gap-4">
        <div>
          <Link href="/admin" className="text-xs font-bold text-primary underline">
            ← {t("dashboard")}
          </Link>
          <h1 className="mt-2 text-2xl font-black text-foreground">{t("profitDetailsTitle")}</h1>
          <p className="mt-1 text-sm text-muted">{t("profitDetailsSubtitle")}</p>
        </div>
      </div>

      <section className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <div className="rounded-card border border-green-500/30 bg-card p-4">
          <p className="text-[10px] font-black uppercase leading-tight text-muted sm:text-xs">
            {t("platformProfit")}
          </p>
          <p className="mt-1.5 text-xl font-black text-green-400 sm:text-2xl">
            {money(data.platform_profit, locale)}
          </p>
        </div>
        <div className="rounded-card border border-primary/30 bg-gradient-to-br from-primary/10 to-card p-4">
          <p className="text-[10px] font-black uppercase leading-tight text-muted sm:text-xs">
            {t("allTimeRevenue")}
          </p>
          <p className="mt-1.5 text-xl font-black text-primary sm:text-2xl">
            {money(data.total_revenue, locale)}
          </p>
        </div>
        <div className="rounded-card border border-border-subtle bg-card p-4">
          <p className="text-[10px] font-black uppercase leading-tight text-muted sm:text-xs">
            {t("profitThisMonth")}
          </p>
          <p className="mt-1.5 text-xl font-black text-foreground sm:text-2xl">
            {money(data.profit_this_month, locale)}
          </p>
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-card border border-border-subtle bg-card p-6">
          <h2 className="text-lg font-black text-foreground">{t("profitOverTime")}</h2>
          <div className="mt-6">
            <AnalyticsChart
              data={profitChartData}
              formatAmount={(v) => money(String(v), locale)}
              bookingsLabel={t("bookingsShort")}
              scaleBy="amount"
              axisLocale={locale === "ar" ? "ar" : "en"}
              xAxisLabel={t("chartAxisDate")}
              yAxisLabel={t("chartAxisAmount")}
              barClassName="bg-[#22c55e]"
              barColor="#22c55e"
              tooltipAmountClassName="text-green-400"
              activeRingClassName="ring-green-400/60"
              emptyHint={t("profitChartEmpty")}
            />
          </div>
        </section>
        <section className="rounded-card border border-border-subtle bg-card p-6">
          <h2 className="text-lg font-black text-foreground">{t("revenueChart")}</h2>
          <div className="mt-6">
            <AnalyticsChart
              data={revenueChartData}
              formatAmount={(v) => money(String(v), locale)}
              bookingsLabel={t("bookingsShort")}
              scaleBy="amount"
              axisLocale={locale === "ar" ? "ar" : "en"}
              maxScale={chartMaxAmount}
              minBarHeightPx={8}
              xAxisLabel={t("chartAxisDate")}
              yAxisLabel={t("chartAxisAmount")}
              barClassName="bg-primary"
            />
          </div>
        </section>
      </div>

      <section className="rounded-card border border-border-subtle bg-card p-6">
        <h2 className="text-lg font-black text-foreground">{t("topRoutes")}</h2>
        <div className="mt-4 overflow-x-auto">
          <table className="w-full table-fixed text-center text-sm">
            <colgroup>
              <col className="w-[35%]" />
              <col className="w-[25%]" />
              <col className="w-[40%]" />
            </colgroup>
            <thead>
              <tr className="border-b border-border-subtle text-xs uppercase text-muted">
                <th className="px-3 py-2 text-center">{t("flight")}</th>
                <th className="px-3 py-2 text-center">{t("bookings")}</th>
                <th className="px-3 py-2 text-center">{t("payment")}</th>
              </tr>
            </thead>
            <tbody>
              {data.top_routes.map((r) => (
                <tr key={`${r.origin_iata}-${r.destination_iata}`} className="border-b border-border-subtle">
                  <td className="px-3 py-3 text-center font-bold whitespace-nowrap" dir="ltr">
                    {r.origin_iata} → {r.destination_iata}
                  </td>
                  <td className="px-3 py-3 text-center whitespace-nowrap">{r.bookings}</td>
                  <td className="px-3 py-3 text-center font-bold text-primary whitespace-nowrap" dir="ltr">
                    {money(r.revenue, locale)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
