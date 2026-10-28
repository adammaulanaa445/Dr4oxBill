import 'package:flutter_test/flutter_test.dart';

import 'package:dr4ox_bill/core/utils/money.dart';

void main() {
  group('formatRupiah', () {
    test('formats positive amount with Rp prefix and dot separator', () {
      expect(formatRupiah(15000), equals('Rp 15.000'));
    });

    test('formats zero amount', () {
      expect(formatRupiah(0), equals('Rp 0'));
    });

    test('formats large amount', () {
      expect(formatRupiah(1000000), equals('Rp 1.000.000'));
    });
  });

  group('parseRupiah', () {
    test('parses plain integer string', () {
      expect(parseRupiah('15000'), equals(15000));
    });

    test('parses with dot separator', () {
      expect(parseRupiah('15.000'), equals(15000));
    });

    test('parses with Rp prefix', () {
      expect(parseRupiah('Rp 15.000'), equals(15000));
    });

    test('returns null for empty string', () {
      expect(parseRupiah(''), isNull);
    });

    test('returns null for null input', () {
      expect(parseRupiah(null), isNull);
    });

    test('returns null for whitespace only', () {
      expect(parseRupiah('   '), isNull);
    });
  });

  group('calculateChange', () {
    test('returns change when cash is sufficient', () {
      expect(calculateChange(20000, 15000), equals(5000));
    });

    test('returns zero change when exact', () {
      expect(calculateChange(15000, 15000), equals(0));
    });

    test('returns null when cash is insufficient', () {
      expect(calculateChange(10000, 15000), isNull);
    });
  });

  group('calculateItemSubtotal', () {
    test('calculates subtotal without discount', () {
      expect(calculateItemSubtotal(10000, 3, 0), equals(30000));
    });

    test('calculates subtotal with discount per item', () {
      expect(calculateItemSubtotal(10000, 2, 2000), equals(16000));
    });

    test('clamps discount to not exceed unit price', () {
      expect(calculateItemSubtotal(10000, 1, 15000), equals(0));
    });

    test('clamps negative discount to zero', () {
      expect(calculateItemSubtotal(10000, 1, -5000), equals(10000));
    });
  });

  group('calculateGrandTotal', () {
    test('sums multiple subtotals', () {
      expect(calculateGrandTotal([10000, 20000, 30000]), equals(60000));
    });

    test('returns zero for empty list', () {
      expect(calculateGrandTotal([]), equals(0));
    });
  });

  group('calculateTotalAfterDiscount', () {
    test('subtracts discount from grand total', () {
      expect(calculateTotalAfterDiscount(100000, 10000), equals(90000));
    });

    test('clamps discount to not exceed grand total', () {
      expect(calculateTotalAfterDiscount(50000, 100000), equals(0));
    });
  });
}
