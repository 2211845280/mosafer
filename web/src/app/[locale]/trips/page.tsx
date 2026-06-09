import { apiUrl } from "@/lib/api";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getLocale, getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { TripsList } from "@/components/trips/TripsList";
import { redirect } from "next/navigation";

type FlightRead = {
  origin_iata: string;
  destination_iata: string;
  carrier_code: string;
  flight_number: string;
  departure_at: string;
  arrival_at?: string;
};

type ReservationRow = {
  id: number;
  seat: string;
  seats?: string[];
  status: string;
  ticket_number?: string | null;
  qr_code?: string | null;
  flight: FlightRead;
  total_price?: string | null;
  currency?: string | null;
  created_at?: string;
};

type Paginated<T> = {
  items: T[];
  total: number;
};

export default async function TripsPage() {
  const t = await getTranslations("trips");
  const locale = await getLocale();
  const token = await getAccessToken();

  if (!token) {
    return (
      <div className="rounded-card border border-border-subtle bg-card p-8 text-center">
        <p className="text-muted">{t("pleaseLogin")}</p>
        <Link
          href="/login"
          className="mt-4 inline-block rounded-mosafer bg-primary px-6 py-2 text-sm font-black uppercase tracking-wide text-primary-foreground"
        >
          {t("login")}
        </Link>
      </div>
    );
  }

  // Redirect admins to admin panel - My Trips is for regular users only
  const profile = await fetchProfile(token);
  if (profile?.isAdmin) {
    redirect(`/${locale}/admin`);
  }

  const res = await fetch(`${apiUrl("/reservations/me")}?page=1&page_size=50`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Accept-Language": locale,
    },
    cache: "no-store",
  });

  if (!res.ok) {
    const te = await getTranslations("errors");
    return (
      <div className="rounded-card border border-accent/30 bg-card p-8">
        <p className="text-accent">{te("generic")}</p>
      </div>
    );
  }

  const data = (await res.json()) as Paginated<ReservationRow>;
  const items = data.items ?? [];

  return (
    <div className="content-shell">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-black text-foreground">{t("title")}</h1>
        <Link
          href="/"
          className="rounded-mosafer bg-primary px-4 py-2 text-sm font-black uppercase tracking-wide text-primary-foreground"
        >
          {t("bookNew")}
        </Link>
      </div>

      <TripsList initialItems={items} locale={locale} />
    </div>
  );
}
