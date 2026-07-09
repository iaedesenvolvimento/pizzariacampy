# 📋 Pizzaria Campy - Documentação Completa

## 📅 Data: 09/07/2026

---

## 🏗️ Arquitetura do Sistema

### Stack Tecnológico
| Camada | Tecnologia |
|--------|------------|
| **Frontend** | HTML/CSS/JavaScript vanilla |
| **Backend** | EdgeSpark (Hono.js) |
| **Banco de Dados** | SQLite (D1) via Drizzle ORM |
| **Deploy** | EdgeSpark Cloud |
| **URL Principal** | `https://master-opossum-2815.youware.pro` |

### Estrutura de URLs
| URL | Descrição |
|-----|-----------|
| `/api/public/app` | App do cliente (cardápio + pedidos) |
| `/api/public/gerenciar` | Painel admin (gerenciamento) |
| `/api/public/painel-admin` | Dashboard admin (visualização) |
| `/api/public/menu` | API pública do cardápio |
| `/api/public/admin/*` | API admin (autenticada) |

---

## 🍕 Funcionalidades Implementadas

### 1. App do Cliente (`/api/public/app`)

#### Splash Screen
- Fundo preto fosco com brilho avermelhado nas bordas
- Fatia de pizza minimalista (vermelho, laranja, branco)
- Nome "Pizzaria Campy" com tipografia Poppins Bold
- Slogan "Pizza quentinha, entregue com rapidez."
- Barra de progresso vermelha animada
- Transição suave para o cardápio

#### Cardápio
- Exibição de itens com imagens (quando disponíveis)
- Categorias: Clássicas, Premium, Doces, Bebidas, Sobremesas
- Detalhes do item com descrição
- Seleção de tamanhos (M, G, GG)
- **Adicionais** com checkboxes (ex: Bacon, Catupiry)
- Quantidade选择ável
- Observações personalizadas
- Cálculo dinâmico de preço

#### Carrinho
- Adição/remoção de itens
- Atualização de quantidade
- Resumo com subtotal, entrega e total
- Frete grátis acima de R$ 80

#### Checkout
- Formulário completo:
  - Nome
  - Telefone (com máscara)
  - CEP (com consulta automática)
  - Rua, Número, Complemento, Bairro
- Métodos de pagamento:
  - PIX
  - Cartão de Crédito
  - Cartão de Débito
  - Dinheiro (com campo "Troco para quanto?")
- Notas/observações do pedido

#### Acompanhamento de Pedido
- Timeline visual com status:
  - Pendente → Confirmado → Preparando → Em Entrega → Entregue
- Atualização automática a cada 10 segundos
- Notificações de mudança de status

#### "Meus Pedidos"
- Lista de pedidos anteriores
- Botão **"🔄 Repetir Pedido"** (adiciona itens ao carrinho)
- Botão **"🍕 Novo Pedido"** (limpa carrinho)
- Botão **"📍 Acompanhar"**

#### Autenticação
- Login com telefone + senha
- Cadastro de novo usuário
- Recuperação de senha (senha temporária)
- Alteração de senha

---

### 2. Painel Admin (`/api/public/gerenciar`)

#### Dashboard de Pedidos
- Lista de pedidos em tempo real
- Status com badges coloridos
- Ações por status:
  - Pendente → ✅ Confirmar
  - Confirmado → 👨‍🍳 Preparar
  - Preparando → 🛵 Enviar
  - Em Entrega → 🎉 Entregue
  - Qualquer → ❌ Cancelar
- **Som de notificação** ao receber novo pedido
- **Banner visual** com dados do pedido
- Som para ao confirmar pedido

#### Gerenciamento do Cardápio
- Criar, editar, excluir itens
- Ativar/desativar disponibilidade
- **Upload de imagens** (preview instantâneo)
- Interface visual para:
  - **Tamanhos** (nome + preço)
  - **Adicionais** (nome + preço)
- Toggle de disponibilidade

#### Configurações
- Configurações gerais do sistema
- Limpeza de pedidos (zona de perigo)

---

### 3. APIs Backend

