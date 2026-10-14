import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../cart/cart_controller.dart';
import '../tracking/order_tracking_page.dart';
import 'checkout_controller.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.cartController, required this.accessToken, super.key});

  final CartController cartController;
  final String? accessToken;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutController _controller;
  final _noteController = TextEditingController();
  final _addressController = TextEditingController();
  final _changeController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController(text: 'São Paulo');
  final _couponController = TextEditingController();
  String _fulfillmentType = 'PICKUP';
  String _paymentMethod = 'PIX';
  List<Map<String, dynamic>> _deliveryZones = const [];
  Map<String, dynamic>? _selectedZone;
  List<Map<String, dynamic>> _savedAddresses = const [];
  Map<String, dynamic>? _selectedAddress;
  bool _loadingDeliveryZones = false;

  @override
  void initState() {
    super.initState();
    _controller = CheckoutController(ApiClient(), widget.accessToken);
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    _addressController.dispose();
    _changeController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fulfillmentType == 'DELIVERY' && (_addressController.text.trim().isEmpty || _neighborhoodController.text.trim().isEmpty || _cityController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe endereço, bairro e cidade para entrega.')));
      return;
    }
    if (_fulfillmentType == 'DELIVERY' && _selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esse endereço não está em uma zona de entrega disponível.')),
      );
      return;
    }
    final changeFor = _changeController.text.trim().replaceAll(',', '.');
    final parsedChange = changeFor.isEmpty ? null : double.tryParse(changeFor);
    if (_paymentMethod == 'CASH' && parsedChange != null && parsedChange < widget.cartController.subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O valor para troco deve cobrir o subtotal do pedido.')),
      );
      return;
    }
    if (_paymentMethod == 'CASH' && changeFor.isNotEmpty && parsedChange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor de troco válido.')),
      );
      return;
    }
    final success = await _controller.submit(
      cart: widget.cartController,
      fulfillmentType: _fulfillmentType,
      paymentMethod: _paymentMethod,
      customerNote: _noteController.text,
      changeFor: parsedChange,
      deliveryAddress: _addressController.text,
      deliveryNeighborhood: _neighborhoodController.text,
      deliveryCity: _cityController.text,
      couponCode: _couponController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => OrderConfirmedPage(result: _controller.result!)),
      );
    }
  }

  Future<void> _selectFulfillment(String value) async {
    setState(() => _fulfillmentType = value);
    if (value != 'DELIVERY' || _deliveryZones.isNotEmpty || _loadingDeliveryZones) return;
    setState(() => _loadingDeliveryZones = true);
    try {
      final api = ApiClient();
      final response = await api.get('/delivery-zones');
      final savedResponse = widget.accessToken == null ? const <dynamic>[] : await api.get('/customer/addresses', headers: {'Authorization': 'Bearer ${widget.accessToken}'});
      if (!mounted) return;
      setState(() {
        _deliveryZones = response is List<dynamic>
            ? response.whereType<Map<String, dynamic>>().toList()
            : const [];
        _savedAddresses = savedResponse is List<dynamic> ? savedResponse.whereType<Map<String, dynamic>>().toList() : const [];
        _loadingDeliveryZones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDeliveryZones = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível carregar as zonas de entrega.')));
    }
  }

  void _selectZone(Map<String, dynamic>? zone) {
    if (zone == null) return;
    setState(() {
      _selectedZone = zone;
      _neighborhoodController.text = zone['neighborhood']?.toString() ?? '';
      _cityController.text = zone['city']?.toString() ?? '';
    });
  }

  void _selectAddress(Map<String, dynamic>? address) {
    if (address == null) return;
    final neighborhood = address['neighborhood']?.toString().trim().toLowerCase();
    final city = address['city']?.toString().trim().toLowerCase();
    Map<String, dynamic>? matchingZone;
    for (final zone in _deliveryZones) {
      if (zone['neighborhood']?.toString().trim().toLowerCase() == neighborhood &&
          zone['city']?.toString().trim().toLowerCase() == city) {
        matchingZone = zone;
        break;
      }
    }
    setState(() {
      _selectedAddress = address;
      _addressController.text = address['address']?.toString() ?? '';
      _neighborhoodController.text = address['neighborhood']?.toString() ?? '';
      _cityController.text = address['city']?.toString() ?? '';
      _selectedZone = matchingZone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Finalizar pedido')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _sectionTitle(context, 'Como você quer receber?'),
            _fulfillmentChoice('PICKUP', 'Retirada', 'Sem taxa e sem pedido mínimo', Icons.storefront_outlined),
            _fulfillmentChoice('DELIVERY', 'Entrega', 'Selecione uma zona atendida', Icons.delivery_dining_outlined),
            if (_fulfillmentType == 'DELIVERY') ...[
              const SizedBox(height: 8),
              if (_savedAddresses.isNotEmpty)
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedAddress,
                  decoration: const InputDecoration(labelText: 'Endereço salvo'),
                  items: _savedAddresses.map((address) => DropdownMenuItem(value: address, child: Text(address['label']?.toString() ?? 'Endereço'))).toList(),
                  onChanged: _selectAddress,
                ),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Endereço de entrega'),
              ),
              if (_loadingDeliveryZones)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator())
              else if (_deliveryZones.isNotEmpty)
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedZone,
                  decoration: const InputDecoration(labelText: 'Zona de entrega'),
                  items: _deliveryZones.map((zone) => DropdownMenuItem(
                    value: zone,
                    child: Text('${zone['neighborhood']} · ${zone['city']}'),
                  )).toList(),
                  onChanged: _selectZone,
                )
              else
                TextField(controller: _neighborhoodController, decoration: const InputDecoration(labelText: 'Bairro coberto')),
              TextField(controller: _cityController, decoration: const InputDecoration(labelText: 'Cidade')),
              if (_selectedZone != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Taxa R\$ ${_selectedZone!['delivery_fee']} · mínimo R\$ ${_selectedZone!['minimum_order_amount']} · ${_selectedZone!['estimated_minutes']} min'),
                )
              else
                const Padding(padding: EdgeInsets.only(top: 8), child: Text('Selecione uma zona para consultar taxa, mínimo e prazo.')),
            ],
            _sectionTitle(context, 'Forma de pagamento'),
            _paymentChoice('PIX', 'PIX', 'A conferência será manual.', Icons.pix_outlined),
            _paymentChoice('CASH', 'Dinheiro', 'Você poderá informar o troco.', Icons.payments_outlined),
            _paymentChoice('CARD_ON_DELIVERY', 'Cartão na entrega/retirada', 'Não armazenamos dados do cartão.', Icons.credit_card_outlined),
            if (_paymentMethod == 'CASH')
              TextField(
                controller: _changeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Troco para quanto?'),
              ),
            if (_paymentMethod == 'PIX')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'A chave PIX e o envio do comprovante serão exibidos conforme a configuração da pizzaria. O pagamento será conferido manualmente.',
                ),
              ),
            _sectionTitle(context, 'Observações'),
            TextField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Alguma observação para a pizzaria?'),
            ),
            _sectionTitle(context, 'Cupom de desconto'),
            TextField(controller: _couponController, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Código do cupom', hintText: 'Ex.: CAMPY10')),
            _sectionTitle(context, 'Resumo'),
            ...widget.cartController.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item.quantity}x ${item.productName}'),
                subtitle: Text(item.sizeName),
                trailing: Text(_formatPrice(item.totalPrice)),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(_formatPrice(widget.cartController.subtotal), style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            if (_selectedZone != null) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Taxa de entrega'),
                Text('R\$ ${_selectedZone!['delivery_fee']}'),
              ]),
            ],
            if (_controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_controller.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: ElevatedButton(
              onPressed: _controller.status == CheckoutStatus.submitting ? null : _submit,
              child: _controller.status == CheckoutStatus.submitting
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar pedido'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fulfillmentChoice(String value, String title, String subtitle, IconData icon) {
    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: _fulfillmentType,
        onChanged: (newValue) => _selectFulfillment(newValue!),
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _paymentChoice(String value, String title, String subtitle, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (newValue) => setState(() => _paymentMethod = newValue!),
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class OrderConfirmedPage extends StatelessWidget {
  const OrderConfirmedPage({required this.result, super.key});

  final CheckoutResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 72),
              const SizedBox(height: 20),
              Text('Pedido recebido!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text('Número: ${result.orderNumber}'),
              const SizedBox(height: 8),
              Text('Total: R\$ ${result.total.replaceAll('.', ',')}'),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderTrackingPage(orderId: result.orderId),
                  ),
                ),
                child: const Text('Acompanhar pedido'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Voltar à Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double price) => 'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
