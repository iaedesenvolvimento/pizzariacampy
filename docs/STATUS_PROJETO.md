# Status do Projeto — Pizzaria Campy

Data da revisão: 2026-10-13

Este é o documento de referência para o estado atual do projeto. Os documentos de fases anteriores preservam decisões e especificações históricas; quando houver divergência de status, este arquivo prevalece.

## Fases

| Fase | Entrega | Situação |
|---|---|---|
| 0 | Requisitos e regras iniciais | Concluída |
| 1 | Arquitetura | Concluída como especificação |
| 2 | Fluxos de usuário | Concluída como especificação |
| 3 | Design system | Concluída como especificação |
| 4 | Wireframes | Concluída como especificação |
| 5 | Modelo de banco | Concluída e implementada com migrations |
| 6 | Regras de negócio | Concluída e implementada parcialmente no backend |
| 7–12 | Backend, autenticação, catálogo, administração e personalização | Implementadas |
| 13 | Compra completa do cliente | Concluída e validada no emulador |
| 14–21 | Histórico, pagamentos, hardening, operação e catálogo real | Implementadas com validações pendentes |
| 22 | Preços e imagens oficiais restantes | Concluída; Cloudinary e preços comerciais importados |
| 23 | Recuperação real de senha | Implementada; aguarda SMTP e migration em ambiente |
| 24 | Painel de pedidos e cupons | Implementada; aguarda validação integrada |
| 25 | Testes completos de cliente e operação | Testes automatizados aprovados; validação manual pendente |
| 31 | Publicação mobile | Pendente |
| 32 | Roadmap pós-MVP | Planejada |

## Implementado

- API FastAPI, PostgreSQL, Alembic e Docker para desenvolvimento.
- Autenticação de cliente e administrador com tokens e controle de perfil.
- Catálogo com categorias, produtos, tamanhos, sabores, bordas e adicionais.
- CRUD administrativo com edição, ativação/desativação e exclusão protegida.
- Matriz de preços de sabores por tamanho e cotação server-side.
- Horários da loja, zonas de entrega, taxas, mínimos e prazos.
- Aplicativo Flutter com cardápio, busca, personalização de pizzas e carrinho persistente.
- Checkout com retirada, entrega, PIX manual, dinheiro, cartão presencial, observações e cupom.
- Criação de pedido autenticada, painel de pedidos e transições administrativas.
- Acompanhamento individual do pedido e cancelamento antes da confirmação.

## Fases recentes

- Fase 13 — checkout, criação, acompanhamento e cancelamento: concluída e validada no emulador.
- Fase 14 — histórico de pedidos do cliente: concluída e validada no emulador.
- Fase 15 — comprovante PIX e conferência administrativa: implementada; validação ponta a ponta pendente.
- Fase 16 — gerenciamento de endereços salvos e integração com checkout: concluída e validada no emulador.
- Fase 17 — testes automatizados das regras críticas: concluída; Flutter e API aprovados.
- Fase 18 — upload real de comprovante PIX: implementada; endpoint e armazenamento persistente aprovados.
- Fase 19 — compatibilidade do seletor de arquivos Android: implementada; APK instalada no emulador.
- Fase 20 — validação segura do catálogo oficial e testes adicionais: implementada; 17 testes da API aprovados.
- Fase 22 — catálogo real: Cloudinary integrado, imagens exibidas no dispositivo físico e seis preços comerciais definidos e importados.
- Fase 25 — testes automatizados: 20 testes da API e 4 testes Flutter aprovados; validação manual aprovou login cliente/admin, catálogo, bebida, pizza personalizada, carrinho, entrega, endereço salvo, zona Ariston, taxa de R$ 7,00, mínimo de R$ 30,00, prazo de 45 minutos e criação de pedido; resumo do endereço corrigido no acompanhamento.

## Pendências do MVP

- Validar no emulador a inclusão de produtos simples, como bebidas e doces, ao carrinho.
- Manter imagens e dados oficiais do cardápio revisados após alterações comerciais.
- Ampliar testes de integração da API e testes Flutter do fluxo de compra.
- Validar manualmente no dispositivo físico o fluxo completo de cliente, PIX, entrega, retirada e produtos simples.
- Concluir no emulador/dispositivo o envio do comprovante PIX e a conferência administrativa do pagamento.

## Validação da Fase 14

Validada no emulador Android em 2026-10-10:

- acesso ao histórico pelo ícone do cardápio;
- consulta autenticada ao endpoint `GET /orders`;
- tratamento correto da lista vazia do cliente.

## Fase 15 implementada

