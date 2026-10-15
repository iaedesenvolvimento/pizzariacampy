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
      if (!mounted || response is! Map<String, dynamic>) {
        return;
      }
      setState(() {
        _isOpen = response['status'] == 'OPEN';
        _message = response['message']?.toString();
      });
    } catch (_) {
      if (mounted) {
        setState(
            () => _message = 'Não foi possível consultar o horário da loja.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final background =
        _isOpen ? const Color(0xFFDDF3E5) : const Color(0xFFFFD9D5);
    final foreground =
        _isOpen ? const Color(0xFF246B3A) : const Color(0xFF9D2D2D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
              _isOpen
                  ? Icons.storefront_outlined
                  : Icons.store_mall_directory_outlined,
              color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message ?? 'Consultando horário da loja...',
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.chevron_right, color: foreground),
        ],
      ),
    );
  }
}
