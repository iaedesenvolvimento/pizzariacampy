import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'order_tracking_controller.dart';
import '../../core/notifications/realtime_notification_service.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({required this.orderId, super.key});

  final String orderId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  OrderTrackingController? _controller;
  StreamSubscription<RealtimeNotification>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription =
        realtimeNotificationService.events.listen((event) {
      if (event.orderNumber.isNotEmpty && mounted) {
        _controller?.load(widget.orderId);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final storage = await AppStorage.create();
    final controller = OrderTrackingController(
        ApiClient(config: AppConfig.fromEnvironment()), storage);
    if (!mounted) return;
    setState(() => _controller = controller);
    await controller.load(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.status == OrderTrackingStatus.loading ||
            controller.status == OrderTrackingStatus.idle) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (controller.order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acompanhar pedido')),
            body: Center(
                child:
                    Text(controller.errorMessage ?? 'Pedido não encontrado.')),
          );
        }
        return _TrackingContent(
          order: controller.order!,
          onRefresh: () => controller.load(widget.orderId),
          onSubmitProof: controller.order!.paymentMethod == 'PIX' &&
                  controller.order!.paymentStatus != 'CONFIRMED'
              ? () => _submitProof(controller)
              : null,
        );
      },
    );
  }

  Future<void> _submitProof(OrderTrackingController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum arquivo selecionado.')),
          );
        }
        return;
      }

      final file = result.files.single;
      final path = file.path;
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Não foi possível acessar o arquivo.')),
          );
        }
        return;
      }

      const acceptedExtensions = {'jpg', 'jpeg', 'png', 'pdf'};
      final extension = file.extension?.toLowerCase();
      if (extension == null || !acceptedExtensions.contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Selecione um comprovante JPG, PNG ou PDF.')),
          );
        }
        return;
      }

      await controller.submitPixProofFile(widget.orderId, path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir o seletor de arquivos.')),
        );
      }
    }
  }
}

class _TrackingContent extends StatelessWidget {
  const _TrackingContent(
      {required this.order,
      required this.onRefresh,
      required this.onSubmitProof});

  final OrderTracking order;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onSubmitProof;

  static const _steps = <String, String>{
    'PENDING': 'Pedido recebido',
    'CONFIRMED': 'Confirmado',
    'PREPARING': 'Preparando',
    'READY': 'Pronto',
    'OUT_FOR_DELIVERY': 'Saiu para entrega',
    'DELIVERED': 'Entregue',
  };

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == 'CANCELLED';
    final currentIndex = _steps.keys.toList().indexOf(order.status);
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhar pedido')),
      body: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text('Pedido ${order.orderNumber}',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isCancelled
                      ? const ListTile(
                          leading: Icon(Icons.cancel_outlined),
                          title: Text('Pedido cancelado'))
                      : Column(
                          children: _steps.entries.map((entry) {
                            final index =
                                _steps.keys.toList().indexOf(entry.key);
                            return ListTile(
                              leading: Icon(index <= currentIndex
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked),
                              title: Text(entry.value),
                              textColor: index <= currentIndex
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _infoCard(
                  context,
                  'Resumo',
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Produtos',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        ...order.items.map(_itemSummary),
                        const Divider(height: 20),
                        _row('Subtotal', _price(order.subtotal)),
                        _row('Taxa de entrega', _price(order.deliveryFee)),
                        if ((double.tryParse(order.discountAmount) ?? 0) > 0)
                          _row(
                            order.couponCode == null
                                ? 'Desconto'
                                : 'Desconto (${order.couponCode})',
                            '- ${_price(order.discountAmount)}',
                          ),
                        _row('Total', _price(order.total), strong: true),
                        _row('Pagamento', _paymentLabel(order.paymentMethod)),
                        order.fulfillmentType == 'DELIVERY'
                            ? _addressRow(order.deliveryAddress ??
                                'Endereço não informado')
                            : _row('Recebimento', 'Retirada na pizzaria'),
                      ])),
              if (onSubmitProof != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.pix_outlined),
                    title: Text(order.proofUrl == null
                        ? 'Envie o comprovante PIX'
                        : 'Comprovante enviado'),
                    subtitle: Text(order.paymentStatus == 'UNDER_REVIEW'
                        ? 'Aguardando conferência da pizzaria.'
                        : 'A conferência será manual.'),
                    trailing: TextButton(
                        onPressed: onSubmitProof,
                        child: Text(
                            order.proofUrl == null ? 'Anexar' : 'Atualizar')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String title, Widget child) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              child,
            ])),
      );

  Widget _row(String label, String value, {bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                softWrap: true,
                style: strong
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null),
          ),
        ]),
      );

  Widget _addressRow(String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Endereço'),
            const SizedBox(height: 4),
            Text(value, softWrap: true),
          ],
        ),
      );

  Widget _itemSummary(OrderTrackingItem item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text('${item.quantity}x ${item.name}')),
                const SizedBox(width: 12),
                Text(_price(item.total)),
              ],
            ),
            if (item.size.isNotEmpty)
              Text('Tamanho: ${item.size}', style: _detailStyle),
            if (item.flavors.isNotEmpty)
              Text('Sabores: ${item.flavors.join(', ')}', style: _detailStyle),
            if (item.edge != null && item.edge!.isNotEmpty)
              Text('Borda: ${item.edge}', style: _detailStyle),
            if (item.extras.isNotEmpty)
              Text('Adicionais: ${item.extras.join(', ')}',
                  style: _detailStyle),
          ],
        ),
      );

  static const _detailStyle = TextStyle(fontSize: 12);

  String _price(String value) => 'R\$ ${value.replaceAll('.', ',')}';

  String _paymentLabel(String value) => switch (value) {
        'PIX' => 'PIX',
        'CASH' => 'Dinheiro',
        'CARD_ON_DELIVERY' => 'Cartão',
        _ => value,
      };
}
