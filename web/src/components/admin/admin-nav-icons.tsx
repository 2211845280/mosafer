import type { ReactElement, ReactNode } from "react";

type IconProps = { className?: string };

function Icon({ children, className = "h-5 w-5 shrink-0" }: { children: ReactNode; className?: string }) {
  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.75"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      {children}
    </svg>
  );
}

export function NavIconDashboard(props: IconProps) {
  return (
    <Icon className={props.className}>
      <rect x="3" y="3" width="7" height="7" rx="1" />
      <rect x="14" y="3" width="7" height="7" rx="1" />
      <rect x="3" y="14" width="7" height="7" rx="1" />
      <rect x="14" y="14" width="7" height="7" rx="1" />
    </Icon>
  );
}

export function NavIconUsers(props: IconProps) {
  return (
    <Icon className={props.className}>
      <path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2" />
      <circle cx="9" cy="7" r="4" />
      <path d="M22 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75" />
    </Icon>
  );
}

export function NavIconBookings(props: IconProps) {
  return (
    <Icon className={props.className}>
      <path d="M4 19.5A2.5 2.5 0 016.5 17H20" />
      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2z" />
    </Icon>
  );
}

export function NavIconStaff(props: IconProps) {
  return (
    <Icon className={props.className}>
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
    </Icon>
  );
}

export function NavIconRevenue(props: IconProps) {
  return (
    <Icon className={props.className}>
      <path d="M12 2v20M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6" />
    </Icon>
  );
}

export function NavIconProfit(props: IconProps) {
  return (
    <Icon className={props.className}>
      <path d="M3 3v18h18" />
      <path d="M7 16l4-4 4 4 6-6" />
    </Icon>
  );
}

export function NavIconProfile(props: IconProps) {
  return (
    <Icon className={props.className}>
      <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
      <circle cx="12" cy="7" r="4" />
    </Icon>
  );
}

export type NavIconKey =
  | "dashboard"
  | "users"
  | "bookings"
  | "staffNav"
  | "totalRevenue"
  | "platformProfit"
  | "profile";

const ICON_MAP: Record<NavIconKey, (props: IconProps) => ReactElement> = {
  dashboard: NavIconDashboard,
  users: NavIconUsers,
  bookings: NavIconBookings,
  staffNav: NavIconStaff,
  totalRevenue: NavIconRevenue,
  platformProfit: NavIconProfit,
  profile: NavIconProfile,
};

export function AdminNavIcon({
  name,
  className,
}: {
  name: NavIconKey;
  className?: string;
}) {
  const Component = ICON_MAP[name];
  return <Component className={className} />;
}
