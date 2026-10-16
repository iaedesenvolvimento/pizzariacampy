import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = const [];
  bool? _activeFilter;
  String? _error;
  bool _loading = true;

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
      final response =
          await AdminApiClient(_api, storage).get('/admin/customers');
      if (response is! List<dynamic>) throw const FormatException();
      if (!mounted) return;
      setState(() {
        _customers = response.whereType<Map<String, dynamic>>().toList();
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os clientes.';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleCustomers {
    return AdminCustomerFilters.visible(
      customers: _customers,
      query: _searchController.text,
      activeFilter: _activeFilter,
    );
  }

  int _count(bool? status) => status == null
      ? _customers.length
      : _customers.where((customer) => customer['is_active'] == status).length;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Clientes',
      activeDestination: AdminDestinationId.customers,
      body: _loading && _customers.isEmpty
          ? const AdminLoadingState(label: 'Carregando clientes')
          : _error != null && _customers.isEmpty
              ? AdminErrorState(message: _error!, onRetry: _load)
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final customers = _visibleCustomers;
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth > AdminBreakpoints.compactMax ? 2 : 1;
          final cardWidth = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - AdminSpacing.md) / columns;
          return ListView(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            children: [
              AdminPageHeader(
                title: 'Clientes',
                subtitle: 'Gerencie os clientes cadastrados na Pizzaria Campy.',
                actions: [
                  IconButton(
                    tooltip: 'Atualizar clientes',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              _Summary(
                total: _count(null),
                active: _count(true),
                inactive: _count(false),
              ),
              const SizedBox(height: AdminSpacing.lg),
              AdminSearchField(
                controller: _searchController,
                hintText: 'Buscar por nome ou e-mail',
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
                    label: Text('Inativos ${_count(false)}'),
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
              if (customers.isEmpty)
                SizedBox(
                  height: 220,
                  child: AdminEmptyState(
                    message: _searchController.text.trim().isNotEmpty ||
                            _activeFilter != null
                        ? 'Nenhum cliente encontrado.'
                        : 'Nenhum cliente cadastrado.',
                    icon: Icons.people_outline,
                  ),
                )
              else
                Wrap(
                  spacing: AdminSpacing.md,
                  runSpacing: AdminSpacing.md,
                  children: [
                    for (final customer in customers)
                      SizedBox(
                        width: cardWidth,
                        child: AdminCustomerCard(customer: customer),
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

class _Summary extends StatelessWidget {
  const _Summary(
      {required this.total, required this.active, required this.inactive});

  final int total;
  final int active;
  final int inactive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AdminSpacing.md,
      runSpacing: AdminSpacing.md,
      children: [
        _SummaryItem(label: 'Total', value: total),
        _SummaryItem(label: 'Ativos', value: active),
        _SummaryItem(label: 'Inativos', value: inactive),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.people_outline, size: 18),
      label: Text('$label: $value'),
    );
  }
}
