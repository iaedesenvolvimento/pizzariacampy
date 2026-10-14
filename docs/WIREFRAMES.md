# Wireframes — Pizzaria Campy

Versão: 0.1  
Status: Fase 4 — especificação concluída e implementada parcialmente  
Base: `docs/USER_FLOW.md` e `docs/DESIGN_SYSTEM.md`  
Data: 09/10/2026

## 1. Objetivo

Descrever a estrutura de baixa fidelidade das telas principais do aplicativo mobile. Cada especificação define objetivo, conteúdo, componentes, ações, estados e navegação para orientar a futura implementação visual.

As medidas abaixo são referências de composição, não uma implementação final. A interface deve adaptar-se a diferentes dimensões Android/iOS e respeitar áreas seguras do dispositivo.

## 2. Estrutura comum

### Cabeçalho

- Título da tela ou saudação curta.
- Ação de voltar quando a tela não for raiz.
- Ações contextuais acessíveis por ícone com label.

### Navegação principal

Nas telas raiz, usar: `Home | Cardápio | Carrinho | Pedidos | Conta`.

### Rodapé de ação

Checkout, carrinho e montagem podem usar uma área fixa inferior com total/preço e ação principal. Ela deve respeitar a área segura e não cobrir campos ou listas.

### Estados padrão

Toda tela que consulta dados deve prever loading, sucesso, vazio, erro de rede, indisponibilidade e sessão expirada quando aplicável.

## 3. Mapa de navegação

```text
Splash → Home
Home → Cardápio → Busca
Cardápio → Detalhes → Montagem → Carrinho
Carrinho → Checkout → Endereço → Pagamento → Revisão
Revisão → Pedido confirmado → Acompanhamento
Home → Login/Cadastro → retorno ao fluxo original
Conta → Perfil / Endereços / Histórico
Pedidos → Histórico / Acompanhamento
```

## 4. Splash

**Objetivo:** apresentar a marca enquanto a sessão e a configuração mínima são verificadas.

**Conteúdo:** logo da Pizzaria Campy centralizado, fundo da marca e indicador discreto.

**Componentes:** logo, indicador de carregamento, mensagem alternativa para falha inicial.

**Ações:** nenhuma ação obrigatória; em falha persistente, oferecer `Tentar novamente`.

**Estados:** carregando, sessão recuperada, visitante, falha de rede.

**Navegação:** Home após inicialização; não usar o Splash como tela de retorno.

## 5. Onboarding (opcional)

**Objetivo:** explicar rapidamente o pedido para novos usuários sem impedir a consulta do cardápio.

**Conteúdo:** até três páginas sobre escolher sabores, receber/retirar e acompanhar o pedido.

**Componentes:** ilustração/foto, título, texto curto, indicador de páginas, `Pular` e `Começar`.

**Ações:** avançar, voltar, pular e concluir.

**Estados:** primeira abertura, página intermediária e última página.

**Navegação:** Home após concluir. Não reapresentar automaticamente após conclusão.

## 6. Login

**Objetivo:** autenticar o cliente no momento de finalizar o pedido ou ao acessar a conta.

**Conteúdo:** título, e-mail/telefone conforme decisão final, senha, recuperação, botão entrar e link de cadastro.

**Componentes:** campos, mostrar/ocultar senha, botão primário, link secundário, mensagem inline.

**Ações:** entrar, cadastrar, recuperar senha e voltar.

**Estados:** inicial, validando campos, enviando, credenciais inválidas, rede indisponível e sessão autenticada.

**Navegação:** retornar ao ponto de origem após sucesso; não perder o carrinho.

## 7. Cadastro

**Objetivo:** criar conta para permitir a finalização do pedido.

**Conteúdo:** nome, contato, senha, confirmação de senha, aceite de termos/política quando definidos.

**Componentes:** formulário agrupado, requisitos de senha, botão criar conta e link para login.

**Ações:** criar conta, voltar para login e corrigir campos.

**Estados:** validação local, envio, contato já utilizado, erro de API e cadastro concluído.

**Navegação:** retornar ao checkout ou à Conta, conforme origem.

## 8. Home

**Objetivo:** iniciar rapidamente um pedido e apresentar a situação da loja.

**Conteúdo, de cima para baixo:**

1. Saudação e acesso à conta.
2. Banner de status da loja e horário limite.
3. Ação principal `Ver cardápio`.
4. Categorias em rolagem horizontal.
5. Produtos populares ou destaques.
6. Pedido ativo, se existir.

**Componentes:** cabeçalho, banner de status, botão primário, chips de categoria, cards de produto, navegação inferior.

