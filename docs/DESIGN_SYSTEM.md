# Design System — Pizzaria Campy

Versão: 0.1  
Status: Fase 3 — proposta inicial aplicada parcialmente  
Base: `docs/docs/REQUISITOS_FASE_0.md` e `docs/USER_FLOW.md`  
Data: 09/10/2026

## 1. Objetivo

Definir uma base visual consistente para o aplicativo mobile e orientar futuramente o painel administrativo. A interface deve transmitir apetite, velocidade, confiança e simplicidade, destacando os produtos e mantendo o pedido fácil de concluir.

Esta é uma proposta inicial. Logo, fotografias, identidade oficial e eventuais cores institucionais ainda dependem das pendências comerciais da Fase 0.

## 2. Direção visual

- Visual acolhedor e contemporâneo, com energia de pizzaria sem excesso de elementos.
- Fundo predominantemente claro para favorecer leitura e imagens dos produtos.
- Vermelho/tomate reservado para ações principais e destaque de apetite.
- Amarelo/queijo usado como acento, promoção e estados de atenção.
- Verde usado somente para sucesso e confirmação, nunca como cor decorativa dominante.
- Fotos de produtos com grande destaque, recortes limpos e proporção consistente.
- Hierarquia clara: produto e preço primeiro; detalhes e ações em seguida.

## 3. Cores

### 3.1 Paleta semântica inicial

| Token | Valor inicial | Uso |
|---|---|---|
| `brand.primary` | `#C62828` | Botão principal, ação de pedir, marca |
| `brand.primaryPressed` | `#9E1F1F` | Estado pressionado/ativo |
| `brand.primarySoft` | `#FDECEC` | Fundo de seleção e destaque suave |
| `brand.accent` | `#F9A825` | Promoções, queijo, atenção não crítica |
| `surface.default` | `#FFFDF9` | Fundo principal do app |
| `surface.raised` | `#FFFFFF` | Cards, bottom sheets e campos |
| `surface.subtle` | `#F5F1EC` | Áreas secundárias e separadores suaves |
| `text.primary` | `#241A17` | Títulos e conteúdo principal |
| `text.secondary` | `#6D5E59` | Descrições e metadados |
| `text.muted` | `#8E817B` | Placeholders e informação auxiliar |
| `border.default` | `#E4DCD6` | Bordas e divisores |
| `feedback.success` | `#287D45` | Sucesso e status positivo |
| `feedback.warning` | `#A86600` | Atenção e pendências |
| `feedback.error` | `#B3261E` | Erros e ações destrutivas |
| `feedback.info` | `#216A8A` | Informação e orientação |

As cores de texto devem ser usadas sobre fundos que garantam contraste adequado. Não comunicar estado exclusivamente por cor: sempre combinar texto, ícone ou forma.

### 3.2 Uso da paleta

- Um único botão primário dominante por área de decisão.
- Vermelho não deve ser usado em grandes superfícies com texto pequeno.
- Amarelo não deve representar sucesso ou erro.
- Erro destrutivo usa `feedback.error`; remoções permanentes exigem confirmação.
- Estados desabilitados reduzem contraste de forma controlada, sem tornar o conteúdo ilegível.

## 4. Tipografia

Fonte recomendada: uma sans-serif legível e disponível nas plataformas, com fallback nativo. A família definitiva será escolhida junto da identidade da marca.

| Estilo | Tamanho | Peso | Uso |
|---|---:|---:|---|
| `display` | 32 px | 700 | Mensagens de confirmação e destaques especiais |
| `heading1` | 24 px | 700 | Títulos de tela |
| `heading2` | 20 px | 700 | Seções e nome de produto |
| `heading3` | 18 px | 600 | Subtítulos e cards importantes |
| `bodyLarge` | 16 px | 400 | Conteúdo principal e campos |
| `body` | 14 px | 400 | Descrições e informações gerais |
| `label` | 14 px | 600 | Labels, botões e chips |
| `caption` | 12 px | 400 | Metadados e auxílio |
| `price` | 18 px | 700 | Preços em cards |

