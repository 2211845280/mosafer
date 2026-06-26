"use client";

import { useTranslations } from "next-intl";
import { InputHTMLAttributes, useState } from "react";

type PasswordInputProps = Omit<
  InputHTMLAttributes<HTMLInputElement>,
  "type"
> & {
  className?: string;
  invalid?: boolean;
};

function EyeIcon({ open }: { open: boolean }) {
  if (open) {
    return (
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M2.42 12.71c-.12-.34-.12-.71 0-1.05C4.24 6.62 7.87 4 12 4s7.76 2.62 9.58 7.66c.12.34.12.71 0 1.05C19.76 17.38 16.13 20 12 20s-7.76-2.62-9.58-7.29Z"
          stroke="currentColor"
          strokeWidth="1.75"
        />
        <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.75" />
      </svg>
    );
  }

  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M3 3l18 18M10.58 10.58A2 2 0 0 0 12 15a2 2 0 0 0 1.42-.58M6.7 6.7C4.59 8.16 3.07 10.02 2.42 12c1.82 5.04 5.45 7.66 9.58 7.66 1.55 0 3.02-.36 4.35-1.02M17.3 17.3c2.11-1.46 3.63-3.32 4.28-5.3C19.76 6.96 16.13 4.34 12 4.34c-1.55 0-3.02.36-4.35 1.02"
        stroke="currentColor"
        strokeWidth="1.75"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function PasswordInput({
  className,
  invalid = false,
  ...props
}: PasswordInputProps) {
  const t = useTranslations("auth");
  const [visible, setVisible] = useState(false);
  const inputClassName = className
    ? `password-field-input ${className}`
    : "password-field-input";

  return (
    <div className={`password-field${invalid ? " password-field-error" : ""}`}>
      <input
        {...props}
        type={visible ? "text" : "password"}
        className={inputClassName}
      />
      <button
        type="button"
        className="password-toggle"
        onClick={() => setVisible((value) => !value)}
        aria-label={visible ? t("hidePassword") : t("showPassword")}
        aria-pressed={visible}
      >
        <EyeIcon open={visible} />
      </button>
    </div>
  );
}
