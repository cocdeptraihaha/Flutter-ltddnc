import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:f02/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(
      fileInput: 'API_BASE_URL=http://127.0.0.1:8000/api/v1\n',
    );
  });

  testWidgets('Màn đăng nhập Admin KeBook F02', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: KeBookF02App()),
    );
    await tester.pump();

    expect(find.textContaining('Đăng nhập quản trị viên'), findsOneWidget);
    expect(find.textContaining('KeBook'), findsWidgets);
  });
}
