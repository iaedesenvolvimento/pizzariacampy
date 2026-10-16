import 'package:flutter/material.dart';

import 'admin_colors.dart';

String formatFinanceMoney(Object? value) {
  final raw = value?.toString().trim() ?? '0';
  final normalized = raw.replaceAll(',', '.');
  final number = double.tryParse(normalized) ?? 0;
  final fixed = number.toStringAsFixed(2);
  final parts = fixed.split('.');
  final integer = parts.first;
  final sign = integer.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? integer : integer.substring(1);
  final grouped = digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $sign$grouped,${parts[1]}';
}

String paymentMethodLabel(String value) => switch (value.toUpperCase()) {
      'PIX' => 'PIX',
      'CASH' => 'Dinheiro',
      'CARD_ON_DELIVERY' => 'Cartão na entrega',
      _ => 'Não informado',
    };

String paymentStatusLabel(String value) => switch (value.toUpperCase()) {
      'PENDING' => 'Pendente',
      'UNDER_REVIEW' => 'Em análise',
      'CONFIRMED' => 'Confirmado',
      'FAILED' => 'Rejeitado',
      _ => 'Não informado',
    };

({Color foreground, Color background, IconData icon}) paymentStatusVisual(
    String value) {
  return switch (value.toUpperCase()) {
    'CONFIRMED' => (
        foreground: AdminColors.success,
        background: AdminColors.successSurface,
        icon: Icons.check_circle_outline
      ),
    'FAILED' => (
        foreground: AdminColors.danger,
        background: AdminColors.dangerSurface,
        icon: Icons.cancel_outlined
      ),
    'UNDER_REVIEW' => (
        foreground: AdminColors.info,
        background: AdminColors.infoSurface,
        icon: Icons.manage_search_outlined
      ),
    _ => (
        foreground: AdminColors.warning,
        background: AdminColors.warningSurface,
        icon: Icons.schedule_outlined
      ),
  };
}

String formatFinanceDate(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (parsed == null) return 'Data não informada';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
      '${two(parsed.hour)}:${two(parsed.minute)}';
}

enum FinancePeriod { today, sevenDays, thirtyDays, custom }

extension FinancePeriodLabel on FinancePeriod {
  String get label => switch (this) {
        FinancePeriod.today => 'Hoje',
        FinancePeriod.sevenDays => '7 dias',
        FinancePeriod.thirtyDays => '30 dias',
        FinancePeriod.custom => 'Personalizado',
      };
}

({DateTime start, DateTime end}) periodDates(
  FinancePeriod period, {
  DateTime? today,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final base = today ?? DateTime.now();
  final day = DateTime(base.year, base.month, base.day);
  return switch (period) {
    FinancePeriod.today => (start: day, end: day),
    FinancePeriod.sevenDays => (
        start: day.subtract(const Duration(days: 6)),
        end: day
      ),
    FinancePeriod.thirtyDays => (
        start: day.subtract(const Duration(days: 29)),
        end: day
      ),
    FinancePeriod.custom => (start: customStart ?? day, end: customEnd ?? day),
  };
}
