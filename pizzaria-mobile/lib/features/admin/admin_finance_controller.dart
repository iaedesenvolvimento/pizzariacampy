import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/app_storage.dart';
import 'admin_api_client.dart';
import 'core/admin_finance_presentation.dart';

typedef FinanceRequest = Future<dynamic> Function(String path);

enum FinanceSection { summary, sales, pix, cancellations }

class FinancePaymentMethod {
  const FinancePaymentMethod({
    required this.method,
    required this.orderCount,
    required this.amount,
  });

  factory FinancePaymentMethod.fromJson(Map<String, dynamic> json) {
    return FinancePaymentMethod(
      method: json['method']?.toString() ?? '',
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      amount: json['amount']?.toString() ?? '0',
    );
  }

  final String method;
  final int orderCount;
  final String amount;
}

class FinanceSummary {
  const FinanceSummary({
    required this.grossSales,
    required this.ordersCount,
    required this.averageTicket,
    required this.discountsTotal,
    required this.deliveryFeesTotal,
    required this.cancelledOrdersCount,
    required this.cancelledAmount,
    required this.pixPendingCount,
    required this.pixAwaitingProofCount,
    required this.pixAwaitingReviewCount,
    required this.paymentMethods,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    final methods = json['payment_methods'];
    return FinanceSummary(
      grossSales: json['gross_sales']?.toString() ?? '0',
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      averageTicket: json['average_ticket']?.toString() ?? '0',
      discountsTotal: json['discounts_total']?.toString() ?? '0',
      deliveryFeesTotal: json['delivery_fees_total']?.toString() ?? '0',
      cancelledOrdersCount:
          (json['cancelled_orders_count'] as num?)?.toInt() ?? 0,
      cancelledAmount: json['cancelled_amount']?.toString() ?? '0',
      pixPendingCount: (json['pix_pending_count'] as num?)?.toInt() ?? 0,
      pixAwaitingProofCount:
          (json['pix_awaiting_proof_count'] as num?)?.toInt() ?? 0,
      pixAwaitingReviewCount:
          (json['pix_awaiting_review_count'] as num?)?.toInt() ?? 0,
      paymentMethods: methods is List
          ? methods
              .whereType<Map<String, dynamic>>()
              .map(FinancePaymentMethod.fromJson)
              .toList()
          : const [],
    );
  }

  final String grossSales;
  final int ordersCount;
  final String averageTicket;
  final String discountsTotal;
  final String deliveryFeesTotal;
  final int cancelledOrdersCount;
  final String cancelledAmount;
  final int pixPendingCount;
  final int pixAwaitingProofCount;
  final int pixAwaitingReviewCount;
  final List<FinancePaymentMethod> paymentMethods;
}

class FinanceSale {
  const FinanceSale({
    required this.orderNumber,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
  });

  factory FinanceSale.fromJson(Map<String, dynamic> json) => FinanceSale(
        orderNumber: json['order_number']?.toString() ?? 'Pedido',
        createdAt: json['created_at']?.toString(),
        totalAmount: json['total_amount']?.toString() ?? '0',
        paymentMethod: json['payment_method']?.toString() ?? '',
        paymentStatus: json['payment_status']?.toString() ?? '',
        orderStatus: json['order_status']?.toString() ?? '',
        subtotal: json['subtotal']?.toString() ?? '0',
        discountAmount: json['discount_amount']?.toString() ?? '0',
        deliveryFee: json['delivery_fee']?.toString() ?? '0',
      );

  final String orderNumber;
  final String? createdAt;
  final String totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String subtotal;
  final String discountAmount;
  final String deliveryFee;
}

class FinancePixPending {
  const FinancePixPending({
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.proofUrl,
  });

  factory FinancePixPending.fromJson(Map<String, dynamic> json) =>
      FinancePixPending(
        orderId: json['order_id']?.toString() ?? '',
        orderNumber: json['order_number']?.toString() ?? 'Pedido',
        createdAt: json['created_at']?.toString(),
        totalAmount: json['total_amount']?.toString() ?? '0',
        paymentStatus: json['payment_status']?.toString() ?? '',
        orderStatus: json['order_status']?.toString() ?? '',
        proofUrl: json['proof_url']?.toString(),
      );

