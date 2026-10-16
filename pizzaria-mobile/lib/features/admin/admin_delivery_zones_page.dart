import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminDeliveryZonesPage extends StatefulWidget {
  const AdminDeliveryZonesPage({super.key});

  @override
  State<AdminDeliveryZonesPage> createState() => _AdminDeliveryZonesPageState();
}

class _AdminDeliveryZonesPageState extends State<AdminDeliveryZonesPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  final _searchController = TextEditingController();
  AdminApiClient? _adminApi;
  List<Map<String, dynamic>> _zones = const [];
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
      final response = await _adminApi!.get('/admin/delivery-zones');
      if (response is! List<dynamic>) throw const FormatException();
      if (!mounted) return;
      setState(() {
        _zones = response.whereType<Map<String, dynamic>>().toList();
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar as zonas de entrega.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleZones => filterDeliveryZones(
        zones: _zones,
        query: _searchController.text,
        activeFilter: _activeFilter,
      );

  int _count(bool? status) => status == null
      ? _zones.length
      : _zones.where((zone) => zone['is_active'] == status).length;

  Future<void> _openForm([Map<String, dynamic>? zone]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ZoneForm(initial: zone),
    );
    if (result == null || _adminApi == null) return;
    try {
      final id = zone?['id']?.toString();
      if (id == null) {
        await _adminApi!.post('/admin/delivery-zones', body: result);
      } else {
        await _adminApi!.patch('/admin/delivery-zones/$id', body: result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(id == null ? 'Zona criada.' : 'Zona atualizada.')),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a zona.')),
        );
      }
    }
  }

  Future<void> _toggle(Map<String, dynamic> zone) async {
    final isActive = zone['is_active'] == true;
    if (isActive) {
      final confirmed = await AdminConfirmationDialog.show(
        context: context,
        title: 'Pausar zona?',
        message:
            '${zone['name'] ?? zone['neighborhood']} ficará indisponível para novas entregas.',
        confirmLabel: 'Pausar zona',
        destructive: true,
      );
      if (!confirmed) return;
    }
    try {
      await _adminApi!.patch(
        '/admin/delivery-zones/${zone['id']}',
        body: _payload(zone, isActive: !isActive),
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar a zona.')),
        );
      }
    }
  }

  Map<String, dynamic> _payload(Map<String, dynamic> zone, {bool? isActive}) =>
      {
        'name': zone['name'],
        'city': zone['city'],
        'neighborhood': zone['neighborhood'],
        'delivery_fee': zone['delivery_fee'],
        'minimum_order_amount': zone['minimum_order_amount'] ?? 0,
        'estimated_minutes': zone['estimated_minutes'] ?? 45,
        'is_active': isActive ?? zone['is_active'] == true,
      };

  Future<void> _delete(Map<String, dynamic> zone) async {
    final confirmed = await AdminConfirmationDialog.show(
      context: context,
      title: 'Excluir zona?',
      message: 'A zona ${zone['name'] ?? zone['neighborhood']} será removida.',
      confirmLabel: 'Excluir zona',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _adminApi!.delete('/admin/delivery-zones/${zone['id']}');
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir a zona.')),
        );
      }
    }
  }

  Future<void> _setAllZonesStatus(bool isActive) async {
    final action = isActive ? 'Ativar' : 'Pausar';
    final confirmed = await AdminConfirmationDialog.show(
      context: context,
      title: '$action todas as zonas?',
      message: isActive
          ? 'Todas as regiões configuradas voltarão a aceitar entregas.'
          : 'Pausar todas as zonas impedirá novas entregas nas regiões configuradas.',
      confirmLabel: '$action todas',
      destructive: !isActive,
    );
    if (!confirmed) return;
    try {
      final response = await _adminApi!.post(
        '/admin/delivery-zones/bulk-status',
        body: {'is_active': isActive},
      );
      await _load();
      if (!mounted) return;
      final count = response is Map<String, dynamic>
          ? response['updated_count']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${count ?? 'Todas as'} zonas foram ${isActive ? 'ativadas' : 'pausadas'}.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível atualizar todas as zonas.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Entregas',
      activeDestination: AdminDestinationId.delivery,
      body: _loading && _zones.isEmpty
          ? const AdminLoadingState(label: 'Carregando zonas de entrega')
          : _error != null && _zones.isEmpty
              ? AdminErrorState(message: _error!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final zones = _visibleZones;
    final allPaused = _zones.isNotEmpty && _count(true) == 0;
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
                title: 'Entregas',
                subtitle:
                    'Gerencie as regiões atendidas, taxas e condições de entrega.',
                actions: [
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova zona de entrega'),
                  ),
                  IconButton(
                    tooltip: 'Atualizar zonas',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              Wrap(
                spacing: AdminSpacing.md,
                runSpacing: AdminSpacing.sm,
                children: [
                  Chip(label: Text('Total: ${_count(null)}')),
                  Chip(label: Text('Ativas: ${_count(true)}')),
                  Chip(label: Text('Pausadas: ${_count(false)}')),
                ],
              ),
              if (allPaused) ...[
                const SizedBox(height: AdminSpacing.md),
                const AdminSectionCard(
                  title: 'Atenção operacional',
                  child: Text('Todas as zonas de entrega estão pausadas.'),
                ),
              ],
              const SizedBox(height: AdminSpacing.lg),
              AdminSearchField(
                controller: _searchController,
                hintText: 'Buscar por nome, cidade ou bairro',
              ),
              const SizedBox(height: AdminSpacing.md),
              AdminFilterBar(
                children: [
                  ChoiceChip(
                    label: Text('Todas ${_count(null)}'),
                    selected: _activeFilter == null,
                    onSelected: (_) => setState(() => _activeFilter = null),
                  ),
                  ChoiceChip(
                    label: Text('Ativas ${_count(true)}'),
                    selected: _activeFilter == true,
                    onSelected: (_) => setState(() => _activeFilter = true),
                  ),
                  ChoiceChip(
                    label: Text('Pausadas ${_count(false)}'),
                    selected: _activeFilter == false,
                    onSelected: (_) => setState(() => _activeFilter = false),
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.md),
              Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _setAllZonesStatus(true),
                    icon: const Icon(Icons.public),
                    label: const Text('Ativar todas'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _setAllZonesStatus(false),
                    icon: const Icon(Icons.public_off),
                    label: const Text('Pausar todas'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AdminSpacing.md),
                Text(_error!, style: TextStyle(color: AdminColors.danger)),
              ],
              const SizedBox(height: AdminSpacing.xl),
              if (zones.isEmpty)
                SizedBox(
                  height: 220,
                  child: AdminEmptyState(
                    message: _searchController.text.trim().isNotEmpty ||
                            _activeFilter != null
                        ? 'Nenhuma zona encontrada.'
                        : 'Nenhuma zona de entrega cadastrada.',
                    icon: Icons.location_on_outlined,
                  ),
                )
              else
                Wrap(
                  spacing: AdminSpacing.md,
                  runSpacing: AdminSpacing.md,
                  children: [
                    for (final zone in zones)
                      SizedBox(
                        width: cardWidth,
                        child: AdminDeliveryZoneCard(
                          zone: zone,
                          onEdit: () => _openForm(zone),
                          onToggle: () => _toggle(zone),
                          onDelete: () => _delete(zone),
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

class _ZoneForm extends StatefulWidget {
  const _ZoneForm({this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<_ZoneForm> createState() => _ZoneFormState();
}

class _ZoneFormState extends State<_ZoneForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _neighborhood;
  late final TextEditingController _fee;
  late final TextEditingController _minimum;
  late final TextEditingController _minutes;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?['name']?.toString() ?? '');
    _city = TextEditingController(
        text: initial?['city']?.toString() ?? 'Carapicuíba');
    _neighborhood =
        TextEditingController(text: initial?['neighborhood']?.toString() ?? '');
    _fee = TextEditingController(
        text: initial?['delivery_fee']?.toString() ?? '0');
    _minimum = TextEditingController(
        text: initial?['minimum_order_amount']?.toString() ?? '0');
    _minutes = TextEditingController(
        text: initial?['estimated_minutes']?.toString() ?? '45');
    _isActive = initial?['is_active'] != false;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _city,
      _neighborhood,
      _fee,
      _minimum,
      _minutes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'Nova zona de entrega'
          : 'Editar zona de entrega'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminTextField(
                controller: _name,
                label: 'Nome *',
                validator: _required,
              ),
              AdminTextField(
                controller: _city,
                label: 'Cidade *',
                validator: _required,
              ),
              AdminTextField(
                controller: _neighborhood,
                label: 'Bairro/região *',
                validator: _required,
              ),
              AdminCurrencyField(
                controller: _fee,
                label: 'Taxa de entrega *',
                validator: (value) => _nonNegative(value, 'taxa'),
              ),
              AdminCurrencyField(
                controller: _minimum,
                label: 'Pedido mínimo',
                validator: (value) => _nonNegative(value, 'pedido mínimo'),
              ),
              AdminTextField(
                controller: _minutes,
                label: 'Tempo estimado (minutos) *',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final minutes = int.tryParse(value?.trim() ?? '');
                  return minutes == null || minutes < 1
                      ? 'Informe um prazo válido.'
                      : null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_isActive ? 'Zona ativa' : 'Zona pausada'),
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

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório.' : null;

  String? _nonNegative(String? value, String label) {
    final number = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    return number == null || number < 0 ? 'Informe uma $label válida.' : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'city': _city.text.trim(),
      'neighborhood': _neighborhood.text.trim(),
      'delivery_fee': _fee.text.trim().replaceAll(',', '.'),
      'minimum_order_amount': _minimum.text.trim().replaceAll(',', '.'),
      'estimated_minutes': int.parse(_minutes.text.trim()),
      'is_active': _isActive,
    });
  }
}
