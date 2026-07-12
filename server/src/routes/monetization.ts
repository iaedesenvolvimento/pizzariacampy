import { Hono } from "hono";
import { db } from "edgespark";
import { subscriptions, loyaltyPoints, pointTransactions, coupons } from "../defs/monetization_schema";
import { eq, and, gte, lte, sql } from "drizzle-orm";

const monetization = new Hono();

// ==================== PLANOS ====================

// Planos disponíveis
const PLANS = {
  free: {
    name: "Gratuito",
    price: 0,
    deliveryFee: "normal",
    discount: 0,
    freePizzaMonthly: false,
  },
  club: {
    name: "Campy Club",
    price: 19.90,
    deliveryFee: "free",
    discount: 10,
    freePizzaMonthly: false,
  },
  club_plus: {
    name: "Campy Club+",
    price: 29.90,
    deliveryFee: "free",
    discount: 15,
    freePizzaMonthly: true,
  },
};

// GET /api/public/monetization/plans - Listar planos
monetization.get("/plans", (c) => {
  return c.json({ ok: true, plans: PLANS });
});

// ==================== ASSINATURAS ====================

// GET /api/public/monetization/subscription/:userId - Verificar assinatura
monetization.get("/subscription/:userId", async (c) => {
  const userId = c.req.param("userId");
  
  const [subscription] = await db
    .select()
    .from(subscriptions)
    .where(
      and(
        eq(subscriptions.userId, userId),
        eq(subscriptions.status, "active")
      )
    )
    .limit(1);

  if (!subscription) {
    return c.json({ ok: true, subscription: null, plan: PLANS.free });
  }

  const plan = PLANS[subscription.plan as keyof typeof PLANS] || PLANS.free;
  return c.json({ ok: true, subscription, plan });
});

// POST /api/public/monetization/subscribe - Criar assinatura
monetization.post("/subscribe", async (c) => {
  const body = await c.req.json();
  const { userId, plan, paymentMethod } = body;

  if (!userId || !plan) {
    return c.json({ ok: false, error: "userId e plan são obrigatórios" }, 400);
  }

  if (!PLANS[plan as keyof typeof PLANS]) {
    return c.json({ ok: false, error: "Plano inválido" }, 400);
  }

  // Verificar se já tem assinatura ativa
  const [existing] = await db
    .select()
    .from(subscriptions)
    .where(
      and(
        eq(subscriptions.userId, userId),
        eq(subscriptions.status, "active")
      )
    )
    .limit(1);

  if (existing) {
    return c.json({ ok: false, error: "Já possui assinatura ativa" }, 400);
  }

  const now = new Date().toISOString();
  const endDate = new Date();
  endDate.setMonth(endDate.getMonth() + 1);

  const subscriptionId = "sub_" + Date.now().toString(36);

  await db.insert(subscriptions).values({
    id: subscriptionId,
    userId,
    plan,
    status: "active",
    startDate: now,
    endDate: endDate.toISOString(),
    autoRenew: true,
    paymentMethod: paymentMethod || "credit_card",
    createdAt: now,
    updatedAt: now,
  });

  return c.json({ ok: true, subscriptionId, plan: PLANS[plan as keyof typeof PLANS] });
});

// POST /api/public/monetization/cancel - Cancelar assinatura
monetization.post("/cancel", async (c) => {
  const body = await c.req.json();
  const { userId } = body;

  if (!userId) {
    return c.json({ ok: false, error: "userId é obrigatório" }, 400);
  }

  const [subscription] = await db
    .select()
    .from(subscriptions)
    .where(
      and(
        eq(subscriptions.userId, userId),
        eq(subscriptions.status, "active")
      )
    )
    .limit(1);

  if (!subscription) {
    return c.json({ ok: false, error: "Nenhuma assinatura ativa" }, 400);
  }

  await db
    .update(subscriptions)
    .set({
      status: "cancelled",
      autoRenew: false,
      updatedAt: new Date().toISOString(),
    })
    .where(eq(subscriptions.id, subscription.id));

  return c.json({ ok: true, message: "Assinatura cancelada" });
});

// ==================== PONTOS DE FIDELIDADE ====================

// GET /api/public/monetization/points/:userId - Verificar pontos
monetization.get("/points/:userId", async (c) => {
  const userId = c.req.param("userId");

  const [points] = await db
    .select()
    .from(loyaltyPoints)
    .where(eq(loyaltyPoints.userId, userId))
    .limit(1);

  if (!points) {
    return c.json({ ok: true, points: 0, level: "Bronze" });
  }

  // Calcular nível baseado em pontos totais
  let level = "Bronze";
  if (points.totalEarned >= 1000) level = "Ouro";
  else if (points.totalEarned >= 500) level = "Prata";

  return c.json({ ok: true, points: points.points, totalEarned: points.totalEarned, level });
});