  final String orderId;
  final String orderNumber;
  final String? createdAt;
  final String totalAmount;
  final String paymentStatus;
  final String orderStatus;
  final String? proofUrl;
}

class FinanceCancellation {
  const FinanceCancellation({
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.reason,
    required this.paymentConfirmed,
  });

  factory FinanceCancellation.fromJson(Map<String, dynamic> json) =>
      FinanceCancellation(
        orderId: json['order_id']?.toString() ?? '',
        orderNumber: json['order_number']?.toString() ?? 'Pedido',
        createdAt: json['created_at']?.toString(),
        totalAmount: json['total_amount']?.toString() ?? '0',
        paymentMethod: json['payment_method']?.toString() ?? '',
        paymentStatus: json['payment_status']?.toString() ?? '',
        orderStatus: json['order_status']?.toString() ?? '',
        reason: json['cancelled_reason']?.toString(),
        paymentConfirmed: json['payment_confirmed'] == true,
      );

  final String orderId;
  final String orderNumber;
  final String? createdAt;
  final String totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final String? reason;
  final bool paymentConfirmed;
}

class AdminFinanceController extends ChangeNotifier {
  AdminFinanceController({AdminApiClient? adminApi, FinanceRequest? request})
      : _adminApi = adminApi,
        _request = request;

