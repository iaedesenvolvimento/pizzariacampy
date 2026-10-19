import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import 'admin_api_client.dart';

enum AdminDashboardStatus { idle, loading, loaded, error }

class AdminOrderSummary {
  const AdminOrderSummary(
      {required this.id,
      required this.number,
      required this.status,
      required this.fulfillmentType,
      required this.total,
      required this.paymentId,
      required this.paymentStatus,
      required this.proofUrl,
      this.customerName,
      this.customerPhone,
      this.customerEmail,
      this.deliveryAddressSnapshot,
      this.createdAt});

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) =>
      AdminOrderSummary(
        id: json['id']?.toString() ?? '',
        number: json['order_number']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        fulfillmentType: json['fulfillment_type']?.toString() ?? 'PICKUP',
        total: json['total_amount']?.toString() ?? '0.00',
        paymentId: json['payment_id']?.toString(),
        paymentStatus: json['payment_status']?.toString(),
        proofUrl: json['proof_url']?.toString(),
        customerName: json['customer_name']?.toString(),
        customerPhone: json['customer_phone']?.toString(),
        customerEmail: json['customer_email']?.toString(),
        deliveryAddressSnapshot:
            json['delivery_address_snapshot'] is Map<String, dynamic>
                ? json['delivery_address_snapshot'] as Map<String, dynamic>
                : null,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );

  final String id;
  final String number;
  final String status;
  final String fulfillmentType;
  final String total;
  final String? paymentId;
  final String? paymentStatus;
  final String? proofUrl;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final Map<String, dynamic>? deliveryAddressSnapshot;
  final DateTime? createdAt;
}

class AdminDashboardData {
  const AdminDashboardData({required this.metrics, required this.recentOrders});

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final metrics = <String, int>{};
    for (final key in [
      'pending_orders',
      'preparing_orders',
      'ready_orders',
      'active_products',
      'active_categories',
      'active_flavors',
      'active_sizes',
      'active_edges',
      'active_extras',
      'customers'
    ]) {
      metrics[key] = json[key] as int? ?? 0;
    }
    return AdminDashboardData(
      metrics: metrics,
      recentOrders: (json['recent_orders'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminOrderSummary.fromJson)
          .toList(),
    );
  }

  final Map<String, int> metrics;
  final List<AdminOrderSummary> recentOrders;
}

class AdminDashboardController extends ChangeNotifier {
  AdminDashboardController(this._adminApi);

  final AdminApiClient _adminApi;
  AdminDashboardStatus status = AdminDashboardStatus.idle;
  AdminDashboardData? data;
  String? errorMessage;

  Future<void> load() async {
    status = AdminDashboardStatus.loading;
    notifyListeners();
    try {
      final response = await _adminApi.get('/admin/dashboard');
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Dashboard inválido.');
      }
      data = AdminDashboardData.fromJson(response);
      status = AdminDashboardStatus.loaded;
    } on AppException catch (error) {
      status = AdminDashboardStatus.error;
      errorMessage = error.message;
    } catch (_) {
      status = AdminDashboardStatus.error;
      errorMessage = 'Não foi possível carregar o painel.';
    }
    notifyListeners();
  }

  Future<bool> changeStatus(String orderId, String nextStatus) async {
    try {
      await _adminApi.patch(
        '/admin/orders/$orderId/status',
        body: {'status': nextStatus},
      );
      await load();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Não foi possível atualizar o pedido.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> reviewPayment(String paymentId, String nextStatus,
      {String? notes}) async {
    try {
      await _adminApi.patch(
        '/admin/payments/$paymentId/review',
        body: {'status': nextStatus, 'notes': notes},
      );
      await load();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Não foi possível revisar o pagamento.';
    }
    notifyListeners();
    return false;
  }
}
