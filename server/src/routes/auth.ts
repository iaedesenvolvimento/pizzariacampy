import { Hono } from "hono";
import { db } from "edgespark";
import { appUsers, orders } from "../defs/db_schema";
import { sql, eq } from "drizzle-orm";

const SECRET = "pizzaria-campy-secret-key-2024";

function base64UrlEncode(input: string): string {
  return btoa(input).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64UrlDecode(input: string): string {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
  return atob(padded);
}

async function hmac(data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(data));
  const bytes = new Uint8Array(sig);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, "0")).join("");
}

async function signToken(payload: any): Promise<string> {
  const header = base64UrlEncode(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = base64UrlEncode(JSON.stringify(payload));
  const signature = await hmac(header + "." + body);
  return header + "." + body + "." + signature;
}

async function verifyToken(token: string): Promise<any> {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [header, body, signature] = parts;
  const expectedSig = await hmac(header + "." + body);
  if (signature !== expectedSig) return null;
  const payload = JSON.parse(base64UrlDecode(body));
  if (payload.exp && payload.exp < Date.now()) return null;
  return payload;
}

async function hashPassword(password: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode("salt-pizzaria"));
  const bytes = new Uint8Array(sig);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, "0")).join("");
}

const auth = new Hono();

// POST /api/public/auth/register
auth.post("/register", async (c) => {
  const body = await c.req.json();
  const { name, phone, email, password } = body;

  if (!name || !phone || !password) {
    return c.json({ ok: false, error: "Nome, telefone e senha são obrigatórios" }, 400);
  }

  const cleanPhone = phone.replace(/\D/g, "");
  if (cleanPhone.length < 10) {
    return c.json({ ok: false, error: "Telefone inválido" }, 400);
  }

  if (password.length < 4) {
    return c.json({ ok: false, error: "Senha deve ter pelo menos 4 caracteres" }, 400);
  }

  const [existing] = await db.select().from(appUsers).where(eq(appUsers.phone, cleanPhone));
  if (existing) {
    return c.json({ ok: false, error: "Telefone já cadastrado" }, 409);
  }

  const userId = "usr_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
  const hashedPassword = await hashPassword(password);
  const now = new Date().toISOString();

  await db.insert(appUsers).values({
    id: userId,
    name,
    phone: cleanPhone,
    email: email || "",
    password: hashedPassword,
    createdAt: now,
  });

  const token = await signToken({
    sub: userId,
    name,
    phone: cleanPhone,
    exp: Date.now() + 30 * 24 * 60 * 60 * 1000,
  });

  return c.json({
    ok: true,
    token,
    user: { id: userId, name, phone: cleanPhone, email: email || "" },
  });
});

// POST /api/public/auth/login
auth.post("/login", async (c) => {
  const body = await c.req.json();
  const { phone, password } = body;

  if (!phone || !password) {
    return c.json({ ok: false, error: "Telefone e senha são obrigatórios" }, 400);
  }

  const cleanPhone = phone.replace(/\D/g, "");
  const hashedPassword = await hashPassword(password);

  const [user] = await db.select({
    id: appUsers.id,
    name: appUsers.name,
    phone: appUsers.phone,
    email: appUsers.email,
  }).from(appUsers).where(sql`${appUsers.phone} = ${cleanPhone} AND ${appUsers.password} = ${hashedPassword}`);

  if (!user) {
    return c.json({ ok: false, error: "Telefone ou senha incorretos" }, 401);
  }

  const token = await signToken({
    sub: user.id,
    name: user.name,
    phone: user.phone,
    exp: Date.now() + 30 * 24 * 60 * 60 * 1000,
  });

  return c.json({
    ok: true,
    token,
    user: { id: user.id, name: user.name, phone: user.phone, email: user.email },
  });
});

// GET /api/public/auth/me
auth.get("/me", async (c) => {
  const authHeader = c.req.header("authorization") || "";
  const token = authHeader.replace("Bearer ", "");
  if (!token) return c.json({ ok: false, error: "Não autenticado" }, 401);

  const payload = await verifyToken(token);
  if (!payload) return c.json({ ok: false, error: "Token inválido" }, 401);

  const [user] = await db.select({
    id: appUsers.id,
    name: appUsers.name,
    phone: appUsers.phone,
    email: appUsers.email,
  }).from(appUsers).where(eq(appUsers.id, payload.sub));

  if (!user) return c.json({ ok: false, error: "Usuário não encontrado" }, 404);
  return c.json({ ok: true, user });
});