**Ações:** abrir cardápio, buscar, abrir produto, ver pedido ativo, acessar conta.

**Estados:** carregando, aberta, fechada, catálogo vazio, erro de carregamento e offline com conteúdo local válido.

**Navegação:** Cardápio, Detalhes, Acompanhamento e Conta.

## 9. Cardápio

**Objetivo:** explorar todos os produtos disponíveis.

**Conteúdo:** título, campo de busca, categorias, lista/grid responsivo, imagem, nome, descrição curta, preço inicial e disponibilidade.

**Componentes:** campo de busca, chips, cards, indicador de categoria ativa, navegação inferior.

**Ações:** pesquisar, filtrar categoria, abrir detalhes e adicionar item simples.

**Estados:** carregando com skeleton, resultados, categoria vazia, sem resultados, erro e produto indisponível.

**Navegação:** Busca, Detalhes e retorno à Home preservando filtro/posição.

## 10. Busca

**Objetivo:** encontrar produto por texto de forma direta.

**Conteúdo:** campo de busca em foco, termo atual, resultados e estado sem resultado.

**Componentes:** campo com limpar, lista de resultados, histórico recente apenas se aprovado posteriormente, mensagem vazia.

**Ações:** digitar, limpar, abrir produto, voltar ao cardápio.

**Estados:** campo vazio, digitando, carregando, resultado, sem resultado e erro.

**Navegação:** abrir Detalhes; retorno preserva o termo quando possível.

## 11. Detalhes do produto

**Objetivo:** explicar o produto e iniciar sua personalização.

**Conteúdo:** imagem principal, nome, descrição, preço inicial, disponibilidade, informações relevantes e ação.

**Componentes:** galeria/imagem, título, preço, texto, badge de disponibilidade, botão `Personalizar` ou `Adicionar`.

**Ações:** personalizar, adicionar produto simples, voltar e compartilhar fica fora do MVP.

**Estados:** disponível, indisponível, carregando, erro e alteração de disponibilidade.

**Navegação:** Montagem quando houver opções; Carrinho após adicionar; retorno à lista.

## 12. Montagem da pizza

**Objetivo:** permitir selecionar uma pizza válida com baixa carga cognitiva.

**Conteúdo:** indicador de etapas, tamanho, sabores, borda, adicionais, quantidade e preço atualizado.

**Componentes:** stepper/segmentos de etapa, opções selecionáveis, contador, resumo persistente e barra de ação.

**Ordem visual:**

1. Tamanho.
2. Sabores e limite visível.
3. Borda.
4. Adicionais.
5. Quantidade e revisão.

**Ações:** selecionar/deselecionar, avançar, voltar, alterar quantidade e adicionar ao carrinho.

**Estados:** seleção incompleta, limite de sabores atingido, opção desativada, preço atualizando, erro de validação e sucesso.

**Navegação:** voltar aos detalhes/lista; adicionar leva ao Carrinho ou oferece continuar comprando.

## 13. Carrinho

**Objetivo:** revisar itens e iniciar o checkout.

**Conteúdo:** lista de itens, resumo das personalizações, quantidade, editar/remover, subtotal, taxa quando conhecida e total.

**Componentes:** item expansível ou resumido, controles de quantidade, botão editar, ação remover, resumo financeiro e botão `Continuar`.

**Ações:** editar item, aumentar/diminuir quantidade, remover, limpar, continuar comprando, iniciar checkout.

**Estados:** vazio, com itens, recálculo, item indisponível, erro e confirmação para limpar.

**Navegação:** voltar ao Cardápio; editar retorna à Montagem; continuar abre Checkout.

## 14. Checkout

**Objetivo:** conduzir a escolha de recebimento e consolidar o pedido.

**Conteúdo:** indicador de etapas, entrega/retirada, endereço resumido, pagamento resumido, observação e total.

**Componentes:** seleção segmentada ou cards de método, resumo expansível, campos condicionais, barra de ação.

**Ações:** selecionar entrega/retirada, escolher endereço, selecionar pagamento, adicionar observação, avançar para revisão.

**Estados:** método não selecionado, entrega sem endereço, cobertura inválida, retirada selecionada, loja fechada, recálculo e erro.

**Navegação:** Carrinho, Endereço, Pagamento e Revisão.

## 15. Endereço

**Objetivo:** selecionar ou cadastrar endereço de entrega.

**Conteúdo:** endereços salvos, endereço selecionado e formulário de novo endereço.

**Componentes:** cards/radio de endereço, campos de rua, número, complemento, referência, bairro e cidade, botão salvar.

**Ações:** selecionar, adicionar, editar e salvar.

