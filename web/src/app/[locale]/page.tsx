import { FlightHeroSection } from "@/components/flight/FlightHeroSection";
import { PopularDestinations } from "@/components/flight/PopularDestinations";
import { fetchProfile, getAccessToken } from "@/lib/server-session";
import { getLocale } from "next-intl/server";
import { redirect } from "next/navigation";

export default async function HomePage() {
  const locale = await getLocale();
  const token = await getAccessToken();
  if (token) {
    const profile = await fetchProfile(token, locale);
    if (profile?.isAdmin) {
      redirect(`/${locale}/admin`);
    }
  }

  return (
    <div className="flex flex-col">
      <FlightHeroSection initialOrigin="IST" initialDestination="LHR" />
      <PopularDestinations />
    </div>
  );
}
