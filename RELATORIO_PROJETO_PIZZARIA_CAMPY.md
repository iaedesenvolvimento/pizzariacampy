# Relatório do Projeto — Pizzaria Campy

**Data do relatório:** 19/10/2026  
**Repositório:** `iaedesenvolvimento/pizzariacampy`  
**Branch principal:** `main`  
**Último commit registrado:** `ef95bdc` — exposição do ID de ordem do Mercado Pago

## 1. Resumo executivo

A Pizzaria Campy possui um ecossistema formado por um aplicativo Flutter para clientes e administradores, uma API FastAPI e um banco PostgreSQL. O sistema cobre o ciclo principal de uma operação de pizzaria: autenticação, catálogo, personalização de pizzas, carrinho, checkout, entrega ou retirada, pagamentos, acompanhamento de pedidos e gestão administrativa.

O projeto evoluiu de uma base inicial para um MVP operacional com catálogo real, integração com Cloudinary, notificações em tempo real, recuperação de senha por e-mail, zonas de entrega, cupons, financeiro operacional e integração PIX via Mercado Pago Orders API.

O sistema está funcional para validação e operação controlada. Antes de uma expansão comercial maior, ainda é necessário concluir a validação ponta a ponta em produção, revisar publicação mobile e fortalecer observabilidade, backups, testes de integração e performance.

## 2. Arquitetura implementada

```text
Aplicativo Flutter Android/iOS
              |
              | HTTPS / JSON / WebSocket
              v
       API FastAPI /api/v1
              |
       Serviços e regras de negócio
              |
       PostgreSQL + Alembic
```

### Componentes

| Componente | Tecnologia | Responsabilidade |
|---|---|---|
| Aplicativo | Flutter/Dart | Cliente, checkout, acompanhamento e Admin integrado |
| Backend | Python/FastAPI | API, autenticação, validações e regras comerciais |
| Persistência | PostgreSQL | Usuários, catálogo, pedidos, pagamentos e configurações |
| Migrações | Alembic | Evolução versionada do banco |
| Imagens | Cloudinary | Upload e entrega das imagens do catálogo |
| Deploy | Docker/Render | Execução pública da API |
| Banco de produção | Neon PostgreSQL | Banco gerenciado conectado ao Render |
| E-mail | Brevo | Recuperação de senha |
| Notificações | Firebase/WebSocket | Push e eventos em tempo real |
| Pagamento online | Mercado Pago | PIX com QR Code e Pix copia e cola |

O banco não é acessado diretamente pelo aplicativo. O cliente e o Admin consomem exclusivamente a API.

## 3. Aplicativo Flutter

### 3.1 Autenticação e perfil

Implementado:

- cadastro de cliente;
- login e logout;
- refresh de sessão;
- armazenamento local da sessão;
- recuperação e redefinição de senha;
- validação de senha;
- aceite de política de privacidade e LGPD;
- perfil autenticado;
- edição de dados do usuário;
- telefone e avatar/foto do usuário;
- proteção das rotas administrativas.

### 3.2 Cardápio e experiência do cliente

Implementado:

- categorias de produtos;
- busca de produtos;
- filtro e navegação por categoria;
- atualização manual por gesto de deslizar;
- indicação de loja aberta, fechada ou fora do horário de pedidos;
- tema claro e escuro;
- cards de escolha rápida para pizza grande de um sabor;
- cards de pizza grande meio a meio;
- card de pizza broto;
- produtos simples, como bebidas, doces e sobremesas;
- imagens de produtos via URL do Cloudinary;
- descrição, preço e disponibilidade dos produtos;
- tratamento de produto sem imagem;
- tratamento de erros, carregamento e catálogo vazio.

### 3.3 Personalização de pizzas

Implementado:

- seleção de tamanho;
- seleção de um sabor;
- seleção de dois sabores para pizza meio a meio;
- limite de sabores conforme a configuração do produto;
- seleção de borda;
- seleção de tipo de massa;
- seleção de adicionais;
- controle de quantidade;
- descrição dos sabores;
- busca de sabores;
- preço por tamanho e sabor;
- validação de quantidade de sabores antes de adicionar ao carrinho;
- pizzas doces e salgadas com tratamento separado;
- produtos simples sem obrigatoriedade de personalização de pizza.

### 3.4 Carrinho e checkout

Implementado:

