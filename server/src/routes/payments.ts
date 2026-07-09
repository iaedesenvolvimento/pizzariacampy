import { Hono } from "hono";
import { db } from "edgespark";
import { orders, settings } from "../defs/db_schema";
import { sql } from "drizzle-orm";
import Stripe from "stripe";

const payments = new Hono();

async function getStripe(): Promise<Stripe | null> {
  const [row] = await db.select().from(settings).where(sql`${settings.key} = ${"stripe_secret_key"}`);
  const stripeKey = row?.value;
  if (!stripeKey) return null;
  return new Stripe(stripeKey, { apiVersion: "2024-12-18.acacia" as any });
}

// POST /api/public/payments/create-intent - Create Stripe Payment Intent
payments.post("/create-intent", async (c) => {
  const stripe = await getStripe();
  if (!stripe) {
    return c.json({ ok: false, error: "Pagamento online não configurado. Configure sua Stripe API key nas configurações." }, 503);
  }

  const body = await c.req.json();
  const { orderId, amount, currency = "brl" } = body;

  if (!orderId || !amount) {
    return c.json({ ok: false, error: "orderId e amount são obrigatórios" }, 400);
  }

  try {
    const intent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100),
      currency,
      automatic_payment_methods: { enabled: true },
      metadata: { orderId },
      description: `Pizzaria Campy — Pedido #${orderId}`,
    });

    await db.update(orders).set({ paymentId: intent.id }).where(sql`${orders.id} = ${orderId}`);

    return c.json({ ok: true, clientSecret: intent.client_secret, paymentIntentId: intent.id });
  } catch (err: any) {
    console.error("Stripe error:", err.message);
    return c.json({ ok: false, error: "Erro ao processar pagamento: " + err.message }, 500);
  }
});

// POST /api/public/payments/webhook - Stripe Webhook
payments.post("/webhook", async (c) => {
  const stripe = await getStripe();
  if (!stripe) return c.json({ ok: false }, 503);

  const [row] = await db.select().from(settings).where(sql`${settings.key} = ${"stripe_webhook_secret"}`);
  const webhookSecret = row?.value;

  try {
    const body = await c.req.text();
    const sig = c.req.header("stripe-signature");

    let event: Stripe.Event;
    if (webhookSecret && sig) {
      event = stripe.webhooks.constructEvent(body, sig, webhookSecret);
    } else {
      event = JSON.parse(body);
    }

    if (event.type === "payment_intent.succeeded") {
      const pi = event.data.object as Stripe.PaymentIntent;
      await db.update(orders).set({ paymentStatus: "paid" }).where(sql`${orders.paymentId} = ${pi.id}`);
    } else if (event.type === "payment_intent.payment_failed") {
      const pi = event.data.object as Stripe.PaymentIntent;
      await db.update(orders).set({ paymentStatus: "failed" }).where(sql`${orders.paymentId} = ${pi.id}`);
    }

    return c.json({ ok: true });
  } catch (err: any) {
    console.error("Webhook error:", err.message);
    return c.json({ ok: false, error: err.message }, 400);
  }
});

// POST /api/public/payments/confirm-cash - Confirm cash payment
payments.post("/confirm-cash", async (c) => {
  const body = await c.req.json();
  const { orderId } = body;

  if (!orderId) return c.json({ ok: false, error: "orderId é obrigatório" }, 400);

  await db.update(orders).set({ paymentStatus: "paid" }).where(sql`${orders.id} = ${orderId}`);

  return c.json({ ok: true, message: "Pagamento em dinheiro confirmado" });
});

export default payments;