#### Rotas Públicas
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/public/menu` | Listar cardápio |
| GET | `/api/public/menu/:id` | Detalhe do item |
| POST | `/api/public/orders` | Criar pedido |
| GET | `/api/public/orders/:id` | Status do pedido |
| PATCH | `/api/public/orders/:id/status` | Atualizar status |
| GET | `/api/public/orders` | Listar pedidos |
| POST | `/api/public/payments/create-intent` | Criar pagamento Stripe |
| POST | `/api/public/payments/webhook` | Webhook Stripe |
| POST | `/api/public/payments/confirm-cash` | Confirmar pagamento dinheiro |
| POST | `/api/public/telegram/webhook` | Webhook Telegram |
| POST | `/api/public/telegram/send-notification` | Enviar notificação Telegram |
| GET | `/api/public/settings` | Configurações |
| GET | `/api/public/address/cep/:cep` | Consulta CEP (ViaCEP) |

#### Rotas de Autenticação
| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/api/public/auth/register` | Cadastro |
| POST | `/api/public/auth/login` | Login |
| GET | `/api/public/auth/me` | Dados do usuário |
| GET | `/api/public/auth/orders` | Pedidos do usuário |
| GET | `/api/public/auth/order/:id` | Detalhe do pedido |
| POST | `/api/public/auth/forgot-password` | Solicitar nova senha |
| POST | `/api/public/auth/reset-password` | Redefinir senha |

#### Rotas Admin (autenticadas via X-Admin-Token)
| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/public/admin/menu` | Listar cardápio |
| POST | `/api/public/admin/menu` | Criar item |
| PUT | `/api/public/admin/menu/:id` | Editar item |
| DELETE | `/api/public/admin/menu/:id` | Excluir item |
| PATCH | `/api/public/admin/menu/:id/toggle` | Toggle disponibilidade |
| GET | `/api/public/admin/orders` | Listar pedidos |
| PATCH | `/api/public/admin/orders/:id/status` | Atualizar status |
| DELETE | `/api/public/admin/orders` | Limpar pedidos |

---

## 🗃️ Estrutura do Banco de Dados

### Tabela: `menu_items`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | TEXT (PK) | ID único |
| name | TEXT | Nome do item |
| description | TEXT | Descrição |
| price | REAL | Preço base |
| category | TEXT | Categoria |
| image | TEXT | URL/base64 da imagem |
| available | BOOLEAN | Disponível |
| toppings | TEXT (JSON) | Lista de ingredientes |
| sizes | TEXT (JSON) | Tamanhos e preços |
| extras | TEXT (JSON) | Adicionais e preços |
| created_at | TEXT | Data de criação |

### Tabela: `orders`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | TEXT (PK) | ID único (PC + timestamp) |
| customer_name | TEXT | Nome do cliente |
| customer_phone | TEXT | Telefone |
| customer_address | TEXT | Endereço completo |
| customer_neighborhood | TEXT | Bairro |
| items | TEXT (JSON) | Itens do pedido |
| subtotal | REAL | Subtotal |
| delivery_fee | REAL | Taxa de entrega |
| total | REAL | Total |
| status | TEXT | Status do pedido |
| payment_method | TEXT | Método de pagamento |
| payment_id | TEXT | ID do pagamento Stripe |
| cash_change_for | REAL | Troco para quanto |
| notes | TEXT | Observações |
| created_at | TEXT | Data de criação |
| updated_at | TEXT | Última atualização |

### Tabela: `app_users`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | TEXT (PK) | ID único |
| name | TEXT | Nome |
| phone | TEXT | Telefone (único) |
| email | TEXT | E-mail (opcional) |
| password_hash | TEXT | Hash da senha |
| temp_password | TEXT | Senha temporária |
| created_at | TEXT | Data de criação |

### Tabela: `customers`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | TEXT (PK) | ID único |
| name | TEXT | Nome |
| phone | TEXT | Telefone |
| email | TEXT | E-mail |
| address | TEXT | Endereço |
| created_at | TEXT | Data de criação |

### Tabela: `settings`
| Campo | Tipo | Descrição |
|-------|------|-----------|
| key | TEXT (PK) | Chave da configuração |
| value | TEXT | Valor |

---

## 🎨 Design System

### Paleta de Cores
| Cor | Variável | Uso |
|-----|----------|-----|
| `#1a1a2e` | `--primary` | Fundo principal |
| `#e94560` | `--accent` | Cor de destaque (vermelho) |
| `#f5a623` | `--gold` | Preços e destaques |
| `#16213e` | `--surface` | Superfícies |
| `#1f2f50` | `--surface-light` | Superfícies claras |
| `#eef0f2` | `--text` | Texto principal |
| `#8892a4` | `--muted` | Texto secundário |
| `#27ae60` | `--success` | Sucesso/entregue |

