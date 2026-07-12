import { Hono } from "hono";
import { installBloomeBridge } from "./bloome-bridge";
import menuRoutes from "./routes/menu";
import orderRoutes from "./routes/orders";
import paymentRoutes from "./routes/payments";
import telegramRoutes from "./routes/telegram";
import settingsRoutes from "./routes/settings";
import addressRoutes from "./routes/address";
import { auth } from "./routes/auth";
import appRoutes from "./routes/app";
import adminRoutes from "./routes/admin";
import adminPanelRoutes from "./routes/admin-panel";
import gerenciarRoutes from "./routes/gerenciar";
import pwaRoutes from "./routes/pwa";
import soundsRoutes from "./routes/sounds";
import landingRoutes from "./routes/landing";
import monetizationRoutes from "./routes/monetization";

const app = new Hono();

// Install Bloome auth bridge (health + silent-sign-in)
installBloomeBridge(app);

// CORS middleware
app.use("/api/public/*", async (c, next) => {
  c.header("Access-Control-Allow-Origin", "*");
  c.header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
  c.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
  if (c.req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  await next();
});

// Landing page
app.route("/api/public/landing", landingRoutes);

// Monetization (subscriptions, loyalty, coupons)
app.route("/api/public/monetization", monetizationRoutes);

// Admin Panel - BEFORE other admin routes
app.route("/api/public/painel-admin", adminPanelRoutes);
app.route("/api/public/gerenciar", gerenciarRoutes);
app.route("/api/public", pwaRoutes);
app.route("/api/public/sounds", soundsRoutes);

// Business routes under /api/public/*
app.route("/api/public/menu", menuRoutes);
app.route("/api/public/orders", orderRoutes);
app.route("/api/public/payments", paymentRoutes);
app.route("/api/public/telegram", telegramRoutes);
app.route("/api/public/settings", settingsRoutes);
app.route("/api/public/address", addressRoutes);
app.route("/api/public/auth", auth);
app.route("/api/public/app", appRoutes);
app.route("/api/public/admin", adminRoutes);

// Root health check
app.get("/api/public/health", (c) => c.json({ name: "Pizzaria Campy API", version: "1.0.0" }));

export default app;
