import { getTranslations } from "next-intl/server";
import { Suspense } from "react";
import { ForgotPasswordForm } from "./ForgotPasswordForm";

export async function generateMetadata() {
  const t = await getTranslations("auth");
  return { title: t("forgotPasswordTitle") };
}

export default function ForgotPasswordPage() {
  return (
    <Suspense
      fallback={
        <div className="auth-shell">
          <div className="auth-card text-center text-muted">…</div>
        </div>
      }
    >
      <ForgotPasswordForm />
    </Suspense>
  );
}
