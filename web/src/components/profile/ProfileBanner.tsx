"use client";

import { ProfileAvatar } from "@/components/profile/ProfileAvatar";
import { useLocale, useTranslations } from "next-intl";

type Props = {
  displayName: string;
  email: string;
  hasAvatar: boolean;
  avatarVersion: string | number;
  onAvatarClick?: () => void;
  uploading?: boolean;
};

export function ProfileBanner({
  displayName,
  email,
  hasAvatar,
  avatarVersion,
  onAvatarClick,
  uploading,
}: Props) {
  const t = useTranslations("profile");
  const locale = useLocale();

  return (
    <div className="profile-hero">
      <div className="flex flex-col items-center gap-4 text-center sm:flex-row sm:items-center sm:text-start">
        <ProfileAvatar
          size="lg"
          hasAvatar={hasAvatar}
          displayName={displayName}
          cacheKey={avatarVersion}
          editable={Boolean(onAvatarClick)}
          editLabel={t("changePhoto")}
          onEditClick={onAvatarClick}
        />
        <div className="min-w-0">
          <p className="text-xl font-black text-foreground">{displayName}</p>
          <p
            className={`mt-1 text-sm text-muted${locale === "ar" ? " text-end" : ""}`}
            dir="ltr"
          >
            {email}
          </p>
          <span className="mt-2 inline-block rounded-full bg-primary/20 px-3 py-1 text-[10px] font-black text-primary">
            {t("adminBadge")}
          </span>
          {uploading && (
            <p className="mt-2 text-xs font-semibold text-muted">{t("uploading")}</p>
          )}
        </div>
      </div>
    </div>
  );
}