Regras:

- Texto base mínimo de 14 px; `caption` não deve carregar informação essencial sozinho.
- Preços usam tabularidade visual quando disponível para facilitar comparação.
- Títulos devem ser curtos e orientados à ação.
- Evitar caixa alta em textos longos.

## 5. Espaçamento e layout

Escala base de 4 px:

`space.1 = 4` · `space.2 = 8` · `space.3 = 12` · `space.4 = 16` · `space.5 = 20` · `space.6 = 24` · `space.8 = 32` · `space.10 = 40` · `space.12 = 48`

- Margem horizontal padrão mobile: 16 px.
- Separação entre seções: 24 a 32 px.
- Espaço interno de card: 16 px.
- Área de toque mínima: 44 × 44 px.
- Em telas maiores, limitar conteúdo de leitura a aproximadamente 600–720 px quando fizer sentido.
- O painel administrativo usa grade responsiva, com conteúdo principal e áreas laterais que colapsam no tablet.

## 6. Forma, elevação e ícones

### Raios

| Token | Valor | Uso |
|---|---:|---|
| `radius.sm` | 8 px | Inputs, chips e pequenos controles |
| `radius.md` | 12 px | Cards e botões |
| `radius.lg` | 16 px | Imagens, seções e bottom sheets |
| `radius.pill` | 999 px | Chips e badges |

### Elevação

- `elevation.none`: listas e superfícies sem separação.
- `elevation.low`: cards sobre o fundo.
- `elevation.medium`: bottom navigation, dialogs e menus.
- Sombras suaves, curtas e pouco saturadas; não usar sombras como decoração.

### Ícones

- Usar uma única família de ícones consistente.
- Ícones de ação recebem label acessível ou tooltip quando o significado não for óbvio.
- Ícones de navegação não devem substituir texto em ações críticas.
- Status do pedido usam ícone + texto + estado visual.

## 7. Componentes fundamentais

### Botões

Variantes:

- `Primary`: ação principal, como “Adicionar ao carrinho” e “Confirmar pedido”.
- `Secondary`: ação alternativa, como “Continuar comprando”.
- `Tertiary`: ação discreta, como “Editar”.
- `Destructive`: cancelamento, remoção e limpeza do carrinho.

Estados: normal, pressionado, foco, carregando, desabilitado e erro contextual. O estado carregando mantém a largura do botão e impede toques duplicados.

### Campos de entrada

Cada campo possui label, exemplo opcional, valor, estado de foco, mensagem de erro e suporte a acessibilidade. Erro deve aparecer próximo ao campo e explicar como corrigir.

Tipos previstos: texto, telefone, senha, número, endereço, observação e seleção.

### Cards de produto

Devem priorizar imagem, nome, descrição curta, preço inicial e disponibilidade. A ação deve ser clara mesmo quando o produto exige personalização. Não esconder o preço atrás de múltiplas telas.

### Card de pizza personalizada

Exibir tamanho, sabores resumidos, borda, adicionais, quantidade e preço unitário. A representação de meio a meio deve usar texto explícito, por exemplo: `1/2 Calabresa · 1/2 Portuguesa`.

### Chips e badges

- Chips: filtros e seleção de categoria.
- Badges: status curto, promoção ou quantidade.
- Não usar chips para textos longos ou instruções importantes.

### Resumo de preço

Usado no carrinho e checkout. Alinhar valores à direita e mostrar subtotal, taxa, desconto quando existir e total final. O total deve ter maior peso visual.

### Barra de ação fixa

No carrinho e checkout, pode fixar a ação principal na parte inferior, respeitando área segura do dispositivo. Deve mostrar total e verbo de ação, como `Continuar` ou `Confirmar pedido`.

### Bottom sheet e dialog

