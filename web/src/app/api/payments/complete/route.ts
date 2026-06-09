import { NextRequest, NextResponse } from "next/server";
import { apiUrl } from "@/lib/api";
import { getAccessToken } from "@/lib/server-session";

type PaymentRead = {
  id: number;
  reservation_id: number | null;
  user_id: number;
  provider_payment_id: string;
  status: string;
};

/**
 * Completes mock payment by calling the public webhook with status "completed",
 * after verifying the payment belongs to the authenticated user.
 */
export async function POST(req: NextRequest) {
  const token = await getAccessToken();
  if (!token) {
    return NextResponse.json({ detail: "Unauthorized" }, { status: 401 });
  }

  const { payment_id } = (await req.json()) as { payment_id?: number };
  if (payment_id == null || Number.isNaN(Number(payment_id))) {
    return NextResponse.json({ detail: "payment_id required" }, { status: 400 });
  }

  const pr = await fetch(apiUrl(`/payments/${payment_id}`), {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
    cache: "no-store",
  });
  if (!pr.ok) {
    return NextResponse.json(await pr.json().catch(() => ({})), {
      status: pr.status,
    });
  }
  const payment = (await pr.json()) as PaymentRead;

  const webhookRes = await fetch(apiUrl("/payments/webhook"), {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({
      provider_payment_id: payment.provider_payment_id,
      status: "completed",
      signature: null,
    }),
    cache: "no-store",
  });
  if (!webhookRes.ok) {
    const errText = await webhookRes.text();
    return NextResponse.json(
      { detail: "Webhook failed", upstream: errText },
      { status: 502 },
    );
  }

  const final = await fetch(apiUrl(`/payments/${payment_id}`), {
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
    cache: "no-store",
  });
  const text = await final.text();
  return new NextResponse(text, {
    status: final.status,
    headers: { "Content-Type": "application/json" },
  });
}
