"use client";

import { BookingRowActionsMenu } from "@/components/admin/BookingRowActionsMenu";
import { PaymentBadge } from "@/components/admin/PaymentBadge";
import { StatusBadge } from "@/components/admin/StatusBadge";
import { resolveAdminPaymentStatus } from "@/lib/admin/booking-status";
import { formatTableDateTime } from "@/lib/format-datetime";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useMemo, useState } from "react";

type FlightInfo = {
  origin_iata: string;
  destination_iata: string;
  carrier_code: string;
  flight_number: string;
  departure_at: string;
};

type ReservationRow = {
  id: number;
  user_id: number;
  user_email?: string;
  seat: string;
  status: string;
  ticket_number?: string | null;
  total_price?: string | null;
  currency?: string | null;
  created_at: string;
  flight: FlightInfo;
  payment_status?: string;
};

type PageResp = {
  items: ReservationRow[];
  total: number;
};

type FilterStatus = "all" | "confirmed" | "cancelled";

export default function AdminBookingsPage() {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [rows, setRows] = useState<ReservationRow[]>([]);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState<FilterStatus>("all");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        // Fetch all reservations - using admin endpoint if available, otherwise fallback
        const res = await fetch("/api/admin/reservations?page=1&page_size=100", {
          headers: { "Accept-Language": locale },
        });
        const data = (await res.json()) as PageResp & { detail?: string };
        if (!res.ok) {
          if (!cancelled) {
            setErr(typeof data.detail === "string" ? data.detail : t("loadBookingsError"));
          }
          return;
        }
        if (!cancelled) setRows(data.items ?? []);
      } catch {
        if (!cancelled) setErr(t("loadBookingsError"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locale]);

  const filteredRows = useMemo(() => {
    return rows.filter((r) => {
      // Status filter
      if (filterStatus !== "all") {
        const rowStatus = r.status.toLowerCase();
        if (filterStatus === "confirmed" && rowStatus !== "confirmed") return false;
        if (filterStatus === "cancelled" && !["cancelled", "canceled"].includes(rowStatus)) return false;
      }

      // Search filter
      if (!search.trim()) return true;
      const query = search.toLowerCase();
      return (
        (r.user_email ?? "").toLowerCase().includes(query) ||
        r.ticket_number?.toLowerCase().includes(query) ||
        r.flight.origin_iata.toLowerCase().includes(query) ||
        r.flight.destination_iata.toLowerCase().includes(query) ||
        r.id.toString().includes(query)
      );
    });
  }, [rows, search, filterStatus]);

  const stats = useMemo(() => {
    return {
      total: rows.length,
      confirmed: rows.filter((r) => r.status.toLowerCase() === "confirmed").length,
      cancelled: rows.filter((r) => ["cancelled", "canceled"].includes(r.status.toLowerCase())).length,
    };
  }, [rows]);

  function handleCanceled(reservationId: number) {
    setRows((prev) =>
      prev.map((r) =>
        r.id === reservationId ? { ...r, status: "cancelled" } : r,
      ),
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <p className="text-muted">{t("loading")}…</p>
      </div>
    );
  }

  if (err) {
    return (
      <div className="rounded-card border border-accent/30 bg-card p-6">
        <p className="text-accent">{err}</p>
      </div>
    );
  }

  return (
    <div>
      {/* Header with Stats */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-black text-foreground">{t("bookings")}</h1>
        <div className="flex flex-wrap gap-3 text-xs font-bold">
          <span className="rounded-full bg-foreground/10 px-3 py-1 text-muted">
            {t("total")}: {stats.total}
          </span>
          <span className="rounded-full bg-green-500/20 px-3 py-1 text-green-400">
            {t("confirmed")}: {stats.confirmed}
          </span>
          <span className="rounded-full bg-accent/20 px-3 py-1 text-accent">
            {t("cancelled")}: {stats.cancelled}
          </span>
        </div>
      </div>

      {/* Filters */}
      <div className="mt-6 flex flex-wrap items-center gap-3">
        <div className="flex-1 min-w-[200px]">
          <input
            type="text"
            placeholder={t("searchBookingsPlaceholder")}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-mosafer border border-border-subtle bg-surface px-4 py-2 text-sm text-foreground placeholder:text-muted focus:border-primary focus:outline-none"
          />
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => setFilterStatus("all")}
            className={`rounded-mosafer px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors ${
              filterStatus === "all"
                ? "bg-foreground/10 text-foreground"
                : "border border-border-strong text-muted hover:text-foreground"
            }`}
          >
            {t("all")}
          </button>
          <button
            type="button"
            onClick={() => setFilterStatus("confirmed")}
            className={`rounded-mosafer px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors ${
              filterStatus === "confirmed"
                ? "bg-green-500/20 text-green-400"
                : "border border-border-strong text-muted hover:text-foreground"
            }`}
          >
            {t("confirmed")}
          </button>
          <button
            type="button"
            onClick={() => setFilterStatus("cancelled")}
            className={`rounded-mosafer px-4 py-2 text-xs font-black uppercase tracking-wide transition-colors ${
              filterStatus === "cancelled"
                ? "bg-accent/20 text-accent"
                : "border border-border-strong text-muted hover:text-foreground"
            }`}
          >
            {t("cancelled")}
          </button>
        </div>
      </div>

      {/* Bookings Table */}
      <div className="mt-4 overflow-x-auto rounded-card border border-border-subtle">
        <table className="w-full min-w-[900px] table-fixed text-center text-sm">
          <thead className="border-b border-border-subtle bg-surface text-xs font-black uppercase text-muted">
            <tr>
              <th className="px-4 py-3 text-center">{t("reservation")}</th>
              <th className="px-4 py-3 text-center">{t("passenger")}</th>
              <th className="px-4 py-3 text-center">{t("flight")}</th>
              <th className="px-4 py-3 text-center">{t("departure")}</th>
              <th className="px-4 py-3 text-center">{t("status")}</th>
              <th className="px-4 py-3 text-center">{t("payment")}</th>
              <th className="px-4 py-3 text-center">{t("price")}</th>
              <th className="w-16 px-4 py-3 text-center">{t("actions")}</th>
            </tr>
          </thead>
          <tbody>
            {filteredRows.length === 0 ? (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-muted">
                  {t("noBookingsFound")}
                </td>
              </tr>
            ) : (
              filteredRows.map((r) => (
                <tr key={r.id} className="border-b border-border-subtle hover:bg-foreground/5 transition-colors">
                  <td className="px-4 py-3 text-center">
                    <div className="inline-flex flex-col items-center">
                      <span className="font-mono text-xs text-foreground">#{r.id}</span>
                      {r.ticket_number && (
                        <span className="mt-1 font-mono text-[10px] text-muted" dir="ltr">
                          {r.ticket_number}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <span className="inline-block text-sm text-foreground" dir="ltr">
                      {r.user_email ?? `User #${r.user_id}`}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <div className="inline-flex flex-col items-center">
                      <span className="font-bold text-foreground" dir="ltr">
                        {r.flight.origin_iata} → {r.flight.destination_iata}
                      </span>
                      <span className="text-xs text-muted" dir="ltr">
                        {r.flight.carrier_code}{r.flight.flight_number}
                      </span>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <span className="inline-block text-sm tabular-nums text-foreground" dir="ltr">
                      {formatTableDateTime(r.flight.departure_at)}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-center">
                    <StatusBadge status={r.status} />
                  </td>
                  <td className="px-4 py-3 text-center">
                    <PaymentBadge status={resolveAdminPaymentStatus(r.status)} />
                  </td>
                  <td className="px-4 py-3 text-center">
                    {r.total_price ? (
                      <span className="inline-block font-bold text-primary" dir="ltr">
                        {r.total_price} {r.currency}
                      </span>
                    ) : (
                      <span className="text-muted">—</span>
                    )}
                  </td>
                  <td className="w-16 px-4 py-3 text-center">
                    <BookingRowActionsMenu
                      userId={r.user_id}
                      reservationId={r.id}
                      status={r.status}
                      departureAt={r.flight.departure_at}
                      totalPrice={r.total_price}
                      currency={r.currency}
                      onCanceled={() => handleCanceled(r.id)}
                    />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
