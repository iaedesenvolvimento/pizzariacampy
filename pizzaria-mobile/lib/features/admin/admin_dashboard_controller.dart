import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';

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
      required this.proofUrl});

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
      );

  final String id;
  final String number;
  final String status;
  final String fulfillmentType;
  final String total;
  final String? paymentId;
  final String? paymentStatus;
  final String? proofUrl;
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
  AdminDashboardController(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final AppStorage _storage;
  AdminDashboardStatus status = AdminDashboardStatus.idle;
  AdminDashboardData? data;
  String? errorMessage;

  Future<void> load() async {
    status = AdminDashboardStatus.loading;
    notifyListeners();
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      final response = await _getDashboard(token);
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Dashboard inválido.');
      }
      data = AdminDashboardData.fromJson(response);
      status = AdminDashboardStatus.loaded;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final refreshedToken = await _refreshAccessToken();
        if (refreshedToken != null) {
          try {
            final response = await _getDashboard(refreshedToken);
            if (response is Map<String, dynamic>) {
              data = AdminDashboardData.fromJson(response);
              status = AdminDashboardStatus.loaded;
              notifyListeners();
              return;
            }
          } catch (_) {
            // Fall through to the authentication error below.
          }
        }
      }
      status = AdminDashboardStatus.error;
      errorMessage = error.message;
    } on AppException catch (error) {
      status = AdminDashboardStatus.error;
      errorMessage = error.message;
    } catch (_) {
      status = AdminDashboardStatus.error;
      errorMessage = 'Não foi possível carregar o painel.';
    }
    notifyListeners();
  }

  Future<dynamic> _getDashboard(String token) {
    return _apiClient
        .get('/admin/dashboard', headers: {'Authorization': 'Bearer $token'});
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null) return null;
    try {
      final response = await _apiClient
          .post('/auth/refresh', body: {'refresh_token': refreshToken});
      if (response is! Map<String, dynamic>) return null;
      final accessToken = response['access_token']?.toString();
      final nextRefreshToken = response['refresh_token']?.toString();
      if (accessToken == null || nextRefreshToken == null) return null;
      await _storage.saveTokens(
          accessToken: accessToken, refreshToken: nextRefreshToken);
      return accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<bool> changeStatus(String orderId, String nextStatus) async {
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      await _apiClient.patch(
        '/admin/orders/$orderId/status',
        headers: {'Authorization': 'Bearer $token'},
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

  Future<bool> reviewPayment(String paymentId, String nextStatus, {String? notes}) async {
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      await _apiClient.patch(
        '/admin/payments/$paymentId/review',
        headers: {'Authorization': 'Bearer $token'},
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
