import { Hono } from "hono";
import { db } from "edgespark";
import { orders, settings, menuItems } from "../defs/db_schema";
import { sql, desc } from "drizzle-orm";

const telegram = new Hono();

async function getSettingsMap(): Promise<Record<string, string>> {
  const rows = await db.select().from(settings);
  return Object.fromEntries(rows.map(s => [s.key, s.value]));
}

async function sendTelegram(botToken: string, chatId: number | string, text: string) {
  try {
    const res = await fetch("https://api.telegram.org/bot" + botToken + "/sendMessage", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: chatId, text, disable_web_page_preview: true }),
    });
    return await res.json();
  } catch (err) {
    console.error("Telegram send error:", err);
    return null;
  }
}

// POST /api/public/telegram/webhook - Receive Telegram updates
telegram.post("/webhook", async (c) => {
  const settingsMap = await getSettingsMap();
  const botToken = settingsMap.telegram_bot_token;
  if (!botToken) return c.json({ ok: false }, 503);

  const body = await c.req.json();
  const message = body.message || body.callback_query?.message;
  if (!message) return c.json({ ok: true });

  const chatId = message.chat.id;
  const text = message.text || "";
  const firstName = message.from?.first_name || "Cliente";

  if (text === "/start") {
    await sendTelegram(botToken, chatId, `🍕 Olá ${firstName}! Bem-vindo à *Pizzaria Campy*!\n\nAcesse nosso cardápio e faça seu pedido pelo app.\n📞 Para dúvidas, ligue: ${settingsMap.phone || "(XX) XXXX-XXXX"}\nHorário: ${settingsMap.business_hours_open || "18h"} às ${settingsMap.business_hours_close || "23h30"}`);
    return c.json({ ok: true });
  }

  if (text === "/cardapio" || text === "/menu") {
    const cats = await db.select({ category: menuItems.category }).from(menuItems).where(sql`${menuItems.available} = ${true}`).groupBy(menuItems.category);
    const categoryNames: Record<string, string> = {
      pizza_classica: "🍕 Pizzas Clássicas",
      pizza_premium: "🍕 Pizzas Premium",
      pizza_doce: "🍫 Pizzas Doces",
      bebida: "🥤 Bebidas",
      sobremesa: "🍰 Sobremesas",
    };

    let menuText = "📋 *CARDÁPIO PIZZARIA CAMPY*\n\n";
    for (const cat of cats) {
      const items = await db.select().from(menuItems).where(sql`${menuItems.category} = ${cat.category} AND ${menuItems.available} = ${true}`);
      menuText += `*${categoryNames[cat.category] || cat.category}*\n`;
      for (const item of items) {
        menuText += `  ${item.name} — R$ ${item.price.toFixed(2)}\n  _${item.description}_\n`;
        if (item.sizes) {
          const sizes = JSON.parse(item.sizes);
          menuText += `  📏 Tamanhos: ${Object.entries(sizes).map(([k, v]) => `${k}: R$ ${(v as number).toFixed(2)}`).join(" | ")}\n`;
        }
        menuText += "\n";
      }
    }

    await sendTelegram(botToken, chatId, menuText);
    return c.json({ ok: true });
  }

  if (text.startsWith("/status_")) {
    const orderId = text.replace("/status_", "");
    const [order] = await db.select().from(orders).where(sql`${orders.id} = ${orderId}`);

    if (!order) {
      await sendTelegram(botToken, chatId, `❌ Pedido *${orderId}* não encontrado.`);
      return c.json({ ok: true });
    }

    const statusLabels: Record<string, string> = {
      pending: "⏳ Aguardando confirmação",
      confirmed: "✅ Confirmado",
      preparing: "👨‍🍳 Preparando",
      out_for_delivery: "🛵 Saiu para entrega",
      delivered: "🎉 Entregue",
      cancelled: "❌ Cancelado",
    };

    await sendTelegram(botToken, chatId, `📦 *Pedido ${order.id}*\n\nStatus: ${statusLabels[order.status!] || order.status}\nTotal: R$ ${order.total.toFixed(2)}\nCriado: ${new Date(order.createdAt).toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" })}`);
    return c.json({ ok: true });
  }

  if (text.startsWith("/cancelar_")) {
    const orderId = text.replace("/cancelar_", "");
    const [order] = await db.select().from(orders).where(
      sql`${orders.id} = ${orderId} AND ${orders.status} != ${"delivered"} AND ${orders.status} != ${"cancelled"}`
    );

    if (!order) {
      await sendTelegram(botToken, chatId, `❌ Não foi possível cancelar o pedido *${orderId}*.`);
      return c.json({ ok: true });
    }

    await db.update(orders).set({ status: "cancelled", updatedAt: new Date().toISOString() }).where(sql`${orders.id} = ${orderId}`);
    await sendTelegram(botToken, chatId, `❌ Pedido *${orderId}* cancelado com sucesso.`);
    return c.json({ ok: true });
  }

  if (text.startsWith("/entregue_")) {
    const orderId = text.replace("/entregue_", "");
    const [order] = await db.select().from(orders).where(
      sql`${orders.id} = ${orderId} AND ${orders.status} != ${"delivered"} AND ${orders.status} != ${"cancelled"}`
    );

    if (!order) {
      await sendTelegram(botToken, chatId, `❌ Não foi possível marcar o pedido *${orderId}*.`);
      return c.json({ ok: true });
    }

    await db.update(orders).set({ status: "delivered", updatedAt: new Date().toISOString() }).where(sql`${orders.id} = ${orderId}`);
    await sendTelegram(botToken, chatId, `✅ Pedido *${orderId}* marcado como entregue!`);
    return c.json({ ok: true });
  }

  if (text === "/pedidos" || text === "/orders") {
    const pendingOrders = await db.select().from(orders).where(
      sql`${orders.status} != ${"delivered"} AND ${orders.status} != ${"cancelled"}`
    ).orderBy(desc(orders.createdAt)).limit(20);

    if (pendingOrders.length === 0) {
      await sendTelegram(botToken, chatId, "📭 Nenhum pedido pendente no momento.");
      return c.json({ ok: true });
    }

    let ordersText = `📋 *PEDIDOS PENDENTES* (${pendingOrders.length})\n\n`;
    const statusLabels: Record<string, string> = { pending: "⏳", confirmed: "✅", preparing: "👨‍🍳", out_for_delivery: "🛵" };

    for (const o of pendingOrders) {
      const items = JSON.parse(o.items);
      const itemsList = items.map((i: any) => `${i.qty}x ${i.name}`).join(", ");
      ordersText += `${statusLabels[o.status!] || "❓"} *${o.id}* — R$ ${o.total.toFixed(2)}\n👤 ${o.customerName} | 📍 ${o.customerNeighborhood || o.customerAddress}\n📦 ${itemsList}\n/status_${o.id} | /cancelar_${o.id} | /entregue_${o.id}\n\n`;
    }

    await sendTelegram(botToken, chatId, ordersText);
    return c.json({ ok: true });
  }

  await sendTelegram(botToken, chatId, `Olá! 👋 Comandos disponíveis:\n\n/menu — Ver cardápio\n/pedidos — Ver pedidos pendentes\n/status_<número> — Consultar pedido\n/cancelar_<número> — Cancelar pedido\n/entregue_<número> — Marcar como entregue`);
  return c.json({ ok: true });
});

// POST /api/public/telegram/send-notification
telegram.post("/send-notification", async (c) => {
  const settingsMap = await getSettingsMap();
  const botToken = settingsMap.telegram_bot_token;
  if (!botToken) return c.json({ ok: false, error: "Bot não configurado" }, 503);

  const body = await c.req.json();
  const { chatId, message } = body;
  if (!chatId || !message) return c.json({ ok: false, error: "chatId e message obrigatórios" }, 400);

  const result = await sendTelegram(botToken, chatId, message);
  return c.json({ ok: true, result });
});

export default telegram;
