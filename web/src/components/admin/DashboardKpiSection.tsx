"use client";

import { Link } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";

export type DashboardKpiData = {
  total_users: number;
  active_users: number;
  total_bookings: number;
  paid_bookings: number;
  pending_bookings: number;
  canceled_bookings: number;
  total_revenue: string;
  revenue_this_month: string;
  platform_profit: string;
  profit_margin_pct: string;
  total_tickets: number;
  valid_tickets: number;
  used_tickets: number;
  completed_payments: number;
  pending_payments: number;
  refunded_payments: number;
  staff_count: number;
};

type Props = {
  data: DashboardKpiData;
  isSuperAdmin: boolean;
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

const metricCardLinkClass =
  "rounded-card border p-5 cursor-pointer transition-all duration-200 hover:border-primary/40 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary";

const staticCardClass = "rounded-card border border-border-subtle bg-card p-5";

const kpiValueClass = "mt-2 text-3xl font-black text-foreground";
const kpiLinkClass = "mt-2 text-xs font-bold text-primary";
const kpiLinkSpacerClass = "mt-2 h-4";

type BottomMetric = {
  key: string;
  label: string;
  value: string;
  href?: string;
  linkText?: string;
};

export function DashboardKpiSection({ data, isSuperAdmin }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();

  const bottomMetrics: BottomMetric[] = [];

  if (isSuperAdmin) {
    bottomMetrics.push({
      key: "revenue-month",
      label: t("revenueThisMonth"),
      value: money(data.revenue_this_month, locale),
    });
  }

  bottomMetrics.push(
    {
      key: "active-users",
      label: t("activeTravelers"),
      value: String(data.active_users),
    },
    {
      key: "bookings",
      label: t("totalBookings"),
      value: String(data.total_bookings),
      href: "/admin/bookings",
      linkText: t("viewBookings"),
    },
    {
      key: "cancelled-bookings",
      label: t("cancelledBookings"),
      value: String(data.canceled_bookings),
    },
  );

  return (
    <div className="space-y-6">
      <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {isSuperAdmin ? (
          <>
            <Link
              href="/admin/analytics/revenue"
              className={`${metricCardLinkClass} border-primary/30 bg-gradient-to-br from-primary/10 to-card`}
            >
              <p className="text-xs font-black uppercase text-muted">{t("totalRevenue")}</p>
              <p className="mt-2 text-3xl font-black text-primary">
                {money(data.total_revenue, locale)}
              </p>
              <p className={kpiLinkClass}>{t("viewDetails")} →</p>
            </Link>
            <Link
              href="/admin/analytics/profit"
              className={`${metricCardLinkClass} border-green-500/30 bg-card`}
            >
              <p className="text-xs font-black uppercase text-muted">{t("totalPlatformProfit")}</p>
              <p className="mt-2 text-3xl font-black text-green-400">
                {money(data.platform_profit, locale)}
              </p>
              <p className={kpiLinkClass}>{t("viewDetails")} →</p>
            </Link>
          </>
        ) : (
          <>
            <div className={staticCardClass}>
              <p className="text-xs font-black uppercase text-muted">{t("paidBookings")}</p>
              <p className={kpiValueClass}>{data.paid_bookings}</p>
              <p className="mt-2 text-xs text-muted">
                {t("pending")}: {data.pending_bookings} · {t("cancelled")}:{" "}
                {data.canceled_bookings}
              </p>
            </div>
            <div className={staticCardClass}>
              <p className="text-xs font-black uppercase text-muted">{t("completedPayments")}</p>
              <p className={kpiValueClass}>{data.completed_payments}</p>
              <p className="mt-2 text-xs text-muted">
                {t("pending")}: {data.pending_payments} · {t("refunded")}:{" "}
                {data.refunded_payments}
              </p>
            </div>
          </>
        )}

        <Link href="/admin/users" className={`${metricCardLinkClass} border-border-subtle bg-card`}>
          <p className="text-xs font-black uppercase text-muted">{t("totalTravelers")}</p>
          <p className={kpiValueClass}>{data.total_users}</p>
          <p className={kpiLinkClass}>{t("viewTravelers")} →</p>
        </Link>

        <Link href="/admin/staff" className={`${metricCardLinkClass} border-border-subtle bg-card`}>
          <p className="text-xs font-black uppercase text-muted">{t("totalStaff")}</p>
          <p className={kpiValueClass}>{data.staff_count}</p>
          <p className={kpiLinkClass}>{t("staffManageCta")}</p>
        </Link>
      </section>

      {bottomMetrics.length > 0 && (
        <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {bottomMetrics.map((metric) => {
            const inner = (
              <>
                <p className="text-xs font-black uppercase text-muted">{metric.label}</p>
                <p className={kpiValueClass}>{metric.value}</p>
                {metric.linkText ? (
                  <p className={kpiLinkClass}>{metric.linkText} →</p>
                ) : (
                  <p className={kpiLinkSpacerClass} aria-hidden="true" />
                )}
              </>
            );

            if (metric.href) {
              return (
                <Link
                  key={metric.key}
                  href={metric.href}
                  className={`${metricCardLinkClass} border-border-subtle bg-card`}
                >
                  {inner}
                </Link>
              );
            }

            return (
              <div key={metric.key} className={staticCardClass}>
                {inner}
              </div>
            );
          })}
        </section>
      )}
    </div>
  );
}
