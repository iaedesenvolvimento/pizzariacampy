import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({
    required this.accessToken,
    this.refreshAccessToken,
    this.onStartPizza,
    this.onOpenProduct,
    this.onOpenCart,
    this.onGetCartSummary,
    super.key,
  });

  final String? accessToken;
  final Future<String?> Function()? refreshAccessToken;
  final Future<void> Function(int maxFlavors)? onStartPizza;
  final Future<bool> Function(String query)? onOpenProduct;
  final Future<void> Function()? onOpenCart;
  final Future<String?> Function()? onGetCartSummary;

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _api = ApiClient();
  final List<({bool isUser, String text})> _messages = [
    (
      isUser: false,
      text:
          'Olá! Sou o assistente da Pizzaria Campy. Posso ajudar você a conhecer nosso cardápio.'
    ),
  ];
  bool _sending = false;

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() {
      _messages.add((isUser: true, text: message));
      _input.clear();
      _sending = true;
    });
    _scrollToEnd();
    final localReply = await _handleLocalCommand(message);
    if (localReply != null) {
      if (!mounted) return;
      setState(() {
        _messages.add((isUser: false, text: localReply));
        _sending = false;
      });
      _scrollToEnd();
      return;
    }
    try {
      final response = await _sendMessage(message);
      if (!mounted) return;
      final reply = response is Map ? response['reply']?.toString() : null;
      setState(() => _messages.add((
            isUser: false,
            text: reply?.isNotEmpty == true
                ? reply!
                : 'Não consegui responder agora.',
          )));
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.add((
            isUser: false,
            text:
                'O atendimento está temporariamente indisponível. Consulte o cardápio no aplicativo.',
          )));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  Future<String?> _handleLocalCommand(String message) async {
    final normalized = message
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u');
    if (widget.onStartPizza == null) return null;
    if (normalized.contains('meio a meio') ||
        normalized.contains('dois sabores') ||
        normalized.contains('2 sabores')) {
      await widget.onStartPizza!(2);
      final additionalItems = await _openAdditionalItems(message);
      final reply = additionalItems == 0
          ? 'Vamos montar sua pizza meio a meio. Escolha os dois sabores na próxima tela.'
          : 'Pizza meio a meio e $additionalItems item(ns) encaminhados para configuração.';
      return _appendSummary(reply, await _cartSummary());
    }
    if (normalized.contains('1 sabor') ||
        normalized.contains('um sabor') ||
        normalized.contains('pizza grande')) {
      await widget.onStartPizza!(1);
      final additionalItems = await _openAdditionalItems(message);
      final reply = additionalItems == 0
          ? 'Vamos montar sua pizza de um sabor. Escolha o tamanho e o sabor na próxima tela.'
          : 'Pizza de um sabor e $additionalItems item(ns) encaminhados para configuração.';
      return _appendSummary(reply, await _cartSummary());
    }
    if (normalized.contains('carrinho') ||
        normalized.contains('finalizar pedido')) {
      if (widget.onOpenCart == null) return null;
      await widget.onOpenCart!();
      return 'Aqui está seu carrinho. Confira os itens antes de finalizar.';
    }
    if (widget.onOpenProduct != null &&
        (normalized.contains('quero ') ||
            normalized.contains('comprar ') ||
            normalized.contains('adicionar '))) {
      final opened = await widget.onOpenProduct!(message);
      if (opened) {
        return _appendSummary(
          'Encontrei o produto. Configure as opções e toque em Adicionar ao carrinho.',
          await _cartSummary(),
        );
      }
    }
    return null;
  }

  Future<String?> _cartSummary() async => widget.onGetCartSummary?.call();

  String _appendSummary(String reply, String? summary) {
    if (summary == null || summary.isEmpty) return reply;
    return '$reply\n\n$summary';
  }

  Future<int> _openAdditionalItems(String message) async {
    if (widget.onOpenProduct == null) return 0;
    final segments = message.split(RegExp(r'\s+e\s+', caseSensitive: false));
    var opened = 0;
    for (final segment in segments.skip(1)) {
      final normalized = segment.toLowerCase();
      final isAdditionalItem = RegExp(
        r'coca|guarana|refrigerante|suco|agua|sobremesa|doce|bebida',
        caseSensitive: false,
      ).hasMatch(normalized);
      if (isAdditionalItem && await widget.onOpenProduct!(segment)) {
        opened++;
      }
    }
    return opened;
  }

  Future<dynamic> _sendMessage(String message) async {
    var token = widget.accessToken;
    if (token == null || token.isEmpty) {
      throw const FormatException('Sessão expirada.');
    }

    try {
      return await _api.post(
        '/ai/chat',
        body: {'message': message},
        headers: {'Authorization': 'Bearer $token'},
      );
    } on ApiException catch (error) {
      if (error.statusCode != 401 || widget.refreshAccessToken == null) {
        rethrow;
      }
      token = await widget.refreshAccessToken!();
      if (token == null || token.isEmpty) rethrow;
      return _api.post(
        '/ai/chat',
        body: {'message': message},
        headers: {'Authorization': 'Bearer $token'},
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Atendente virtual')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                  'Posso consultar o cardápio e guiar você na montagem do pedido.'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: ExpansionTile(
                  initiallyExpanded: true,
                  leading: const Icon(Icons.lightbulb_outline),
                  title: const Text('Como posso pedir?'),
                  subtitle: const Text('Veja exemplos de frases'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: const [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '• “Quero uma pizza grande”\n'
                        '• “Quero pizza meio a meio”\n'
                        '• “Quero uma pizza com dois sabores”\n'
                        '• “Quero uma pizza e uma Coca-Cola”',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onStartPizza != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.looks_one_outlined, size: 18),
                        label: const Text('Pizza 1 sabor'),
                        onPressed: _sending ? null : () => _startPizza(1),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.call_split_outlined, size: 18),
                        label: const Text('Pizza meio a meio'),
                        onPressed: _sending ? null : () => _startPizza(2),
                      ),
                      if (widget.onOpenCart != null)
                        ActionChip(
                          avatar: const Icon(Icons.shopping_cart_outlined,
                              size: 18),
                          label: const Text('Ver carrinho'),
                          onPressed: _sending ? null : widget.onOpenCart,
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final item = _messages[index];
                  return Align(
                    alignment: item.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.isUser
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(item.text),
                    ),
                  );
                },
              ),
            ),
            if (_sending) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Pergunte sobre nossas pizzas...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar mensagem',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPizza(int maxFlavors) async {
    if (widget.onStartPizza == null || _sending) return;
    setState(() {
      _messages.add((
        isUser: true,
        text: maxFlavors == 2
            ? 'Quero uma pizza meio a meio.'
            : 'Quero uma pizza de um sabor.',
      ));
      _sending = true;
    });
    await widget.onStartPizza!(maxFlavors);
    if (!mounted) return;
    setState(() {
      _messages.add((
        isUser: false,
        text: maxFlavors == 2
            ? 'Perfeito! Escolha os dois sabores, tamanho, borda e adicionais.'
            : 'Perfeito! Escolha o sabor, tamanho, borda e adicionais.',
      ));
      _sending = false;
    });
    _scrollToEnd();
  }
}