- cliente envia o link do comprovante PIX pelo acompanhamento do pedido;
- API registra o comprovante e altera o pagamento para `UNDER_REVIEW`;
- painel administrativo exibe pedidos aguardando análise;
- administrador confirma ou recusa o pagamento, registrando o status e o responsável.

## Fase 16 implementada

- API com cadastro, listagem, edição e exclusão lógica de endereços por cliente;
- endereço padrão por cliente;
- tela “Meus endereços” no aplicativo;
- migration `20261010_0009_create_customer_addresses` criada.

Validação realizada no emulador:

- cadastro de endereço “Casa”;
- exibição do endereço salvo com bairro e cidade;
- identificação visual do endereço padrão.

## Fase 18 implementada

- endpoint multipart autenticado para comprovantes PIX;
- aceitação restrita a JPG, PNG e PDF até 10 MB;
- armazenamento persistente em volume Docker;
- seleção de arquivo no aplicativo pelo acompanhamento do pedido.

## Fase 19 implementada

- seletor Android alterado para seleção ampla, evitando a tela vazia observada com filtros customizados no `DocumentsUI`;
- validação local das extensões JPG, JPEG, PNG e PDF antes do envio;
- mensagens para cancelamento, arquivo inacessível, formato inválido e falha ao abrir o seletor;
- APK `fase19-picker` compilada e instalada com sucesso no `emulator-5554`.

Validação técnica realizada:

- `flutter analyze`: aprovado;
- testes Flutter: 4 aprovados;
- build debug Android: aprovada;
- instalação via ADB: aprovada.

A validação ponta a ponta do anexo ainda requer abrir um pedido PIX autenticado e selecionar um arquivo no emulador.

## Fase 20 implementada

- importador de catálogo com validação antes da transação;
- modo `--dry-run` para conferir o JSON sem acessar o banco;
- bloqueio de placeholders, URLs de exemplo, slugs duplicados, tipos inválidos, preços negativos e tamanhos fora da regra do MVP;
- quatro testes automatizados para o contrato do catálogo;
- suíte API ampliada de 13 para 17 testes aprovados.

## Fase 21 implementada

- planilha oficial `cardapio_pizzaria_campy.xlsx` convertida para `pizzaria-api/catalogo-real.json`;
- catálogo validado com 6 categorias, 143 produtos e 266 tamanhos com preço;
- slugs duplicados entre categorias recebem sufixo da categoria sem alterar o nome exibido;
- registros demo antigos foram desativados sem exclusão, preservando histórico;
- API pública confirmada com 6 categorias ativas e catálogo real publicado;
- opções de sabor corrigidas para retornar somente sabores vinculados ao produto;
- relatório `pizzaria-api/catalogo-real.skipped.json` registra 6 itens sem preço, que aguardam conferência comercial.

## Fase 23 implementada

- tokens de recuperação armazenados somente como hash;
- expiração configurável e uso único;
- endpoints `POST /auth/password-recovery` e `POST /auth/password-reset`;
- tela mobile permite informar o token e cadastrar a nova senha;
- envio SMTP configurável por ambiente, com resposta genérica para não revelar contas existentes.

## Fase 24 implementada

- listagem administrativa completa em `GET /admin/orders`;
- avanço de status de pedidos pelo novo módulo administrativo;
- criação, listagem e ativação/desativação de cupons no aplicativo;
- validação server-side de cupons permanece no cálculo e na criação do pedido.

### Preços definidos na Fase 22

| Produto | Tamanho | Preço |
|---|---|---:|
| A Moda do Freguês | Personalizada | R$ 50,00 |
| Três Estações | Personalizada | R$ 50,00 |
| Sucos de Caixinha | 1L | R$ 13,00 |
| Refrigerante | 2L | R$ 15,00 |
| Refrigerante Lata | 350 ml | R$ 6,00 |
| Cerveja Lata | Lata | R$ 7,00 |

## Fase 17 implementada

- teste Flutter para diferenciar pizza de bebida/bebida não personalizável;
- testes de schema para endereços obrigatórios;
- teste de schema para limitar revisão de pagamento a `CONFIRMED` ou `FAILED`.

## Validação da Fase 13

Validada no emulador Android em 2026-10-10:

- carrinho persistente com dois itens;
- checkout com retirada e PIX;
- criação do pedido e número de pedido;
- acompanhamento com status `PENDING`;
- cancelamento pelo cliente e status `CANCELLED`.

## Pendências comerciais e operacionais

- Chave PIX e instruções oficiais.
- Endereço e instruções de retirada.
- Política de cancelamento e devolução.
- Canal real de recuperação de senha.
- Horários especiais e feriados.

