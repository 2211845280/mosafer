"use client";

import { useLocale, useTranslations } from "next-intl";

export type AdminProfileForm = {
  email: string;
  fullName: string;
  phone: string;
};

type Props = {
  form: AdminProfileForm;
  editing: boolean;
  saving: boolean;
  saveMessage: "success" | "error" | null;
  onChange: (patch: Partial<AdminProfileForm>) => void;
  onEdit: () => void;
  onCancel: () => void;
  onSave: () => void;
};

export function ProfilePersonalForm({
  form,
  editing,
  saving,
  saveMessage,
  onChange,
  onEdit,
  onCancel,
  onSave,
}: Props) {
  const t = useTranslations("profile");
  const locale = useLocale();
  const fieldDir = locale === "ar" ? "rtl" : "ltr";

  const inputClass = (editable: boolean) =>
    editable ? "form-input mt-1 w-full" : "form-input form-input-readonly mt-1 w-full";

  return (
    <div className="profile-hero">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-black text-foreground">{t("personalInfo")}</h2>
          <p className="mt-1 text-xs text-muted">{t("profileSettingsSubtitle")}</p>
        </div>
        {!editing && (
          <button
            type="button"
            onClick={onEdit}
            className="rounded-mosafer border border-border-strong px-4 py-1.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary"
          >
            {t("edit")}
          </button>
        )}
      </div>

      <div className="mt-4 grid gap-4 sm:grid-cols-2">
        <div className="profile-field sm:col-span-2">
          <label className="profile-field-label" htmlFor="admin-profile-name">
            {t("fullName")}
          </label>
          <input
            id="admin-profile-name"
            type="text"
            value={form.fullName}
            onChange={(e) => onChange({ fullName: e.target.value })}
            readOnly={!editing}
            className={inputClass(editing)}
            dir={fieldDir}
          />
        </div>

        <div className="profile-field">
          <label className="profile-field-label" htmlFor="admin-profile-email">
            {t("email")}
          </label>
          <input
            id="admin-profile-email"
            type="email"
            value={form.email}
            onChange={(e) => onChange({ email: e.target.value })}
            readOnly={!editing}
            className={inputClass(editing)}
            dir="ltr"
          />
        </div>

        <div className="profile-field">
          <label className="profile-field-label" htmlFor="admin-profile-phone">
            {t("phone")}
          </label>
          <input
            id="admin-profile-phone"
            type="tel"
            value={form.phone}
            onChange={(e) => onChange({ phone: e.target.value })}
            readOnly={!editing}
            className={inputClass(editing)}
            dir="ltr"
          />
        </div>
      </div>

      {editing && (
        <div className="mt-4 flex flex-wrap gap-3">
          <button
            type="button"
            disabled={saving}
            onClick={onSave}
            className="rounded-mosafer bg-primary px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-60"
          >
            {saving ? t("saving") : t("save")}
          </button>
          <button
            type="button"
            disabled={saving}
            onClick={onCancel}
            className="rounded-mosafer border border-border-strong px-6 py-2.5 text-xs font-extrabold uppercase tracking-wide text-foreground transition-colors hover:border-primary hover:text-primary disabled:opacity-60"
          >
            {t("cancel")}
          </button>
        </div>
      )}

      {saveMessage === "success" && (
        <p className="mt-3 text-xs font-semibold text-green-400">{t("saveSuccess")}</p>
      )}
      {saveMessage === "error" && (
        <p className="mt-3 text-xs font-semibold text-accent">{t("saveError")}</p>
      )}
    </div>
  );
}
