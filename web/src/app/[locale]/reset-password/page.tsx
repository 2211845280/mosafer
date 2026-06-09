import { getTranslations } from "next-intl/server";
import { Suspense } from "react";
import { ResetPasswordForm } from "./ResetPasswordForm";

export async function generateMetadata() {
  const t = await getTranslations("auth");
  return { title: t("resetPasswordTitle") };
}

export default function ResetPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="auth-shell">
          <div className="auth-card text-center text-muted">…</div>
        </div>
      }
    >
      <ResetPasswordForm />
    </Suspense>
  );
}
