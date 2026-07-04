import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/auth/data/auth_models.dart';
import 'package:mobile_app/features/auth/data/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists, restores, and clears an authentication session', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AuthSessionStore();
    const session = AuthSession(
      token: 'token',
      user: AuthUser(
        id: 'user-id',
        email: 'user@example.com',
        name: 'Test User',
        role: 'manager',
        company: 'Sowaka',
      ),
    );

    await store.save(session);
    final restored = await store.read();

    expect(restored?.token, session.token);
    expect(restored?.user.email, session.user.email);
    expect(restored?.user.role, session.user.role);

    await store.clear();
    expect(await store.read(), isNull);
  });
}
