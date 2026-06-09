"use client";

import { PassengerSeatPicker } from "@/components/booking/PassengerSeatPicker";
import { Link, useRouter } from "@/i18n/navigation";
import { resolveBookingError } from "@/lib/booking-errors";
import { resolveCarrierName } from "@/lib/carriers";
import { fetchPaymentConfig, startFlightPayment, type PaymentConfig } from "@/lib/payment";
import {
  createEmptyPassenger,
  hasPassportDetails,
  isPassengerComplete,
  mergePassportDetails,
  replacePassportDetails,
} from "@/lib/passport-details";
import type { BookingPassengerInput, CheckoutSessionDetail } from "@/types/booking";
import type { UserProfile } from "@/types/profile";
import { useLocale, useTranslations } from "next-intl";
import { useSearchParams } from "next/navigation";
import { FormEvent, Suspense, useEffect, useMemo, useRef, useState } from "react";

const EMPTY_PASSENGER = createEmptyPassenger;

type PassportAnalyzeResponse = {
  looks_like_passport?: boolean;
  extracted_fields?: {
    given_name?: string | null;
    family_name?: string | null;
    date_of_birth?: string | null;
    gender?: string | null;
    nationality?: string | null;
    passport_number?: string | null;
    passport_expiry?: string | null;
    passport_issuing_country?: string | null;
  };
  warnings?: string[];
};

