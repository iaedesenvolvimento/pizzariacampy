import { sqliteTable, text, integer, real } from "drizzle-orm/sqlite-core";

export const menuItems = sqliteTable("menu_items", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description"),
  price: real("price").notNull(),
  category: text("category").notNull(),
  image: text("image"),
  available: integer("available", { mode: "boolean" }).default(true),
  toppings: text("toppings"),
  sizes: text("sizes"),
  extras: text("extras"),
  createdAt: text("created_at").default(""),
});

export const orders = sqliteTable("orders", {
  id: text("id").primaryKey(),
  customerName: text("customer_name").notNull(),
  customerPhone: text("customer_phone").notNull(),
  customerAddress: text("customer_address").notNull(),
  customerNeighborhood: text("customer_neighborhood"),
  items: text("items").notNull(),
  subtotal: real("subtotal").notNull(),
  deliveryFee: real("delivery_fee").default(0),
  total: real("total").notNull(),
  paymentMethod: text("payment_method").notNull(),
  paymentStatus: text("payment_status").default("pending"),
  paymentId: text("payment_id"),
  status: text("status").default("pending"),
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

export const appUsers = sqliteTable("app_users", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  phone: text("phone").notNull(),
  email: text("email").default(""),
  password: text("password").notNull(),
  createdAt: text("created_at").notNull(),
});
