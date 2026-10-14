import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class BusinessStatusBanner extends StatefulWidget {
  const BusinessStatusBanner({super.key});

  @override
  State<BusinessStatusBanner> createState() => _BusinessStatusBannerState();
}

class _BusinessStatusBannerState extends State<BusinessStatusBanner> {
  String? _message;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient().get('/business-status');
      if (!mounted || response is! Map<String, dynamic>) return;
      setState(() {
        _isOpen = response['status'] == 'OPEN';
        _message = response['message']?.toString();
      });
    } catch (_) {
      if (mounted) setState(() => _message = 'Não foi possível consultar o horário da loja.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isOpen ? colorScheme.primaryContainer : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_isOpen ? Icons.storefront_outlined : Icons.store_mall_directory_outlined),
          const SizedBox(width: 12),
          Expanded(child: Text(_message ?? 'Consultando horário da loja...')),
        ],
      ),
    );
  }
}