**Estados:** lista vazia, endereço coberto, bairro não atendido, validação de campo, salvando e erro.

**Navegação:** retornar ao Checkout com endereço selecionado; endereço não coberto oferece Retirada.

## 16. Pagamento

**Objetivo:** registrar a forma de pagamento sem coletar dados sensíveis de cartão.

**Conteúdo:** opções PIX, dinheiro e cartão; instruções condicionais; comprovante PIX e troco.

**Componentes:** cards de seleção, campo `Troco para`, instruções PIX, seletor/anexo de comprovante e aviso operacional.

**Ações:** selecionar método, preencher troco, anexar comprovante, continuar para revisão.

**Estados:** nenhum método, PIX sem comprovante quando exigido, upload em andamento, upload falho, dinheiro sem troco e cartão selecionado.

**Navegação:** retornar ao Checkout; avançar para Revisão.

## 17. Revisão do pedido

**Objetivo:** permitir conferir tudo antes da confirmação final.

**Conteúdo:** itens, entrega/retirada, endereço, pagamento, observações, subtotal, taxa, mínimo e total.

**Componentes:** seções editáveis, resumo financeiro, aviso de atualização de preço e botão `Confirmar pedido`.

**Ações:** editar seção, confirmar, voltar e cancelar o checkout.

**Estados:** pronto, recalculando, preço alterado, item indisponível, horário encerrado, enviando e falha.

**Navegação:** retorno à seção editada; sucesso abre Pedido confirmado.

## 18. Pedido confirmado

**Objetivo:** confirmar criação do pedido e orientar o próximo passo.

**Conteúdo:** ícone/mensagem de sucesso, número do pedido, status inicial, previsão, total, pagamento e ação acompanhar.

**Componentes:** ilustração simples, card de resumo, botão `Acompanhar pedido`, botão secundário `Voltar à Home`.

**Ações:** acompanhar, voltar à Home e acessar histórico.

**Estados:** pedido criado, confirmação pendente de atualização e falha de consulta após criação.

**Navegação:** Acompanhamento, Pedidos e Home.

## 19. Acompanhamento

**Objetivo:** mostrar a evolução do pedido com segurança e clareza.

**Conteúdo:** número, status atual, linha de etapas, itens, total, endereço/retirada, pagamento e previsão.

**Componentes:** stepper de status, resumo do pedido, banner de cancelamento, atualização/refresh e suporte.

**Ações:** atualizar, consultar detalhes, cancelar quando permitido e voltar ao histórico.

**Estados:** `PENDING`, `CONFIRMED`, `PREPARING`, `READY`, `OUT_FOR_DELIVERY`, `DELIVERED`, `CANCELLED`, erro de atualização e pedido não encontrado.

**Navegação:** Pedidos, detalhe do pedido e Home.

## 20. Histórico

**Objetivo:** consultar pedidos anteriores e abrir seus detalhes.

**Conteúdo:** lista por data com número, status, total e método de recebimento.

**Componentes:** filtros simples se necessários, cards de pedido, paginação/infinite scroll quando houver volume.

**Ações:** abrir pedido, atualizar lista e voltar.

**Estados:** carregando, lista, vazio com CTA para cardápio, erro e carregamento de mais itens.

**Navegação:** Acompanhamento/detalhes e Cardápio.

## 21. Perfil / Conta

**Objetivo:** centralizar dados do cliente e configurações da conta.

**Conteúdo:** nome, contato, atalhos para endereços, pedidos, recuperação de senha e logout.

**Componentes:** cabeçalho de perfil, lista de ações, estados de sessão e confirmação de logout.

**Ações:** editar dados, abrir endereços, abrir histórico, recuperar senha e sair.

**Estados:** visitante, autenticado, carregando dados, erro e logout confirmado.

**Navegação:** Login quando visitante; Endereços, Histórico e telas de segurança quando autenticado.

## 22. Regras de composição

- Uma tela deve ter uma ação principal claramente identificável.
- Evitar mais de um banner chamativo na mesma área visível.
- Informações financeiras devem ficar agrupadas e nunca escondidas por scroll excessivo.
- Erros aparecem perto da decisão que precisa ser corrigida.
- O retorno nunca deve apagar seleções válidas ou o carrinho.
- Conteúdo indisponível fica visível apenas quando ajuda a explicar a situação; não oferecer ação impossível.

## 23. Fora do escopo

Não fazem parte destes wireframes: painel administrativo detalhado, design visual final, protótipo navegável, código Flutter, mapas, rastreamento, favoritos, cupons e gateway de pagamento.

## 24. Próxima fase

Os estados ainda pendentes de implementação estão em `docs/STATUS_PROJETO.md`.
