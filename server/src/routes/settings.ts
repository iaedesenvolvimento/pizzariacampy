import { Hono } from "hono";
import { db } from "edgespark";
import { settings } from "../defs/db_schema";
import { sql } from "drizzle-orm";

const settingsRoutes = new Hono();

async function getSettingsMap(): Promise<Record<string, string>> {
  const rows = await db.select().from(settings);
  return Object.fromEntries(rows.map(s => [s.key, s.value]));
}

// GET /api/public/settings - Get public settings
settingsRoutes.get("/", async (c) => {
  const s = await getSettingsMap();
  return c.json({
    ok: true,
    settings: {
      delivery_fee: parseFloat(s.delivery_fee || "5.90"),
      free_delivery_minimum: parseFloat(s.free_delivery_minimum || "80"),
      min_order: parseFloat(s.min_order || "30"),
      business_name: s.business_name || "Pizzaria Campy",
      business_hours: s.business_hours ? JSON.parse(s.business_hours) : { open: "18:00", close: "23:30" },
      phone: s.phone || "",
      address: s.address || "",
      instagram: s.instagram || "",
      whatsapp: s.whatsapp || "",
    },
  });
});

// GET /api/public/settings/config - Get payment config
settingsRoutes.get("/config", async (c) => {
  const s = await getSettingsMap();
  return c.json({
    ok: true,
    config: {
      paymentMethods: ["pix", "credit_card", "debit_card", "cash"],
      stripePublishableKey: s.stripe_publishable_key || "",
      telegramBotUsername: s.telegram_bot_username || "",
    },
  });
});

// POST /api/public/settings/update - Update settings (admin)
settingsRoutes.post("/update", async (c) => {
  const body = await c.req.json();
  const { key, value } = body;

  if (!key || value === undefined) {
    return c.json({ ok: false, error: "key e value são obrigatórios" }, 400);
  }

  // Only allow updating specific keys
  const allowedKeys = [
    "telegram_bot_token", "telegram_chat_id", "telegram_bot_username",
    "stripe_secret_key", "stripe_webhook_secret", "stripe_publishable_key",
    "delivery_fee", "free_delivery_minimum", "min_order",
    "business_hours", "business_name", "phone", "address", "instagram", "whatsapp"
  ];

  if (!allowedKeys.includes(key)) {
    return c.json({ ok: false, error: "Chave não permitida" }, 403);
  }

  const [existing] = await db.select().from(settings).where(sql`${settings.key} = ${key}`);
  if (existing) {
    await db.update(settings).set({ value }).where(sql`${settings.key} = ${key}`);
  } else {
    await db.insert(settings).values({ key, value });
  }

  return c.json({ ok: true, message: `Configuração ${key} atualizada` });
});

// POST /api/public/settings/setup-telegram - Setup Telegram bot
settingsRoutes.post("/setup-telegram", async (c) => {
  const body = await c.req.json();
  const { botToken, chatId } = body;

  if (!botToken) {
    return c.json({ ok: false, error: "botToken é obrigatório" }, 400);
  }

  // Save bot token
  const [existingToken] = await db.select().from(settings).where(sql`${settings.key} = ${"telegram_bot_token"}`);
  if (existingToken) {
    await db.update(settings).set({ value: botToken }).where(sql`${settings.key} = ${"telegram_bot_token"}`);
  } else {
    await db.insert(settings).values({ key: "telegram_bot_token", value: botToken });
  }

  // Save chat ID if provided
  if (chatId) {
    const [existingChat] = await db.select().from(settings).where(sql`${settings.key} = ${"telegram_chat_id"}`);
    if (existingChat) {
      await db.update(settings).set({ value: chatId }).where(sql`${settings.key} = ${"telegram_chat_id"}`);
    } else {
      await db.insert(settings).values({ key: "telegram_chat_id", value: chatId });
    }
  }

  // Set webhook
  const webhookUrl = `https://master-opossum-2815.youware.pro/api/public/telegram/webhook`;
  try {
    const res = await fetch(`https://api.telegram.org/bot${botToken}/setWebhook`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: webhookUrl }),
    });
    const result = await res.json();
    return c.json({ ok: true, webhook: result, message: "Bot configurado com sucesso!" });
  } catch (err: any) {
    return c.json({ ok: false, error: "Erro ao configurar webhook: " + err.message }, 500);
  }
});

// POST /api/public/settings/test-telegram - Send test message
settingsRoutes.post("/test-telegram", async (c) => {
  const body = await c.req.json();
  const { chatId, message } = body;

  const s = await getSettingsMap();
  const botToken = s.telegram_bot_token;

  if (!botToken) {
    return c.json({ ok: false, error: "Bot não configurado" }, 400);
  }

  const targetChatId = chatId || s.telegram_chat_id;
  if (!targetChatId) {
    return c.json({ ok: false, error: "chatId não fornecido" }, 400);
  }

  try {
    const res = await fetch(`https://api.telegram.org/bot${botToken}/sendMessage`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        chat_id: targetChatId,
        text: message || "🍕 Teste de conexão da Pizzaria Campy!",
        parse_mode: "Markdown",
      }),
    });
    const result = await res.json();
    return c.json({ ok: true, result });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message }, 500);
  }
});

// POST /api/public/settings/get-bot-info - Get bot info
settingsRoutes.get("/bot-info", async (c) => {
  const s = await getSettingsMap();
  const botToken = s.telegram_bot_token;

  if (!botToken) {
    return c.json({ ok: false, error: "Bot não configurado" });
  }

  try {
    const res = await fetch(`https://api.telegram.org/bot${botToken}/getMe`);
    const result = await res.json();
    return c.json({ ok: true, bot: result.result });
  } catch (err: any) {
    return c.json({ ok: false, error: err.message });
  }
});

export default settingsRoutes;