- carrinho persistente localmente;
- inclusão, remoção e alteração de quantidade;
- alerta ao adicionar produto;
- sugestões de produtos complementares;
- escolha entre entrega e retirada;
- escolha de endereço salvo;
- preenchimento de endereço por CEP;
- número da residência;
- complemento opcional;
- validação de cidade, bairro e zona de entrega;
- cálculo de taxa de entrega;
- pedido mínimo por zona;
- prazo estimado;
- cupom de desconto com alerta de aplicação;
- troco para pagamento em dinheiro;
- observações do pedido;
- revisão completa de itens, taxas, desconto e total;
- dados do cliente no resumo administrativo;
- confirmação de pedido.

### 3.5 Pedidos e acompanhamento

Implementado:

- criação autenticada de pedido;
- histórico de pedidos;
- acompanhamento individual;
- resumo dos produtos e personalizações;
- exibição de endereço, número e complemento;
- exibição de taxas, descontos e total;
- status de pedido em tempo real;
- notificações para mudança de status;
- remoção do cancelamento na tela de acompanhamento conforme decisão de produto;
- fluxo para entrega e retirada.

Fluxo operacional:

```text
PENDING → CONFIRMED → PREPARING → READY → OUT_FOR_DELIVERY → DELIVERED
```

Para retirada:

```text
READY → DELIVERED
```

O backend permanece como autoridade das transições.

## 4. Área administrativa

O Admin continua integrado ao mesmo aplicativo Flutter, principalmente em `pizzaria-mobile/lib/features/admin/`. Não foi criado um painel separado.

### Módulos implementados

- Dashboard administrativo;
- métricas operacionais;
- pedidos;
- clientes;
- catálogo;
- categorias;
- produtos;
- tamanhos e variações;
- preços de sabores;
- sabores vinculados aos produtos;
- bordas e adicionais;
- ativação e desativação de produtos;
- exclusão protegida de produtos;
- upload de imagem;
- cupons;
- zonas de entrega;
- habilitação ou desabilitação de regiões;
- horários de funcionamento;
- configurações da loja;
- pagamentos pendentes;
- conferência de comprovante PIX manual;
- financeiro operacional MVP;
- notificações administrativas de novos pedidos.

### Design System Admin

Foi criada uma base compartilhada para padronizar a operação:

- `AdminScaffold`;
- navegação administrativa;
- cabeçalho de página;
- cards de métricas;
- cards de seção;
- badges de status;
- campo de busca;
- barra de filtros;
- estados de carregamento, vazio e erro;
- diálogos de confirmação;
- cards de pedido, cliente, cupom e produto;
- campos de formulário;
- espaçamentos, cores, raios e breakpoints.

O objetivo foi reduzir inconsistências entre telas sem remover os recursos já existentes.

## 5. Backend e API

### Autenticação

Rotas implementadas:

- `POST /auth/register`;
- `POST /auth/login`;
- `POST /auth/refresh`;
- `POST /auth/logout`;
- `GET /auth/me`;
- `PATCH /auth/me`;
- `POST /auth/me/avatar`;
- `POST /auth/password-recovery`;
- `POST /auth/password-reset`.

Características:

- senha armazenada como hash;
- tokens de acesso e refresh;
- refresh rotacionável;
- controle de perfil `CUSTOMER`, `ADMIN` e estrutura para outros perfis;
- escopo por usuário;
- resposta genérica na recuperação de senha para evitar descoberta de contas;
- token de redefinição com expiração e uso único.

### Catálogo

Rotas principais:

- `GET /categories`;
- `GET /products`;
- `GET /products/{id}`;
- `GET /products/{id}/options`;
- `POST /pricing/quote`.

O catálogo foi normalizado para diferenciar:

- pizzas configuráveis;
- produtos simples;
- combos;
- tamanhos;
- preços;
- sabores;
- bordas;
- adicionais;
- composições.

O catálogo real foi importado a partir de dados oficiais, com validação de slugs, preços, tamanhos, descrições e imagens.

### Pedidos

Rotas principais:

- `POST /orders`;
- `GET /orders`;
- `GET /orders/{id}`;
- `POST /orders/{id}/cancel`;
- rotas administrativas de listagem e atualização de status.

O preço final é recalculado no servidor. O preço enviado pelo aplicativo não é considerado fonte confiável.

### Entrega e horários

Implementado:

- zonas por cidade e bairro;
- taxa por zona;
- pedido mínimo;
- prazo estimado;
- validação de cobertura;
- horário no fuso `America/Sao_Paulo`;
- estado `OPEN`;
- estado `CLOSED`;
- estado `ORDERING_CLOSED`;
- configuração administrativa dos sete dias.

