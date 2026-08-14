import 'package:flutter_test/flutter_test.dart';
import 'package:lingoocall/core/controllers/app_controller.dart';
import 'package:lingoocall/core/services/socket_service.dart';

void main() {
  group('chat security validation', () {
    test('rejects chat targets that are not registered users', () {
      expect(
        AppController.isRegisteredChatTargetAllowed(
          'not_a_real_user_123',
          registeredContacts: const [],
          currentUser: null,
        ),
        isFalse,
      );

      expect(
        AppController.isRegisteredChatTargetAllowed(
          '+999999999999',
          registeredContacts: const [],
          currentUser: null,
        ),
        isFalse,
      );

      expect(
        AppController.isRegisteredChatTargetAllowed(
          '   ',
          registeredContacts: const [],
          currentUser: null,
        ),
        isFalse,
      );
    });

    test('uses the configured backend base URL for socket connections', () {
      expect(SocketService.buildSocketUrl().isNotEmpty, isTrue);
    });
  });
}
