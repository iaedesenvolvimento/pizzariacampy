import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _api = ApiClient(config: AppConfig.fromEnvironment());
  List<Map<String, dynamic>> _customers = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final storage = await AppStorage.create();
      final response =
          await AdminApiClient(_api, storage).get('/admin/customers');
      if (response is! List<dynamic>) {
        throw const FormatException('Clientes inválidos.');
      }
      if (!mounted) return;
      setState(() {
        _customers = response.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Clientes')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text('${_customers.length} cliente(s)',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        ..._customers.map((customer) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(customer['name']?.toString() ?? ''),
                                subtitle:
                                    Text(customer['email']?.toString() ?? ''),
                                trailing: Icon(customer['is_active'] == true
                                    ? Icons.check_circle_outline
                                    : Icons.block_outlined),
                              ),
                            )),
                      ],
                    ),
                  ),
      );
}
