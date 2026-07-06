import 'dart:convert';
import 'dart:typed_data';

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

  test('uploads a selected receipt as multipart form data', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/reimbursements');
      expect(request.headers['Authorization'], 'Bearer token');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      final body = latin1.decode(request.bodyBytes);
      expect(body, contains('name="receipt"; filename="cab.pdf"'));
      expect(body, contains('name="expenseDate"'));
      expect(body, contains('2026-07-06'));
      expect(body, contains('%PDF-'));
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

    await service.submitReimbursement(
      expenseDate: DateTime(2026, 7, 6),
      amount: '1,250.50',
      category: 'Travel',
      receiptName: 'cab.pdf',
      receiptBytes: Uint8List.fromList(utf8.encode('%PDF-1.7 test')),
      note: 'Client visit',
    );
  });
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
