import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'admin_design_system.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  final _storeName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _pixKey = TextEditingController();
  final _pickup = TextEditingController();
  AdminApiClient? _adminApi;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  List<TextEditingController> get _controllers => [_storeName, _phone, _address, _pixKey, _pickup];

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(_markDirty);
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_loading && mounted && !_dirty) setState(() => _dirty = true);
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final storage = await AppStorage.create();
      _adminApi = AdminApiClient(_api, storage);
      final data = await _adminApi!.get('/admin/settings') as Map<String, dynamic>;
      _storeName.text = data['store_name']?.toString() ?? '';
      _phone.text = data['phone']?.toString() ?? '';
      _address.text = data['address']?.toString() ?? '';
      _pixKey.text = data['pix_key']?.toString() ?? '';
      _pickup.text = data['pickup_instructions']?.toString() ?? '';
      if (mounted) setState(() { _loading = false; _dirty = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Não foi possível carregar as configurações.'; });
    }
  }

  Future<void> _save() async {
    if (_adminApi == null || _saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _adminApi!.patch('/admin/settings', body: {
        'store_name': _storeName.text.trim(), 'phone': _phone.text.trim(), 'address': _address.text.trim(),
        'pix_key': _pixKey.text.trim(), 'pickup_instructions': _pickup.text.trim(),
      });
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações atualizadas.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar as configurações. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Configurações da loja',
      subtitle: 'Mantenha os dados exibidos aos seus clientes atualizados.',
      activeDestination: AdminDestinationId.settings,
      body: _loading
          ? const AdminLoadingState(label: 'Carregando configurações')
          : _error != null
              ? AdminErrorState(message: _error!, onRetry: _load)
              : LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth > AdminBreakpoints.mediumMax ? 760.0 : double.infinity;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    child: Center(child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width),
                      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const AdminPageHeader(title: 'Configurações da loja', subtitle: 'Atualize os dados da Pizzaria Campy, pagamentos e retirada.'),
                        AdminSectionCard(title: 'Dados da loja', child: Column(children: [
                          AdminTextField(controller: _storeName, label: 'Nome da loja', validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome da loja.' : null),
                          const SizedBox(height: AdminSpacing.md),
                          AdminTextField(controller: _phone, label: 'Telefone', keyboardType: TextInputType.phone),
                          const SizedBox(height: AdminSpacing.md),
                          AdminTextField(controller: _address, label: 'Endereço', maxLines: 2),
                        ])),
                        const SizedBox(height: AdminSpacing.lg),
                        AdminSectionCard(title: 'Pagamentos', child: AdminTextField(controller: _pixKey, label: 'Chave PIX')),
                        const SizedBox(height: AdminSpacing.lg),
                        AdminSectionCard(title: 'Retirada', child: AdminTextField(controller: _pickup, label: 'Instruções para retirada', maxLines: 4)),
                        const SizedBox(height: AdminSpacing.xl),
                        Align(alignment: Alignment.centerRight, child: FilledButton.icon(
                          onPressed: _saving || !_dirty ? null : _save,
                          icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
                        )),
                      ])),
                    )),
                  );
                }),
    );
  }
}
