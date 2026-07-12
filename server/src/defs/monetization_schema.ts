import { sqliteTable, text, real, integer } from "drizzle-orm/sqlite-core";

// Tabela de assinaturas
export const subscriptions = sqliteTable("subscriptions", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull(),
  plan: text("plan").notNull(), // "free", "club", "club_plus"
  status: text("status").notNull(), // "active", "cancelled", "expired"
  startDate: text("start_date").notNull(),
  endDate: text("end_date"),
  autoRenew: integer("auto_renew", { mode: "boolean" }).default(true),
  paymentMethod: text("payment_method"),
  paymentId: text("payment_id"),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});

// Tabela de pontos de fidelidade
export const loyaltyPoints = sqliteTable("loyalty_points", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull(),
  points: integer("points").notNull().default(0),
  totalEarned: integer("total_earned").notNull().default(0),
  totalRedeemed: integer("total_redeemed").notNull().default(0),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});

// Tabela de transações de pontos
export const pointTransactions = sqliteTable("point_transactions", {
  id: text("id").primaryKey(),
  userId: text("user_id").notNull(),
  orderId: text("order_id"),
  type: text("type").notNull(), // "earn", "redeem", "expire"
  points: integer("points").notNull(),
  description: text("description"),
  createdAt: text("created_at").notNull(),
});

// Tabela de cupons
export const coupons = sqliteTable("coupons", {
  id: text("id").primaryKey(),
  code: text("code").notNull().unique(),
  type: text("type").notNull(), // "percentage", "fixed", "free_delivery"
  value: real("value").notNull(),
  minOrder: real("min_order").default(0),
  maxUses: integer("max_uses"),
  usedCount: integer("used_count").notNull().default(0),
  validFrom: text("valid_from").notNull(),
  validUntil: text("valid_until").notNull(),
  active: integer("active", { mode: "boolean" }).default(true),
  createdAt: text("created_at").notNull(),
});
