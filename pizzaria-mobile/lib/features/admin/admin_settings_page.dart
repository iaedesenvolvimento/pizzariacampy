import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  final _storeName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _pixKey = TextEditingController();
  final _pickup = TextEditingController();
  AdminApiClient? _adminApi;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in [_storeName, _phone, _address, _pixKey, _pickup]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final storage = await AppStorage.create();
      _adminApi = AdminApiClient(_api, storage);
      final data =
          await _adminApi!.get('/admin/settings') as Map<String, dynamic>;
      _storeName.text = data['store_name']?.toString() ?? '';
      _phone.text = data['phone']?.toString() ?? '';
      _address.text = data['address']?.toString() ?? '';
      _pixKey.text = data['pix_key']?.toString() ?? '';
      _pickup.text = data['pickup_instructions']?.toString() ?? '';
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_adminApi == null || _storeName.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _adminApi!.patch('/admin/settings', body: {
        'store_name': _storeName.text,
        'phone': _phone.text,
        'address': _address.text,
        'pix_key': _pixKey.text,
        'pickup_instructions': _pickup.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configurações salvas.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                          controller: _storeName,
                          decoration: const InputDecoration(
                              labelText: 'Nome da pizzaria *')),
                      TextField(
                          controller: _phone,
                          decoration:
                              const InputDecoration(labelText: 'Telefone')),
                      TextField(
                          controller: _address,
                          maxLines: 2,
                          decoration:
                              const InputDecoration(labelText: 'Endereço')),
                      TextField(
                          controller: _pixKey,
                          decoration:
                              const InputDecoration(labelText: 'Chave PIX')),
                      TextField(
                          controller: _pickup,
                          maxLines: 3,
                          decoration: const InputDecoration(
                              labelText: 'Instruções para retirada')),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving
                              ? 'Salvando...'
                              : 'Salvar configurações')),
                    ],
                  ),
      );
}
