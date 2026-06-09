import { getTranslations } from "next-intl/server";
import { Suspense } from "react";
import { LoginForm } from "./LoginForm";

export async function generateMetadata() {
  const t = await getTranslations("auth");
  return { title: t("loginTitle") };
}

export default function LoginPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto max-w-md rounded-card border border-border-subtle bg-card p-8 text-center text-muted">
          …
        </div>
      }
    >
      <LoginForm />
    </Suspense>
  );
}
