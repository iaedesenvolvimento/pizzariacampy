import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class BusinessStatusController extends ChangeNotifier {
  bool isOpen = false;
  bool isLoading = true;
  String? message;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient().get('/business-status');
      if (response is Map<String, dynamic>) {
        isOpen = response['status'] == 'OPEN';
        message = response['message']?.toString();
      }
    } catch (_) {
      isOpen = false;
      message = 'Não foi possível consultar o horário da loja.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class BusinessStatusBanner extends StatefulWidget {
  const BusinessStatusBanner({required this.controller, super.key});

  final BusinessStatusController controller;

  @override
  State<BusinessStatusBanner> createState() => _BusinessStatusBannerState();
}

class _BusinessStatusBannerState extends State<BusinessStatusBanner> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => _buildBanner(context),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final isOpen = widget.controller.isOpen;
    final background =
        isOpen ? const Color(0xFFDDF3E5) : const Color(0xFFFFD9D5);
    final foreground =
        isOpen ? const Color(0xFF246B3A) : const Color(0xFF9D2D2D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
              isOpen
                  ? Icons.storefront_outlined
                  : Icons.store_mall_directory_outlined,
              color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.controller.isLoading
                  ? 'Consultando horário da loja...'
                  : widget.controller.message ?? 'Fechado',
              style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.chevron_right, color: foreground),
        ],
      ),
    );
  }
}
