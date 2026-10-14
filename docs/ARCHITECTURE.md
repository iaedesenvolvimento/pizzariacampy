# Arquitetura do Sistema — Pizzaria Campy

Versão: 0.1  
Status: Fase 1 — especificação concluída; implementação acompanhada em `STATUS_PROJETO.md`  
Base: `docs/docs/REQUISITOS_FASE_0.md`  
Data: 09/10/2026

## 1. Objetivo

Definir a arquitetura inicial do ecossistema da Pizzaria Campy, composto por aplicativo mobile, API e painel administrativo. O desenho atende ao MVP de uma unidade e permite evolução para múltiplas unidades sem permitir que o aplicativo ou o painel acessem o banco diretamente.

## 2. Visão geral

```text
Cliente Android/iOS                 Operador desktop/tablet
        |                                      |
        +------------ HTTPS / JSON ------------+
                         |
                   FastAPI REST
                         |
        +----------------+----------------+
        |                                 |
   Serviços de aplicação             Repositórios
        |                                 |
        +------------- PostgreSQL --------+
```

Aplicações previstas:

- `pizzaria-mobile`: Flutter/Dart, experiência do cliente.
- `pizzaria-api`: Python/FastAPI, regras de negócio, autenticação e persistência.
- `pizzaria-admin`: aplicação web responsiva para operação e administração.

O PostgreSQL permanece privado. Somente a API possui credenciais e acesso à base.

## 3. Responsabilidades

### Mobile

- Exibir home, cardápio, montagem de pizza, carrinho, checkout e acompanhamento.
- Manter estado temporário de interface e sessão local de forma segura.
- Enviar intenções e dados de entrada à API; nunca definir o preço final.
- Tratar carregamento, erro, vazio, indisponibilidade e sessão expirada.

### API

- Expor contratos REST versionados.
- Autenticar usuários e autorizar operações por perfil.
- Validar entrada, disponibilidade, horários, cobertura e transições de pedido.
- Recalcular preços no servidor dentro de uma transação antes de criar pedidos.
- Isolar regras de negócio da camada HTTP e do banco.
- Produzir logs estruturados sem dados sensíveis.

### Painel administrativo

- Consumir exclusivamente a API.
- Operar pedidos, catálogo, disponibilidade, horários, regiões, taxas e prazos.
- Exibir claramente pedidos novos e impedir ações incompatíveis com o status atual.
- Não conter regras comerciais próprias que possam divergir do backend.

## 4. Arquitetura da API

O backend será organizado por responsabilidade:

```text
pizzaria-api/
  app/
    api/             # rotas, dependências e versionamento HTTP
    core/            # configurações, segurança, logging e exceções
    models/          # modelos SQLAlchemy
    schemas/         # contratos Pydantic de entrada e saída
    repositories/    # acesso persistente à base
    services/        # casos de uso e regras de negócio
    dependencies/    # sessão de banco, usuário atual e permissões
  migrations/       # Alembic
  tests/             # unitários, integração e API
```

Fluxo de uma requisição:

```text
Router → Schema de entrada → Serviço → Repositório → PostgreSQL
  ↑             ↓              ↓           ↓
Resposta ← Schema de saída ← Regras ← Transação
```

Routers cuidam de HTTP. Serviços cuidam de casos de uso. Repositórios cuidam de persistência. Essa separação evita lógica de negócio em endpoints e widgets.

## 5. Contrato REST

Os endpoints serão publicados sob `/api/v1`. A nomenclatura inicial será:

- `/auth`: cadastro, login, refresh, logout e recuperação de senha.
- `/categories`, `/products`, `/products/{id}/options`: consulta do cardápio.
- `/addresses`: endereços do cliente autenticado.
- `/cart` e `/orders`: validação, criação, consulta e cancelamento de pedidos.
- `/business-status`: situação da loja segundo o horário do servidor.
- `/admin/*`: operações administrativas protegidas.

Respostas de erro seguirão um formato consistente, com código estável para tratamento no cliente:

```json
{
  "error": {
    "code": "ORDER_MINIMUM_NOT_REACHED",
    "message": "O pedido ainda não atingiu o valor mínimo.",
    "details": {"remaining": "10.00"},
    "request_id": "..."
  }
}
```

