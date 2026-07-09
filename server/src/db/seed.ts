import { db } from "edgespark";
import { menuItems, settings } from "../defs/db_schema";
import { sql } from "drizzle-orm";

let seeded = false;

export async function ensureSeeded() {
  if (seeded) return;
  seeded = true;

  try {
    // Check if menu already has data
    const [existing] = await db.select({ count: sql<number>`count(*)` }).from(menuItems);
    if (existing && existing.count > 0) return;
  } catch {
    // Continue with seeding
  }

  // Seed menu items
  const menuData = [
    { id: "pizza-001", name: "Margherita", description: "Molho de tomate San Marzano, mussarela de búfala fresca, manjericão extra-virgem e azeite de oliva", price: 44.90, category: "pizza_classica", toppings: JSON.stringify(["mussarela búfala", "manjericão", "molho tomate", "azeite"]), sizes: JSON.stringify({ "M": 44.90, "G": 54.90, "GG": 64.90 }) },
    { id: "pizza-002", name: "Napoli", description: "Molho de tomate, mussarela, presunto parma, azeitonas pretas e orégano", price: 49.90, category: "pizza_classica", toppings: JSON.stringify(["mussarela", "presunto parma", "azeitonas", "orégano"]), sizes: JSON.stringify({ "M": 49.90, "G": 59.90, "GG": 69.90 }) },
    { id: "pizza-003", name: "Quatro Queijos", description: "Mussarela, gorgonzola, parmesão e provolone", price: 54.90, category: "pizza_classica", toppings: JSON.stringify(["mussarela", "gorgonzola", "parmesão", "provolone"]), sizes: JSON.stringify({ "M": 54.90, "G": 64.90, "GG": 74.90 }) },
    { id: "pizza-004", name: "Calabresa Especial", description: "Calabresa artesanal defumada, cebola caramelizada, mussarela e azeitonas verdes", price: 47.90, category: "pizza_classica", toppings: JSON.stringify(["calabresa", "cebola caramelizada", "mussarela", "azeitonas"]), sizes: JSON.stringify({ "M": 47.90, "G": 57.90, "GG": 67.90 }) },
    { id: "pizza-005", name: "Portuguesa", description: "Presunto, ovos, cebola, azeitonas, ervilha, mussarela e orégano", price: 49.90, category: "pizza_classica", toppings: JSON.stringify(["presunto", "ovo", "cebola", "azeitonas", "ervilha"]), sizes: JSON.stringify({ "M": 49.90, "G": 59.90, "GG": 69.90 }) },
    { id: "pizza-006", name: "Trufada", description: "Creme de trufas negras, mussarela, parmesão, rúcula e lascas de trufa", price: 69.90, category: "pizza_premium", toppings: JSON.stringify(["trufa negra", "mussarela", "parmesão", "rúcula"]), sizes: JSON.stringify({ "M": 69.90, "G": 79.90, "GG": 89.90 }) },
    { id: "pizza-007", name: "Salmão Gourmet", description: "Creme de ricota, salmão defumado, alcaparras, cebola roxa e dill fresco", price: 64.90, category: "pizza_premium", toppings: JSON.stringify(["salmão defumado", "ricota", "alcaparras", "cebola roxa"]), sizes: JSON.stringify({ "M": 64.90, "G": 74.90, "GG": 84.90 }) },
    { id: "pizza-008", name: "Pepperoni Supreme", description: "Tripla camada de pepperoni importado, mussarela derretida e molho picante caseiro", price: 59.90, category: "pizza_premium", toppings: JSON.stringify(["pepperoni", "mussarela", "molho picante"]), sizes: JSON.stringify({ "M": 59.90, "G": 69.90, "GG": 79.90 }) },
    { id: "pizza-009", name: "Frango com Catupiry", description: "Frango desfiado temperado, catupiry cremoso original e milho dourado", price: 52.90, category: "pizza_premium", toppings: JSON.stringify(["frango", "catupiry", "milho"]), sizes: JSON.stringify({ "M": 52.90, "G": 62.90, "GG": 72.90 }) },
    { id: "pizza-010", name: "Bacon & Cheddar", description: "Bacon crocante artesanal, cheddar importado, cebola crispy e mussarela", price: 56.90, category: "pizza_premium", toppings: JSON.stringify(["bacon", "cheddar", "cebola crispy", "mussarela"]), sizes: JSON.stringify({ "M": 56.90, "G": 66.90, "GG": 76.90 }) },
    { id: "pizza-d01", name: "Chocolate Belga", description: "Chocolate belga meio amargo derretido, morangos frescos e granulado artesanal", price: 49.90, category: "pizza_doce", toppings: JSON.stringify(["chocolate belga", "morango", "granulado"]), sizes: JSON.stringify({ "M": 49.90, "G": 59.90, "GG": 69.90 }) },
    { id: "pizza-d02", name: "Romeu & Julieta", description: "Goiabada cascão artesanal com queijo minas curado", price: 47.90, category: "pizza_doce", toppings: JSON.stringify(["goiabada", "queijo minas"]), sizes: JSON.stringify({ "M": 47.90, "G": 57.90, "GG": 67.90 }) },
    { id: "pizza-d03", name: "Banana com Canela", description: "Banana caramelizada, canela ceilão, leite condensado e mussarela", price: 46.90, category: "pizza_doce", toppings: JSON.stringify(["banana", "canela", "leite condensado"]), sizes: JSON.stringify({ "M": 46.90, "G": 56.90, "GG": 66.90 }) },
    { id: "beb-001", name: "Coca-Cola 2L", description: "Coca-Cola gelada", price: 14.90, category: "bebida" },
    { id: "beb-002", name: "Guaraná Antarctica 2L", description: "Guaraná gelado", price: 12.90, category: "bebida" },
    { id: "beb-003", name: "Água Mineral 500ml", description: "Água mineral natural ou com gás", price: 5.90, category: "bebida" },
    { id: "beb-004", name: "Suco Natural 500ml", description: "Laranja, limão, maracujá ou manga", price: 9.90, category: "bebida" },
    { id: "beb-005", name: "Cerveja Heineken Long Neck", description: "Heineken gelada 330ml", price: 8.90, category: "bebida" },
    { id: "beb-006", name: "Cerveja Stella Artois", description: "Stella Artois long neck 330ml", price: 9.90, category: "bebida" },
    { id: "sob-001", name: "Brownie Artesanal", description: "Brownie de chocolate belga com sorvete de creme e calda de frutas vermelhas", price: 22.90, category: "sobremesa" },
    { id: "sob-002", name: "Petit Gateau", description: "Bolinho de chocolate com centro derretido, sorvete de baunilha e calda de chocolate", price: 24.90, category: "sobremesa" },
    { id: "sob-003", name: "Pudim de Leite", description: "Pudim caseiro de leite condensado com calda de caramelo", price: 14.90, category: "sobremesa" },
  ];

  const now = new Date().toISOString();

  // Insert menu items one by one to avoid batch issues
  for (const item of menuData) {
    try {
      await db.insert(menuItems).values({
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        category: item.category,
        toppings: item.toppings,
        sizes: item.sizes,
        available: true,
        createdAt: now,
      });
    } catch (e) {
      console.error(`Failed to insert menu item ${item.id}:`, e);
    }
  }

  // Seed settings
  const settingsData = [
    { key: "telegram_bot_token", value: "" },
    { key: "telegram_chat_id", value: "" },
    { key: "stripe_secret_key", value: "" },
    { key: "stripe_webhook_secret", value: "" },
    { key: "delivery_fee", value: "5.90" },
    { key: "free_delivery_minimum", value: "80.00" },
    { key: "min_order", value: "30.00" },
    { key: "business_hours", value: JSON.stringify({ open: "18:00", close: "23:30" }) },
    { key: "business_name", value: "Pizzaria Campy" },
  ];

  for (const setting of settingsData) {
    try {
      await db.insert(settings).values(setting);
    } catch (e) {
      console.error(`Failed to insert setting ${setting.key}:`, e);
    }
  }
}