- Bottom sheet: seleção curta, opções de produto e confirmação contextual.
- Dialog: confirmação destrutiva ou decisão que exige foco imediato.
- Não empilhar modais; permitir fechar com ação explícita e gesto padrão quando suportado.

### Feedback e mensagens

- Toast/snackbar: confirmação breve de ação não crítica.
- Banner: indisponibilidade, loja fechada ou falha persistente.
- Inline: erro de campo e validação contextual.
- Tela de estado: erro abrangente, vazio ou pedido cancelado.

## 8. Navegação

Estrutura mobile inicial:

```text
Home | Cardápio | Carrinho | Pedidos | Conta
```

- A aba atual é identificável por cor, ícone e label.
- Carrinho exibe contador somente quando houver itens.
- Ações de checkout usam navegação sequencial com título e retorno previsível.
- Não interromper o fluxo para pedir cadastro antes do checkout.

## 9. Estados visuais obrigatórios

| Estado | Tratamento |
|---|---|
| Carregando | Skeleton ou indicador associado ao conteúdo |
| Vazio | Explicação curta e ação útil |
| Erro | Causa em linguagem simples e tentar novamente |
| Desabilitado | Aparência inativa e motivo quando necessário |
| Sucesso | Feedback imediato e próximo passo claro |
| Loja fechada | Status, próximo horário e cardápio consultável |
| Indisponível | Item bloqueado, sem permitir adição |
| Sessão expirada | Aviso e retorno seguro ao login |
| Offline | Último conteúdo permitido e indicação de dados desatualizados |

## 10. Imagens e conteúdo

- Fotos devem mostrar o produto real, com iluminação e enquadramento consistentes.
- Usar proporção estável nos cards para evitar saltos de layout.
- Toda imagem precisa de descrição alternativa útil.
- Se a imagem falhar, mostrar placeholder sem remover nome e preço.
- Evitar fotos meramente decorativas onde o produto não possa ser identificado.
- Textos de card são curtos; detalhes ficam na tela do produto.

## 11. Acessibilidade

- Contraste de texto e componentes deve atender WCAG AA como referência.
- Suportar aumento de fonte sem cortar conteúdo ou esconder ações.
- Garantir ordem de foco lógica e labels para leitor de tela.
- Não depender apenas de vermelho/verde para status.
- Áreas de toque de pelo menos 44 × 44 px.
- Mensagens de validação devem ser associadas ao controle correspondente.
- Animações devem ser discretas e respeitar preferência de reduzir movimento quando disponível.

## 12. Painel administrativo

O painel reutiliza a paleta sem competir com a operação. Prioridades visuais:

- pedidos novos e pendentes no topo;
- status e ações operacionais em destaque;
- tabelas legíveis, filtros persistentes e feedback após salvar;
- confirmação para cancelamento e alterações que afetem disponibilidade;
- responsividade para desktop, notebook e tablet.

O painel pode usar uma densidade maior que o app, mas mantém tipografia, cores semânticas, estados e regras de acessibilidade.

## 13. Tokens a manter centralizados

Quando o código for iniciado, os seguintes grupos devem ser centralizados no tema compartilhado de cada aplicação:

- cores semânticas;
- escala tipográfica;
- espaçamento;
- raios;
- elevação;
- dimensões de toque;
- duração e curva de transições;
- estilos de botão, campo, card e feedback.

Valores não devem ser repetidos diretamente em telas sem justificativa.

## 14. Pendências de identidade

- Aprovação da paleta oficial e da fonte da marca.
- Logo, versões reduzida e monocromática.
- Direção fotográfica e imagens reais dos produtos.
- Tom de voz para mensagens e promoções.
- Ícone do aplicativo e splash final.

## 15. Fora do escopo desta fase

Não serão criados nesta fase código Flutter, componentes implementados, wireframes, imagens finais ou arquivos de tema. Esses itens serão detalhados e implementados nas fases seguintes.

## 16. Próxima fase

O design system orienta as telas atuais; a revisão visual final fica registrada em `docs/STATUS_PROJETO.md`.
