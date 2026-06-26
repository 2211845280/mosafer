"use client";

import { DashboardKpiSection } from "@/components/admin/DashboardKpiSection";
import { LatestBookingsTable } from "@/components/admin/LatestBookingsTable";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useState } from "react";

type DashboardData = {
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
  recent_bookings: {
    id: number;
    user_email: string;
    route: string;
    amount: string;
    currency: string;
    status: string;
    payment_status: string | null;
    created_at: string;
  }[];
};

type Props = {
  isSuperAdmin: boolean;
};

export function AdminDashboardClient({ isSuperAdmin }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [data, setData] = useState<DashboardData | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch("/api/admin/dashboard", {
          headers: { "Accept-Language": locale },
        });
        const json = (await res.json()) as DashboardData & { detail?: string };
        if (!res.ok) {
          if (!cancelled) {
            setErr(typeof json.detail === "string" ? json.detail : t("dashboardLoadError"));
          }
          return;
        }
        if (!cancelled) setData(json);
      } catch {
        if (!cancelled) setErr(t("dashboardLoadError"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locale]);

  if (loading) {
    return <p className="text-muted">{t("loading")}…</p>;
  }

  if (err || !data) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-6 text-sm text-accent">
        {err ?? t("dashboardLoadError")}
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-black text-foreground">{t("title")}</h1>
      </div>

      <DashboardKpiSection data={data} isSuperAdmin={isSuperAdmin} />

      <LatestBookingsTable bookings={data.recent_bookings} />
    </div>
  );
}
