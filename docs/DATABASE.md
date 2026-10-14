# Modelagem do Banco — Pizzaria Campy

Versão: 0.1  
Status: Fase 5 — modelo lógico concluído e implementado com migrations  
Base: `docs/docs/REQUISITOS_FASE_0.md` e `docs/ARCHITECTURE.md`  
Data: 09/10/2026

## 1. Objetivo

Definir o modelo lógico inicial do PostgreSQL para o MVP. O banco é acessado exclusivamente pela API FastAPI. Esta fase documenta entidades, relacionamentos, constraints e índices; migrations e código SQL serão produzidos durante a implementação do backend.

## 2. Convenções

- PKs principais usam `UUID` gerado no servidor.
- Datas usam `TIMESTAMPTZ` e são armazenadas em UTC; regras de funcionamento usam `America/Sao_Paulo`.
- Valores monetários usam `NUMERIC(12,2)`, nunca `FLOAT` ou `REAL`.
- Quantidades inteiras positivas usam `INTEGER` com `CHECK`.
- Tabelas mutáveis possuem `created_at` e `updated_at`.
- Catálogo usa `is_active` para desativação sem apagar histórico.
- Usuários e endereços podem usar `deleted_at` quando a remoção lógica for necessária.
- Nomes físicos de tabelas e colunas serão definidos em `snake_case`.

## 3. Visão lógica

```text
users ──< addresses
  │          │
  ├──< refresh_tokens
  ├──< favorites >── products
  └──< orders ──< order_items ──< order_item_flavors >── flavors
                         │              │
                         ├── products   ├── product_sizes
                         ├── edges      └── extras
                         └── payments

categories ──< products
delivery_zones ──< addresses (por bairro/regra de cobertura)
business_hours
```

## 4. Entidades e campos

### 4.1 `users`

Clientes e administradores do sistema.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `name` | VARCHAR(120) | obrigatório |
| `email` | VARCHAR(254) | nullable conforme canal definido; único quando informado |
| `phone` | VARCHAR(20) | nullable; normalizado |
| `password_hash` | TEXT | obrigatório para autenticação por senha |
| `role` | ENUM | `CUSTOMER`, `ADMIN`, `MANAGER`, `DELIVERY` |
| `is_active` | BOOLEAN | default `true` |
| `created_at` | TIMESTAMPTZ | obrigatório |
| `updated_at` | TIMESTAMPTZ | obrigatório |
| `deleted_at` | TIMESTAMPTZ | nullable |

Não armazenar senha, token ou dados completos de cartão. Deve existir ao menos um identificador de login válido conforme a regra final de autenticação.

### 4.2 `addresses`

Endereços pertencentes a clientes.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `user_id` | UUID | FK `users.id`, obrigatório |
| `label` | VARCHAR(60) | opcional, por exemplo “Casa” |
| `street` | VARCHAR(160) | obrigatório |
| `number` | VARCHAR(20) | obrigatório |
| `complement` | VARCHAR(120) | opcional |
| `reference` | VARCHAR(200) | opcional |
| `neighborhood` | VARCHAR(120) | obrigatório |
| `city` | VARCHAR(100) | obrigatório |
| `state` | CHAR(2) | obrigatório |
| `postal_code` | VARCHAR(10) | obrigatório e normalizado |
| `is_default` | BOOLEAN | default `false` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |
| `deleted_at` | TIMESTAMPTZ | nullable |

No MVP, cobertura é determinada por bairro/regra administrativa; latitude e longitude ficam fora do modelo inicial.

### 4.3 `categories`

Categorias como pizzas, bebidas, sobremesas e combos.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `name` | VARCHAR(80) | obrigatório |
| `slug` | VARCHAR(100) | único |
| `description` | TEXT | opcional |
| `sort_order` | INTEGER | default `0`, não negativo |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

### 4.4 `products`

Itens vendidos no catálogo. Uma pizza pode usar opções de tamanho, sabor, borda e adicional.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `category_id` | UUID | FK `categories.id`, obrigatório |
| `name` | VARCHAR(120) | obrigatório |
| `slug` | VARCHAR(140) | único |
| `description` | TEXT | opcional |
| `product_type` | ENUM | `PIZZA`, `BEVERAGE`, `DESSERT`, `COMBO` |
| `image_url` | TEXT | opcional |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

Produto desativado não pode compor pedido novo. Exclusão física não é permitida se houver histórico associado.

### 4.5 `product_sizes`

