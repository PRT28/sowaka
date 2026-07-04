import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/auth/data/auth_models.dart';
import 'package:mobile_app/features/manager/bloc/manager_bloc.dart';
import 'package:mobile_app/features/manager/data/manager_models.dart';

void main() {
  test('employee starts on Grow and cannot select Manage', () {
    final bloc = ManagerBloc(session: _session('employee'));

    expect(bloc.state.canManage, isFalse);
    expect(bloc.state.tab, ManagerTab.grow);

    bloc.add(const ChangeManagerTab(ManagerTab.manage));
    expect(bloc.state.tab, ManagerTab.grow);

    bloc.dispose();
  });

  test('manager starts on Manage', () {
    final bloc = ManagerBloc(session: _session('manager'));

    expect(bloc.state.canManage, isTrue);
    expect(bloc.state.tab, ManagerTab.manage);

    bloc.dispose();
  });
}

AuthSession _session(String role) {
  return AuthSession(
    token: 'token',
    user: AuthUser(
      id: 'user-id',
      email: 'user@example.com',
      name: 'Test User',
      role: role,
      company: 'Sowaka',
    ),
  );
}
