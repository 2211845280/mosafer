"use client";

import { UserEnableButton } from "@/components/admin/UserEnableButton";
import { UserStatusBadge } from "@/components/admin/UserStatusBadge";
import { Link } from "@/i18n/navigation";
import { useLocale, useTranslations } from "next-intl";
import { useState } from "react";

export type TravelerUser = {
  id: number;
  email: string;
  is_active: boolean;
  is_email_verified?: boolean;
  created_at?: string;
  passenger?: {
    full_name: string;
    phone?: string | null;
    account_status: string;
    passport_details?: {
      passport_number?: string | null;
    } | null;
  } | null;
};

type Props = {
  user: TravelerUser;
};

function formatDate(iso: string | undefined, locale: string) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleDateString(locale === "ar" ? "ar" : "en-GB", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch {
    return iso;
  }
}

function formatPhone(phone: string | null | undefined): string {
  return phone && phone !== "unknown" ? phone : "—";
}

function ReadonlyField({
  id,
  label,
  value,
  dir,
  className,
}: {
  id: string;
  label: string;
  value: string;
  dir?: "ltr" | "rtl";
  className?: string;
}) {
  return (
    <div className="profile-field">
      <label className="profile-field-label" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        type="text"
        value={value}
        readOnly
        tabIndex={-1}
        className={`form-input form-input-readonly mt-1 w-full${className ? ` ${className}` : ""}`}
        dir={dir}
      />
    </div>
  );
}

export function TravelerDetailView({ user }: Props) {
  const t = useTranslations("admin");
  const locale = useLocale();
  const [isActive, setIsActive] = useState(user.is_active);

  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-black text-foreground">{t("detailTitle")}</h1>
        <Link
          href="/admin/users"
          className="rounded-mosafer border border-border-strong px-4 py-2 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
        >
          {t("backUsers")}
        </Link>
      </div>

      <div className="profile-hero mt-6">
        <h2 className="text-lg font-black text-foreground">{t("passengerInfo")}</h2>
        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <ReadonlyField
            id="traveler-full-name"
            label={t("fullName")}
            value={user.passenger?.full_name ?? "—"}
          />
          <ReadonlyField
            id="traveler-phone"
            label={t("phone")}
            value={formatPhone(user.passenger?.phone)}
            dir="ltr"
            className="text-end"
          />
          <ReadonlyField
            id="traveler-email"
            label={t("email")}
            value={user.email}
            dir="ltr"
            className="text-end"
          />
          <ReadonlyField
            id="traveler-member-since"
            label={t("memberSince")}
            value={formatDate(user.created_at, locale)}
          />
          <div className="profile-field">
            <p className="profile-field-label">{t("accountStatus")}</p>
            <div className="mt-2">
              <UserStatusBadge isActive={isActive} />
            </div>
          </div>
        </div>

        <div className="mt-6 flex justify-end">
          <UserEnableButton
            userId={user.id}
            initialActive={user.is_active}
            onActiveChange={setIsActive}
          />
        </div>
      </div>
    </div>
  );
}
