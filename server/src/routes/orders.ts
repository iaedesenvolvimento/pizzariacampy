import { Hono } from "hono";
import { db } from "edgespark";
import { orders, customers, settings } from "../defs/db_schema";
import { sql, desc } from "drizzle-orm";

const orderRoutes = new Hono();

function generateOrderId(): string {
  const now = new Date();
  const date = now.toISOString().slice(0, 10).replace(/-/g, "");
  const time = now.getTime().toString(36).slice(-4).toUpperCase();
  return `PC${date}${time}`;
}

async function getSettingsMap(): Promise<Record<string, string>> {
  const rows = await db.select().from(settings);
  return Object.fromEntries(rows.map(s => [s.key, s.value]));
}

function sendTelegramNotification(order: any, settingsMap: Record<string, string>): void {
  const botToken = settingsMap.telegram_bot_token;
  const chatId = settingsMap.telegram_chat_id;

  // Log for debugging
  console.log("Telegram notification attempt:", { botToken: botToken ? "SET" : "MISSING", chatId: chatId ? "SET" : "MISSING" });

  if (!botToken || !chatId) {
    console.log("Telegram notification skipped: missing bot token or chat ID");
    return;
  }

  let items;
  try {
    items = typeof order.items === "string" ? JSON.parse(order.items) : order.items;
  } catch (e) {
    console.error("Failed to parse order items:", e);
    items = [];
  }

  const itemsText = items.map((i: any) => `  • ${i.name}${i.size ? " (" + i.size + ")" : ""} x${i.qty} — R$ ${(i.price * i.qty).toFixed(2)}`).join("\n");

  const paymentMethods: Record<string, string> = {
    pix: "PIX",
    credit_card: "Cartão de Crédito",
    debit_card: "Cartão de Débito",
    cash: "Dinheiro",
  };

  const message = [
    "🍕 NOVO PEDIDO — " + order.id,
    "",
    "👤 " + order.customerName,
    "📱 " + order.customerPhone,
    "📍 " + order.customerAddress,
    "🏘️ " + (order.customerNeighborhood || "—"),
    "",
    "📋 Itens:",
    itemsText,
    "",
    "💰 Subtotal: R$ " + order.subtotal.toFixed(2),
    "🚚 Entrega: R$ " + (order.deliveryFee || 0).toFixed(2),
    "💵 Total: R$ " + order.total.toFixed(2),
    "",
    "💳 Pagamento: " + (paymentMethods[order.paymentMethod] || order.paymentMethod),
    "📝 Obs: " + (order.notes || "Nenhuma"),
    "",
    "🕐 " + new Date(order.createdAt).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" }),
    "",
    "✅ /status_" + order.id,
    "❌ /cancelar_" + order.id,
    "🎉 /entregue_" + order.id,
  ].join("\n");

  console.log("Sending Telegram notification to chat:", chatId);

  fetch("https://api.telegram.org/bot" + botToken + "/sendMessage", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: chatId, text: message }),
  }).then(res => {
    console.log("Telegram API response status:", res.status);
    return res.json();
  }).then(data => {
    console.log("Telegram API response:", data);
  }).catch(e => console.error("Telegram notification failed:", e));
}

