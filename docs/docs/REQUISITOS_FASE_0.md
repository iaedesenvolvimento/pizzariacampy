# Documento de Requisitos — Pizzaria Campy

Versão: 0.1
Status: Fase 0 aprovada explicitamente pelo usuário
Data de aprovação: 08/10/2026

## Produto

Aplicativo Flutter para Android, API FastAPI, banco PostgreSQL e painel administrativo web. O aplicativo será preparado arquiteturalmente para iOS.

## Definições comerciais

| Item | Definição |
|---|---|
| Marca | Pizzaria Campy; logo, cores e identidade visual a definir |
| Público | Consumidores finais; pizzas tradicionais |
| Unidades | Uma no MVP, com possibilidade de expansão |
| Região | Carapicuíba, Barueri, Alphaville e Osasco, em São Paulo; cobertura específica a definir |
| Atendimento | Entrega e retirada |
| Funcionamento | Terça a domingo, das 18h à meia-noite; segunda-feira fechada |
| Novos pedidos | Das 18h até as 23h, nos dias de funcionamento |
| Categorias | Pizzas, bebidas, sobremesas e combos |
| Tamanhos | Pequena, média, grande e família; todos com 8 fatias |
| Sabores | Até 2 na pequena/média; até 4 na grande/família |
| Preço multissabor | Valor do sabor mais caro no tamanho escolhido |
| Bordas e adicionais | Cheddar, catupiry e requeijão; demais opções a definir |
| Pagamentos | PIX manual, dinheiro com troco e cartão na entrega/retirada |
| Administração | Um administrador inicial, com possibilidade de ampliar |

## RF — Requisitos Funcionais

| ID | Requisito |
|---|---|
| RF01 | Permitir cadastro, login, recuperação de senha e logout. |
| RF02 | Permitir consulta ao cardápio sem login; exigir login para finalizar pedidos. |
| RF03 | Exibir categorias, produtos, preços, opções e disponibilidade. |
| RF04 | Permitir montar pizzas com tamanho, sabores, borda, adicionais e quantidade. |
| RF05 | Permitir adicionar, editar e remover itens do carrinho. |
| RF06 | Permitir cadastrar e selecionar endereços com bairro. |
| RF07 | Oferecer entrega ou retirada no checkout. |
| RF08 | Calcular taxa e pedido mínimo conforme a região do endereço. |
| RF09 | Bloquear entrega fora da cobertura e oferecer retirada. |
| RF10 | Permitir selecionar pagamento, informar troco e enviar comprovante de PIX. |
| RF11 | Exibir o detalhamento dos valores antes da confirmação. |
| RF12 | Permitir acompanhar o status e consultar o histórico de pedidos. |
| RF13 | Permitir cancelamento pelo cliente antes da confirmação da pizzaria. |
| RF14 | Permitir ao administrador aceitar pedidos e atualizar seu andamento. |
| RF15 | Permitir gerenciar catálogo, preços, regiões, taxas, mínimos, horários e prazos estimados. |
| RF16 | Permitir desativar temporariamente produtos, sabores, bordas e adicionais. |
| RF17 | Permitir conferir manualmente o PIX e registrar sua situação. |
| RF18 | Exibir a situação da loja e informar o horário limite para novos pedidos. |

## RNF — Requisitos Não Funcionais

| ID | Requisito |
|---|---|
| RNF01 | Aplicativo Flutter inicialmente para Android, preparado arquiteturalmente para iOS. |
| RNF02 | Mobile e painel acessam os dados exclusivamente pela API FastAPI. |
| RNF03 | PostgreSQL mantém os dados; valores monetários utilizam DECIMAL/NUMERIC. |
| RNF04 | Senhas recebem hash seguro; credenciais ficam fora do código. |
| RNF05 | Autorização distingue cliente e administrador; clientes acessam somente seus próprios dados. |
| RNF06 | Comunicação em produção utiliza HTTPS; dados sensíveis de cartão não são armazenados. |
| RNF07 | Interface apresenta carregamento, erros, estados vazios e feedback das ações. |
| RNF08 | Interface oferece contraste, rótulos acessíveis e áreas de toque adequadas. |
| RNF09 | Painel funciona em desktop, notebook e tablet. |
| RNF10 | Regras comerciais ficam fora da interface, com validação no backend. |
| RNF11 | Logs não registram senhas, tokens ou dados sensíveis de pagamento. |
| RNF12 | Fluxos críticos possuem testes relevantes e documentação de execução. |

## RN — Regras de Negócio