## Configuração operacional aplicada

- Zona `Ariston · Carapicuíba`: taxa de R$ 7,00, pedido mínimo de R$ 30,00 e prazo estimado de 45 minutos.
- Horário regular: terça-feira a domingo, das 18:00 às 23:00.
- Segunda-feira: fechado.
- Validação realizada em 2026-10-10: zona ativa no endpoint público e loja retornando `OPEN` dentro do horário.

## Publicação

- Configurar domínio, HTTPS, secrets, backups restauráveis e monitoramento.
- Criar keystore e gerar o `.aab` de release.
- Testar em faixa interna da Google Play.
- Publicar política de privacidade e revisar dados coletados.

## Pós-MVP

WebSocket para notificações em tempo real está implementado: clientes recebem mudanças de status do próprio pedido e administradores recebem novos pedidos e atualizações enquanto o app está aberto. Push em segundo plano via Firebase, favoritos, fidelidade, mapas, rastreamento, gateway de pagamento e múltiplas unidades permanecem pendentes conforme `POST_MVP_ROADMAP.md`.

## Fase J — horários e configurações administrativas

- Tela de horários padronizada com os sete dias, status textual, edição por TimePicker, validação de intervalo e salvamento individual.
- Tela de configurações organizada em dados da loja, pagamentos e retirada, com formulário, validação básica, detecção de alterações e feedback amigável.
- Backend permanece como autoridade sobre disponibilidade; endpoints, schemas, banco e regras PIX não foram alterados.

## Fase K — auditoria integrada e hardening administrativo

- Inventário integrado concluído para autenticação, navegação, Design System, API administrativa, realtime e módulos do Admin.
- Refresh de token do Dashboard consolidado no `AdminApiClient`, com proteção contra refresh concorrente.
- Autorização permanece no backend para `ADMIN` e `MANAGER`; rotas administrativas do Flutter também bloqueiam perfis sem permissão.
- `flutter analyze`, testes Flutter e build debug foram executados; validações manuais com sessão real permanecem pendentes quando não há evidência reproduzível.
- Dívidas mantidas: detalhes completos em pedidos, histórico administrativo avançado, N+1 de preços de sabores, composição avançada de combos, cupons segmentados, roteirização e QA manual ponta a ponta.

## Fase K.1 — QA final e gate de estabilidade

- Cobertura crítica ampliada para transições de pedidos, busca combinada de clientes, shell administrativo e refresh concorrente.
- Suíte Flutter: 18 testes aprovados; `flutter analyze` sem issues; build debug x86_64 aprovado.
- O `AdminApiClient` foi validado contra duas respostas 401 simultâneas: um único refresh compartilhado atualiza os tokens e repete as requisições.
- QA manual autenticado permanece `BLOQUEADO POR AMBIENTE`: o emulador está disponível, mas não há credenciais apropriadas fornecidas para testar produção sem risco.
- N+1 de preços de sabores permanece como dívida de severidade ALTA: aproximadamente uma requisição de tamanhos por produto pizza, além das consultas de produtos e preços.
- Base existente para futuro Financeiro: pedidos com totais, taxas e descontos; pagamentos com método, status, valor, comprovante PIX, revisão e notas. Nenhum módulo financeiro foi implementado.
- Gate: `GATE A — APROVADO`, com ressalva exclusiva do QA manual autenticado bloqueado por ambiente. Próximo passo recomendado: planejar a Fase L — Financeiro Admin.

## Fase L.0 — auditoria e planejamento do Financeiro Admin

Status: **EM ANÁLISE**. Nenhuma tela, rota, tabela, migration, regra de pagamento ou checkout foi alterada.

### Base financeira encontrada

- `orders` guarda subtotal, taxa de entrega, desconto, total, método, status de pagamento, cupom, troco, timestamps e endereço de entrega snapshot.
- `order_items` guarda nomes, tamanho, preço unitário, quantidade, adicionais e total da linha; sabores e adicionais possuem snapshots próprios.
- `payments` é uma entidade própria vinculada a `orders`, com método, status, valor, comprovante, revisor, data de revisão e notas.
- Cupons possuem configuração, uso acumulado e `coupon_redemptions`; o desconto é calculado no backend com `Decimal` e persistido no pedido.
- Não existem fluxo de caixa, despesas, contas a pagar/receber, custos, CMV, lucro, DRE, estorno ou conciliação.

### Limitações para o futuro Financeiro

