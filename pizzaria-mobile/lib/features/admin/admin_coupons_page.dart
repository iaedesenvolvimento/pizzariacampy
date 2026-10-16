import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  final _searchController = TextEditingController();
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _items = const [];
  bool? _activeFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final storage = await AppStorage.create();
      _adminApi = AdminApiClient(_api, storage);
      final response = await _adminApi!.get('/admin/coupons');
      if (response is! List<dynamic>) throw const FormatException();
      if (!mounted) return;
      setState(() {
        _items = response.whereType<Map<String, dynamic>>().toList();
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os cupons.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesStatus =
          _activeFilter == null || item['is_active'] == _activeFilter;
      final code = item['code']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      return matchesStatus &&
          (query.isEmpty ||
              code.contains(query) ||
              description.contains(query));
    }).toList();
  }

  int _count(bool? status) => status == null
      ? _items.length
      : _items.where((item) => item['is_active'] == status).length;

  Future<void> _create() => _openForm();

  Future<void> _edit(Map<String, dynamic> item) => _openForm(initial: item);

  Future<void> _openForm({Map<String, dynamic>? initial}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CouponForm(initial: initial),
    );
    if (result == null || _adminApi == null) {
      return;
    }
    try {
      if (initial == null) {
        await _adminApi!.post('/admin/coupons', body: result);
      } else {
        await _adminApi!.patch('/admin/coupons/${initial['id']}', body: result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  initial == null ? 'Cupom criado.' : 'Cupom atualizado.')),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar o cupom.')),
        );
      }
    }
  }

  Future<void> _toggle(Map<String, dynamic> item) async {
    final isActive = item['is_active'] == true;
    if (isActive) {
      final confirmed = await AdminConfirmationDialog.show(
        context: context,
        title: 'Pausar cupom?',
        message:
            'O cupom ${item['code']} ficará indisponível para novos pedidos.',
        confirmLabel: 'Pausar cupom',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await _adminApi!.patch(
        '/admin/coupons/${item['id']}',
        body: _payload(item, isActive: !isActive),
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar o cupom.')),
        );
      }
    }
  }

  Map<String, dynamic> _payload(Map<String, dynamic> item, {bool? isActive}) =>
      {
        'code': item['code'],
        'discount_type': item['discount_type'],
        'value': item['value'],
        'starts_at': item['starts_at'],
        'ends_at': item['ends_at'],
        'minimum_order_amount': item['minimum_order_amount'] ?? 0,
        'usage_limit': item['usage_limit'],
        'per_customer_limit': item['per_customer_limit'],
        'is_active': isActive ?? item['is_active'] == true,
        'description': item['description'],
      };

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Promoções e cupons',
      activeDestination: AdminDestinationId.coupons,
      body: _loading && _items.isEmpty
          ? const AdminLoadingState(label: 'Carregando cupons')
          : _error != null && _items.isEmpty
              ? AdminErrorState(message: _error!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final items = _visibleItems;
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth > AdminBreakpoints.compactMax
              ? (constraints.maxWidth - AdminSpacing.md) / 2
              : constraints.maxWidth;
          return ListView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            children: [
              AdminPageHeader(
                title: 'Promoções e cupons',
                subtitle:
                    'Gerencie os cupons e descontos disponíveis para os clientes.',
                actions: [
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo cupom'),
                  ),
                  IconButton(
                    tooltip: 'Atualizar cupons',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              AdminSearchField(
                controller: _searchController,
                hintText: 'Buscar por código ou descrição',
              ),
              const SizedBox(height: AdminSpacing.md),
              AdminFilterBar(
                children: [
                  ChoiceChip(
                    label: Text('Todos ${_count(null)}'),
                    selected: _activeFilter == null,
                    onSelected: (_) => setState(() => _activeFilter = null),
                  ),
                  ChoiceChip(
                    label: Text('Ativos ${_count(true)}'),
                    selected: _activeFilter == true,
                    onSelected: (_) => setState(() => _activeFilter = true),
                  ),
                  ChoiceChip(
                    label: Text('Pausados ${_count(false)}'),
                    selected: _activeFilter == false,
                    onSelected: (_) => setState(() => _activeFilter = false),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AdminSpacing.md),
                Text(_error!, style: TextStyle(color: AdminColors.danger)),
              ],
              const SizedBox(height: AdminSpacing.xl),
              if (items.isEmpty)
                SizedBox(
                  height: 220,
                  child: AdminEmptyState(
                    message: _searchController.text.trim().isNotEmpty ||
                            _activeFilter != null
                        ? 'Nenhum cupom encontrado.'
                        : 'Nenhum cupom cadastrado.',
                    icon: Icons.local_offer_outlined,
                  ),
                )
              else
                Wrap(
                  spacing: AdminSpacing.md,
                  runSpacing: AdminSpacing.md,
                  children: [
                    for (final item in items)
                      SizedBox(
                        width: cardWidth,
                        child: AdminCouponCard(
                          coupon: item,
                          onEdit: () => _edit(item),
                          onToggle: () => _toggle(item),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CouponForm extends StatefulWidget {
  const _CouponForm({this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<_CouponForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _minimum;
  late final TextEditingController _usageLimit;
  late final TextEditingController _perCustomerLimit;
  late bool _isActive;
  late String _type;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _code = TextEditingController(text: initial?['code']?.toString() ?? '');
    _description =
        TextEditingController(text: initial?['description']?.toString() ?? '');
    _value = TextEditingController(text: initial?['value']?.toString() ?? '');
    _minimum = TextEditingController(
        text: initial?['minimum_order_amount']?.toString() ?? '0');
    _usageLimit =
        TextEditingController(text: initial?['usage_limit']?.toString() ?? '');
    _perCustomerLimit = TextEditingController(
        text: initial?['per_customer_limit']?.toString() ?? '');
    _type = initial?['discount_type']?.toString() ?? 'PERCENTAGE';
    _isActive = initial?['is_active'] != false;
  }

  @override
  void dispose() {
    _code.dispose();
    _description.dispose();
    _value.dispose();
    _minimum.dispose();
    _usageLimit.dispose();
    _perCustomerLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Novo cupom' : 'Editar cupom'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminTextField(
                controller: _code,
                label: 'Código *',
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Informe ao menos 3 caracteres.'
                    : null,
              ),
              AdminTextField(
                controller: _description,
                label: 'Descrição (opcional)',
                maxLines: 2,
              ),
              DropdownButtonFormField<String>(
                value: _type,
                decoration:
                    const InputDecoration(labelText: 'Tipo de desconto'),
                items: const [
                  DropdownMenuItem(
                      value: 'PERCENTAGE', child: Text('Percentual')),
                  DropdownMenuItem(value: 'FIXED', child: Text('Valor fixo')),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              AdminTextField(
                controller: _value,
                label: _type == 'PERCENTAGE' ? 'Percentual *' : 'Valor *',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: _validateValue,
              ),
              AdminCurrencyField(
                controller: _minimum,
                label: 'Pedido mínimo',
                validator: (value) =>
                    _validateNonNegative(value, 'pedido mínimo'),
              ),
              AdminTextField(
                controller: _usageLimit,
                label: 'Limite total (opcional)',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    _validatePositiveInteger(value, 'limite total'),
              ),
              AdminTextField(
                controller: _perCustomerLimit,
                label: 'Limite por cliente (opcional)',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    _validatePositiveInteger(value, 'limite por cliente'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_isActive ? 'Cupom ativo' : 'Cupom pausado'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String? _validateValue(String? value) {
    final parsed = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Informe um valor maior que zero.';
    }
    if (_type == 'PERCENTAGE' && parsed > 100) {
      return 'O percentual deve estar entre 0 e 100.';
    }
    return null;
  }

  String? _validateNonNegative(String? value, String label) {
    final parsed = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    return parsed == null || parsed < 0 ? 'Informe um $label válido.' : null;
  }

  String? _validatePositiveInteger(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    return parsed == null || parsed < 1
        ? 'Informe um $label maior que zero.'
        : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final initial = widget.initial;
    Navigator.pop(context, {
      'code': _code.text.trim().toUpperCase(),
      'description':
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      'discount_type': _type,
      'value': _value.text.trim().replaceAll(',', '.'),
      'starts_at': initial?['starts_at'],
      'ends_at': initial?['ends_at'],
      'minimum_order_amount': _minimum.text.trim().replaceAll(',', '.'),
      'usage_limit': _usageLimit.text.trim().isEmpty
          ? null
          : int.parse(_usageLimit.text.trim()),
      'per_customer_limit': _perCustomerLimit.text.trim().isEmpty
          ? null
          : int.parse(_perCustomerLimit.text.trim()),
      'is_active': _isActive,
    });
  }
}
