import Database from "better-sqlite3";

let _db: Database.Database | null = null;

export function getDb(): Database.Database {
  if (!_db) {
    _db = new Database(":memory:");
    initTables(_db);
    seedData(_db);
  }
  return _db;
}

function initTables(db: Database.Database) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS menu_items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      category TEXT NOT NULL,
      image TEXT,
      available INTEGER DEFAULT 1,
      toppings TEXT,
      sizes TEXT,
      created_at TEXT DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY,
      customer_name TEXT NOT NULL,
      customer_phone TEXT NOT NULL,
      customer_address TEXT NOT NULL,
      customer_neighborhood TEXT,
      items TEXT NOT NULL,
      subtotal REAL NOT NULL,
      delivery_fee REAL DEFAULT 0,
      total REAL NOT NULL,
      payment_method TEXT NOT NULL,
      payment_status TEXT DEFAULT 'pending',
      payment_id TEXT,
      status TEXT DEFAULT 'pending',
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS customers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      address TEXT,
      neighborhood TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  `);
}

function seedData(db: Database.Database) {
  const count = db.prepare("SELECT COUNT(*) as c FROM menu_items").get() as any;
  if (count.c > 0) return;

  const menu = [
    { id: "pizza-001", name: "Margherita", description: "Molho de tomate San Marzano, mussarela de búfala fresca, manjericão extra-virgem e azeite de oliva", price: 44.90, category: "pizza_classica", toppings: ["mussarela búfala", "manjericão", "molho tomate", "azeite"], sizes: { "M": 44.90, "G": 54.90, "GG": 64.90 } },
    { id: "pizza-002", name: "Napoli", description: "Molho de tomate, mussarela, presunto parma, azeitonas pretas e orégano", price: 49.90, category: "pizza_classica", toppings: ["mussarela", "presunto parma", "azeitonas", "orégano"], sizes: { "M": 49.90, "G": 59.90, "GG": 69.90 } },
    { id: "pizza-003", name: "Quatro Queijos", description: "Mussarela, gorgonzola, parmesão e provolone — para os verdadeiros amantes de queijo", price: 54.90, category: "pizza_classica", toppings: ["mussarela", "gorgonzola", "parmesão", "provolone"], sizes: { "M": 54.90, "G": 64.90, "GG": 74.90 } },
    { id: "pizza-004", name: "Calabresa Especial", description: "Calabresa artesanal defumada, cebola caramelizada, mussarela e azeitonas verdes", price: 47.90, category: "pizza_classica", toppings: ["calabresa", "cebola caramelizada", "mussarela", "azeitonas"], sizes: { "M": 47.90, "G": 57.90, "GG": 67.90 } },
    { id: "pizza-005", name: "Portuguesa", description: "Presunto, ovos, cebola, azeitonas, ervilha, mussarela e orégano — a clássica brasileira", price: 49.90, category: "pizza_classica", toppings: ["presunto", "ovo", "cebola", "azeitonas", "ervilha"], sizes: { "M": 49.90, "G": 59.90, "GG": 69.90 } },
    { id: "pizza-006", name: "Trufada", description: "Creme de trufas negras, mussarela, parmesão, rúcula e lascas de trufa", price: 69.90, category: "pizza_premium", toppings: ["trufa negra", "mussarela", "parmesão", "rúcula"], sizes: { "M": 69.90, "G": 79.90, "GG": 89.90 } },
    { id: "pizza-007", name: "Salmão Gourmet", description: "Creme de ricota, salmão defumado, alcaparras, cebola roxa e dill fresco", price: 64.90, category: "pizza_premium", toppings: ["salmão defumado", "ricota", "alcaparras", "cebola roxa"], sizes: { "M": 64.90, "G": 74.90, "GG": 84.90 } },
    { id: "pizza-008", name: "Pepperoni Supreme", description: "Tripla camada de pepperoni importado, mussarela derretida e molho picante caseiro", price: 59.90, category: "pizza_premium", toppings: ["pepperoni", "mussarela", "molho picante"], sizes: { "M": 59.90, "G": 69.90, "GG": 79.90 } },
    { id: "pizza-009", name: "Frango com Catupiry", description: "Frango desfiado temperado, catupiry cremoso original e milho dourado", price: 52.90, category: "pizza_premium", toppings: ["frango", "catupiry", "milho"], sizes: { "M": 52.90, "G": 62.90, "GG": 72.90 } },
    { id: "pizza-010", name: "Bacon & Cheddar", description: "Bacon crocante artesanal, cheddar importado, cebola crispy e mussarela", price: 56.90, category: "pizza_premium", toppings: ["bacon", "cheddar", "cebola crispy", "mussarela"], sizes: { "M": 56.90, "G": 66.90, "GG": 76.90 } },
    { id: "pizza-d01", name: "Chocolate Belga", description: "Chocolate belga meio amargo derretido, morangos frescos e granulado artesanal", price: 49.90, category: "pizza_doce", toppings: ["chocolate belga", "morango", "granulado"], sizes: { "M": 49.90, "G": 59.90, "GG": 69.90 } },
    { id: "pizza-d02", name: "Romeu & Julieta", description: "Goiabada cascão artesanal com queijo minas curado — o clássico perfeito", price: 47.90, category: "pizza_doce", toppings: ["goiabada", "queijo minas"], sizes: { "M": 47.90, "G": 57.90, "GG": 67.90 } },
    { id: "pizza-d03", name: "Banana com Canela", description: "Banana caramelizada, canela ceilão, leite condensado e mussarela", price: 46.90, category: "pizza_doce", toppings: ["banana", "canela", "leite condensado"], sizes: { "M": 46.90, "G": 56.90, "GG": 66.90 } },
    { id: "beb-001", name: "Coca-Cola 2L", description: "Coca-Cola gelada — perfeita para acompanhar", price: 14.90, category: "bebida" },
    { id: "beb-002", name: "Guaraná Antarctica 2L", description: "Guaraná gelado — o sabor brasileiro", price: 12.90, category: "bebida" },
    { id: "beb-003", name: "Água Mineral 500ml", description: "Água mineral natural ou com gás", price: 5.90, category: "bebida" },
    { id: "beb-004", name: "Suco Natural 500ml", description: "Laranja, limão, maracujá ou manga — fresco na hora", price: 9.90, category: "bebida" },
    { id: "beb-005", name: "Cerveja Heineken Long Neck", description: "Heineken gelada 330ml", price: 8.90, category: "bebida" },
    { id: "beb-006", name: "Cerveja Stella Artois", description: "Stella Artois long neck 330ml", price: 9.90, category: "bebida" },
    { id: "sob-001", name: "Brownie Artesanal", description: "Brownie de chocolate belga com sorvete de creme e calda de frutas vermelhas", price: 22.90, category: "sobremesa" },
    { id: "sob-002", name: "Petit Gateau", description: "Bolinho de chocolate com centro derretido, sorvete de baunilha e calda de chocolate", price: 24.90, category: "sobremesa" },
    { id: "sob-003", name: "Pudim de Leite", description: "Pudim caseiro de leite condensado com calda de caramelo", price: 14.90, category: "sobremesa" },
  ];

  const stmt = db.prepare(`
    INSERT INTO menu_items (id, name, description, price, category, image, available, toppings, sizes, created_at)
    VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?, datetime('now'))
  `);

  for (const item of menu) {
    stmt.run(item.id, item.name, item.description, item.price, item.category, null, JSON.stringify(item.toppings), JSON.stringify(item.sizes));
  }

  const settingsStmt = db.prepare("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)");
  settingsStmt.run("telegram_bot_token", "");
  settingsStmt.run("telegram_chat_id", "");
  settingsStmt.run("stripe_secret_key", "");
  settingsStmt.run("stripe_webhook_secret", "");
  settingsStmt.run("delivery_fee", "5.90");
  settingsStmt.run("free_delivery_minimum", "80.00");
  settingsStmt.run("min_order", "30.00");
  settingsStmt.run("business_hours", JSON.stringify({ open: "18:00", close: "23:30" }));
  settingsStmt.run("business_name", "Pizzaria Campy");
}