Tamanhos e preços base por produto.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `product_id` | UUID | FK `products.id`, obrigatório |
| `name` | VARCHAR(60) | obrigatório |
| `slug` | VARCHAR(80) | único por produto |
| `price` | NUMERIC(12,2) | `>= 0` |
| `slices` | SMALLINT | default `8`, `> 0` |
| `max_flavors` | SMALLINT | `> 0`; conforme tamanho |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

O preço pode representar o preço do sabor mais caro; o serviço de preços deve definir a fonte final para pizzas com sabores.

### 4.6 `flavors`

Sabores disponíveis para pizzas.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `name` | VARCHAR(100) | obrigatório |
| `description` | TEXT | opcional |
| `image_url` | TEXT | opcional |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

### 4.7 `edges`

Bordas, com preço configurável.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `name` | VARCHAR(100) | obrigatório |
| `price` | NUMERIC(12,2) | `>= 0` |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

### 4.8 `extras`

Adicionais, com preço configurável.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `name` | VARCHAR(100) | obrigatório |
| `price` | NUMERIC(12,2) | `>= 0` |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

### 4.9 `delivery_zones`

Regiões de entrega, taxa e pedido mínimo.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `name` | VARCHAR(120) | obrigatório |
| `city` | VARCHAR(100) | obrigatório |
| `neighborhood` | VARCHAR(120) | obrigatório |
| `delivery_fee` | NUMERIC(12,2) | `>= 0` |
| `minimum_order_amount` | NUMERIC(12,2) | `>= 0` |
| `estimated_minutes` | INTEGER | `> 0` |
| `is_active` | BOOLEAN | default `true` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

O MVP usa bairro/cidade como regra de cobertura. Se houver sobreposição, a API deve rejeitar configuração ambígua ou aplicar uma prioridade explícita.

### 4.10 `business_hours`

Horários de funcionamento e janela de novos pedidos.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `weekday` | SMALLINT | `0..6`, convenção documentada como domingo a sábado |
| `opens_at` | TIME | nullable quando fechado |
| `closes_at` | TIME | nullable quando fechado |
| `orders_close_at` | TIME | nullable quando fechado |
| `is_closed` | BOOLEAN | default `false` |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

Deve existir no máximo um registro ativo por dia. A API avalia o horário no fuso `America/Sao_Paulo` e não confia exclusivamente no dispositivo.

### 4.11 `orders`

