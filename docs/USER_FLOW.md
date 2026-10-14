# Fluxos de Usuário — Pizzaria Campy

Versão: 0.1  
Status: Fase 2 — UX e Fluxos especificados e parcialmente implementados  
Base: `docs/docs/REQUISITOS_FASE_0.md` e `docs/ARCHITECTURE.md`  
Data: 09/10/2026

## 1. Objetivo

Definir a jornada do cliente no aplicativo e os fluxos operacionais essenciais do MVP. Este documento orienta os wireframes e o design da interface, mas não implementa telas ou regras de negócio.

## 2. Princípios da jornada

- Permitir consultar o cardápio sem cadastro.
- Deixar preço, disponibilidade, taxa e próximo passo visíveis.
- Solicitar login somente no momento necessário: finalização do pedido.
- Permitir voltar e editar escolhas sem perder o carrinho.
- Informar a causa do erro e uma ação de recuperação.
- Usar o backend como fonte de verdade para horário, preço, disponibilidade e status.
- Não bloquear o cliente em uma única forma de atendimento quando a retirada for possível.

## 3. Jornada principal

```text
Splash
  → Home
  → Cardápio
  → Produto
  → Personalização
  → Carrinho
  → Entrega ou retirada
  → Endereço (se entrega)
  → Pagamento
  → Revisão
  → Confirmação
  → Acompanhamento
  → Histórico
```

### 3.1 Splash

**Objetivo:** iniciar o aplicativo e recuperar contexto mínimo.

**Conteúdo:** identidade da Pizzaria Campy e indicador de carregamento.

**Ações:** verificar sessão local, carregar configuração mínima e consultar situação da loja.

**Estados:**

- Carregando: exibir indicador sem permitir ações duplicadas.
- Sessão válida: seguir para Home.
- Sem sessão: seguir para Home como visitante.
- Falha de rede: seguir para Home com aviso de indisponibilidade, quando houver dados locais utilizáveis.

**Navegação:** não retornar para o Splash após a inicialização.

### 3.2 Home

**Objetivo:** orientar rapidamente para começar um pedido.

**Conteúdo:** situação da loja, ação principal para ver cardápio, categorias, destaques e resumo do carrinho quando houver itens.

**Ações:** abrir cardápio, buscar produto, selecionar categoria, abrir carrinho, acessar conta e acompanhar pedido ativo.

**Estados:**

- Loja aberta: destacar ação de pedir.
- Loja fechada: informar “Fechado” e próximo horário; permitir consulta do cardápio e ocultar/desabilitar confirmação de novos pedidos.
- Catálogo vazio: explicar que os produtos ainda não estão disponíveis e oferecer atualização.
- Erro: mostrar mensagem curta, tentar novamente e manter acesso a áreas já disponíveis.
- Carregando: usar placeholders sem deslocamentos bruscos.

### 3.3 Cardápio e busca

**Objetivo:** encontrar um produto com o mínimo de esforço.

**Conteúdo:** categorias, busca, filtros simples, cards com imagem, nome, descrição curta, preço inicial e disponibilidade.

**Ações:** trocar categoria, pesquisar, abrir produto, adicionar produto simples e abrir personalização de pizza.

**Estados:**

- Carregando: skeleton dos cards.
- Resultado: listar produtos ordenados conforme configuração do administrador.
- Sem resultados: informar o termo pesquisado e oferecer limpar busca.
- Categoria vazia: informar indisponibilidade temporária e permitir escolher outra categoria.
- Produto indisponível: exibir visualmente desativado e impedir adição.
- Falha: oferecer tentar novamente sem apagar a busca.

**Regra de navegação:** voltar preserva categoria, busca e posição aproximada da lista quando possível.

### 3.4 Detalhes e personalização da pizza

**Objetivo:** montar um item válido e compreender seu preço.

**Conteúdo:** imagem, nome, descrição, seleção de tamanho, sabores, borda, adicionais, quantidade, observação e preço atualizado.

**Fluxo:**

```text
Escolher tamanho
  → Escolher sabor(es)
  → Escolher borda
  → Escolher adicionais
  → Definir quantidade
  → Revisar preço
  → Adicionar ao carrinho
```

**Ações:** avançar, voltar, remover seleção, alterar quantidade e adicionar ao carrinho.

**Feedback obrigatório:** mostrar limite de sabores e representar claramente escolhas como “1/2 Calabresa” e “1/2 Portuguesa”.

**Estados:**

- Seleção incompleta: destacar o próximo campo obrigatório.
- Limite atingido: impedir nova seleção e explicar o limite do tamanho.
- Opção indisponível: desabilitar a opção e explicar quando aplicável.
- Revalidação falhou: informar que o item mudou e pedir revisão antes de adicionar.
- Sucesso: confirmar adição e oferecer continuar comprando ou ir ao carrinho.