// GET /api/public/auth/orders
auth.get("/orders", async (c) => {
  const authHeader = c.req.header("authorization") || "";
  const token = authHeader.replace("Bearer ", "");
  if (!token) return c.json({ ok: false, error: "Não autenticado" }, 401);

  const payload = await verifyToken(token);
  if (!payload) return c.json({ ok: false, error: "Token inválido" }, 401);

  const [user] = await db.select({ phone: appUsers.phone }).from(appUsers).where(eq(appUsers.id, payload.sub));
  if (!user) return c.json({ ok: false, error: "Usuário não encontrado" }, 404);

  const userOrders = await db.select().from(orders).where(sql`${orders.customerPhone} = ${user.phone}`).orderBy(sql`${orders.createdAt} DESC`).limit(20);

  return c.json({
    ok: true,
    orders: userOrders.map(o => ({
      ...o,
      items: typeof o.items === "string" ? JSON.parse(o.items) : o.items,
    })),
  });
});

// GET /api/public/auth/order/:id
auth.get("/order/:id", async (c) => {
  const authHeader = c.req.header("authorization") || "";
  const token = authHeader.replace("Bearer ", "");
  if (!token) return c.json({ ok: false, error: "Não autenticado" }, 401);

  const payload = await verifyToken(token);
  if (!payload) return c.json({ ok: false, error: "Token inválido" }, 401);

  const [order] = await db.select().from(orders).where(eq(orders.id, c.req.param("id")));
  if (!order) return c.json({ ok: false, error: "Pedido não encontrado" }, 404);

  return c.json({
    ok: true,
    order: { ...order, items: typeof order.items === "string" ? JSON.parse(order.items) : order.items },
  });
});

export { auth, verifyToken };

// POST /api/public/auth/forgot-password - Request password reset
auth.post("/forgot-password", async (c) => {
  const body = await c.req.json();
  const { phone } = body;
  if (!phone) return c.json({ ok: false, error: "Informe o telefone" }, 400);
  
  const cleanPhone = phone.replace(/\D/g, "");
  const [user] = await db.select().from(appUsers).where(sql`${appUsers.phone} = ${cleanPhone}`);
  
  if (!user) return c.json({ ok: false, error: "Usuário não encontrado" }, 404);
  
  // Generate a temporary password
  const tempPassword = Math.random().toString(36).slice(-8);
  const tempHash = await hashPassword(tempPassword);
  
  await db.update(appUsers).set({ password: tempHash }).where(sql`${appUsers.id} = ${user.id}`);
  
  return c.json({ 
    ok: true, 
    message: "Senha temporária gerada",
    tempPassword: tempPassword,
    phone: cleanPhone
  });
});

// POST /api/public/auth/reset-password - Set new password
auth.post("/reset-password", async (c) => {
  const body = await c.req.json();
  const { phone, tempPassword, newPassword } = body;
  
  if (!phone || !tempPassword || !newPassword) {
    return c.json({ ok: false, error: "Preencha todos os campos" }, 400);
  }
  
  if (newPassword.length < 4) {
    return c.json({ ok: false, error: "Nova senha deve ter pelo menos 4 caracteres" }, 400);
  }
  
  const cleanPhone = phone.replace(/\D/g, "");
  
  // Verify temp password
  const tempHash = await hashPassword(tempPassword);
  
  const [user] = await db.select().from(appUsers).where(
    sql`${appUsers.phone} = ${cleanPhone} AND ${appUsers.password} = ${tempHash}`
  );
  
  if (!user) return c.json({ ok: false, error: "Código inválido ou expirado" }, 401);
  
  // Set new password
  const newHash = await hashPassword(newPassword);
  
  await db.update(appUsers).set({ password: newHash }).where(sql`${appUsers.id} = ${user.id}`);
  
  return c.json({ ok: true, message: "Senha alterada com sucesso!" });
});
