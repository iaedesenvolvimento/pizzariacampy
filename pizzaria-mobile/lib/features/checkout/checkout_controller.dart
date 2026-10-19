import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../cart/cart_controller.dart';

enum CheckoutStatus { idle, submitting, success, error }

class CheckoutResult {
  const CheckoutResult(
      {required this.orderId,
      required this.orderNumber,
      required this.total,
      required this.discountAmount,
      required this.couponCode,
      this.pixPaymentId,
      this.pixStatus,
      this.pixQrCode,
      this.pixQrCodeBase64});

  final String orderId;
  final String orderNumber;
  final String total;
  final String discountAmount;
  final String? couponCode;
  final String? pixPaymentId;
  final String? pixStatus;
  final String? pixQrCode;
  final String? pixQrCodeBase64;
}

class CheckoutController extends ChangeNotifier {
  CheckoutController(this._apiClient, this.accessToken,
      {required this.refreshAccessToken});

  final ApiClient _apiClient;
  final String? accessToken;
  final Future<String?> Function() refreshAccessToken;
  CheckoutStatus status = CheckoutStatus.idle;
  String? errorMessage;
  CheckoutResult? result;

  Future<bool> submit({
    required CartController cart,
    required String fulfillmentType,
    required String paymentMethod,
    String? customerNote,
    double? changeFor,
    String? deliveryAddress,
    String? deliveryNumber,
    String? deliveryPostalCode,
    String? deliveryNeighborhood,
    String? deliveryCity,
    String? couponCode,
  }) async {
    status = CheckoutStatus.submitting;
    errorMessage = null;
    result = null;
    notifyListeners();
    try {
      final doughNotes = cart.items
          .where((item) => item.doughName != null)
          .map((item) => '${item.productName}: massa ${item.doughName}')
          .join('; ');
      final combinedNote = [
        if (customerNote?.trim().isNotEmpty == true) customerNote!.trim(),
        if (doughNotes.isNotEmpty) 'Massas escolhidas: $doughNotes',
      ].join(' | ');
      final body = {
        'items': cart.items
            .map(
              (item) => {
                'product_id': item.productId,
                'product_size_id': item.sizeId,
                'pizza_configuration_id': item.pizzaConfigurationId,
                'flavor_ids': item.flavorIds,
                'edge_id': item.edgeId,
                'extras': item.extras
                    .map((extra) => {'extra_id': extra.id, 'quantity': 1})
                    .toList(),
                'quantity': item.quantity,
              },
            )
            .toList(),
        'fulfillment_type': fulfillmentType,
        'payment_method': paymentMethod,
        'change_for': changeFor,
        'delivery_address': deliveryAddress,
        'delivery_number': deliveryNumber,
        'delivery_postal_code': deliveryPostalCode,
        'delivery_neighborhood': deliveryNeighborhood,
        'delivery_city': deliveryCity,
        'coupon_code':
            couponCode?.trim().isEmpty == true ? null : couponCode?.trim(),
        'customer_note': combinedNote.isEmpty ? null : combinedNote,
      };
      var token = accessToken;
      token ??= await refreshAccessToken();
      dynamic response;
      try {
        response = await _apiClient.post(
          '/orders',
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
          body: body,
        );
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
        token = await refreshAccessToken();
        if (token == null) rethrow;
        response = await _apiClient.post(
          '/orders',
          headers: {'Authorization': 'Bearer $token'},
          body: body,
        );
      }
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Resposta de pedido inválida.');
      }
      String? pixPaymentId;
      String? pixStatus;
      String? pixQrCode;
      String? pixQrCodeBase64;
      if (paymentMethod == 'PIX' && token != null) {
        try {
          final pixResponse = await _apiClient.post(
            '/payments/orders/${response['id']}/mercadopago/pix',
            headers: {'Authorization': 'Bearer $token'},
          );
          if (pixResponse is Map<String, dynamic>) {
            pixPaymentId = pixResponse['payment_id']?.toString();
            pixStatus = pixResponse['status']?.toString();
            pixQrCode = pixResponse['qr_code']?.toString();
            pixQrCodeBase64 = pixResponse['qr_code_base64']?.toString();
          }
        } on ApiException {
          // The manual PIX proof flow remains available as a fallback.
        }
      }
      result = CheckoutResult(
        orderId: response['id']?.toString() ?? '',
        orderNumber: response['order_number']?.toString() ?? '',
        total: response['total_amount']?.toString() ?? '0.00',
        discountAmount: response['discount_amount']?.toString() ?? '0.00',
        couponCode: response['coupon_code']?.toString(),
        pixPaymentId: pixPaymentId,
        pixStatus: pixStatus,
        pixQrCode: pixQrCode,
        pixQrCodeBase64: pixQrCodeBase64,
      );
      status = CheckoutStatus.success;
      await cart.clear();
      notifyListeners();
      return true;
    } on AppException catch (error) {
      status = CheckoutStatus.error;
      errorMessage = error.message;
    } catch (_) {
      status = CheckoutStatus.error;
      errorMessage = 'Não foi possível confirmar o pedido.';
    }
    notifyListeners();
    return false;
  }
}
