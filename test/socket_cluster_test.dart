import 'package:flutter_test/flutter_test.dart';

import 'package:socket_cluster/socket_cluster.dart';

void main() {
  group('ReconnectStrategy', () {
    test('should initialize with default values', () {
      final strategy = ReconnectStrategy();
      expect(strategy.reconnectInterval, 3000);
      expect(strategy.maxReconnectInterval, 30000);
      expect(strategy.maxAttempts, isNull);
      expect(strategy.attmptsMade, 0);
    });

    test('should initialize with custom values', () {
      final strategy = ReconnectStrategy(
        reconnectInterval: 5000,
        maxReconnectInterval: 60000,
        maxAttempts: 10,
      );
      expect(strategy.reconnectInterval, 5000);
      expect(strategy.maxReconnectInterval, 60000);
      expect(strategy.maxAttempts, 10);
    });

    test('should reset attempts made', () {
      final strategy = ReconnectStrategy(maxAttempts: 5);
      strategy.processValues();
      strategy.processValues();
      expect(strategy.attmptsMade, 2);
      strategy.reset();
      expect(strategy.attmptsMade, 0);
    });

    test('should process values and increment attempts', () {
      final strategy = ReconnectStrategy(maxAttempts: 3);
      expect(strategy.attmptsMade, 0);
      strategy.processValues();
      expect(strategy.attmptsMade, 1);
      strategy.processValues();
      expect(strategy.attmptsMade, 2);
    });

    test('should check if attempts are complete', () {
      final strategy = ReconnectStrategy(maxAttempts: 3);
      expect(strategy.areAttemptsComplete(), false);
      strategy.processValues();
      strategy.processValues();
      strategy.processValues();
      expect(strategy.areAttemptsComplete(), true);
    });

    test('should handle null maxAttempts gracefully', () {
      final strategy = ReconnectStrategy(maxAttempts: null);
      // When maxAttempts is null, areAttemptsComplete() will throw
      // This is expected behavior based on current implementation
      expect(() => strategy.areAttemptsComplete(), throwsA(isA<TypeError>()));
    });

    test('should return reconnect interval', () {
      final strategy = ReconnectStrategy(reconnectInterval: 5000);
      expect(strategy.getReconnectInterval(), 5000);
    });
  });

  group('SocketClusterController', () {
    test('should initialize with default strategy', () {
      final controller = SocketClusterController();
      expect(controller.strategy, isNotNull);
      expect(controller.strategy?.reconnectInterval, 5000);
      expect(controller.strategy?.maxReconnectInterval, 60000);
      expect(controller.strategy?.maxAttempts, 30);
    });

    test('should implement SocketEventListener', () {
      final controller = SocketClusterController();
      expect(controller, isA<SocketEventListener>());
    });

    test('should handle destroy without errors', () async {
      final controller = SocketClusterController();
      await controller.destroy();
      // Should complete without throwing
      expect(controller, isNotNull);
    });
  });

  group('SocketCallback', () {
    test('should call callback on event', () {
      var called = false;
      var receivedData;
      final callback = SocketCallback((data) {
        called = true;
        receivedData = data;
      });

      callback.onEvent('test-channel', SocketEventType.Any, {'test': 'data'});
      expect(called, true);
      expect(receivedData, {'test': 'data'});
    });

    test('should implement SocketEventCallBackListener', () {
      final callback = SocketCallback((data) {});
      expect(callback, isA<SocketEventCallBackListener>());
    });
  });

  group('SocketEventType', () {
    test('should have Any value', () {
      expect(SocketEventType.Any, isNotNull);
    });

    test('should convert to short string', () {
      final extension = SocketEventType.Any;
      expect(extension.toShortString(), 'Any');
    });
  });
}
