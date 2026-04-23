import 'package:flutter_test/flutter_test.dart';
import 'package:f03/features/admin/data/models/admin_models.dart';

void main() {
  test('DashboardSummary fromJson', () {
    final s = DashboardSummary.fromJson({
      'revenue': 100.5,
      'order_count': 3,
      'aov': 33.5,
      'new_user_count': 1,
      'low_stock_count': 2,
      'pending_order_count': 0,
    });
    expect(s.revenue, 100.5);
    expect(s.orderCount, 3);
  });

  test('TopCustomerRow fromJson', () {
    final t = TopCustomerRow.fromJson({
      'user_id': 1,
      'full_name': 'A',
      'email': 'a@a.com',
      'order_count': 2,
      'total_spent': 50.0,
    });
    expect(t.userId, 1);
    expect(t.totalSpent, 50.0);
  });
}
