# Regras de Negócio — Pizzaria Campy

Versão: 0.1  
Status: Fase 6 — regras formalizadas e parcialmente implementadas  
Base: `docs/docs/REQUISITOS_FASE_0.md`, `docs/ARCHITECTURE.md` e `docs/DATABASE.md`  
Data: 09/10/2026

## 1. Objetivo e autoridade

Este documento formaliza as regras comerciais e operacionais do MVP. A API é a autoridade final para disponibilidade, horário, preço, taxa, pedido e pagamento. O aplicativo e o painel apenas apresentam e enviam intenções; não podem substituir as validações do backend.

Quando uma regra depender de uma definição comercial ainda pendente, ela aparece explicitamente na seção de pendências e não deve ser presumida em produção.

## 2. Catálogo

### 2.1 Categorias e produtos

- O catálogo inicial contém pizzas, bebidas, sobremesas e combos.
- Cada produto pertence a uma categoria e possui nome, descrição, imagem opcional e disponibilidade.
- Produto, tamanho, sabor, borda ou adicional inativo não pode ser usado em um pedido novo.
- Desativação não remove registros associados a pedidos já criados.
- Alterações futuras de nome ou preço não modificam o snapshot de um pedido histórico.
- Produtos sem preço válido ou sem configuração obrigatória não ficam disponíveis para compra.

### 2.2 Tamanhos

- Tamanhos iniciais: pequena, média, grande e família.
- Todos possuem 8 fatias no MVP.
- Pequena e média permitem até 2 sabores.
- Grande e família permitem até 4 sabores.
- O limite é validado no backend, inclusive quando o item veio de um carrinho persistido.
- O tamanho selecionado deve estar ativo e configurado para o produto.

### 2.3 Sabores

- Um item de pizza precisa de pelo menos um sabor.
- O mesmo sabor não deve ser repetido no mesmo item, salvo decisão comercial futura.
- A ordem dos sabores pode ser preservada para exibição, mas não altera o preço.
- Sabores desativados não podem ser adicionados a novos pedidos.
- O item registra o nome e preço de referência do sabor no momento da compra.

### 2.4 Bordas e adicionais

- Borda é opcional, salvo configuração específica de um produto.
- Adicionais são opcionais e podem ter quantidade positiva.
- Cada preço é configurável pelo administrador e validado pelo backend.
- Opções desativadas não podem ser adicionadas, mesmo que estejam no carrinho local.
- O preço da borda e dos adicionais compõe o preço final do item.

## 3. Motor de preços

### 3.1 Princípios

- O preço enviado pelo cliente é apenas informativo e nunca é confiável.
- A API recarrega as configurações atuais e recalcula todos os itens antes de criar o pedido.
- O cálculo ocorre em uma função/serviço central, sem lógica duplicada na UI ou nos routers.
- Valores são calculados com precisão decimal e persistidos como `NUMERIC(12,2)`.
- A resposta deve conter detalhamento suficiente para o cliente entender o total.

### 3.2 Entradas mínimas

O serviço recebe:

- produto;
- tamanho;
- sabores;
- borda;
- adicionais e quantidades;
- quantidade do item;
- modalidade de recebimento;
- endereço/zona quando for entrega;
- cupom somente quando o recurso for liberado em fase futura.

### 3.3 Regra de preço multissabor

Para uma pizza com mais de um sabor, o preço base é o maior preço entre os sabores selecionados para o tamanho escolhido.

```text
preço_base = máximo(preço_do_sabor_1, preço_do_sabor_2, ...)
preço_unitário = preço_base + preço_borda + soma(preços_adicionais)
total_item = preço_unitário × quantidade
```

Exemplo:

| Sabor | Preço no tamanho |
|---|---:|
| Calabresa | R$ 45,00 |
| Portuguesa | R$ 50,00 |

Uma pizza meio a meio custa R$ 50,00 antes de borda e adicionais. O app deve exibir claramente `1/2 Calabresa · 1/2 Portuguesa`, mas não dividir o preço proporcionalmente.

### 3.4 Matriz de preços necessária

Como os preços de sabores variam por tamanho, a implementação precisa de uma relação explícita entre sabor, tamanho e preço, por exemplo uma tabela de preços de sabor por tamanho ou uma estrutura equivalente. O modelo de `DATABASE.md` deve ser refinado antes da migration inicial para suportar essa regra sem preço hardcoded.

### 3.5 Arredondamento e total

- Cada valor monetário é arredondado conforme a precisão de centavos somente na fronteira definida pelo serviço.
- O total do pedido é a soma dos itens mais taxa menos descontos válidos.
- Nunca recalcular o total com `float`.
- O backend retorna subtotal, taxa, desconto, total e detalhamento por item.