### Tipografia
- **Principal:** Sora (400, 500, 600, 700)
- **Splash Screen:** Poppins (400, 600, 700, 800)

### Componentes
- Cards com bordas arredondadas (14px)
- Botões com hover suave
- Badges de status coloridos
- Modais com slide-up animation
- Toasts de notificação
- Popups de confirmação

---

## 🔔 Sistema de Notificações

### Som de Notificação
- **Arquivo:** `notification.mp3` (1.35MB)
- **Armazenamento:** EdgeSpark Storage (bucket "sounds")
- **URL:** `/api/public/sounds/notification.mp3`
- **Comportamento:**
  - Toca ao receber novo pedido
  - Para ao confirmar pedido
  - Fallback para bell gerado (Web Audio API) se bloqueado

### Banner de Notificação
- Aparece no topo do painel admin
- Exibe: "#ID - Nome do Cliente - R$ Total"
- Botão "Fechar" para dispensar
- Some ao confirmar pedido

---

## 📱 Funcionalidades Especiais

### Repetir Pedido
- Botão "🔄 Repetir" em pedidos entregues/cancelados
- Adiciona todos os itens ao carrinho
- Mantém tamanhos e adicionais
- Popup de confirmação

### Troco para Quanto
- Campo aparece ao selecionar "Dinheiro"
- Campo opcional (não bloqueia o pedido)
- Enviado junto com os dados do pedido

### Upload de Imagens
- Suporta JPG, PNG, WebP
- Tamanho máximo: 2MB
- Preview instantâneo antes de salvar
- Imagens salvas como base64 no banco

### Consulta de CEP
- Integração com ViaCEP
- Preenchimento automático de rua e bairro
- Validação de CEP (8 dígitos)

---

## 🚀 Deploy e Manutenção

### Comandos de Deploy
```bash
# Gerar migração
edgespark db generate

# Aplicar migração
edgespark db migrate

# Deploy
edgespark deploy

# Verificar projeto
edgespark project verify <alias>
```

### Variáveis de Ambiente
| Variável | Descrição |
|----------|-----------|
| `EDGESPARK_API_KEY` | Chave de API do EdgeSpark |
| `BLOOME_JWKS_URL` | URL de chaves JWT |
| `BLOOME_ISSUER` | Emissor JWT |
| `EDGESPARK_PROJECT_ID` | ID do projeto |
| `BLOOME_BRIDGE_SECRET` | Segredo de bridge |

---

## 📊 Métricas

### Tamanho do Bundle
- **Backend:** ~450KB
- **Frontend (HTML/CSS/JS):** ~47KB

### Performance
- **Tempo de carregamento:** < 2s
- **Tempo de splash screen:** 2.5s
- **Polling de pedidos:** 5 segundos
- **Atualização de tracking:** 10 segundos

---

## 🔒 Segurança

### Autenticação
- Senhas com hash bcrypt
- Tokens JWT para autenticação
- Senha temporária para recuperação

### Validações
- Campos obrigatórios validados
- Telefone com máscara
- CEP com validação de dígitos
- Preços com validação numérica

### Proteção
- CORS configurado
- Rate limiting (via EdgeSpark)
- Validação de autorização em rotas admin

---

## 📝 Notas para Desenvolvedor

### Estrutura de Arquivos
```
edgespark/pizzaria-campy/
├── server/
│   ├── src/
│   │   ├── routes/
│   │   │   ├── app.ts          # App do cliente
│   │   │   ├── gerenciar.ts    # Painel admin
│   │   │   ├── admin.ts        # API admin
│   │   │   ├── menu.ts         # API pública menu
│   │   │   ├── sounds.ts       # Endpoint de áudio
│   │   │   └── ...
│   │   ├── defs/
│   │   │   ├── db_schema.ts    # Schema do banco
│   │   │   └── storage_schema.ts
│   │   └── __generated__/
│   └── drizzle/                # Migrações SQL
```

### Convenções
- IDs gerados com timestamp: `PC + timestamp`
- Status de pedido: `pending`, `confirmed`, `preparing`, `out_for_delivery`, `delivered`, `cancelled`
- Categorias: `pizza_classica`, `pizza_premium`, `pizza_doce`, `bebida`, `sobremesa`

---

**Desenvolvido por:** Raphael (Agente IA)
**Plataforma:** Bloome + EdgeSpark
**Data:** 09/07/2026