- Não há endpoints agregados por período; listas administrativas têm limite e não servem sozinhas para métricas históricas.
- Não há audit trail próprio de alterações financeiras, além da revisão de pagamentos e histórico de status do pedido.
- Cancelamento não possui estorno automático: o status do pedido e o status do pagamento são tratados separadamente.
- A tela futura não deve exibir lucro; vendas, recebimentos e totais precisam ser semanticamente diferenciados.
- O N+1 de preços de sabores permanece restrito ao Admin de catálogo e não deve ser reutilizado para agregações financeiras.

### Recomendação

**B — o backend precisa de pequenas extensões antes do frontend.** A base atual permite planejar o Financeiro Operacional, mas exige agregações server-side, filtros temporais, definição de auditoria e política explícita para cancelamento/estorno antes da implementação visual.

## Fase L.1 — backend financeiro operacional

Status: **IMPLEMENTADO**. O frontend Financeiro permanece não implementado.

- Criado o router protegido `/api/v1/admin/finance` para summary, vendas, métodos de pagamento, PIX pendente e cancelamentos.
- Períodos usam `start_date`/`end_date` inclusivos por data comercial, convertidos de `America/Sao_Paulo` para UTC e consultados com intervalo semiaberto `[start, end)`.
- Venda operacional significa pedido não cancelado cujo pagamento não esteja `FAILED`; isso representa faturamento operacional, não recebimento confirmado.
- Agregações usam `Decimal`/`Numeric`, sem lucro, despesas, CMV, DRE, caixa ou estorno.
- Vendas são paginadas e filtráveis por método, status de pagamento e status do pedido.
- PIX diferencia `PENDING` (aguardando comprovante) de `UNDER_REVIEW` (aguardando revisão); a revisão continua no endpoint existente.
- Cancelamentos identificam explicitamente pedidos `CANCELLED` com pagamento `CONFIRMED`, sem alterar o pagamento ou simular reembolso.
- Adicionada dependência `tzdata` para garantir `America/Sao_Paulo` em ambientes sem base tzdata do sistema.
- Backend: 27 testes aprovados; Flutter: analyze e 18 testes aprovados; nenhum endpoint existente foi removido ou alterado.
- Próxima etapa possível: Fase L.2 — Dashboard Financeiro Admin.

## Fase L.2 — Dashboard Financeiro Admin

Status: **IMPLEMENTADO**. O dashboard apresenta apenas os indicadores financeiros operacionais fornecidos pelo backend L.1.

- Adicionada a rota protegida `/admin/finance` e o destino Financeiro no shell administrativo.
- A tela usa exclusivamente os endpoints `/admin/finance/summary` e `/admin/finance/sales`, sem cálculos financeiros no Flutter.
- Períodos disponíveis: Hoje, 7 dias, 30 dias e Personalizado, enviados ao backend por `start_date`/`end_date`.
- Cards exibem `gross_sales` como **Vendas operacionais**, pedidos, ticket médio e PIX pendente; não exibem lucro, saldo ou recebido.
- Incluídos descontos, taxas de entrega, pedidos cancelados, valor de pedidos cancelados, métodos de pagamento, pendências PIX e vendas recentes.
- Estados de carregamento, erro, vazio, atualização manual, acessibilidade e layout responsivo foram integrados ao Design System Admin existente.
- Não foram alterados contratos, endpoints, banco, migrations ou fluxo de revisão PIX.
- Testes Flutter adicionados para moeda, períodos, rótulos de pagamento, semântica de vendas e estados do controller.

## Fase L.3 — Vendas e Pagamentos Admin

Status: **IMPLEMENTADO COM RESSALVAS DE QA MANUAL**.

- O módulo Financeiro agora possui navegação interna entre Resumo, Vendas, PIX pendentes e Cancelamentos, sem criar novos itens principais no shell.
- Vendas usam `/admin/finance/sales`, apresentam os campos do contrato L.1, filtros server-side por método/status e paginação por `limit`/`offset`.
- PIX usa `/admin/finance/pix-pending`, diferenciando `PENDING` como aguardando comprovante de `UNDER_REVIEW` como aguardando análise.
- A revisão continua no fluxo existente de Pedidos via `/admin/payments/{payment_id}/review`; o contrato financeiro atual não retorna `payment_id`, portanto nenhum campo foi inventado nem endpoint foi alterado.
- Cancelamentos usam `/admin/finance/cancellations` e destacam `CANCELLED + CONFIRMED` como pagamento confirmado com reembolso/estorno ainda não registrado.
- Não foram adicionados status inexistentes, ações de reembolso, estorno ou operações de cozinha na área Financeiro.
- Nenhuma alteração de banco, migration ou contrato backend foi feita nesta fase.
