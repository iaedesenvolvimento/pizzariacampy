import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaria_mobile/features/admin/core/admin_business_hour_presentation.dart';

void main() {
  test('formata e valida intervalo de horário', () {
    const opening = TimeOfDay(hour: 18, minute: 5);
    const closing = TimeOfDay(hour: 23, minute: 0);
    expect(AdminBusinessHourPresentation.formatTime(opening), '18:05');
    expect(AdminBusinessHourPresentation.formatRange(opening, closing), '18:05 – 23:00');
    expect(AdminBusinessHourPresentation.isValidRange(opening, closing), isTrue);
    expect(AdminBusinessHourPresentation.isValidRange(closing, opening), isFalse);
  });

  test('não aceita horário inválido', () {
    expect(AdminBusinessHourPresentation.parseTime('25:00'), isNull);
    expect(AdminBusinessHourPresentation.parseTime('18:60'), isNull);
    expect(AdminBusinessHourPresentation.parseTime('18:30'), const TimeOfDay(hour: 18, minute: 30));
  });
}
