import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:edunest_mobile/l10n/app_language_provider.dart';
import 'package:edunest_mobile/providers/app_data_provider.dart';
import 'package:edunest_mobile/providers/auth_provider.dart';
import 'package:edunest_mobile/services/api_service.dart';
import 'package:edunest_mobile/main.dart';

void main() {
  testWidgets('EduNest app shell builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final prefs = await SharedPreferences.getInstance();
    final api = ApiService(prefs: prefs);
    final authProvider = AuthProvider(api: api);
    await authProvider.bootstrap();

    await tester.pumpWidget(
      EduNestApp(
        api: api,
        authProvider: authProvider,
        languageProvider: AppLanguageProvider(prefs: prefs),
        appDataProvider: AppDataProvider(api: api),
      ),
    );
    await tester.pump();

    expect(find.text('EduNest'), findsWidgets);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
