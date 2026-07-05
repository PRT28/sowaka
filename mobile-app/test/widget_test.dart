import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HrmsMobileApp());
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Sign in to\nConnect'), findsOneWidget);
    expect(find.text('Send me a code'), findsOneWidget);
  });
}