Cabeçalho do pedido e snapshots necessários para preservar o histórico.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `order_number` | VARCHAR(30) | único, público e não sequencial globalmente quando possível |
| `user_id` | UUID | FK `users.id`, obrigatório |
| `address_id` | UUID | FK `addresses.id`, nullable para retirada |
| `fulfillment_type` | ENUM | `DELIVERY`, `PICKUP` |
| `status` | ENUM | `PENDING`, `CONFIRMED`, `PREPARING`, `READY`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED` |
| `payment_method` | ENUM | `PIX`, `CASH`, `CARD_ON_DELIVERY` |
| `payment_status` | ENUM | `PENDING`, `UNDER_REVIEW`, `CONFIRMED`, `FAILED`, `REFUNDED` |
| `subtotal` | NUMERIC(12,2) | `>= 0` |
| `delivery_fee` | NUMERIC(12,2) | `>= 0` |
| `discount_amount` | NUMERIC(12,2) | default `0`, `>= 0` |
| `total_amount` | NUMERIC(12,2) | `>= 0` |
| `change_for` | NUMERIC(12,2) | nullable, `> 0` quando informado |
| `delivery_zone_name` | VARCHAR(120) | snapshot nullable |
| `delivery_address_snapshot` | JSONB | obrigatório para entrega; nullable para retirada |
| `customer_note` | VARCHAR(500) | opcional |
| `cancelled_reason` | VARCHAR(300) | obrigatório se cancelado quando aplicável |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |
| `confirmed_at` / `delivered_at` | TIMESTAMPTZ | nullable |

O pedido guarda snapshots de endereço, região e valores porque o cliente pode alterar o endereço e o catálogo pode mudar depois da compra. `total_amount` é sempre derivado pelo backend dentro da transação.

### 4.12 `order_items`

Itens do pedido com snapshot de nome e preços.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `order_id` | UUID | FK `orders.id`, obrigatório |
| `product_id` | UUID | FK `products.id`, nullable para preservar histórico se necessário |
| `product_name` | VARCHAR(120) | snapshot obrigatório |
| `product_size_id` | UUID | FK opcional para referência |
| `size_name` | VARCHAR(60) | snapshot |
| `edge_id` | UUID | FK opcional |
| `edge_name` | VARCHAR(100) | snapshot nullable |
| `unit_price` | NUMERIC(12,2) | `>= 0` |
| `quantity` | INTEGER | `> 0` |
| `extras_total` | NUMERIC(12,2) | `>= 0` |
| `line_total` | NUMERIC(12,2) | `>= 0` |
| `note` | VARCHAR(300) | opcional |
| `created_at` | TIMESTAMPTZ | obrigatório |

`line_total` deve corresponder à soma validada de preço unitário, adicionais e quantidade.

### 4.13 `order_item_flavors`

Sabores escolhidos para cada item, preservando a composição da pizza.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `order_item_id` | UUID | FK `order_items.id`, obrigatório |
| `flavor_id` | UUID | FK opcional para referência histórica |
| `flavor_name` | VARCHAR(100) | snapshot obrigatório |
| `position` | SMALLINT | `> 0`, único por item |
| `price_reference` | NUMERIC(12,2) | `>= 0` |

O serviço valida a quantidade contra `product_sizes.max_flavors` antes de criar o pedido. A regra do preço multissabor usa o maior preço aplicável, conforme a Fase 0.

### 4.14 Tabela associativa de adicionais

Para registrar adicionais por item, usar `order_item_extras` como entidade complementar, embora não esteja na lista inicial de entidades.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `order_item_id` | UUID | FK `order_items.id` |
| `extra_id` | UUID | FK opcional |
| `extra_name` | VARCHAR(100) | snapshot |
| `unit_price` | NUMERIC(12,2) | `>= 0` |
| `quantity` | INTEGER | `> 0` |
| `total_price` | NUMERIC(12,2) | `>= 0` |

### 4.15 `payments`

Registro operacional do pagamento.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `order_id` | UUID | FK `orders.id`, obrigatório |
| `method` | ENUM | `PIX`, `CASH`, `CARD_ON_DELIVERY` |
| `status` | ENUM | `PENDING`, `UNDER_REVIEW`, `CONFIRMED`, `FAILED`, `REFUNDED` |
| `amount` | NUMERIC(12,2) | `>= 0` |
| `proof_url` | TEXT | nullable para PIX manual |
| `reviewed_by` | UUID | FK `users.id`, nullable |
| `reviewed_at` | TIMESTAMPTZ | nullable |
| `notes` | VARCHAR(300) | opcional |
| `created_at` / `updated_at` | TIMESTAMPTZ | obrigatórios |

Não guardar número, código de segurança, validade ou outros dados sensíveis de cartão.

### 4.16 `favorites`

Preparada para evolução pós-MVP; não será usada enquanto favoritos estiverem fora do escopo.

| Campo | Tipo | Regras |
|---|---|---|
| `user_id` | UUID | FK `users.id` |
| `product_id` | UUID | FK `products.id` |
| `created_at` | TIMESTAMPTZ | obrigatório |

PK composta: (`user_id`, `product_id`).

### 4.17 `refresh_tokens`

Sessões renováveis e revogáveis.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `user_id` | UUID | FK `users.id` |
| `token_hash` | TEXT | único; nunca armazenar token puro |
| `expires_at` | TIMESTAMPTZ | obrigatório |
| `revoked_at` | TIMESTAMPTZ | nullable |
| `created_at` | TIMESTAMPTZ | obrigatório |
| `user_agent` | VARCHAR(300) | opcional |

### 4.18 `order_status_history`

Histórico de transições para auditoria e acompanhamento.

| Campo | Tipo | Regras |
|---|---|---|
| `id` | UUID | PK |
| `order_id` | UUID | FK `orders.id` |
| `from_status` | ENUM | nullable no primeiro registro |
| `to_status` | ENUM | obrigatório |
| `changed_by` | UUID | FK `users.id`, nullable para eventos sistêmicos |
| `reason` | VARCHAR(300) | opcional |
| `created_at` | TIMESTAMPTZ | obrigatório |

## 5. Relacionamentos e cardinalidades

| Relação | Cardinalidade | Comportamento |
|---|---|---|
| Usuário → endereços | 1:N | endereço pertence a um usuário |
| Categoria → produtos | 1:N | produto exige categoria ativa no cadastro |
| Produto → tamanhos | 1:N | tamanho desativável sem apagar histórico |
| Usuário → pedidos | 1:N | pedido mantém proprietário original |
| Pedido → itens | 1:N | apagar item isolado não é permitido após confirmação |
| Item → sabores | 1:N | pelo menos um para pizza |
| Item → adicionais | 1:N | zero ou mais |
| Pedido → pagamentos | 1:N | permite tentativas/ajustes auditáveis |
| Pedido → histórico de status | 1:N | cada transição gera registro |
| Zona → endereços | lógico | associação é resolvida por cidade/bairro, não FK obrigatória |

## 6. Constraints e integridade

- E-mail deve ser comparado de forma case-insensitive; índice único parcial para valores não nulos.
- `quantity`, `slices`, `max_flavors`, taxas e preços não podem ser negativos.
- Pedido `PICKUP` não possui endereço obrigatório nem taxa de entrega.
- Pedido `DELIVERY` exige snapshot de endereço e zona válida.
- `payment_method = CASH` permite `change_for`; outros métodos ignoram ou rejeitam esse campo.
- `payment_method = PIX` pode ter comprovante, mas o upload não confirma o pagamento automaticamente.
- Pedido cancelado exige transição válida e registro em `order_status_history`.
- Status de pedido não pode retroceder para uma etapa incompatível.
- Itens e opções desativados não podem ser usados em pedidos novos.
- Foreign keys de histórico usam `RESTRICT` ou `SET NULL` conforme necessário para preservar dados; nunca apagar pedido em cascata.
- Campos de snapshot são obrigatórios mesmo quando a FK original for nullable.

## 7. Índices iniciais

- `users(lower(email))` único e parcial quando e-mail existir.
- `users(phone)` único e parcial quando telefone existir.
- `addresses(user_id, deleted_at)`.
- `categories(is_active, sort_order)`.
- `products(category_id, is_active, sort_order)` — incluir `sort_order` em `products` durante a migration inicial.
- `product_sizes(product_id, is_active)`.
- `delivery_zones(city, neighborhood, is_active)`.
- `business_hours(weekday)` único.
- `orders(user_id, created_at DESC)`.
- `orders(status, created_at DESC)` para operação administrativa.
- `orders(order_number)` único.
- `order_items(order_id)`.
- `order_item_flavors(order_item_id, position)` único.
- `payments(order_id, created_at DESC)`.
- `refresh_tokens(token_hash)` único e `refresh_tokens(user_id, revoked_at)`.
- `order_status_history(order_id, created_at)`.

Índices adicionais serão baseados em consultas reais após o MVP, evitando otimização prematura.

## 8. Transações críticas

### Criação do pedido

1. Revalidar usuário e sessão.
2. Revalidar horário pelo servidor.
3. Revalidar catálogo e disponibilidade.
4. Resolver zona, taxa e pedido mínimo.
5. Calcular preços no serviço central.
6. Inserir `orders`, itens, sabores, adicionais e pagamento.
7. Inserir primeiro evento em `order_status_history`.
8. Confirmar a transação.

Falha em qualquer etapa faz rollback de toda a criação.

### Alteração de status

Atualizar `orders.status` e inserir `order_status_history` na mesma transação, após validar a transição e a permissão do operador.

## 9. Dados fora do banco no MVP

- Imagens e comprovantes podem ser armazenados em serviço de arquivos; o banco guarda somente URL/chave e metadados necessários.
- Não armazenar mapas, rastreamento GPS ou dados completos de cartão.
- Cupons ficam fora do MVP, apesar de estarem previstos para uma fase posterior.

## 10. Migrations e evolução

- Toda alteração estrutural será feita via Alembic.
- Migrations devem ser pequenas, reversíveis quando possível e testadas em staging.
- Alterações destrutivas exigem decisão explícita, backup e plano de recuperação.
- Dados históricos de pedidos não devem depender da existência atual de um produto, sabor, borda ou adicional.

## 11. Pendências que afetam o modelo

- Definição final do identificador de login: e-mail, telefone ou ambos.
- Endereço completo da unidade e configuração de retirada.
- Lista final de bairros, cidades, taxas e mínimos.
- Regra definitiva para cálculo do mínimo: somente produtos ou total antes da taxa.
- Estratégia de armazenamento de comprovantes PIX.
- Política de retenção e remoção de dados pessoais.

## 12. Próxima fase

O modelo foi implementado nas migrations do backend. Pendências atuais estão em `docs/STATUS_PROJETO.md`.