// POST /api/public/monetization/points/earn - Ganhar pontos
monetization.post("/points/earn", async (c) => {
  const body = await c.req.json();
  const { userId, orderId, points: pointsToEarn } = body;

  if (!userId || !pointsToEarn) {
    return c.json({ ok: false, error: "userId e points são obrigatórios" }, 400);
  }

  const now = new Date().toISOString();
  const transactionId = "pt_" + Date.now().toString(36);

  // Registrar transação
  await db.insert(pointTransactions).values({
    id: transactionId,
    userId,
    orderId: orderId || null,
    type: "earn",
    points: pointsToEarn,
    description: orderId ? `Pedido #${orderId}` : "Bônus",
    createdAt: now,
  });

  // Atualizar saldo de pontos
  const [existing] = await db
    .select()
    .from(loyaltyPoints)
    .where(eq(loyaltyPoints.userId, userId))
    .limit(1);

  if (existing) {
    await db
      .update(loyaltyPoints)
      .set({
        points: existing.points + pointsToEarn,
        totalEarned: existing.totalEarned + pointsToEarn,
        updatedAt: now,
      })
      .where(eq(loyaltyPoints.userId, userId));
  } else {
    await db.insert(loyaltyPoints).values({
      id: "lp_" + Date.now().toString(36),
      userId,
      points: pointsToEarn,
      totalEarned: pointsToEarn,
      totalRedeemed: 0,
      createdAt: now,
      updatedAt: now,
    });
  }

  return c.json({ ok: true, pointsEarned: pointsToEarn });
});

// POST /api/public/monetization/points/redeem - Resgatar pontos
monetization.post("/points/redeem", async (c) => {
  const body = await c.req.json();
  const { userId, points: pointsToRedeem, description } = body;

  if (!userId || !pointsToRedeem) {
    return c.json({ ok: false, error: "userId e points são obrigatórios" }, 400);
  }

  const [existing] = await db
    .select()
    .from(loyaltyPoints)
    .where(eq(loyaltyPoints.userId, userId))
    .limit(1);

  if (!existing || existing.points < pointsToRedeem) {
    return c.json({ ok: false, error: "Pontos insuficientes" }, 400);
  }

  const now = new Date().toISOString();
  const transactionId = "pt_" + Date.now().toString(36);

  // Registrar transação
  await db.insert(pointTransactions).values({
    id: transactionId,
    userId,
    type: "redeem",
    points: -pointsToRedeem,
    description: description || "Resgate",
    createdAt: now,
  });

  // Atualizar saldo
  await db
    .update(loyaltyPoints)
    .set({
      points: existing.points - pointsToRedeem,
      totalRedeemed: existing.totalRedeemed + pointsToRedeem,
      updatedAt: now,
    })
    .where(eq(loyaltyPoints.userId, userId));

  return c.json({ ok: true, pointsRedeemed: pointsToRedeem, remaining: existing.points - pointsToRedeem });
});

// GET /api/public/monetization/points/history/:userId - Histórico de pontos
monetization.get("/points/history/:userId", async (c) => {
  const userId = c.req.param("userId");

  const history = await db
    .select()
    .from(pointTransactions)
    .where(eq(pointTransactions.userId, userId))
    .orderBy(sql`${pointTransactions.createdAt} DESC`)
    .limit(50);

  return c.json({ ok: true, history });
});

// ==================== CUPONS ====================

// POST /api/public/monetization/coupon/validate - Validar cupom
monetization.post("/coupon/validate", async (c) => {
  const body = await c.req.json();
  const { code, orderTotal } = body;

  if (!code) {
    return c.json({ ok: false, error: "Código do cupom é obrigatório" }, 400);
  }

  const [coupon] = await db
    .select()
    .from(coupons)
    .where(eq(coupons.code, code.toUpperCase()))
    .limit(1);

  if (!coupon) {
    return c.json({ ok: false, error: "Cupom não encontrado" });
  }

  if (!coupon.active) {
    return c.json({ ok: false, error: "Cupom desativado" });
  }

  const now = new Date();
  if (now < new Date(coupon.validFrom) || now > new Date(coupon.validUntil)) {
    return c.json({ ok: false, error: "Cupom fora do período de validade" });
  }

  if (coupon.maxUses && coupon.usedCount >= coupon.maxUses) {
    return c.json({ ok: false, error: "Cupom esgotado" });
  }

  if (orderTotal && orderTotal < (coupon.minOrder || 0)) {
    return c.json({ ok: false, error: `Pedido mínimo: R$ ${coupon.minOrder}` });
  }

  // Calcular desconto
  let discount = 0;
  if (coupon.type === "percentage") {
    discount = (orderTotal || 0) * (coupon.value / 100);
  } else if (coupon.type === "fixed") {
    discount = coupon.value;
  } else if (coupon.type === "free_delivery") {
    discount = 5.90; // Valor médio do frete
  }

  return c.json({
    ok: true,
    coupon: {
      code: coupon.code,
      type: coupon.type,
      value: coupon.value,
      discount: Math.min(discount, orderTotal || Infinity),
    },
  });
});

// POST /api/public/monetization/coupon/apply - Aplicar cupom
monetization.post("/coupon/apply", async (c) => {
  const body = await c.req.json();
  const { code } = body;

  const [coupon] = await db
    .select()
    .from(coupons)
    .where(eq(coupons.code, code.toUpperCase()))
    .limit(1);

  if (!coupon) {
    return c.json({ ok: false, error: "Cupom não encontrado" });
  }

  // Incrementar contador de uso
  await db
    .update(coupons)
    .set({ usedCount: coupon.usedCount + 1 })
    .where(eq(coupons.id, coupon.id));

  return c.json({ ok: true });
});

export default monetization;
