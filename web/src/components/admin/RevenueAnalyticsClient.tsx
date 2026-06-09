"use client";

import { AnalyticsChart } from "@/components/admin/AnalyticsChart";
import { Link } from "@/i18n/navigation";
import { formatPaymentStatusLabel } from "@/lib/admin/booking-status";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useState } from "react";

type RevenueData = {
  total_revenue: string;
  revenue_this_month: string;
  monthly_revenue: { month: string; revenue: string; bookings: number }[];
  top_routes: {
    origin_iata: string;
    destination_iata: string;
    bookings: number;
    revenue: string;
  }[];
  payment_breakdown: { status: string; count: number; amount: string }[];
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

export function RevenueAnalyticsClient() {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [data, setData] = useState<RevenueData | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/admin/analytics/revenue", {
          headers: { "Accept-Language": locale },
        });
        const json = (await res.json()) as RevenueData & { detail?: string };
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
  }, [locale, t]);

  const chartData = useMemo(
    () =>
      (data?.monthly_revenue ?? []).map((m) => ({
        label: formatMonth(m.month, locale),
        bookings: m.bookings,
        amount: Number(m.revenue),
      })),
    [data, locale],
  );

  if (loading) return <p className="text-muted">{t("loading")}…</p>;
  if (err || !data) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-6 text-sm text-accent">
        {err ?? t("analyticsLoadError")}
      </div>
    );
  }

  return (
    <div className="min-w-0 space-y-8">
      <div className="flex flex-wrap items-center gap-4">
        <div>
          <Link href="/admin" className="text-xs font-bold text-primary underline">
            ← {t("dashboard")}
          </Link>
          <h1 className="mt-2 text-2xl font-black text-foreground">{t("revenueDetailsTitle")}</h1>
          <p className="mt-1 text-sm text-muted">{t("revenueDetailsSubtitle")}</p>
        </div>
      </div>

      <section className="grid gap-4 sm:grid-cols-2">
        <div className="rounded-card border border-primary/30 bg-gradient-to-br from-primary/10 to-card p-5">
          <p className="text-xs font-black uppercase text-muted">{t("allTimeRevenue")}</p>
          <p className="mt-2 text-3xl font-black text-primary">
            {money(data.total_revenue, locale)}
          </p>
        </div>
        <div className="rounded-card border border-border-subtle bg-card p-5">
          <p className="text-xs font-black uppercase text-muted">{t("thisMonth")}</p>
          <p className="mt-2 text-3xl font-black text-foreground">
            {money(data.revenue_this_month, locale)}
          </p>
        </div>
      </section>

      <section className="rounded-card border border-border-subtle bg-card p-6">
        <h2 className="text-lg font-black text-foreground">{t("revenueChart")}</h2>
        <div className="mt-6">
          <AnalyticsChart
            data={chartData}
            formatAmount={(v) => money(String(v), locale)}
            bookingsLabel={t("bookingsShort")}
            scaleBy="amount"
            axisLocale={locale === "ar" ? "ar" : "en"}
            xAxisLabel={t("chartAxisDate")}
            yAxisLabel={t("chartAxisAmount")}
            barClassName="bg-primary"
          />
        </div>
      </section>

      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-card border border-border-subtle bg-card p-6">
          <h2 className="text-lg font-black text-foreground">{t("topRoutes")}</h2>
          <div className="mt-4 overflow-x-auto">
            <table className="w-full table-fixed text-center text-sm">
              <colgroup>
                <col className="w-[40%]" />
                <col className="w-[30%]" />
                <col className="w-[30%]" />
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

        <section className="rounded-card border border-border-subtle bg-card p-6">
          <h2 className="text-lg font-black text-foreground">{t("paymentBreakdown")}</h2>
          <div className="mt-4 overflow-x-auto">
            <table className="w-full table-fixed text-center text-sm">
              <colgroup>
                <col className="w-[40%]" />
                <col className="w-[30%]" />
                <col className="w-[30%]" />
              </colgroup>
              <thead>
                <tr className="border-b border-border-subtle text-xs uppercase text-muted">
                  <th className="px-3 py-2 text-center">{t("status")}</th>
                  <th className="px-3 py-2 text-center">{t("total")}</th>
                  <th className="px-3 py-2 text-center">{t("payment")}</th>
                </tr>
              </thead>
              <tbody>
                {data.payment_breakdown
                  .filter((row) => row.status.toLowerCase() !== "pending")
                  .map((row) => (
                  <tr key={row.status} className="border-b border-border-subtle">
                    <td className="px-3 py-3 text-center whitespace-nowrap">
                      {formatPaymentStatusLabel(row.status, t)}
                    </td>
                    <td className="px-3 py-3 text-center whitespace-nowrap">{row.count}</td>
                    <td className="px-3 py-3 text-center font-bold text-primary whitespace-nowrap" dir="ltr">
                      {money(row.amount, locale)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>
  );
}
