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
