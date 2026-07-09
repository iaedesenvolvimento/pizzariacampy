import { Hono } from "hono";
import { db } from "edgespark";
import { menuItems } from "../defs/db_schema";
import { sql } from "drizzle-orm";
import { ensureSeeded } from "../db/seed";

const menu = new Hono();

function parseItem(item: any) {
  return {
    ...item,
    available: Boolean(item.available),
    toppings: item.toppings ? JSON.parse(item.toppings) : [],
    extras: item.extras ? JSON.parse(item.extras) : [],
    sizes: item.sizes ? JSON.parse(item.sizes) : null,
  };
}

// GET /api/public/menu - List all menu items
menu.get("/", async (c) => {
  await ensureSeeded();
  const category = c.req.query("category");
  const available = c.req.query("available");

  let allItems;
  if (category && available !== "false") {
    allItems = await db.select().from(menuItems).where(
      sql`${menuItems.category} = ${category} AND ${menuItems.available} = ${true}`
    );
  } else if (category) {
    allItems = await db.select().from(menuItems).where(
      sql`${menuItems.category} = ${category}`
    );
  } else if (available !== "false") {
    allItems = await db.select().from(menuItems).where(
      sql`${menuItems.available} = ${true}`
    );
  } else {
    allItems = await db.select().from(menuItems);
  }

  return c.json({ ok: true, items: allItems.map(parseItem) });
});

// GET /api/public/menu/meta/categories - Get all categories
menu.get("/meta/categories", async (c) => {
  await ensureSeeded();
  const result = await db
    .select({ category: menuItems.category, count: sql<number>`count(*)` })
    .from(menuItems)
    .where(sql`${menuItems.available} = ${true}`)
    .groupBy(menuItems.category);
  return c.json({ ok: true, categories: result });
});

// GET /api/public/menu/:id - Get single menu item
menu.get("/:id", async (c) => {
  await ensureSeeded();
  const [item] = await db.select().from(menuItems).where(
    sql`${menuItems.id} = ${c.req.param("id")}`
  );
  if (!item) return c.json({ ok: false, error: "Item não encontrado" }, 404);
  return c.json({ ok: true, item: parseItem(item) });
});

export default menu;