O preço exibido é uma estimativa de interface. O valor definitivo será recalculado pela API no checkout.

### 3.5 Carrinho

**Objetivo:** revisar itens antes do checkout.

**Conteúdo:** itens, personalização resumida, quantidade, preço unitário, subtotal, descontos quando futuramente aplicável, taxa estimada quando disponível e total.

**Ações:** editar item, alterar quantidade, remover item, limpar carrinho, continuar comprando e iniciar checkout.

**Estados:**

- Vazio: mensagem orientadora, ação para ver cardápio e nenhuma ação de checkout.
- Item desatualizado: identificar item alterado ou indisponível e exigir revisão.
- Carregando recálculo: bloquear confirmação duplicada e mostrar atualização do total.
- Erro de recálculo: manter itens locais, informar o problema e permitir tentar novamente.

**Confirmação destrutiva:** limpar carrinho pede confirmação e informa que os itens serão removidos.

### 3.6 Entrega ou retirada

**Objetivo:** escolher como receber o pedido.

**Conteúdo:** duas opções explícitas, resumo do subtotal, prazo estimado e aviso sobre taxa/mínimo.

**Ações:** escolher entrega, escolher retirada, avançar e voltar ao carrinho.

**Estados:**

- Entrega: exigir endereço coberto e calcular taxa/mínimo.
- Retirada: remover taxa e não exigir valor mínimo.
- Loja fechada: manter consulta, mas impedir confirmação fora da janela permitida.
- Cobertura indisponível: explicar que a entrega não está disponível e oferecer retirada.

### 3.7 Endereço

**Objetivo:** selecionar ou cadastrar o local de entrega.

**Conteúdo:** endereços salvos, formulário com identificação, rua, número, complemento, referência, bairro, cidade e observação.

**Ações:** selecionar endereço, cadastrar, editar, remover endereço não utilizado e voltar ao método de recebimento.

**Estados:**

- Sem endereços: apresentar formulário diretamente e explicar os campos obrigatórios.
- Bairro não coberto: impedir entrega e oferecer retirada.
- Taxa/mínimo alterados: atualizar o resumo e destacar a mudança.
- Endereço inválido: apontar o campo específico sem apagar os demais.
- Falha ao salvar: manter dados preenchidos para nova tentativa.

### 3.8 Pagamento

**Objetivo:** escolher a forma de pagamento e informar dados necessários à operação.

**Conteúdo:** PIX manual, dinheiro e cartão na entrega/retirada; instruções condicionais e total final.

**Ações:** selecionar pagamento, informar troco para dinheiro, anexar comprovante PIX quando aplicável, revisar pedido e avançar.

**Estados:**

- PIX: mostrar chave/instruções e informar que o comprovante será conferido manualmente.
- Dinheiro: mostrar campo “troco para” quando necessário.
- Cartão: informar que o pagamento ocorre na entrega ou retirada; não solicitar dados do cartão.
- Comprovante inválido ou upload falho: informar o problema e permitir reenviar.
- Falha de validação: voltar ao campo responsável sem descartar o pedido.

### 3.9 Revisão e confirmação

**Objetivo:** permitir conferência antes de criar o pedido.

**Conteúdo:** itens, quantidades, endereço ou retirada, pagamento, observações, subtotal, taxa, mínimo e total.

**Ações:** editar cada seção, confirmar pedido e cancelar a operação.

**Estados:**

- Enviando: desabilitar o botão para evitar pedidos duplicados.
- Sucesso: exibir número do pedido e ir para confirmação.
- Item indisponível: destacar item afetado e retornar à edição.
- Horário encerrado: explicar que novos pedidos não são aceitos e preservar o carrinho.
- Preço ou taxa alterados: mostrar novo resumo e pedir nova confirmação.
- Erro desconhecido: usar `request_id` apenas para suporte, sem expor detalhes técnicos.

### 3.10 Pedido confirmado e acompanhamento

**Objetivo:** confirmar que o pedido foi recebido e reduzir incerteza.

**Conteúdo:** número do pedido, status atual, etapas, itens, total, forma de pagamento, endereço/retirada e prazo estimado.

**Linha de status:**

```text
PENDING → CONFIRMED → PREPARING → READY → OUT_FOR_DELIVERY → DELIVERED
```

Para retirada, o fluxo pode omitir `OUT_FOR_DELIVERY`. O status `CANCELLED` deve ser exibido como encerramento com motivo disponível quando apropriado.