// POST /api/public/orders - Create a new order
orderRoutes.post("/", async (c) => {
  const body = await c.req.json();
  const { customerName, customerPhone, customerAddress, customerNeighborhood, items, paymentMethod, notes } = body;

  if (!customerName || !customerPhone || !customerAddress || !items?.length || !paymentMethod) {
    return c.json({ ok: false, error: "Dados incompletos. Preencha nome, telefone, endereço, itens e forma de pagamento." }, 400);
  }

  const settingsMap = await getSettingsMap();
  let subtotal = 0;
  for (const item of items) {
    subtotal += (item.price || 0) * (item.qty || 1);
  }

  const deliveryFee = subtotal >= parseFloat(settingsMap.free_delivery_minimum || "80") ? 0 : parseFloat(settingsMap.delivery_fee || "5.90");
  const total = subtotal + deliveryFee;

  const minOrder = parseFloat(settingsMap.min_order || "30");
  if (subtotal < minOrder) {
    return c.json({ ok: false, error: `Pedido mínimo: R$ ${minOrder.toFixed(2)}` }, 400);
  }

  const orderId = generateOrderId();
  const now = new Date().toISOString();

  await db.insert(orders).values({
    id: orderId,
    customerName,
    customerPhone,
    customerAddress,
    customerNeighborhood: customerNeighborhood || "",
    items: JSON.stringify(items),
    subtotal,
    deliveryFee,
    total,
    paymentMethod,
    status: "pending",
    notes: notes || "",
    createdAt: now,
    updatedAt: now,
  });

  const [existingCustomer] = await db.select().from(customers).where(
    sql`${customers.phone} = ${customerPhone}`
  );
  if (existingCustomer) {
    await db.update(customers).set({ name: customerName, address: customerAddress, neighborhood: customerNeighborhood || "" }).where(
      sql`${customers.id} = ${existingCustomer.id}`
    );
  } else {
    await db.insert(customers).values({ id: customerPhone, name: customerName, phone: customerPhone, address: customerAddress, neighborhood: customerNeighborhood || "", createdAt: now });
  }

  const [order] = await db.select().from(orders).where(sql`${orders.id} = ${orderId}`);
  console.log("Order created:", order?.id);

  // Send Telegram notification
  try {
    if (order) {
      let items;
      try { items = typeof order.items === "string" ? JSON.parse(order.items) : order.items; } catch { items = []; }
      const itemsText = items.map((i: any) => "  • " + i.name + (i.size ? " (" + i.size + ")" : "") + " x" + i.qty + " — R$ " + (i.price * i.qty).toFixed(2)).join("\n");
      const paymentMethods: Record<string, string> = { pix: "PIX", credit_card: "Cartão de Crédito", debit_card: "Cartão de Débito", cash: "Dinheiro" };
      const msg = "🍕 NOVO PEDIDO — " + order.id + "\n\n👤 " + order.customerName + "\n📱 " + order.customerPhone + "\n📍 " + order.customerAddress + "\n🏘️ " + (order.customerNeighborhood || "—") + "\n\n📋 Itens:\n" + itemsText + "\n\n💰 Subtotal: R$ " + order.subtotal.toFixed(2) + "\n🚚 Entrega: R$ " + (order.deliveryFee || 0).toFixed(2) + "\n💵 Total: R$ " + order.total.toFixed(2) + "\n\n💳 Pagamento: " + (paymentMethods[order.paymentMethod] || order.paymentMethod) + "\n📝 Obs: " + (order.notes || "Nenhuma") + "\n\n✅ /status_" + order.id + "\n❌ /cancelar_" + order.id + "\n🎉 /entregue_" + order.id;

      // Get settings directly from DB
      const [tokenRow] = await db.select().from(settings).where(sql`${settings.key} = ${"telegram_bot_token"}`);
      const [chatRow] = await db.select().from(settings).where(sql`${settings.key} = ${"telegram_chat_id"}`);
      const botToken = tokenRow?.value;
      const chatId = chatRow?.value;

      if (botToken && chatId) {
        // Try direct Telegram API call
        const tgRes = await fetch("https://api.telegram.org/bot" + botToken + "/sendMessage", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ chat_id: chatId, text: msg }),
        });
        const tgData = await tgRes.json();
        console.log("Telegram direct:", tgData.ok ? "SUCCESS" : tgData.description);
      } else {
        console.log("Telegram config missing:", { botToken: !!botToken, chatId: !!chatId });
      }
    }
  } catch (e) {
    console.error("Telegram error:", e);
  }

  return c.json({ ok: true, order }, 201);
});

// GET /api/public/orders/:id - Get order details
orderRoutes.get("/:id", async (c) => {
  const [order] = await db.select().from(orders).where(sql`${orders.id} = ${c.req.param("id")}`);
  if (!order) return c.json({ ok: false, error: "Pedido não encontrado" }, 404);
  return c.json({ ok: true, order: { ...order, items: JSON.parse(order.items) } });
});

// PATCH /api/public/orders/:id/status - Update order status
orderRoutes.patch("/:id/status", async (c) => {
  const body = await c.req.json();
  const { status } = body;

  const validStatuses = ["pending", "confirmed", "preparing", "out_for_delivery", "delivered", "cancelled"];
  if (!validStatuses.includes(status)) {
    return c.json({ ok: false, error: "Status inválido" }, 400);
  }

  const [order] = await db.select().from(orders).where(sql`${orders.id} = ${c.req.param("id")}`);
  if (!order) return c.json({ ok: false, error: "Pedido não encontrado" }, 404);

  await db.update(orders).set({ status, updatedAt: new Date().toISOString() }).where(
    sql`${orders.id} = ${c.req.param("id")}`
  );

  const settingsMap = await getSettingsMap();
  const botToken = settingsMap.telegram_bot_token;

  const statusMessages: Record<string, string> = {
    confirmed: "✅ Seu pedido " + order.id + " foi confirmado! Estamos preparando com carinho.",
    preparing: "👨‍🍳 Seu pedido " + order.id + " está sendo preparado com amor.",
    out_for_delivery: "🛵 Seu pedido " + order.id + " saiu para entrega! Em breve chega.",
    delivered: "🎉 Seu pedido " + order.id + " foi entregue. Bom apetite!",
    cancelled: "❌ Seu pedido " + order.id + " foi cancelado. Entre em contato para mais informações.",
  };

  if (botToken && statusMessages[status]) {
    fetch("https://api.telegram.org/bot" + botToken + "/sendMessage", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: order.customerPhone, text: statusMessages[status] }),
    }).catch(e => console.error("Telegram status notification failed:", e));
  }

  return c.json({ ok: true, message: "Status atualizado" });
});

// GET /api/public/orders - List orders
orderRoutes.get("/", async (c) => {
  const status = c.req.query("status");
  const limit = parseInt(c.req.query("limit") || "50");
  const offset = parseInt(c.req.query("offset") || "0");

  let allOrders;
  let total;

  if (status) {
    allOrders = await db.select().from(orders).where(sql`${orders.status} = ${status}`).orderBy(desc(orders.createdAt)).limit(limit).offset(offset);
    const [countResult] = await db.select({ count: sql<number>`count(*)` }).from(orders).where(sql`${orders.status} = ${status}`);
    total = countResult.count;
  } else {
    allOrders = await db.select().from(orders).orderBy(desc(orders.createdAt)).limit(limit).offset(offset);
    const [countResult] = await db.select({ count: sql<number>`count(*)` }).from(orders);
    total = countResult.count;
  }

  return c.json({ ok: true, orders: allOrders.map(o => ({ ...o, items: JSON.parse(o.items) })), total });
});

export default orderRoutes;
