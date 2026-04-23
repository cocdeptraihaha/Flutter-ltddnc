import 'package:flutter_test/flutter_test.dart';

import 'package:f01/main.dart';

void main() {
  testWidgets('Màn intro hiển thị tên và MSSV KeBook F01', (WidgetTester tester) async {
    await tester.pumpWidget(const KeBookF01App());

    expect(find.textContaining('Nguyễn Thanh Tính'), findsOneWidget);
    expect(find.textContaining('22110247'), findsOneWidget);
    expect(find.textContaining('KeBook'), findsWidgets);
  });
}