  AdminApiClient? _adminApi;
  final FinanceRequest? _request;
  bool loading = true;
  String? error;
  FinanceSummary? summary;
  List<FinanceSale> sales = const [];
  int salesTotal = 0;
  int salesOffset = 0;
  final int salesLimit = 10;
  String? salesPaymentMethod;
  String? salesPaymentStatus;
  String? salesOrderStatus;
  List<FinancePixPending> pixPending = const [];
  int pixTotal = 0;
  List<FinanceCancellation> cancellations = const [];
  int cancellationsTotal = 0;
  bool sectionLoading = false;
  String? sectionError;
  FinancePeriod period = FinancePeriod.sevenDays;
  DateTime? customStart;
  DateTime? customEnd;
  int _requestId = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (_request == null) {
        _adminApi ??= AdminApiClient(
          ApiClient(config: AppConfig.fromEnvironment()),
          await AppStorage.create(),
        );
      }
      final query = _query(extra: '&limit=$salesLimit&offset=0');
      final request = _request ?? ((path) => _adminApi!.get(path));
      final responses = await Future.wait<dynamic>([
        request('/admin/finance/summary$query'),
        request('/admin/finance/sales$query&limit=10&offset=0'),
      ]);
      if (requestId != _requestId) return;
      final summaryResponse = responses[0];
      final salesResponse = responses[1];
      if (summaryResponse is! Map<String, dynamic> ||
          salesResponse is! Map<String, dynamic>) {
        throw const FormatException('Resposta financeira inválida.');
      }
      final items = salesResponse['items'];
      summary = FinanceSummary.fromJson(summaryResponse);
      salesTotal = (salesResponse['total'] as num?)?.toInt() ?? 0;
      salesOffset = (salesResponse['offset'] as num?)?.toInt() ?? 0;
      sales = items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map(FinanceSale.fromJson)
              .toList()
          : const [];
      loading = false;
    } catch (_) {
      if (requestId != _requestId) return;
      loading = false;
      error = 'Não foi possível carregar os dados financeiros.';
    }
    notifyListeners();
  }

  Future<void> loadSales({bool resetOffset = false}) async {
    if (resetOffset) salesOffset = 0;
    final requestId = ++_requestId;
    sectionLoading = true;
    sectionError = null;
    notifyListeners();
    try {
      final response = await _send(
        '/admin/finance/sales${_query(extra: '&limit=$salesLimit&offset=$salesOffset${_optionalFilters()}')}',
      );
      if (requestId != _requestId) return;
      if (response is! Map<String, dynamic>) throw const FormatException();
      final items = response['items'];
      sales = items is List
          ? items
              .whereType<Map<String, dynamic>>()
              .map(FinanceSale.fromJson)
              .toList()
          : const [];
      salesTotal = (response['total'] as num?)?.toInt() ?? 0;
      salesOffset = (response['offset'] as num?)?.toInt() ?? 0;
      sectionLoading = false;
    } catch (_) {
      if (requestId != _requestId) return;
      sectionLoading = false;
      sectionError = 'Não foi possível carregar as vendas.';
    }
    notifyListeners();
  }

  Future<void> loadPixPending() async {
    await _loadEndpoint(
      '/admin/finance/pix-pending',
      (response) {
        final items = response['items'];
        pixPending = items is List
            ? items
                .whereType<Map<String, dynamic>>()
                .map(FinancePixPending.fromJson)
                .toList()
            : const [];
        pixTotal = (response['total'] as num?)?.toInt() ?? 0;
      },
      'Não foi possível carregar os pagamentos PIX.',
    );
  }

  Future<void> loadCancellations() async {
    await _loadEndpoint(
      '/admin/finance/cancellations',
      (response) {
        final items = response['items'];
        cancellations = items is List
            ? items
                .whereType<Map<String, dynamic>>()
                .map(FinanceCancellation.fromJson)
                .toList()
            : const [];
        cancellationsTotal = (response['total'] as num?)?.toInt() ?? 0;
      },
      'Não foi possível carregar os cancelamentos.',
    );
  }

  Future<void> _loadEndpoint(
    String path,
    void Function(Map<String, dynamic>) onResult,
    String errorMessage,
  ) async {
    final requestId = ++_requestId;
    sectionLoading = true;
    sectionError = null;
    notifyListeners();
    try {
      final response =
          await _send('$path${_query(extra: '&limit=50&offset=0')}');
      if (requestId != _requestId) return;
      if (response is! Map<String, dynamic>) throw const FormatException();
      onResult(response);
      sectionLoading = false;
    } catch (_) {
      if (requestId != _requestId) return;
      sectionLoading = false;
      sectionError = errorMessage;
    }
    notifyListeners();
  }

  Future<dynamic> _send(String path) async {
    if (_request != null) return _request(path);
    _adminApi ??= AdminApiClient(
      ApiClient(config: AppConfig.fromEnvironment()),
      await AppStorage.create(),
    );
    return _adminApi!.get(path);
  }

  String _query({String extra = ''}) {
    final dates =
        periodDates(period, customStart: customStart, customEnd: customEnd);
    return '?start_date=${_date(dates.start)}&end_date=${_date(dates.end)}$extra';
  }

  String _optionalFilters() {
    final filters = <String>[];
    if (salesPaymentMethod != null) {
      filters.add('&payment_method=$salesPaymentMethod');
    }
    if (salesPaymentStatus != null) {
      filters.add('&payment_status=$salesPaymentStatus');
    }
    if (salesOrderStatus != null) {
      filters.add('&order_status=$salesOrderStatus');
    }
    return filters.join();
  }

  Future<void> setSalesFilters({
    String? method,
    String? paymentStatus,
    String? orderStatus,
  }) async {
    salesPaymentMethod = method;
    salesPaymentStatus = paymentStatus;
    salesOrderStatus = orderStatus;
    await loadSales(resetOffset: true);
  }

  Future<void> setPeriod(FinancePeriod value) async {
    period = value;
    if (value != FinancePeriod.custom) {
      customStart = null;
      customEnd = null;
    }
    await load();
  }

  Future<void> setCustomPeriod(DateTime start, DateTime end) async {
    if (start.isAfter(end)) return;
    customStart = DateTime(start.year, start.month, start.day);
    customEnd = DateTime(end.year, end.month, end.day);
    period = FinancePeriod.custom;
    await load();
  }

  String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
