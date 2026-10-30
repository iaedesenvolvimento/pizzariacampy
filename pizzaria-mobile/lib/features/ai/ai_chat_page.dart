import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({
    required this.accessToken,
    this.refreshAccessToken,
    super.key,
  });

  final String? accessToken;
  final Future<String?> Function()? refreshAccessToken;

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
                  'Versão de teste: consultas ao cardápio. Pedidos devem ser feitos pelo carrinho.'),
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
}
