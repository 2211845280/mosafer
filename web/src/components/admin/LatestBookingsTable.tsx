"use client";

import { StatusBadge } from "@/components/admin/StatusBadge";
import { Link } from "@/i18n/navigation";
import { formatTableDateTime } from "@/lib/format-datetime";
import { useLocale, useTranslations } from "next-intl";

export type RecentBooking = {
  id: number;
  user_email: string;
  route: string;
  amount: string;
  currency: string;
  status: string;
  payment_status: string | null;
  created_at: string;
};

type Props = {
  bookings: RecentBooking[];
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

export function LatestBookingsTable({ bookings }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();

  return (
    <section className="rounded-card border border-border-subtle bg-card p-6">
      <div className="flex items-center justify-between gap-4">
        <h2 className="text-lg font-black text-foreground">{t("recentBookings")}</h2>
        <Link href="/admin/bookings" className="text-xs font-bold text-primary underline">
          {t("viewAll")}
        </Link>
      </div>
      <div className="mt-4 overflow-x-auto rounded-mosafer border border-border-subtle">
        <table className="w-full min-w-[720px] table-fixed text-center text-sm">
          <colgroup>
            <col className="w-[30%]" />
            <col className="w-[14%]" />
            <col className="w-[14%]" />
            <col className="w-[16%]" />
            <col className="w-[26%]" />
          </colgroup>
          <thead>
            <tr className="border-b border-border-subtle bg-surface text-xs uppercase text-muted">
              <th className="px-4 py-3 text-center font-black">{t("email")}</th>
              <th className="px-4 py-3 text-center font-black">{t("flight")}</th>
              <th className="px-4 py-3 text-center font-black">{t("payment")}</th>
              <th className="px-4 py-3 text-center font-black">{t("status")}</th>
              <th className="px-4 py-3 text-center font-black">{t("date")}</th>
            </tr>
          </thead>
          <tbody>
            {bookings.map((b) => (
              <tr
                key={b.id}
                className="border-b border-border-subtle transition-colors duration-200 hover:bg-foreground/5"
              >
                <td className="px-4 py-3 text-center">
                  <span className="inline-block max-w-full truncate font-mono text-xs text-foreground" dir="ltr">
                    {b.user_email}
                  </span>
                </td>
                <td className="px-4 py-3 text-center">
                  <span
                    className="inline-block whitespace-nowrap font-mono text-sm font-bold text-foreground"
                    dir="ltr"
                  >
                    {b.route}
                  </span>
                </td>
                <td className="px-4 py-3 text-center">
                  <span className="inline-block whitespace-nowrap font-bold text-primary" dir="ltr">
                    {money(b.amount, locale)}
                  </span>
                </td>
                <td className="px-4 py-3 text-center">
                  <StatusBadge status={b.status} />
                </td>
                <td className="px-4 py-3 text-center">
                  <span className="inline-block whitespace-nowrap text-xs tabular-nums text-muted" dir="ltr">
                    {formatTableDateTime(b.created_at)}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
