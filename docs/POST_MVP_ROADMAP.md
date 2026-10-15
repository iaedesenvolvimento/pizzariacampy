# Roadmap Pós-MVP

Status: Fase 32 — notificações em tempo real em implementação

Este documento organiza evoluções somente depois que o MVP estiver publicado, monitorado e estável.

## Critérios de entrada

- API e aplicativo sem falhas críticas abertas.
- Backup e restauração do PostgreSQL testados.
- Logs, métricas e alertas operacionais ativos.
- Pagamentos manuais conciliados pela operação.
- Pedidos de retirada e entrega funcionando em produção.
- Consentimento e política de privacidade revisados antes de analytics, push e avaliações.

## Ordem recomendada

### 1. Retenção e comunicação

- WebSocket implementado para alertas em tempo real enquanto o app está aberto.
- Cliente recebe mudanças de status do próprio pedido.
- Admin recebe novos pedidos e alterações de status no painel.
- Push notifications via Firebase para mudança de status e confirmação quando o app estiver fechado (pendente).
- Repetir pedido a partir do histórico, sempre revalidando preço, disponibilidade e horário.
- Favoritos para produtos e combinações frequentes.

Dependências: provedor de push, preferências de notificação e consentimento do usuário.

### 2. Relacionamento

- Programa de fidelidade com regras de acúmulo, expiração e estorno.
- Indicação com antifraude e limites por usuário.
- Avaliações vinculadas a pedidos entregues/concluídos.

Dependências: regras comerciais aprovadas, moderação, auditoria e proteção contra abuso.

### 3. Operação integrada

- Integração com WhatsApp para atendimento e notificações.
- Impressão automática de pedidos em impressora homologada.
- Gestão de entregadores e atribuição de rotas.

Dependências: provedor externo, equipamentos, controle de acesso e fallback manual.

### 4. Dados e logística

- Analytics com eventos minimizados e consentidos.
- Mapas apenas para apoio operacional.
- Rastreamento de entrega somente com privacidade, retenção e opt-in definidos.

Dependências: política de dados, custos de mapas, geolocalização e impacto no suporte.

## Regras de evolução

- Cada recurso entra em uma fase própria, com contrato de API, migration, testes e rollback.
- Nenhuma funcionalidade pós-MVP altera preço, pedido ou pagamento sem validação no backend.
- Dados pessoais e localização devem ter finalidade, retenção e exclusão documentadas.
- Integrações externas devem possuir timeout, retry limitado, idempotência e fallback operacional.

## Fora desta fase

Fidelidade, avaliação, WhatsApp, impressão, analytics, mapas e rastreamento continuam fora desta etapa. O push em segundo plano depende da configuração do Firebase.

## Próxima fase

A Fase 32 está concluída como roadmap. Evoluções futuras devem ser selecionadas a partir deste documento após a estabilidade do MVP.
