import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';

enum OrderTrackingStatus { idle, loading, loaded, error }

class OrderTrackingItem {
  const OrderTrackingItem(
      {required this.name,
      required this.size,
      required this.quantity,
      required this.total});

  factory OrderTrackingItem.fromJson(Map<String, dynamic> json) {
    return OrderTrackingItem(
      name: json['product_name']?.toString() ?? 'Produto',
      size: json['size_name']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 1,
      total: json['line_total']?.toString() ?? '0.00',
    );
  }

  final String name;
  final String size;
  final int quantity;
  final String total;
}

class OrderTracking {
  const OrderTracking({
    required this.orderNumber,
    required this.status,
    required this.fulfillmentType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.proofUrl,
    required this.total,
    required this.deliveryAddress,
    required this.items,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    final address = json['delivery_address_snapshot'];
    final deliveryAddress = address is Map<String, dynamic>
        ? address['formatted']?.toString() ??
            [
              address['address']?.toString(),
              address['neighborhood']?.toString(),
              address['city']?.toString(),
            ].where((part) => part != null && part.isNotEmpty).join(' · ')
        : null;
    return OrderTracking(
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      fulfillmentType: json['fulfillment_type']?.toString() ?? 'PICKUP',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
      proofUrl: (json['payments'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map((payment) => payment['proof_url']?.toString())
          .firstWhere((url) => url != null && url.isNotEmpty,
              orElse: () => null),
      total: json['total_amount']?.toString() ?? '0.00',
      deliveryAddress:
          deliveryAddress?.isEmpty == true ? null : deliveryAddress,
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(OrderTrackingItem.fromJson)
          .toList(),
    );
  }

  final String orderNumber;
  final String status;
  final String fulfillmentType;
  final String paymentMethod;
  final String paymentStatus;
  final String? proofUrl;
  final String total;
  final String? deliveryAddress;
  final List<OrderTrackingItem> items;
}

class OrderTrackingController extends ChangeNotifier {
  OrderTrackingController(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final AppStorage _storage;
  OrderTrackingStatus status = OrderTrackingStatus.idle;
  OrderTracking? order;
  String? errorMessage;

  Future<void> load(String orderId) async {
    status = OrderTrackingStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      final response = await _apiClient
          .get('/orders/$orderId', headers: {'Authorization': 'Bearer $token'});
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Pedido inválido.');
      }
      order = OrderTracking.fromJson(response);
      status = OrderTrackingStatus.loaded;
    } on AppException catch (error) {
      status = OrderTrackingStatus.error;
      errorMessage = error.message;
    } catch (_) {
      status = OrderTrackingStatus.error;
      errorMessage = 'Não foi possível carregar o acompanhamento.';
    }
    notifyListeners();
  }

  Future<bool> cancel(String orderId, {String? reason}) async {
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      final response = await _apiClient.post(
        '/orders/$orderId/cancel',
        headers: {'Authorization': 'Bearer $token'},
        body: {'reason': reason},
      );
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Pedido inválido.');
      }
      order = OrderTracking.fromJson(response);
      status = OrderTrackingStatus.loaded;
      errorMessage = null;
      notifyListeners();
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Não foi possível cancelar o pedido.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> submitPixProof(String orderId, String proofUrl) async {
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      await _apiClient.post(
        '/payments/orders/$orderId/proof',
        headers: {'Authorization': 'Bearer $token'},
        body: {'proof_url': proofUrl},
      );
      await load(orderId);
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Não foi possível enviar o comprovante.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> submitPixProofFile(String orderId, String filePath) async {
    try {
      final token = _storage.accessToken;
      if (token == null) throw const FormatException('Sessão expirada.');
      await _apiClient.uploadFile(
        '/payments/orders/$orderId/proof/upload',
        filePath: filePath,
        fieldName: 'proof',
        headers: {'Authorization': 'Bearer $token'},
      );
      await load(orderId);
      return true;
    } on AppException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Não foi possível enviar o comprovante.';
    }
    notifyListeners();
    return false;
  }
}