Valores monetários trafegam como strings decimais ou estrutura equivalente definida no contrato; nunca como `float`. A especificação detalhada será produzida na Fase 7/9.

## 6. Autenticação e autorização

- Cadastro e login retornam um access token de curta duração e um refresh token rotacionável.
- Senhas são armazenadas somente como hash seguro.
- O mobile armazena tokens em armazenamento seguro da plataforma; o painel usa mecanismo seguro compatível com sua implementação web.
- Perfis iniciais: `CUSTOMER` e `ADMIN`; `MANAGER` e `DELIVERY` ficam preparados, mas fora do MVP.
- O backend deriva o usuário do token e aplica escopo por proprietário: cliente só lê seus endereços, pedidos e pagamentos.
- Rotas administrativas exigem perfil administrativo no servidor.
- Logout invalida o refresh token. Tokens, senhas e dados de cartão não entram em logs.

Recuperação de senha dependerá do canal operacional definido nas pendências da Fase 0; o contrato será mantido desacoplado do provedor de envio.

## 7. Estado e persistência

### Mobile

- Estado de sessão, catálogo, carrinho, checkout e pedido atual será separado por feature.
- O carrinho pode ser persistido localmente para recuperação após encerramento do app, mas será revalidado pela API antes da confirmação.
- Cache local não é fonte de verdade para preço, disponibilidade, horário ou status do pedido.

### API

- PostgreSQL é a fonte de verdade dos dados comerciais e operacionais.
- SQLAlchemy será usado como camada de persistência e Alembic para migrations.
- Operações críticas de pedido e pagamento usam transação.
- Soft delete/desativação será usado para itens de catálogo associados a histórico.

## 8. Regras críticas de integridade

- O backend calcula novamente itens, adicionais, taxa, mínimo e total.
- O backend consulta o horário da loja no fuso `America/Sao_Paulo`.
- A criação do pedido falha se algum item estiver indisponível ou se a regra de cobertura tiver mudado.
- Transições de pedido serão validadas por uma máquina de estados no serviço de pedidos.
- PIX manual permanece pendente até conferência administrativa.
- Nenhum dado sensível de cartão é persistido.

## 9. Configuração e ambientes

Ambientes previstos:

- `development`: execução local, banco local e dados de teste.
- `staging`: validação integrada antes da publicação.
- `production`: HTTPS, banco dedicado, backups e segredos externos.

Configurações entram por variáveis de ambiente. O repositório conterá apenas `.env.example`, sem chaves reais. Variáveis esperadas incluem URL do banco, chave de assinatura, duração dos tokens, CORS, ambiente, URL pública da API e configurações operacionais da unidade.

O backend terá endpoint de health check que verifica a aplicação e, quando apropriado, a conectividade com o banco sem expor detalhes internos.

## 10. Segurança, erros e observabilidade

- HTTPS é obrigatório em produção.
- CORS será restrito às origens aprovadas do painel e demais clientes.
- Entrada será validada com schemas; consultas usarão ORM/parâmetros.
- Exceções internas serão convertidas em respostas seguras com `request_id`.
- Logs serão estruturados e correlacionados por requisição.
- Rate limiting e proteção adicional de endpoints de autenticação serão incorporados antes da publicação.
- Não serão registrados senha, tokens, comprovantes sensíveis ou dados completos de pagamento.

## 11. Decisões e limites do MVP

- Monólito modular na API, suficiente para uma unidade e mais simples de operar inicialmente.
- REST/JSON como integração entre clientes e backend.
- PostgreSQL como banco relacional principal.
- Sem microserviços, mapas, rastreamento, gateway de pagamento, push ou múltiplas unidades no MVP.
- Cupons permanecem fora do MVP conforme decisão da Fase 0.

## 12. Estrutura de repositório proposta

```text
apppizzaria/
  docs/
    docs/REQUISITOS_FASE_0.md
    ARCHITECTURE.md
  pizzaria-mobile/
  pizzaria-api/
  pizzaria-admin/
```

Os três projetos podem iniciar no mesmo repositório para compartilhar documentação e facilitar o MVP. A separação em repositórios independentes poderá ser avaliada quando houver necessidade operacional real.

## 13. Próxima fase

A especificação da Fase 1 foi concluída. A implementação atual e as pendências estão em `docs/STATUS_PROJETO.md`.
