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
        profilePhotoUrl: 'https://example.com/profile.jpg',
        location: 'Bengaluru, India',
        designation: 'Engineering Manager',
        employmentType: 'full_time',
        department: 'Engineering',
        teamDescription: 'Builds the core product.',
        managerName: 'Executive Manager',
        joiningDate: '2022-01-17T00:00:00.000Z',
        birthday: '1992-03-12T00:00:00.000Z',
        recognition: UserRecognition(
          label: 'People Champion',
          period: 'Q2 2026',
        ),
      ),
    );

    await store.save(session);
    final restored = await store.read();

    expect(restored?.token, session.token);
    expect(restored?.user.email, session.user.email);
    expect(restored?.user.role, session.user.role);
    expect(restored?.user.designation, session.user.designation);
    expect(restored?.user.managerName, session.user.managerName);
    expect(restored?.user.recognition?.label, session.user.recognition?.label);

    await store.clear();
    expect(await store.read(), isNull);
  });
}
