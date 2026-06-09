"use client";

import {
  AdminCancelBookingDialog,
  canAdminCancelBooking,
} from "@/components/admin/AdminCancelBookingDialog";
import { Link } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useEffect, useId, useRef, useState } from "react";

function IconMoreVertical({ className }: { className?: string }) {
  return (
    <svg
      className={className ?? "h-5 w-5"}
      viewBox="0 0 24 24"
      fill="currentColor"
      aria-hidden
    >
      <circle cx="12" cy="5" r="1.75" />
      <circle cx="12" cy="12" r="1.75" />
      <circle cx="12" cy="19" r="1.75" />
    </svg>
  );
}

type Props = {
  userId: number;
  reservationId: number;
  status: string;
  departureAt: string;
  totalPrice?: string | null;
  currency?: string | null;
  onCanceled?: () => void;
};

export function BookingRowActionsMenu({
  userId,
  reservationId,
  status,
  departureAt,
  totalPrice,
  currency,
  onCanceled,
}: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const menuId = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const [menuOpen, setMenuOpen] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);

  const showCancel = canAdminCancelBooking(status, departureAt);

  useEffect(() => {
    if (!menuOpen) return;
    const onPointerDown = (e: MouseEvent) => {
      if (rootRef.current && !rootRef.current.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    };
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") setMenuOpen(false);
    };
    document.addEventListener("mousedown", onPointerDown);
    window.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [menuOpen]);

  function openCancelDialog() {
    setMenuOpen(false);
    setCancelOpen(true);
  }

  const viewTravelerLabel =
    t("viewTraveler") === "admin.viewTraveler" || t("viewTraveler") === "viewTraveler"
      ? locale === "ar"
        ? "عرض المسافر"
        : "View traveler"
      : t("viewTraveler");

  const menuItemClass =
    "block w-full px-4 py-2.5 text-start text-sm font-bold transition-colors hover:bg-foreground/5";

  return (
    <div ref={rootRef} className="relative inline-flex justify-center">
      <button
        type="button"
        aria-label={t("bookingActionsMenu")}
        aria-haspopup="menu"
        aria-expanded={menuOpen}
        aria-controls={menuOpen ? menuId : undefined}
        onClick={() => setMenuOpen((prev) => !prev)}
        className="inline-flex h-9 w-9 items-center justify-center rounded-mosafer text-muted transition-colors hover:bg-foreground/10 hover:text-foreground"
      >
        <IconMoreVertical />
      </button>

      {menuOpen && (
        <div
          id={menuId}
          role="menu"
          className="absolute end-0 top-full z-20 mt-1 min-w-[180px] overflow-hidden rounded-mosafer border border-border-subtle bg-card py-1 shadow-lg"
        >
          <Link
            href={`/admin/users/${userId}`}
            role="menuitem"
            className={`${menuItemClass} text-primary`}
            onClick={() => setMenuOpen(false)}
          >
            {viewTravelerLabel}
          </Link>
          {showCancel && (
            <button
              type="button"
              role="menuitem"
              className={`${menuItemClass} text-accent`}
              onClick={openCancelDialog}
            >
              {t("adminCancelBooking")}
            </button>
          )}
        </div>
      )}

      <AdminCancelBookingDialog
        open={cancelOpen}
        onClose={() => setCancelOpen(false)}
        reservationId={reservationId}
        status={status}
        departureAt={departureAt}
        totalPrice={totalPrice}
        currency={currency}
        onCanceled={onCanceled}
      />
    </div>
  );
}
