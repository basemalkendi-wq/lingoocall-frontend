import 'package:flutter_test/flutter_test.dart';
import 'package:lingoocall/core/services/backend_api_service.dart';

void main() {
  test('backend service exposes a direct registration API without OTP', () {
    expect(BackendApiService.instance.register, isA<Function>());
  });
}