| ID | Regra |
|---|---|
| RN01 | Novos pedidos são aceitos de terça a domingo, das 18h até as 23h, no horário de São Paulo. |
| RN02 | Após o encerramento dos pedidos, o cardápio continua disponível para consulta e os pedidos existentes continuam sendo atendidos. |
| RN03 | Todos os tamanhos têm 8 fatias. Pequena/média permitem até 2 sabores; grande/família, até 4. |
| RN04 | O preço base de uma pizza multissabor corresponde ao sabor mais caro no tamanho selecionado. |
| RN05 | Bordas e adicionais têm preços configuráveis e compõem o valor do item. |
| RN06 | O backend recalcula os valores e valida disponibilidade antes de criar o pedido. |
| RN07 | A entrega depende da cobertura do endereço; taxa e mínimo variam por região. |
| RN08 | Retirada não possui taxa nem valor mínimo. |
| RN09 | GPS, mapas e rastreamento não fazem parte do MVP. |
| RN10 | Todo pedido exige aceite do administrador antes do preparo. |
| RN11 | O cliente pode cancelar pelo aplicativo antes da confirmação; depois, deve entrar em contato. |
| RN12 | Comprovante de PIX exige conferência manual; seu envio não comprova pagamento automaticamente. |
| RN13 | Dinheiro permite informar necessidade de troco; cartão é pago na entrega ou retirada. |
| RN14 | Prazos estimados de entrega e retirada são configuráveis pelo administrador. |
| RN15 | Opções desativadas não podem compor novos pedidos, preservando o histórico existente. |
| RN16 | Cupons ficam para depois do MVP. |

## Critérios de aceite

- Autenticação: um visitante consulta o cardápio, mas precisa entrar na conta para finalizar o pedido.
- Montagem: selecionar sabores acima do limite do tamanho é impedido.
- Preço: uma pizza com sabores de R$ 45 e R$ 50 no mesmo tamanho tem preço base de R$ 50, antes de bordas e adicionais.
- Entrega: um endereço coberto recebe a taxa e o mínimo configurados para sua região; abaixo do mínimo, a finalização informa quanto falta.
- Cobertura: um endereço não atendido não permite entrega e apresenta retirada como alternativa.
- Retirada: não adiciona taxa nem exige valor mínimo.
- Horários: o backend impede novos pedidos fora da janela permitida, independentemente do relógio do celular.
- PIX: o comprovante fica disponível ao administrador, sem marcar o pagamento automaticamente como confirmado.
- Pedidos: o preparo depende do aceite do administrador; o cliente acompanha as mudanças de status.
- Cancelamento: antes da confirmação, o cliente cancela pelo aplicativo; depois, recebe orientação para contato.
- Disponibilidade: uma opção desativada não pode ser comprada, inclusive se já estiver no carrinho.
- Segurança: um cliente não consegue consultar pedidos de outro cliente nem utilizar funções administrativas.

## Escopo do MVP

Inclui autenticação, home, cardápio, busca, personalização de pizzas, carrinho, endereços, entrega, retirada, checkout, pagamentos definidos, acompanhamento, histórico e painel para gestão do catálogo e da operação.

Ficam para evolução futura: cupons, favoritos, fidelidade, notificações push, mapas, rastreamento, gateway de pagamento e múltiplas unidades.

## Pendências antes do lançamento

- Endereço da unidade e contato de atendimento.
- Bairros ou critérios exatos de cobertura, taxas e mínimos por região.
- Cardápio, preços, dimensões dos tamanhos e opções disponíveis.
- Identidade visual e imagens dos produtos.
- Chave PIX, instruções de pagamento e bandeiras de cartão aceitas.
- Prazos iniciais de entrega e retirada.
- Procedimento de devolução para pedidos pagos e cancelados.
- Canal de recuperação de senha.
- Definição exata do corte das 23h e da base do pedido mínimo — se considera somente produtos ou também a taxa.

## Estado do projeto — checkpoint

- Fase original: Fase 0 — Descoberta e Requisitos.
- Status documental: concluída e aprovada explicitamente pelo usuário.
- Status atual do software: consulte `docs/STATUS_PROJETO.md`; a implementação já avançou para backend, mobile e painel.
- Arquivo principal: docs/REQUISITOS_FASE_0.md.
- Decisões arquiteturais: Flutter, FastAPI, PostgreSQL e painel administrativo web; acesso aos dados exclusivamente pela API. Detalhamento reservado à Fase 1.
- Migrations e endpoints: implementados após esta fase documental.
- Testes: os testes críticos de integração ainda são pendentes.
- Problemas conhecidos: pendências comerciais e operacionais listadas acima.
- Próxima referência: `docs/STATUS_PROJETO.md`.

As pendências permanecem abertas; a aprovação deste documento não atribui valores ou regras ainda não definidos. Não avançar automaticamente para outras fases.