## 4. Carrinho

- O cliente pode adicionar, editar, remover e alterar quantidade.
- Quantidade deve ser inteira e maior que zero; existe um limite operacional configurável a definir antes do lançamento.
- Limpar o carrinho exige confirmação.
- O carrinho local pode sobreviver ao fechamento do aplicativo.
- Antes do checkout e novamente antes da confirmação, o backend revalida itens, opções, preços e disponibilidade.
- Se um item mudou, o cliente deve ser informado e confirmar o novo resumo.
- Carrinho não é pedido e não reserva estoque ou disponibilidade.

## 5. Horários e situação da loja

### 5.1 Janela operacional

- Atendimento: terça a domingo, das 18:00 à 00:00, no fuso `America/Sao_Paulo`.
- Segunda-feira: fechada.
- Novos pedidos: permitidos das 18:00 até 23:00 nos dias de funcionamento.
- Após 23:00, o cardápio continua consultável, mas novos pedidos não podem ser confirmados.
- Pedidos já aceitos continuam sendo processados após o encerramento de novos pedidos.
- O horário exibido e a validação usam o relógio do backend, não o relógio do celular.

### 5.2 Estados

- `OPEN`: loja disponível para novos pedidos.
- `CLOSED`: loja fechada; exibir próximo horário quando conhecido.
- `ORDERING_CLOSED`: loja em funcionamento, mas a janela de novos pedidos terminou.
- Uma exceção operacional futura pode suspender pedidos sem alterar o horário cadastrado.

O estado deve ser consultado pela API e mostrado em Home, Cardápio e Checkout.

## 6. Entrega e retirada

### 6.1 Modalidade

- O cliente escolhe `DELIVERY` ou `PICKUP`.
- Retirada não possui taxa de entrega nem valor mínimo.
- Entrega exige endereço válido e cobertura confirmada.
- O endereço selecionado pertence ao cliente autenticado.

### 6.2 Cobertura

- No MVP, a cobertura é baseada em cidade e bairro configurados pelo administrador.
- Zona inativa ou não encontrada não atende entrega.
- Endereço fora da cobertura não permite finalizar como entrega.
- Quando possível, a interface oferece retirada como alternativa direta.
- A zona, taxa, mínimo e prazo são revalidados no momento da confirmação.

### 6.3 Taxa, mínimo e prazo

- Cada zona ativa possui taxa e prazo estimado configuráveis.
- A taxa de entrega entra no total somente para `DELIVERY`.
- O pedido mínimo é aplicado somente à modalidade de entrega.
- O pedido abaixo do mínimo não pode ser confirmado; o cliente deve ver quanto falta.
- A base exata do mínimo permanece pendente: produtos/subtotal ou total antes da taxa.
- O prazo mostrado é estimativa e não garantia; alterações operacionais devem ser comunicadas.

## 7. Checkout

Antes da confirmação, a API deve validar na mesma operação lógica:

1. sessão e autorização do cliente;
2. situação da loja;
3. validade dos itens e opções;
4. limites de sabores e quantidades;
5. modalidade de recebimento;
6. cobertura, taxa, mínimo e prazo;
7. método de pagamento e dados condicionais;
8. preços e total recalculados.

Se qualquer validação falhar, nenhum pedido parcial deve ser criado. O cliente recebe erro acionável e pode corrigir o ponto indicado.

## 8. Pagamentos

### 8.1 PIX manual

- O cliente recebe a chave/instruções configuradas pela operação.
- O comprovante pode ser anexado conforme a estratégia definida.
- Enviar comprovante não confirma o pagamento.
- O pagamento inicia como `PENDING` ou `UNDER_REVIEW` e depende de conferência administrativa.
- O sistema registra quem conferiu, quando e qual decisão tomou.
- Chaves PIX e instruções não devem ser hardcoded no aplicativo.

### 8.2 Dinheiro

- O cliente pode informar para quanto precisa de troco.
- O valor de troco deve ser positivo e, quando informado, maior ou igual ao total do pedido.
- A conferência e entrega do troco ocorrem na operação física.
- O pagamento não é considerado confirmado apenas pela informação do cliente.

### 8.3 Cartão

- O pagamento ocorre na entrega ou retirada.
- O aplicativo não coleta nem armazena dados sensíveis do cartão no MVP.
- O pedido pode permanecer pendente até confirmação operacional.
- Integração com gateway fica fora do escopo atual.

## 9. Ciclo de vida do pedido

### 9.1 Status

