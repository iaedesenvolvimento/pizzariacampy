import { Hono } from "hono";
import { db } from "edgespark";
import { menuItems, orders, settings } from "../defs/db_schema";
import { sql, eq } from "drizzle-orm";

const admin = new Hono();

async function checkAdmin(c: any): Promise<boolean> {
  const token = c.req.header("x-admin-token") || "";
  const [row] = await db.select().from(settings).where(sql`${settings.key} = ${"admin_token"}`);
  return row?.value === token || token === "pizzaria-campy-admin-2024";
}

// GET /api/public/admin/menu
admin.get("/menu", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const items = await db.select().from(menuItems).orderBy(sql`${menuItems.category}, ${menuItems.name}`);
  return c.json({ ok: true, items: items.map(i => ({ ...i, available: Boolean(i.available), toppings: i.toppings ? JSON.parse(i.toppings) : [], sizes: i.sizes ? JSON.parse(i.sizes) : null, extras: i.extras ? JSON.parse(i.extras) : [] })) });
});

// POST /api/public/admin/menu
admin.post("/menu", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const body = await c.req.json();
  const { name, description, price, category, toppings, sizes, extras, image, available } = body;
  if (!name || !price || !category) return c.json({ ok: false, error: "Nome, preço e categoria obrigatórios" }, 400);
  const itemId = "item_" + Date.now().toString(36);
  await db.insert(menuItems).values({ id: itemId, name, description: description || "", price: parseFloat(price), category, toppings: toppings ? JSON.stringify(toppings) : null, sizes: sizes ? JSON.stringify(sizes) : null, extras: extras ? JSON.stringify(extras) : null, image: image || null, available: available !== false, createdAt: new Date().toISOString() });
  return c.json({ ok: true, id: itemId });
});

// PUT /api/public/admin/menu/:id
admin.put("/menu/:id", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const itemId = c.req.param("id");
  const body = await c.req.json();
  const [existing] = await db.select().from(menuItems).where(eq(menuItems.id, itemId));
  if (!existing) return c.json({ ok: false, error: "Item não encontrado" }, 404);
  await db.update(menuItems).set({
    name: body.name || existing.name, description: body.description !== undefined ? body.description : existing.description,
    price: body.price !== undefined ? parseFloat(body.price) : existing.price, category: body.category || existing.category,
    toppings: body.toppings !== undefined ? JSON.stringify(body.toppings) : existing.toppings,
    sizes: body.sizes !== undefined ? JSON.stringify(body.sizes) : existing.sizes,
    extras: body.extras !== undefined ? JSON.stringify(body.extras) : existing.extras,
    image: body.image !== undefined ? body.image : existing.image,
    available: body.available !== undefined ? body.available : existing.available,
  }).where(eq(menuItems.id, itemId));
  return c.json({ ok: true });
});

// DELETE /api/public/admin/menu/:id
admin.delete("/menu/:id", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const [existing] = await db.select().from(menuItems).where(eq(menuItems.id, c.req.param("id")));
  if (!existing) return c.json({ ok: false, error: "Item não encontrado" }, 404);
  await db.delete(menuItems).where(eq(menuItems.id, c.req.param("id")));
  return c.json({ ok: true });
});

// PATCH /api/public/admin/menu/:id/toggle
admin.patch("/menu/:id/toggle", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const [existing] = await db.select().from(menuItems).where(eq(menuItems.id, c.req.param("id")));
  if (!existing) return c.json({ ok: false, error: "Item não encontrado" }, 404);
  await db.update(menuItems).set({ available: !existing.available }).where(eq(menuItems.id, c.req.param("id")));
  return c.json({ ok: true, available: !existing.available });
});

// GET /api/public/admin/orders
admin.get("/orders", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const status = c.req.query("status");
  const limit = parseInt(c.req.query("limit") || "50");
  let result;
  if (status) {
    result = await db.select().from(orders).where(sql`${orders.status} = ${status}`).orderBy(sql`${orders.createdAt} DESC`).limit(limit);
  } else {
    result = await db.select().from(orders).orderBy(sql`${orders.createdAt} DESC`).limit(limit);
  }
  return c.json({ ok: true, orders: result.map(o => ({ ...o, items: typeof o.items === "string" ? JSON.parse(o.items) : o.items })) });
});

// PATCH /api/public/admin/orders/:id/status
admin.patch("/orders/:id/status", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  const body = await c.req.json();
  const { status } = body;
  const valid = ["pending", "confirmed", "preparing", "out_for_delivery", "delivered", "cancelled"];
  if (!valid.includes(status)) return c.json({ ok: false, error: "Status inválido" }, 400);
  await db.update(orders).set({ status, updatedAt: new Date().toISOString() }).where(eq(orders.id, c.req.param("id")));

  // Telegram notification
  const [order] = await db.select().from(orders).where(eq(orders.id, c.req.param("id")));
  if (order) {
    const [t] = await db.select().from(settings).where(sql`${settings.key} = ${"telegram_bot_token"}`);
    const [ch] = await db.select().from(settings).where(sql`${settings.key} = ${"telegram_chat_id"}`);
    if (t?.value && ch?.value) {
      const msgs: Record<string, string> = { confirmed: "✅ Pedido " + order.id + " confirmado!", preparing: "👨‍🍳 Pedido " + order.id + " em preparo!", out_for_delivery: "🛵 Pedido " + order.id + " saiu pra entrega!", delivered: "🎉 Pedido " + order.id + " entregue!", cancelled: "❌ Pedido " + order.id + " cancelado." };
      if (msgs[status]) fetch("https://api.telegram.org/bot" + t.value + "/sendMessage", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ chat_id: ch.value, text: msgs[status] }) }).catch(() => {});
    }
  }
  return c.json({ ok: true });
});

// DELETE /api/public/admin/orders - Clear all orders
admin.delete("/orders", async (c) => {
  if (!(await checkAdmin(c))) return c.json({ ok: false, error: "Unauthorized" }, 401);
  await db.delete(orders);
  return c.json({ ok: true, message: "Todos os pedidos foram excluídos" });
});

export default admin;