Configuração operacional atual registrada:

- terça-feira a domingo;
- das 18:00 às 23:00 para novos pedidos;
- segunda-feira fechada;
- zona de referência em Carapicuíba com taxa, mínimo e prazo configuráveis.

### Pagamentos

#### PIX manual

Implementado:

- criação de pedido com PIX manual;
- envio de comprovante;
- suporte a JPG, PNG e PDF;
- limite de tamanho do arquivo;
- armazenamento persistente;
- análise administrativa;
- confirmação ou recusa do comprovante;
- registro do responsável e observações.

#### Mercado Pago

Implementado:

- integração com Mercado Pago Orders API;
- PIX online;
- QR Code;
- Pix copia e cola;
- criação de ordem externa;
- identificação `ORD...` da ordem Mercado Pago;
- identificação `PAY...` do pagamento;
- webhook;
- atualização de status;
- logs de erro detalhados sem expor credenciais;
- suporte a ambiente de teste e produção;
- retorno do `order_id` na resposta da API.

O modo de produção exige credenciais de produção e deve ser testado com valor baixo antes da liberação comercial.

### Notificações

Implementado:

- WebSocket para eventos em tempo real;
- cliente recebe mudanças do próprio pedido;
- Admin recebe novos pedidos e atualizações;
- registro de tokens de dispositivo;
- integração Firebase para notificações push;
- som configurado nos canais de notificação Android.

## 6. Banco de dados

O PostgreSQL é a fonte de verdade. O schema é evoluído por migrations Alembic.

Áreas cobertas:

- usuários e autenticação;
- tokens de refresh;
- recuperação de senha;
- consentimento de privacidade;
- catálogo;
- categorias;
- produtos;
- tamanhos;
- sabores;
- preços;
- bordas;
- adicionais;
- combos;
- endereços;
- zonas de entrega;
- horários;
- configurações da loja;
- cupons;
- pedidos;
- itens de pedido;
- snapshots do pedido;
- pagamentos;
- comprovantes PIX;
- tokens de dispositivos;
- campos Mercado Pago;
- índices de performance.

As migrations são versionadas e devem ser executadas antes da inicialização da API.

## 7. Infraestrutura e deploy

### Desenvolvimento local

- Docker Compose;
- PostgreSQL local;
- API FastAPI;
- migrations Alembic;
- importação de catálogo;
- execução do Flutter com `--dart-define`.

### Produção

- API hospedada no Render;
- URL pública: `https://pizzariacampy.onrender.com`;
- PostgreSQL hospedado no Neon;
- deploy conectado ao GitHub;
- imagem Docker;
- migrations no startup/deploy;
- catálogo importável por variável de ambiente;
- imagens importáveis para Cloudinary;
- secrets configurados no ambiente do Render.

### APK e dispositivos

Foram realizadas compilações e instalações por ADB em:

- emulador Android `emulator-5554`;
- dispositivo físico Android;
- variantes `arm64-v8a`;
- variante `x86_64` para emulador;
- builds debug para validação;
- builds release para testes de produção.

Também foram tratados problemas de assinatura, cache do Gradle, arquivos `.dill`, shaders e múltiplos dispositivos ADB.

## 8. Segurança, LGPD e qualidade

Implementado:

- HTTPS em produção;
- secrets somente por variáveis de ambiente;
- nenhum token secreto no Flutter;
- senha nunca armazenada em texto puro;
- autorização administrativa no backend;
- validação server-side dos pedidos;
- proteção de escopo por usuário;
- consentimento de privacidade;
- resposta genérica na recuperação de senha;
- logs estruturados com `request_id`;
- tratamento de erros da API;
- validação de arquivos enviados;
- ausência de dados de cartão no sistema.

## 9. Testes e validações realizadas

### API

Foram criados testes para:

- segurança e regras;
- preços;
- schemas;
- recuperação de senha;
- financeiro;
- configuração do banco;
- importação do catálogo.

### Flutter

Foram criados testes para:

- modelos do menu;
- modelos do carrinho;
- shell administrativo;
- ações de pedido;
- financeiro;
- zonas de entrega;
- filtros de clientes;
- cupons;
- horários;
- cliente administrativo;
- refresh concorrente de autenticação.

### Fluxos manuais validados ao longo do desenvolvimento

