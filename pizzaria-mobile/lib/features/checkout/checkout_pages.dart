import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/cep_service.dart';
import '../../core/network/api_client.dart';
import '../cart/cart_controller.dart';
import '../tracking/order_tracking_page.dart';
import 'checkout_controller.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage(
      {required this.cartController, required this.accessToken, super.key});

  final CartController cartController;
  final String? accessToken;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final CheckoutController _controller;
  final _noteController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _changeController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController(text: 'São Paulo');
  final _complementController = TextEditingController();
  final _couponController = TextEditingController();
  String _fulfillmentType = 'PICKUP';
  String _paymentMethod = 'PIX';
  List<Map<String, dynamic>> _deliveryZones = const [];
  Map<String, dynamic>? _selectedZone;
  List<Map<String, dynamic>> _savedAddresses = const [];
  Map<String, dynamic>? _selectedAddress;
  bool _loadingDeliveryZones = false;
  bool _loadingCep = false;
  String? _cepError;
  String? _coverageMessage;
  String _pixKey = '';
  String _pickupInstructions = '';
  bool _loadingPixSettings = true;

  @override
  void initState() {
    super.initState();
    _controller = CheckoutController(ApiClient(), widget.accessToken);
    _loadPixSettings();
  }

  Future<void> _loadPixSettings() async {
    try {
      final response = await ApiClient().get('/store-settings');
      if (!mounted || response is! Map<String, dynamic>) return;
      setState(() {
        _pixKey = response['pix_key']?.toString().trim() ?? '';
        _pickupInstructions =
            response['pickup_instructions']?.toString().trim() ?? '';
        _loadingPixSettings = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingPixSettings = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _changeController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _complementController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fulfillmentType == 'DELIVERY' &&
        _cepController.text.replaceAll(RegExp(r'\D'), '').length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um CEP válido para entrega.')),
      );
      return;
    }
    if (_fulfillmentType == 'DELIVERY' &&
        (_addressController.text.trim().isEmpty ||
            _numberController.text.trim().isEmpty ||
            _neighborhoodController.text.trim().isEmpty ||
            _cityController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe endereço, bairro e cidade para entrega.')));
      return;
    }
    if (_fulfillmentType == 'DELIVERY' && _selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_coverageMessage ??
              'Esse endereço não está em uma zona de entrega disponível.'),
        ),
      );
      return;
    }
    final changeFor = _changeController.text.trim().replaceAll(',', '.');
    final parsedChange = changeFor.isEmpty ? null : double.tryParse(changeFor);
    if (_paymentMethod == 'CASH' &&
        parsedChange != null &&
        parsedChange < widget.cartController.subtotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('O valor para troco deve cobrir o subtotal do pedido.')),
      );
      return;
    }
    if (_paymentMethod == 'CASH' &&
        changeFor.isNotEmpty &&
        parsedChange == null) {
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
      deliveryAddress: _complementController.text.trim().isEmpty
          ? _addressController.text
          : '${_addressController.text}, ${_complementController.text}',
      deliveryNumber: _numberController.text.trim(),
      deliveryPostalCode: _cepController.text,
      deliveryNeighborhood: _neighborhoodController.text,
      deliveryCity: _cityController.text,
      couponCode: _couponController.text,
    );
    if (success && mounted) {
      final result = _controller.result!;
      final discount = double.tryParse(result.discountAmount) ?? 0;
      if (result.couponCode != null && discount > 0) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cupom aplicado'),
            content: Text(
                'O cupom ${result.couponCode} foi aplicado. Desconto de ${_formatPrice(discount)}.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
            builder: (_) => OrderConfirmedPage(result: result)),
      );
    }
  }

  Future<void> _lookupCep() async {
    if (_cepController.text.replaceAll(RegExp(r'\D'), '').length != 8) return;
    setState(() {
      _loadingCep = true;
      _cepError = null;
    });
    try {
      final result = await const CepService().lookup(_cepController.text);
      if (!mounted) return;
      if (result == null) {
        setState(() => _cepError = 'CEP não encontrado.');
        return;
      }
      setState(() {
        _addressController.text = result.street;
        _neighborhoodController.text = result.neighborhood;
        _cityController.text = result.city;
        _selectedZone = _findMatchingZone(result.neighborhood, result.city);
        _coverageMessage = _selectedZone == null
            ? 'Ainda não entregamos neste bairro. Escolha retirada ou outro endereço.'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _cepError = 'Não foi possível consultar o CEP.');
      }
    } finally {
      if (mounted) setState(() => _loadingCep = false);
    }
  }

  Future<void> _selectFulfillment(String value) async {
    setState(() => _fulfillmentType = value);
    if (value != 'DELIVERY' ||
        _deliveryZones.isNotEmpty ||
        _loadingDeliveryZones) {
      return;
    }
    setState(() => _loadingDeliveryZones = true);
    try {
      final api = ApiClient();
      final response = await api.get('/delivery-zones');
      final savedResponse = widget.accessToken == null
          ? const <dynamic>[]
          : await api.get('/customer/addresses',
              headers: {'Authorization': 'Bearer ${widget.accessToken}'});
      if (!mounted) return;
      setState(() {
        _deliveryZones = response is List<dynamic>
            ? response.whereType<Map<String, dynamic>>().toList()
            : const [];
        _savedAddresses = savedResponse is List<dynamic>
            ? savedResponse.whereType<Map<String, dynamic>>().toList()
            : const [];
        _loadingDeliveryZones = false;
      });
      if (_neighborhoodController.text.trim().isNotEmpty) {
        final matchingZone = _findMatchingZone(
          _neighborhoodController.text,
          _cityController.text,
        );
        if (mounted) {
          setState(() {
            _selectedZone = matchingZone;
            _coverageMessage = matchingZone == null
                ? 'Ainda não entregamos neste bairro. Escolha retirada ou outro endereço.'
                : null;
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDeliveryZones = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível carregar as zonas de entrega.')));
    }
  }

  void _selectAddress(Map<String, dynamic>? address) {
    if (address == null) return;
    final neighborhood = address['neighborhood']?.toString() ?? '';
    final city = address['city']?.toString() ?? '';
    final matchingZone = _findMatchingZone(neighborhood, city);
    setState(() {
      _selectedAddress = address;
      _cepController.text =
          _formatPostalCode(address['postal_code']?.toString() ?? '');
      _addressController.text = address['address']?.toString() ?? '';
      _numberController.text = address['number']?.toString() ?? '';
      _neighborhoodController.text = address['neighborhood']?.toString() ?? '';
      _cityController.text = address['city']?.toString() ?? '';
      _complementController.text = address['complement']?.toString() ?? '';
      _selectedZone = matchingZone;
      _coverageMessage = matchingZone == null
          ? 'Este endereço salvo está fora da área de entrega atual.'
          : null;
    });
  }

  String _formatPostalCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return value;
    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  Map<String, dynamic>? _findMatchingZone(String neighborhood, String city) {
    final normalizedNeighborhood = _canonicalNeighborhood(neighborhood);
    final normalizedCity = _normalizeLocation(city);
    for (final zone in _deliveryZones) {
      if (_canonicalNeighborhood(zone['neighborhood']?.toString() ?? '') ==
              normalizedNeighborhood &&
          _normalizeLocation(zone['city']?.toString() ?? '') ==
              normalizedCity) {
        return zone;
      }
    }
    return null;
  }

  String _normalizeLocation(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    var normalized = value.trim().toLowerCase();
    replacements
        .forEach((from, to) => normalized = normalized.replaceAll(from, to));
    return normalized;
  }

  String _canonicalNeighborhood(String value) {
    final normalized = _normalizeLocation(value);
    const aliases = {
      'cidade ariston estela azevedo': 'ariston',
      'parque roseira': 'roseira parque',
    };
    return aliases[normalized] ?? normalized;
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
            _fulfillmentChoice('PICKUP', 'Retirada',
                'Sem taxa e sem pedido mínimo', Icons.storefront_outlined),
            _fulfillmentChoice('DELIVERY', 'Entrega',
                'Selecione uma zona atendida', Icons.delivery_dining_outlined),
            if (_fulfillmentType == 'DELIVERY') ...[
              const SizedBox(height: 8),
              if (_savedAddresses.isNotEmpty)
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedAddress,
                  decoration:
                      const InputDecoration(labelText: 'Endereço salvo'),
                  items: _savedAddresses
                      .map((address) => DropdownMenuItem(
                          value: address,
                          child:
                              Text(address['label']?.toString() ?? 'Endereço')))
                      .toList(),
                  onChanged: _selectAddress,
                ),
              TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _lookupCep(),
                decoration: InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                  suffixIcon: _loadingCep
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              if (_cepError != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _cepError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Endereço de entrega'),
              ),
              TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número'),
              ),
              if (_loadingDeliveryZones)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator()),
              if (_selectedZone != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text('Zona de entrega confirmada'),
                    subtitle: Text(
                        '${_selectedZone!['neighborhood']} · ${_selectedZone!['city']}'),
                  ),
                ),
              TextField(
                controller: _neighborhoodController,
                readOnly:
                    _cepController.text.replaceAll(RegExp(r'\D'), '').length ==
                        8,
                decoration: const InputDecoration(labelText: 'Bairro'),
              ),
              TextField(
                  controller: _cityController,
                  readOnly: _cepController.text
                          .replaceAll(RegExp(r'\D'), '')
                          .length ==
                      8,
                  decoration: const InputDecoration(labelText: 'Cidade')),
              TextField(
                controller: _complementController,
                decoration:
                    const InputDecoration(labelText: 'Complemento (opcional)'),
              ),
              if (_selectedZone != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      'Taxa R\$ ${_selectedZone!['delivery_fee']} · mínimo R\$ ${_selectedZone!['minimum_order_amount']} · ${_selectedZone!['estimated_minutes']} min'),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_coverageMessage ??
                      'Informe o CEP para verificar se o endereço está na área de entrega.'),
                ),
              if (_coverageMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _coverageMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
            _sectionTitle(context, 'Forma de pagamento'),
            _paymentChoice(
                'PIX', 'PIX', 'A conferência será manual.', Icons.pix_outlined),
            _paymentChoice('CASH', 'Dinheiro', 'Você poderá informar o troco.',
                Icons.payments_outlined),
            _paymentChoice('CARD_ON_DELIVERY', 'Cartão na entrega/retirada',
                'Não armazenamos dados do cartão.', Icons.credit_card_outlined),
            if (_paymentMethod == 'CASH')
              TextField(
                controller: _changeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Troco para quanto?'),
              ),
            if (_paymentMethod == 'PIX') _pixInstructions(context),
            _sectionTitle(context, 'Observações'),
            TextField(
              controller: _noteController,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Alguma observação para a pizzaria?'),
            ),
            _sectionTitle(context, 'Cupom de desconto'),
            TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Código do cupom', hintText: 'Ex.: CAMPY10')),
            _sectionTitle(context, 'Resumo'),
            ...widget.cartController.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item.quantity}x ${item.productName}'),
                subtitle: Text([
                  item.sizeName,
                  if (item.doughName != null) 'Massa: ${item.doughName}',
                  if (item.flavorNames.isNotEmpty)
                    'Sabores: ${item.flavorNames.join(', ')}',
                ].join(' · ')),
                trailing: Text(_formatPrice(item.totalPrice)),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text(_formatPrice(widget.cartController.subtotal),
                    style: Theme.of(context).textTheme.titleLarge),
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
                child: Text(_controller.errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: ElevatedButton(
              onPressed: _controller.status == CheckoutStatus.submitting
                  ? null
                  : _submit,
              child: _controller.status == CheckoutStatus.submitting
                  ? const CircularProgressIndicator()
                  : const Text('Confirmar pedido'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fulfillmentChoice(
      String value, String title, String subtitle, IconData icon) {
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

  Widget _paymentChoice(
      String value, String title, String subtitle, IconData icon) {
    return RadioListTile<String>(
      value: value,
      groupValue: _paymentMethod,
      onChanged: (newValue) => setState(() => _paymentMethod = newValue!),
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  Widget _pixInstructions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _loadingPixSettings
          ? const Row(children: [
              SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Carregando dados do PIX...'),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Pague pelo PIX e envie o comprovante após finalizar o pedido.'),
                if (_pixKey.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text('A chave PIX ainda não foi configurada pela pizzaria.',
                      style: TextStyle(color: colors.error)),
                ] else ...[
                  const SizedBox(height: 12),
                  const Text('Chave PIX',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  SelectableText(_pixKey),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _pixKey));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Chave PIX copiada.')));
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copiar chave'),
                    ),
                  ),
                ],
                if (_pickupInstructions.isNotEmpty) Text(_pickupInstructions),
              ],
            ),
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
              Text('Pedido recebido!',
                  style: Theme.of(context).textTheme.headlineMedium),
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
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Voltar à Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double price) =>
    'R\$ ${price.toStringAsFixed(2).replaceAll('.', ',')}';