function PassengersForm() {
  const t = useTranslations("passengers");
  const tBook = useTranslations("book");
  const router = useRouter();
  const locale = useLocale();
  const sp = useSearchParams();
  const checkoutSessionId = sp.get("checkout_session_id")?.trim();
  const paymentId = sp.get("payment_id")?.trim();
  const passportFileRefs = useRef<(HTMLInputElement | null)[]>([]);

  const [detail, setDetail] = useState<CheckoutSessionDetail | null>(null);
  const [reservedSeats, setReservedSeats] = useState<string[]>([]);
  const [seatAssignments, setSeatAssignments] = useState<string[]>([]);
  const [passengers, setPassengers] = useState<BookingPassengerInput[]>([EMPTY_PASSENGER()]);
  const [blockedPassports, setBlockedPassports] = useState<string[]>([]);
  const [prefilledFromPassport, setPrefilledFromPassport] = useState(false);
  const [filledFromOcr, setFilledFromOcr] = useState(false);
  const [uploadingByIndex, setUploadingByIndex] = useState<Record<number, boolean>>({});
  const [messageByIndex, setMessageByIndex] = useState<Record<number, string | null>>({});
  const [errorByIndex, setErrorByIndex] = useState<Record<number, string | null>>({});
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(true);
  const [awaitingPayment, setAwaitingPayment] = useState(false);
  const [paymentConfig, setPaymentConfig] = useState<PaymentConfig | null>(null);

  const anyPassportUploading = Object.values(uploadingByIndex).some(Boolean);

  const blockedSet = useMemo(
    () => new Set(blockedPassports.map((p) => p.toUpperCase())),
    [blockedPassports],
  );

  const blockedPassengerIndexes = useMemo(
    () =>
      passengers
        .map((p, index) =>
          blockedSet.has(p.passport_number.trim().toUpperCase()) ? index : -1,
        )
        .filter((index) => index >= 0),
    [passengers, blockedSet],
  );

  const hasBlockedPassport = blockedPassengerIndexes.length > 0;
  const primaryBlockedIndex = blockedPassengerIndexes[0] ?? 0;

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const config = await fetchPaymentConfig(locale);
      if (!cancelled) setPaymentConfig(config);
    })();
    return () => {
      cancelled = true;
    };
  }, [locale]);

  useEffect(() => {
    if (!checkoutSessionId) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    (async () => {
      try {
        const [sessionRes, blockedRes] = await Promise.all([
          fetch(`/api/checkout-sessions/${checkoutSessionId}`, {
            headers: { "Accept-Language": locale },
          }),
          fetch(`/api/checkout-sessions/${checkoutSessionId}/blocked-passports`, {
            headers: { "Accept-Language": locale },
          }),
        ]);

        if (!sessionRes.ok) {
          if (!cancelled) setError(t("loadError"));
          return;
        }
        const json = (await sessionRes.json()) as CheckoutSessionDetail;
        if (cancelled) return;
        setDetail(json);

        if (json.reservation_id && paymentId) {
          router.replace(
            `/book/confirmation?reservation_id=${json.reservation_id}&payment_id=${paymentId}`,
          );
          return;
        }

        if (json.status !== "open") {
          if (!cancelled) setError(t("loadError"));
          return;
        }

        if (blockedRes.ok) {
          const blockedJson = (await blockedRes.json()) as { blocked_passports?: string[] };
          if (!cancelled) {
            setBlockedPassports(blockedJson.blocked_passports ?? []);
          }
        }

        const count = json.adults_count || 1;
        const initial = Array.from({ length: count }, () => EMPTY_PASSENGER());

        try {
          const profileRes = await fetch("/api/users/me", {
            headers: { "Accept-Language": locale },
          });
          if (profileRes.ok) {
            const profile = (await profileRes.json()) as UserProfile;
            const details = profile.passenger?.passport_details;
            if (hasPassportDetails(details)) {
              initial[0] = mergePassportDetails(initial[0], details);
              if (!cancelled) setPrefilledFromPassport(true);
            }
          }
        } catch {
          // Profile prefill is optional.
        }

        if (!cancelled) setPassengers(initial);

        const bookedSeats = json.seats && json.seats.length > 0 ? json.seats : [];
        if (!cancelled) {
          setReservedSeats(bookedSeats);
          setSeatAssignments([...bookedSeats]);
        }
      } catch {
        if (!cancelled) setError(t("loadError"));
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [checkoutSessionId, locale, router, paymentId, t]);

  function updatePassenger(index: number, field: keyof BookingPassengerInput, value: string) {
    setMessageByIndex((prev) => ({ ...prev, [index]: null }));
    setErrorByIndex((prev) => ({ ...prev, [index]: null }));
    if (index === 0) {
      setPrefilledFromPassport(false);
      setFilledFromOcr(false);
    }
    setPassengers((prev) =>
      prev.map((p, i) => (i === index ? { ...p, [field]: value } : p)),
    );
  }

  async function onPassportFileChange(passengerIndex: number, file: File) {
    setErrorByIndex((prev) => ({ ...prev, [passengerIndex]: null }));
    setMessageByIndex((prev) => ({ ...prev, [passengerIndex]: null }));
    setUploadingByIndex((prev) => ({ ...prev, [passengerIndex]: true }));
    setError(null);
    try {
      const body = new FormData();
      body.append("file", file);
      const res = await fetch("/api/passport/analyze", {
        method: "POST",
        headers: { "Accept-Language": locale },
        body,
      });
      const json = (await res.json().catch(() => ({}))) as PassportAnalyzeResponse & {
        detail?: string;
      };
      if (!res.ok) {
        setErrorByIndex((prev) => ({ ...prev, [passengerIndex]: t("passportUploadError") }));
        return;
      }

      const fields = json.extracted_fields;
      if (hasPassportDetails(fields)) {
        setPassengers((prev) => {
          const next = [...prev];
          next[passengerIndex] = replacePassportDetails(fields);
          return next;
        });
        if (passengerIndex === 0) {
          setPrefilledFromPassport(false);
          setFilledFromOcr(true);
        }
        setMessageByIndex((prev) => ({
          ...prev,
          [passengerIndex]: json.looks_like_passport
            ? t("passportExtractSuccess")
            : t("passportExtractPartial"),
        }));
      } else {
        setErrorByIndex((prev) => ({ ...prev, [passengerIndex]: t("passportUploadError") }));
      }
    } catch {
      setErrorByIndex((prev) => ({ ...prev, [passengerIndex]: t("passportUploadError") }));
    } finally {
      setUploadingByIndex((prev) => ({ ...prev, [passengerIndex]: false }));
    }
  }

  function assignSeat(index: number, seat: string) {
    setSeatAssignments((prev) => prev.map((s, i) => (i === index ? seat : s)));
  }

  function redirectToConfirmation(paymentIdValue: number, reservationId: number) {
    router.push(
      `/book/confirmation?reservation_id=${reservationId}&payment_id=${paymentIdValue}`,
    );
  }

  async function retryPaymentAfterSave() {
    if (!checkoutSessionId) return;
    setError(null);
    setBusy(true);
    try {
      const result = await startFlightPayment(Number(checkoutSessionId), locale);
      if (result === null) return;
      redirectToConfirmation(result.paymentId, result.reservationId);
    } finally {
      setBusy(false);
    }
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!checkoutSessionId) return;
    setError(null);

    if (hasBlockedPassport) {
      setError(
        filledFromOcr && primaryBlockedIndex > 0
          ? t("passportStillBlocked")
          : t("passengerAlreadyBlocked"),
      );
      return;
    }

    if (!passengers.every(isPassengerComplete)) {
      setError(t("validationIncomplete"));
      return;
    }

    const passportNumbers = passengers.map((p) => p.passport_number.trim().toUpperCase());
    if (new Set(passportNumbers).size !== passportNumbers.length) {
      setError(t("duplicatePassportInForm"));
      return;
    }

    if (seatAssignments.length !== passengers.length || seatAssignments.some((s) => !s.trim())) {
      setError(t("chooseSeat"));
      return;
    }
    if (new Set(seatAssignments).size !== seatAssignments.length) {
      setError(t("seatAlreadyAssigned"));
      return;
    }

    setBusy(true);
    try {
      const passengersWithTitle = passengers.map((p, index) => ({
        ...p,
        title: p.gender === "M" ? "MR" : "MS",
        seat: seatAssignments[index]?.trim().toUpperCase() ?? "",
      }));
      const res = await fetch(`/api/checkout-sessions/${checkoutSessionId}/passenger-details`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept-Language": locale,
        },
        body: JSON.stringify({ passengers: passengersWithTitle }),
      });
      const saved = (await res.json().catch(() => ({}))) as CheckoutSessionDetail & {
        detail?: string | { code?: string; existing_seat?: string };
      };
      if (!res.ok) {
        if (
          res.status === 409 &&
          typeof saved.detail === "string" &&
          saved.detail.includes("Passenger details already submitted")
        ) {
          setAwaitingPayment(true);
          await retryPaymentAfterSave();
          return;
        }
        let message = resolveBookingError(saved.detail, t, t("submitError"));
        if (
          saved.detail &&
          typeof saved.detail === "object" &&
          saved.detail.code === "passenger_already_on_flight"
        ) {
          message = `${message}\n${t("passengerAlreadyHint")}`;
        }
        setError(message);
        return;
      }

      setAwaitingPayment(false);
      const paymentResult = await startFlightPayment(Number(checkoutSessionId), locale);
      if (paymentResult === null) return;
      redirectToConfirmation(paymentResult.paymentId, paymentResult.reservationId);
    } finally {
      setBusy(false);
    }
  }

  if (!checkoutSessionId) {
    return (
      <div className="content-shell py-12">
        <p className="text-accent">{t("missingReservation")}</p>
        <Link href="/" className="mt-4 inline-block text-primary underline">
          {tBook("backToSearch")}
        </Link>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="content-shell flex justify-center py-24">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  const airline = detail
    ? resolveCarrierName(detail.flight.carrier_code, detail.carrier_name)
    : "";

  return (
    <div className="content-shell pb-16">
      <h1 className="text-2xl font-extrabold text-foreground">{t("title")}</h1>
      <p className="mt-2 max-w-2xl text-sm text-muted">{t("subtitle")}</p>

      {detail && (
        <div className="mt-6 rounded-2xl border border-border-subtle bg-card p-5 text-sm">
          <p className="font-extrabold text-foreground">{airline}</p>
          <p className="text-muted">
            {detail.flight.origin_iata} → {detail.flight.destination_iata} ·{" "}
            {detail.flight.carrier_code} {detail.flight.flight_number}
          </p>
        </div>
      )}

      {paymentConfig?.provider === "stripe" && paymentConfig.stripe_test_mode && (
        <div className="mt-6 rounded-2xl border border-primary/30 bg-primary/10 p-4 text-sm">
          <p className="font-extrabold text-primary">{tBook("stripeDemoTitle")}</p>
          <p className="mt-1 text-muted">{tBook("stripeDemoCard")}</p>
        </div>
      )}

      {prefilledFromPassport && !hasBlockedPassport && (
        <div className="mt-6 rounded-2xl border border-primary/30 bg-primary/10 p-4 text-sm">
          <p className="font-extrabold text-primary">{t("prefilledFromPassport")}</p>
          <p className="mt-1 text-muted">{t("prefilledHint")}</p>
        </div>
      )}

      {hasBlockedPassport && (
        <div
          className="mt-6 rounded-2xl border border-accent/40 bg-accent/10 p-4 text-sm"
          role="alert"
        >
          <p className="font-extrabold text-accent">
            {filledFromOcr ? t("passportStillBlocked") : t("passengerAlreadyBlocked")}
          </p>
          <p className="mt-1 text-muted">{t("passengerAlreadyHint")}</p>
        </div>
      )}

      <form onSubmit={(e) => void onSubmit(e)} className="mt-8 space-y-8">
        {passengers.map((p, index) => (
          <section
            key={index}
            className="rounded-2xl border border-border-subtle bg-card p-6 sm:p-8"
          >
            <h2 className="text-sm font-extrabold uppercase tracking-wide text-muted">
              {t("traveler")} {index + 1}
            </h2>

            {reservedSeats.length > 0 && (
              <PassengerSeatPicker
                passengerIndex={index}
                seats={reservedSeats}
                value={seatAssignments[index] ?? ""}
                assignedElsewhere={
                  new Set(
                    seatAssignments.filter((s, i) => i !== index && s.trim()),
                  )
                }
                onChange={(seat) => assignSeat(index, seat)}
                labels={{
                  passengerSeat: t("passengerSeat"),
                  chooseSeat: t("chooseSeat"),
                }}
              />
            )}

            <div className="mt-4">
              <input
                ref={(el) => {
                  passportFileRefs.current[index] = el;
                }}
                type="file"
                accept="image/jpeg,image/png,image/webp"
                className="hidden"
                onChange={(e) => {
                  const file = e.target.files?.[0];
                  e.target.value = "";
                  if (file) void onPassportFileChange(index, file);
                }}
              />
              <button
                type="button"
                disabled={uploadingByIndex[index] || busy || anyPassportUploading}
                onClick={() =>
                  !uploadingByIndex[index] && passportFileRefs.current[index]?.click()
                }
                className="rounded-mosafer border border-border-strong px-4 py-2 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
              >
                {t("uploadPassport")}
              </button>
              {uploadingByIndex[index] && (
                <p className="mt-2 text-xs text-muted">{t("passportExtracting")}</p>
              )}
              {messageByIndex[index] && !uploadingByIndex[index] && (
                <p className="mt-2 text-xs font-semibold text-green-400">
                  {messageByIndex[index]}
                </p>
              )}
              {errorByIndex[index] && (
                <p className="mt-2 text-xs font-semibold text-accent">{errorByIndex[index]}</p>
              )}
            </div>

            <div className="mt-6 grid gap-4 sm:grid-cols-2">
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("gender")}
                <select
                  required
                  value={p.gender}
                  onChange={(e) => updatePassenger(index, "gender", e.target.value)}
                  className="form-input"
                >
                  <option value="M">{t("male")}</option>
                  <option value="F">{t("female")}</option>
                </select>
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("givenName")}
                <input
                  required
                  value={p.given_name}
                  onChange={(e) => updatePassenger(index, "given_name", e.target.value)}
                  className="form-input uppercase"
                  placeholder="JOHN"
                />
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("familyName")}
                <input
                  required
                  value={p.family_name}
                  onChange={(e) => updatePassenger(index, "family_name", e.target.value)}
                  className="form-input uppercase"
                  placeholder="DOE"
                />
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("dateOfBirth")}
                <input
                  required
                  type="date"
                  value={p.date_of_birth}
                  onChange={(e) => updatePassenger(index, "date_of_birth", e.target.value)}
                  className="form-input"
                />
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("nationality")}
                <input
                  required
                  maxLength={3}
                  value={p.nationality}
                  onChange={(e) =>
                    updatePassenger(index, "nationality", e.target.value.toUpperCase())
                  }
                  className="form-input uppercase"
                  dir="ltr"
                  placeholder="LBY"
                />
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted sm:col-span-2">
                {t("passportNumber")}
                <input
                  required
                  value={p.passport_number}
                  onChange={(e) =>
                    updatePassenger(index, "passport_number", e.target.value.toUpperCase())
                  }
                  className="form-input uppercase"
                  dir="ltr"
                />
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("passportExpiry")}
                <input
                  required
                  type="date"
                  value={p.passport_expiry}
                  onChange={(e) => updatePassenger(index, "passport_expiry", e.target.value)}
                  className="form-input"
                />
              </label>
              <label className="flex flex-col gap-1 text-xs font-bold uppercase text-muted">
                {t("passportCountry")}
                <input
                  required
                  maxLength={3}
                  value={p.passport_issuing_country}
                  onChange={(e) =>
                    updatePassenger(
                      index,
                      "passport_issuing_country",
                      e.target.value.toUpperCase(),
                    )
                  }
                  className="form-input uppercase"
                  dir="ltr"
                  placeholder="LBY"
                />
              </label>
            </div>
            <p className="mt-4 text-xs text-muted">{t("nameHint")}</p>
          </section>
        ))}

        {error && (
          <p className="whitespace-pre-line text-sm font-semibold text-accent" role="alert">
            {error}
          </p>
        )}

        {awaitingPayment && (
          <button
            type="button"
            disabled={busy || anyPassportUploading}
            onClick={() => void retryPaymentAfterSave()}
            className="w-full rounded-mosafer border border-border-strong py-4 text-sm font-extrabold uppercase tracking-wide text-foreground hover:border-primary disabled:opacity-60 sm:w-auto sm:px-12"
          >
            {busy ? tBook("processing") : t("retryPayment")}
          </button>
        )}

        <button
          type="submit"
          disabled={busy || anyPassportUploading || awaitingPayment}
          className="w-full rounded-mosafer bg-primary py-4 text-sm font-extrabold uppercase tracking-wide text-primary-foreground disabled:opacity-60 sm:w-auto sm:px-12"
        >
          {busy ? tBook("processing") : t("submit")}
        </button>
      </form>
    </div>
  );
}

export default function PassengersPage() {
  return (
    <Suspense
      fallback={
        <div className="content-shell flex justify-center py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      }
    >
      <PassengersForm />
    </Suspense>
  );
}