- cadastro e login de cliente;
- login administrativo;
- catálogo;
- bebida;
- pizza personalizada;
- pizza de um sabor;
- pizza meio a meio;
- adicionais;
- carrinho;
- endereço salvo;
- entrega;
- retirada;
- zona de entrega;
- taxa e pedido mínimo;
- criação de pedido;
- acompanhamento;
- notificações;
- envio de comprovante PIX;
- geração de PIX Mercado Pago;
- QR Code e Pix copia e cola;
- operação administrativa de pedidos e catálogo.

## 10. Histórico resumido de evolução

1. Definição de requisitos, regras de negócio, arquitetura, wireframes e design system.
2. Criação do backend FastAPI e do aplicativo Flutter.
3. Implementação de autenticação e perfis.
4. Criação do catálogo inicial e personalização de pizzas.
5. Implementação de carrinho, checkout e pedidos.
6. Inclusão de endereços, zonas, taxas e horários.
7. Construção do Admin integrado ao aplicativo.
8. Importação do catálogo oficial e imagens Cloudinary.
9. Inclusão de cupons, notificações, perfil e financeiro operacional.
10. Implementação de recuperação de senha com Brevo.
11. Implementação de PIX manual e conferência administrativa.
12. Integração do Mercado Pago Orders API.
13. Ajustes de UX/UI, tema escuro e cards de escolha de pizza.
14. QA, hardening, testes, commits, deploys e builds Android.

O repositório registra 89 commits até o commit `ef95bdc`.

## 11. Pendências atuais

### Alta prioridade

- validar o fluxo completo do Mercado Pago em produção com pagamento real de baixo valor;
- confirmar webhook e atualização automática para `approved`;
- validar o fluxo completo no dispositivo físico em rede móvel;
- confirmar backups restauráveis do banco de produção;
- revisar monitoramento e alertas de indisponibilidade;
- reduzir consultas repetidas de preços de sabores no catálogo.

### Média prioridade

- ampliar testes de integração ponta a ponta;
- validar todos os produtos simples no carrinho;
- revisar imagens e descrições comerciais;
- concluir publicação na Google Play;
- gerar e publicar `.aab` assinado;
- revisar domínio próprio e política de privacidade publicada;
- melhorar histórico administrativo de pedidos;
- evoluir composição de combos;
- segmentar cupons;
- criar ferramentas de roteirização.

### Baixa prioridade / pós-MVP

- favoritos;
- fidelidade;
- mapas e rastreamento;
- múltiplas unidades;
- relatórios avançados;
- estoque;
- avaliações;
- campanhas e marketing automatizado.

## 12. O que já pode ser alterado sem recompilar o APK

Pelo Admin ou backend:

- categorias;
- produtos;
- descrições;
- preços;
- tamanhos;
- sabores;
- bordas;
- adicionais;
- imagens do Cloudinary;
- ativação e desativação;
- horários;
- zonas;
- taxas;
- pedido mínimo;
- prazo;
- cupons;
- status de pedidos;
- configurações operacionais.

## 13. O que exige nova compilação do APK

- alteração de telas e navegação;
- novos componentes Flutter;
- mudança de regras embutidas no aplicativo;
- permissões Android;
- plugins nativos;
- integração Firebase nativa;
- correções de segurança no cliente;
- mudança do identificador ou assinatura, quando aplicável;
- novas funcionalidades não presentes na versão instalada.

## 14. Avaliação atual

### Estado funcional

**MVP avançado e operacional para testes controlados.** O fluxo principal de cliente e Admin está implementado, e a integração PIX Mercado Pago já respondeu com sucesso em ambiente configurado.

### Estado comercial

Pode ser usado em operação limitada após a validação final de produção, principalmente:

- pagamento PIX real;
- webhook;
- backup;
- recuperação de senha;
- entrega em rede móvel;
- publicação e distribuição do APK/AAB;
- conferência dos dados comerciais do catálogo.

### Principal recomendação

Manter a arquitetura atual e evoluir incrementalmente. Não é necessário refazer o projeto neste momento. A prioridade deve ser estabilidade operacional, observabilidade, backups e validação real dos pagamentos antes de adicionar novos módulos.

## 15. Referências do projeto

- `docs/STATUS_PROJETO.md`
- `docs/ARCHITECTURE.md`
- `docs/DATABASE.md`
- `docs/BUSINESS_RULES.md`
- `docs/DESIGN_SYSTEM.md`
- `docs/OPERACAO_E_ATUALIZACOES.md`
- `pizzaria-api/README.md`
- `pizzaria-api/DEPLOY.md`
- `pizzaria-mobile/README.md`

