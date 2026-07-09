import { Hono } from "hono";

const address = new Hono();

// GET /api/public/address/cep/:cep - Lookup CEP via ViaCEP (proxy to avoid CORS)
address.get("/cep/:cep", async (c) => {
  const cep = c.req.param("cep").replace(/\D/g, "");
  if (cep.length !== 8) {
    return c.json({ ok: false, error: "CEP inválido" }, 400);
  }

  try {
    const res = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
    const data = await res.json();

    if (data.erro) {
      return c.json({ ok: false, error: "CEP não encontrado" }, 404);
    }

    return c.json({
      ok: true,
      address: {
        street: data.logradouro || "",
        neighborhood: data.bairro || "",
        city: data.localidade || "",
        state: data.uf || "",
        complement: data.complemento || "",
      },
    });
  } catch (err: any) {
    console.error("ViaCEP error:", err.message);
    return c.json({ ok: false, error: "Erro ao buscar CEP" }, 500);
  }
});

export default address;