**Atualização:** consultar novamente ao abrir a tela e atualizar por mecanismo definido na implementação; a ausência de atualização em tempo real não deve esconder o último status confirmado.

**Estados:**

- Carregando pedido: mostrar estrutura da tela.
- Pedido não encontrado: informar que não foi possível localizar e oferecer histórico/suporte.
- Cancelado: explicar situação e orientar contato quando necessário.
- Falha de atualização: manter último status e oferecer tentar novamente.

## 4. Fluxos de autenticação

### 4.1 Cadastro

```text
Login/Finalizar pedido → Criar conta → Preencher dados → Validar → Conta criada → Retornar ao fluxo original
```

O formulário deve validar campos localmente para feedback imediato e novamente na API. Após cadastro, o cliente retorna ao carrinho/checkout quando esse era o ponto de entrada.

### 4.2 Login

```text
Entrar → Informar credenciais → Autenticar → Home ou retorno ao checkout
```

Falhas devem indicar credenciais inválidas sem revelar se um e-mail está cadastrado. Sessão expirada deve oferecer login novamente e preservar o carrinho local.

### 4.3 Recuperação de senha

```text
Esqueci minha senha → Informar contato → Receber instruções → Definir nova senha → Login
```

O canal de envio ainda depende de decisão operacional. A interface deve exibir uma mensagem neutra mesmo quando o contato não existir.

### 4.4 Logout

Solicitar confirmação se houver pedido em acompanhamento ou alterações não finalizadas. Encerrar sessão sem apagar o carrinho local, salvo decisão posterior de produto.

## 5. Fluxos de conta

### Histórico de pedidos

Exibir pedidos recentes com número, data, total e status. Estado vazio orienta o cliente para o cardápio. Abrir um pedido mostra o mesmo resumo do acompanhamento. Repetir pedido fica fora do MVP.

### Perfil

Permitir visualizar e editar dados básicos, acessar endereços, recuperar senha e sair. Erros de salvamento preservam os valores digitados.

### Endereços

Listar, adicionar, editar e remover endereços. A validação de cobertura ocorre ao escolher entrega e novamente na confirmação do pedido.

## 6. Fluxos de cancelamento e suporte

- Antes de `CONFIRMED`: o cliente pode solicitar cancelamento no aplicativo, com confirmação explícita.
- Depois de `CONFIRMED`: ocultar cancelamento automático e orientar contato com a pizzaria.
- Pedido já entregue: não oferecer cancelamento.
- Pedido com PIX enviado: informar que a análise/devolução depende da conferência administrativa.
- Falha de rede durante confirmação: consultar o pedido antes de permitir nova tentativa, evitando duplicidade.

## 7. Fluxos administrativos relacionados ao cliente

```text
Novo pedido → Administrador revisa → Aceitar/Cancelar → Preparar → Pronto
                                      ↓
                         Entrega: Saiu → Entregue
                         Retirada: Cliente retirou → Entregue
```

O painel deve destacar pedidos `PENDING`, confirmar transições permitidas e pedir justificativa quando uma operação exigir cancelamento. O cliente acompanha somente os dados autorizados do próprio pedido.

## 8. Matriz de estados globais

| Situação | Feedback | Ação principal |
|---|---|---|
| Carregando | Indicador ou skeleton | Aguardar |
| Vazio | Explicação e contexto | Ir ao próximo conteúdo |
| Erro de rede | Mensagem simples | Tentar novamente |
| Sessão expirada | Aviso de segurança | Entrar novamente |
| Loja fechada | Próximo horário | Consultar cardápio |
| Produto indisponível | Item bloqueado | Escolher alternativa |
| Pedido cancelado | Status e orientação | Ver histórico/suporte |
| Falha de pagamento | Causa acionável | Corrigir ou trocar forma |
| Cobertura inválida | Região não atendida | Trocar endereço/retirar |

## 9. Acessibilidade e feedback

- Cada campo tem rótulo persistente e mensagem de erro associada.
- Status não dependem somente de cor; usam texto e ícone/forma.
- Botões principais permanecem com área de toque adequada e estado de carregamento.
- Mensagens de sucesso e erro são anunciadas de modo compatível com leitores de tela.
- O foco retorna ao campo com erro após validação.
- O usuário recebe confirmação após adicionar item, salvar endereço, enviar pedido e cancelar.

## 10. Fora do escopo desta fase

Não serão definidos aqui wireframes visuais, componentes, tokens, código Flutter, endpoints detalhados ou integrações de pagamento. Esses itens pertencem às fases seguintes.

## 11. Próxima fase

Os fluxos implementados e pendentes estão consolidados em `docs/STATUS_PROJETO.md`.
