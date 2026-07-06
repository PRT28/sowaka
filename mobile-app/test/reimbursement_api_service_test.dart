import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_app/features/auth/data/auth_models.dart';
import 'package:mobile_app/features/manager/data/manager_api_service.dart';

void main() {
  test('submits a reimbursement using the backend contract', () async {
    late Map<String, dynamic> body;
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/reimbursements');
      expect(request.headers['Authorization'], 'Bearer token');
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({'success': true, 'claim': _claimJson(status: 'pending')}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = ManagerApiService(
      session: _session,
      baseUrl: 'http://localhost:4000',
      client: client,
    );

    final claim = await service.submitReimbursement(
      expenseDate: DateTime(2026, 7, 6),
      amount: '1,250.50',
      category: 'Travel',
      receiptName: 'cab.pdf',
      note: 'Client visit',
    );

    expect(body, {
      'expenseDate': '2026-07-06',
      'amount': 1250.5,
      'category': 'travel',
      'receiptName': 'cab.pdf',
      'note': 'Client visit',
    });
    expect(claim.status, 'Pending');
    expect(claim.who, 'Test Employee');
    expect(claim.receiptName, 'cab.pdf');
  });

  test(
    'sends manager reimbursement decisions to the decision endpoint',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/reimbursements/claim-1/decision');
        expect(jsonDecode(request.body), {'decision': 'approved'});
        return http.Response(
          jsonEncode({
            'success': true,
            'claim': _claimJson(status: 'approved'),
          }),
          200,
        );
      });
      final service = ManagerApiService(
        session: _session,
        baseUrl: 'http://localhost:4000',
        client: client,
      );

      final claim = await service.decideReimbursement('claim-1', 'approved');

      expect(claim.status, 'Approved');
    },
  );
}

const _session = AuthSession(
  token: 'token',
  user: AuthUser(
    id: 'employee-1',
    email: 'employee@example.com',
    name: 'Test Employee',
    role: 'employee',
    company: 'Sowaka',
  ),
);

Map<String, dynamic> _claimJson({required String status}) => {
  'id': 'claim-1',
  'userId': 'employee-1',
  'employee': {'name': 'Test Employee', 'department': 'Engineering'},
  'expenseDate': '2026-07-06',
  'amount': 1250.5,
  'category': 'travel',
  'receiptName': 'cab.pdf',
  'note': 'Client visit',
  'status': status,
  'createdAt': '2026-07-06T08:00:00.000Z',
};