| Status | Significado |
|---|---|
| `PENDING` | Pedido criado e aguardando aceite da pizzaria |
| `CONFIRMED` | Pedido aceito pela operação |
| `PREPARING` | Produção iniciada |
| `READY` | Pronto para retirada ou saída |
| `OUT_FOR_DELIVERY` | Saiu para entrega |
| `DELIVERED` | Entregue ou retirado |
| `CANCELLED` | Cancelado conforme regra |

### 9.2 Transições permitidas

```text
PENDING → CONFIRMED
PENDING → CANCELLED
CONFIRMED → PREPARING
CONFIRMED → CANCELLED (quando autorizado pela operação)
PREPARING → READY
PREPARING → CANCELLED (situação excepcional e registrada)
READY → OUT_FOR_DELIVERY (entrega)
READY → DELIVERED (retirada)
OUT_FOR_DELIVERY → DELIVERED
```

Não são permitidos retrocessos automáticos, por exemplo `DELIVERED → PREPARING`. Toda transição registra usuário/evento, data, status anterior, novo status e motivo quando aplicável.

### 9.3 Regras por modalidade

- Entrega: `READY → OUT_FOR_DELIVERY → DELIVERED`.
- Retirada: `READY → DELIVERED` após entrega ao cliente.
- O backend rejeita transições incompatíveis com a modalidade.
- O cliente visualiza somente pedidos próprios.
- O administrador pode cancelar conforme permissão e deve informar motivo quando exigido.

## 10. Cancelamento

- O cliente pode cancelar enquanto o pedido estiver `PENDING`, antes do aceite da pizzaria.
- Após `CONFIRMED`, o aplicativo não garante cancelamento automático; orienta contato com a pizzaria.
- O cliente não cancela pedido `DELIVERED`.
- Cancelamento registra motivo, ator, horário e status anterior.
- Pedido com PIX enviado pode exigir análise e devolução manual conforme política operacional.
- O cancelamento não apaga o pedido nem seus itens históricos.

## 11. Disponibilidade e operação

- Administrador pode desativar produto, categoria, tamanho, sabor, borda, adicional ou zona.
- Desativar impede novas compras, mas não altera pedidos existentes.
- Itens do carrinho são revalidados antes da criação do pedido.
- Uma configuração incompleta deve retirar a opção da compra e indicar indisponibilidade, não produzir preço parcial.
- Alteração de disponibilidade não deve apagar imagens, nomes ou snapshots históricos.

## 12. Cupons e descontos

- Cupons estão fora do MVP.
- Não criar campos ou telas funcionais de cupom no cliente até a regra ser aprovada.
- Quando implementado, o backend deverá validar validade, ativo, mínimo, limite total, limite por cliente e tipo de desconto.
- O frontend nunca será autoridade para aplicar desconto.

## 13. Autorização e dados

- Cliente pode consultar e alterar somente sua própria conta, endereços, carrinho lógico e pedidos.
- Administrador pode operar catálogo, horários, zonas, pagamentos e pedidos conforme seu perfil.
- Dados administrativos não são expostos a clientes.
- Logs não registram senha, tokens ou dados sensíveis de cartão.
- Toda ação administrativa relevante deve ser rastreável por usuário e horário.

## 14. Critérios de aceite críticos

- Uma pizza pequena com dois sabores é aceita; uma terceira seleção é bloqueada.
- Uma pizza grande pode ter até quatro sabores; a quinta é bloqueada.
- Para sabores de R$ 45,00 e R$ 50,00 no mesmo tamanho, a base é R$ 50,00.
- Borda e adicionais alteram o preço unitário e o total.
- Item desativado no intervalo entre carrinho e checkout impede a confirmação e pede revisão.
- Entrega fora da zona é bloqueada e retirada é oferecida quando disponível.
- Retirada não cobra taxa nem aplica mínimo.
- Pedido abaixo do mínimo de entrega informa o valor restante.
- Após 23:00, a consulta continua disponível, mas novos pedidos são rejeitados pelo backend.
- Pedido depende de aceite administrativo antes de iniciar preparo.
- Cliente não acessa pedido de outro cliente.
- Pedido entregue não retorna para preparo.

## 15. Pendências e decisões necessárias

- Matriz completa de preços por sabor e tamanho.
- Definição da base do pedido mínimo.
- Limite máximo de itens/quantidades por pedido.
- Endereço e instruções de retirada.
- Prazos padrão por zona e retirada.
- Política de cancelamento e devolução do PIX.
- Identificador de login e canal de recuperação de senha.
- Horário especial em feriados e exceções de fechamento.

## 16. Próxima fase

As regras críticas estão implementadas no backend; validações restantes e decisões comerciais estão em `docs/STATUS_PROJETO.md`.
