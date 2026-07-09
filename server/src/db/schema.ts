import { sqliteTable, text, integer, real } from "drizzle-orm/sqlite-core";

export const menuItems = sqliteTable("menu_items", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  price: real("price").notNull(),
  category: text("category").notNull(), // pizza, bebida, sobremesa, combo
  image: text("image"),
  available: integer("available", { mode: "boolean" }).default(true),
  toppings: text("toppings"), // JSON array for pizza customization
  sizes: text("sizes"), // JSON: { "M": price, "G": price, "GG": price }
  createdAt: text("created_at").default(""),
});

export const orders = sqliteTable("orders", {
  id: text("id").primaryKey(),
  customerName: text("customer_name").notNull(),
  customerPhone: text("customer_phone").notNull(),
  customerAddress: text("customer_address").notNull(),
  customerNeighborhood: text("customer_neighborhood"),
  items: text("items").notNull(), // JSON array of { itemId, name, qty, price, size, extras }
  subtotal: real("subtotal").notNull(),
  deliveryFee: real("delivery_fee").default(0),
  total: real("total").notNull(),
  paymentMethod: text("payment_method").notNull(), // pix, credit_card, debit_card, cash
  paymentStatus: text("payment_status").default("pending"), // pending, paid, failed
  paymentId: text("payment_id"), // Stripe payment intent ID
  status: text("status").default("pending"), // pending, confirmed, preparing, out_for_delivery, delivered, cancelled
  notes: text("notes"),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});

export const customers = sqliteTable("customers", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  phone: text("phone").notNull(),
  address: text("address"),
  neighborhood: text("neighborhood"),
  createdAt: text("created_at").notNull(),
});

export const settings = sqliteTable("settings", {
  key: text("key").primaryKey(),
  value: text("value").notNull(),
});

export type MenuItem = typeof menuItems.$inferSelect;
export type Order = typeof orders.$inferSelect;
export type Customer = typeof customers.$inferSelect;
