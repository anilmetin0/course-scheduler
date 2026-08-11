import 'package:flutter_test/flutter_test.dart';
import 'package:scheduler/core/services/storage_service.dart';

void main() {
  test('InMemoryStorageService supports set/get/remove/clear', () async {
    final storage = InMemoryStorageService();

    expect(await storage.getString('k1'), isNull);

    await storage.setString('k1', 'value');
    expect(await storage.getString('k1'), 'value');

    await storage.remove('k1');
    expect(await storage.getString('k1'), isNull);

    await storage.setString('k2', 'v2');
    await storage.setString('k3', 'v3');
    await storage.clear();
    expect(await storage.getString('k2'), isNull);
    expect(await storage.getString('k3'), isNull);
  });
}
