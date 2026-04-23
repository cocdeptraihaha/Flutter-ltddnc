import 'package:flutter_test/flutter_test.dart';

import 'package:f02/main.dart';

void main() {
  testWidgets('Màn intro hiển thị tên và MSSV KeBook F02', (WidgetTester tester) async {
    await tester.pumpWidget(const KeBookF02App());

    expect(find.textContaining('Nguyễn Thanh Tính'), findsOneWidget);
    expect(find.textContaining('22110247'), findsOneWidget);
    expect(find.textContaining('KeBook'), findsWidgets);
  });
}
