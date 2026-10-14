import 'package:flutter_test/flutter_test.dart';
import 'package:pizzaria_mobile/features/menu/data/menu_models.dart';

void main() {
  test('only pizzas expose pizza customization options', () {
    expect(isPizzaProductType('PIZZA'), isTrue);
    expect(isPizzaProductType('DRINK'), isFalse);
    expect(isPizzaProductType('BEVERAGE'), isFalse);
  });
}
