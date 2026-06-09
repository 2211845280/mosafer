"use client";

import Image from "next/image";

const SIZES = {
  sm: 32,
  md: 40,
  lg: 112,
} as const;

type Size = keyof typeof SIZES;

type Props = {
  size?: Size;
  hasAvatar: boolean;
  displayName?: string;
  cacheKey?: string | number;
  className?: string;
  editable?: boolean;
  editLabel?: string;
  onEditClick?: () => void;
};

export function ProfileAvatar({
  size = "md",
  hasAvatar,
  displayName,
  cacheKey,
  className = "",
  editable = false,
  editLabel,
  onEditClick,
}: Props) {
  const px = SIZES[size];
  const avatarSrc = hasAvatar
    ? `/api/users/me/avatar${cacheKey != null ? `?t=${encodeURIComponent(String(cacheKey))}` : ""}`
    : null;

  const inner = (
    <>
      {avatarSrc ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={avatarSrc}
          alt={displayName ?? ""}
          width={px}
          height={px}
          className="h-full w-full object-cover"
        />
      ) : (
        <Image
          src="/images/guest_avatar.png"
          alt={displayName ?? ""}
          width={px}
          height={px}
          className="h-full w-full object-cover"
        />
      )}
      {editable && (
        <span className="profile-avatar-overlay" aria-hidden>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="currentColor"
            className="h-6 w-6"
          >
            <path d="M12 9a3 3 0 100 6 3 3 0 000-6z" />
            <path
              fillRule="evenodd"
              d="M9.293 2.293A1 1 0 0110 0h4a1 1 0 01.707.293l2.414 2.414a1 1 0 01.293.707V8a1 1 0 01-.293.707l-8.5 8.5A1 1 0 017 18H4a1 1 0 01-1-1v-3a1 1 0 01.293-.707l8.5-8.5A1 1 0 019 4.586V3a1 1 0 01.293-.707zM10 3v1.586l-1 1V16h1.586l1-1H16v-1.586l-6-6V3z"
              clipRule="evenodd"
            />
          </svg>
        </span>
      )}
    </>
  );

  const shellClass = `profile-avatar-shell relative inline-flex shrink-0 overflow-hidden rounded-full bg-primary/20 ring-2 ring-primary/30 ${className}`;

  if (editable && onEditClick) {
    return (
      <button
        type="button"
        onClick={onEditClick}
        aria-label={editLabel}
        className={`${shellClass} group cursor-pointer border-0 p-0`}
        style={{ width: px, height: px }}
      >
        {inner}
      </button>
    );
  }

  return (
    <span className={shellClass} style={{ width: px, height: px }}>
      {inner}
    </span>
  );
}
