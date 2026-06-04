import 'package:flutter_test/flutter_test.dart';
import 'package:human_souls/core/mock/mock_backend.dart';
import 'package:human_souls/core/mock/mock_session.dart';
import 'package:human_souls/models/mision.dart';

void main() {
  late MockBackend mb;

  setUp(() {
    mb = MockBackend.instance;
    mb.resetForTest();
  });

  test('setPersona cambia membresía y rol de buddy', () {
    mb.setPersona(DemoPersona.free);
    expect(mb.profile.membershipStatus, 'free');
    expect(mb.profile.isBuddy, isFalse);

    mb.setPersona(DemoPersona.buddy);
    expect(mb.profile.membershipStatus, 'active');
    expect(mb.profile.isBuddy, isTrue);
    expect(mb.profile.isFounderBuddy, isTrue);
  });

  test('submitMision auto-validada otorga XP y queda validada', () {
    final mision = mb.misionesPorTipo()[MisionTipo.daily]!
        .firstWhere((m) => m.evidenceType == EvidenceType.none);
    final xpAntes = mb.profile.xp;

    final comp = mb.submitMision(mision: mision, evidenceText: null);

    expect(comp.validated, isTrue);
    expect(mb.profile.xp, xpAntes + mision.xpReward);
    expect(mb.misCompletadasDelPeriodo().containsKey(mision.id), isTrue);
  });

  test('toggleLike agrega y quita la reacción', () {
    mb.toggleLike(postId: 'post-1', isLiked: false);
    expect(mb.myReactions().contains('post-1'), isTrue);
    mb.toggleLike(postId: 'post-1', isLiked: true);
    expect(mb.myReactions().contains('post-1'), isFalse);
  });

  test('sendMessage agrega el mensaje y emite por el stream', () async {
    final future = mb.messagesStream('chat-ana').firstWhere(
          (list) => list.any((m) => m.content == 'Hola test'),
        );
    mb.sendMessage(chatId: 'chat-ana', content: 'Hola test');
    final list = await future.timeout(const Duration(seconds: 2));
    expect(list.last.content, 'Hola test');
    expect(list.last.senderId, kDemoUserId);
  });

  test('saveRueda reemplaza la rueda del mes actual', () {
    final actual = mb.ruedaActual();
    final nueva = actual.copyWithValue('salud', 10);
    mb.saveRueda(nueva);
    expect(mb.ruedaActual().salud, 10);
  });

  test('createPost lo agrega al principio del feed', () {
    final antes = mb.feed().length;
    mb.createPost(content: 'Mi primer post demo');
    expect(mb.feed().length, antes + 1);
    expect(mb.feed().first.content, 'Mi primer post demo');
    expect(mb.feed().first.userId, kDemoUserId);
  });
}
