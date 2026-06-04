import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/buddy_dashboard.dart';
import '../../models/capsula.dart';
import '../../models/chat.dart';
import '../../models/mision.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../models/rueda_vida.dart';
import 'mock_session.dart';
import 'seed_data.dart';

enum DemoPersona { free, member, buddy }

/// Backend simulado en memoria. Reinicia su estado al recrearse la app.
class MockBackend {
  MockBackend._() {
    _seed();
  }
  static final MockBackend instance = MockBackend._();

  // --- Estado ---
  late Profile _profile;
  late List<Mision> _misiones;
  late List<MisionCompletada> _completadas; // del usuario + ajenas pendientes
  late List<Capsula> _capsulas;
  late Map<String, CapsulaInscripcion> _inscripciones;
  late List<Post> _posts;
  late Set<String> _reactions;
  late Map<String, List<PostComment>> _comments;
  late List<InboxItem> _inbox;
  late Map<String, List<Message>> _messages;
  late List<RuedaVida> _ruedas;
  late BuddyDashboard _buddyDashboard;
  late List<BuddyMonthlyIncome> _buddyIncome;
  late List<BuddyUpcomingCapsula> _buddyUpcoming;

  int _seq = 0;
  String _newId(String prefix) => '$prefix-${++_seq}';

  final _profileCtrl = StreamController<Profile>.broadcast();
  final Map<String, StreamController<List<Message>>> _msgCtrls = {};

  void _seed() {
    _profile = seedDemoProfile();
    _misiones = seedMisiones();
    _completadas = seedPendingCompletadas();
    _capsulas = seedCapsulas();
    _inscripciones = {
      'cap-live': CapsulaInscripcion(
        id: 'insc-live',
        userId: kDemoUserId,
        capsulaId: 'cap-live',
        paid: true,
        attended: false,
        xpAwarded: false,
        createdAt: DateTime.now(),
      ),
      'cap-pasada': CapsulaInscripcion(
        id: 'insc-pasada',
        userId: kDemoUserId,
        capsulaId: 'cap-pasada',
        paid: true,
        attended: true,
        xpAwarded: true,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    };
    _posts = seedPosts();
    _reactions = {'post-1'};
    _comments = seedComments();
    _inbox = seedInbox();
    _messages = seedMessages();
    _ruedas = seedRuedas();
    _buddyDashboard = seedBuddyDashboard();
    _buddyIncome = seedBuddyMonthlyIncome();
    _buddyUpcoming = seedBuddyUpcoming();
  }

  @visibleForTesting
  void resetForTest() => _seed();

  // ============================ PERFIL ============================
  Profile get profile => _profile;
  Stream<Profile> get profileStream => _profileCtrl.stream;

  void _emitProfile() => _profileCtrl.add(_profile);

  void setPersona(DemoPersona persona) {
    switch (persona) {
      case DemoPersona.free:
        _profile = _copyProfile(
          membershipStatus: 'free',
          membershipPlan: null,
          membershipProvider: null,
          isBuddy: false,
          isFounderBuddy: false,
        );
      case DemoPersona.member:
        _profile = _copyProfile(
          membershipStatus: 'active',
          membershipPlan: 'monthly',
          membershipProvider: 'stripe',
          isBuddy: false,
          isFounderBuddy: false,
        );
      case DemoPersona.buddy:
        _profile = _copyProfile(
          membershipStatus: 'active',
          membershipPlan: 'monthly',
          membershipProvider: 'stripe',
          isBuddy: true,
          isFounderBuddy: true,
        );
    }
    _emitProfile();
  }

  void updateProfile({String? fullName, String? bio, String? username}) {
    _profile = _copyProfile(
      fullName: fullName ?? _profile.fullName,
      bio: bio,
      username: username ?? _profile.username,
    );
    _emitProfile();
  }

  void activateMembership(String plan) {
    _profile = _copyProfile(
      membershipStatus: 'active',
      membershipPlan: plan,
      membershipProvider: 'stripe',
    );
    _emitProfile();
  }

  void cancelMembership() {
    _profile = _copyProfile(membershipStatus: 'cancelled');
    _emitProfile();
  }

  void _awardXp(int xp, int sp) {
    _profile =
        _copyProfile(xp: _profile.xp + xp, soulPoints: _profile.soulPoints + sp);
    _emitProfile();
  }

  /// Copia el perfil cambiando solo los campos indicados. `bio`,
  /// `membershipPlan` y `membershipProvider` usan un centinela para poder
  /// setearlos a null a propósito.
  Profile _copyProfile({
    String? fullName,
    String? username,
    Object? bio = _sentinel,
    int? xp,
    int? soulPoints,
    String? membershipStatus,
    Object? membershipPlan = _sentinel,
    Object? membershipProvider = _sentinel,
    bool? isBuddy,
    bool? isFounderBuddy,
    DateTime? membershipExpiresAt,
  }) {
    final p = _profile;
    return Profile(
      id: p.id,
      email: p.email,
      fullName: fullName ?? p.fullName,
      username: username ?? p.username,
      avatarUrl: p.avatarUrl,
      bio: bio == _sentinel ? p.bio : bio as String?,
      level: p.level,
      levelName: p.levelName,
      xp: xp ?? p.xp,
      soulPoints: soulPoints ?? p.soulPoints,
      isBuddy: isBuddy ?? p.isBuddy,
      isFounderBuddy: isFounderBuddy ?? p.isFounderBuddy,
      membershipStatus: membershipStatus ?? p.membershipStatus,
      membershipPlan: membershipPlan == _sentinel
          ? p.membershipPlan
          : membershipPlan as String?,
      membershipProvider: membershipProvider == _sentinel
          ? p.membershipProvider
          : membershipProvider as String?,
      membershipExpiresAt: membershipExpiresAt ?? p.membershipExpiresAt,
      onboardingCompleted: p.onboardingCompleted,
    );
  }

  static const _sentinel = Object();

  /// Snapshot crudo de stats. El provider construye el `ProfileStats`
  /// (así `core/mock` no depende de `providers/`).
  ({int misiones, int capsulas, int dias}) statsSnapshot() {
    final misiones = _completadas
        .where((c) => c.userId == kDemoUserId && c.validated)
        .length;
    final capsulas = _inscripciones.values.where((i) => i.attended).length;
    return (misiones: misiones, capsulas: capsulas, dias: 42);
  }

  // ============================ MISIONES ============================
  Map<MisionTipo, List<Mision>> misionesPorTipo() => {
        MisionTipo.daily:
            _misiones.where((m) => m.tipo == MisionTipo.daily).toList(),
        MisionTipo.weekly:
            _misiones.where((m) => m.tipo == MisionTipo.weekly).toList(),
        MisionTipo.monthly:
            _misiones.where((m) => m.tipo == MisionTipo.monthly).toList(),
      };

  Map<String, MisionCompletada> misCompletadasDelPeriodo() {
    final result = <String, MisionCompletada>{};
    for (final c in _completadas.where((c) => c.userId == kDemoUserId)) {
      result[c.misionId] = c;
    }
    return result;
  }

  List<MisionCompletada> validationQueue() => _completadas
      .where((c) => c.userId != kDemoUserId && !c.validated)
      .toList();

  MisionCompletada submitMision({
    required Mision mision,
    String? evidenceText,
    bool forceValidated = false,
  }) {
    final autoValidated =
        forceValidated || mision.evidenceType == EvidenceType.none;
    final comp = MisionCompletada(
      id: _newId('comp'),
      userId: kDemoUserId,
      misionId: mision.id,
      periodKey: periodKeyFor(mision.tipo, DateTime.now()),
      validated: autoValidated,
      validatedAt: autoValidated ? DateTime.now() : null,
      createdAt: DateTime.now(),
      evidenceText: evidenceText,
      mision: mision,
    );
    _completadas.insert(0, comp);
    if (autoValidated) _awardXp(mision.xpReward, mision.soulPointsReward);
    return comp;
  }

  void validateMision({required String completionId, required bool approve}) {
    final idx = _completadas.indexWhere((c) => c.id == completionId);
    if (idx == -1) return;
    if (approve) {
      final c = _completadas[idx];
      _completadas[idx] = MisionCompletada(
        id: c.id,
        userId: c.userId,
        misionId: c.misionId,
        periodKey: c.periodKey,
        validated: true,
        validatedBy: kDemoUserId,
        validatedAt: DateTime.now(),
        createdAt: c.createdAt,
        evidenceText: c.evidenceText,
        evidenceUrl: c.evidenceUrl,
        mision: c.mision,
        userName: c.userName,
        userAvatar: c.userAvatar,
      );
    } else {
      _completadas.removeAt(idx);
    }
  }

  // ============================ CÁPSULAS ============================
  List<Capsula> upcomingCapsulas() => _capsulas
      .where((c) => c.endsAt.isAfter(DateTime.now()))
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));

  List<Capsula> pastCapsulas() => _inscripciones.keys
      .map((id) =>
          _capsulas.firstWhere((c) => c.id == id, orElse: () => _capsulas.first))
      .where((c) => c.isPast)
      .toList();

  Capsula capsulaDetail(String id) => _capsulas.firstWhere((c) => c.id == id);

  Map<String, CapsulaInscripcion> myInscripciones() => Map.of(_inscripciones);

  CapsulaInscripcion inscribir(String capsulaId, {required bool paid}) {
    final insc = CapsulaInscripcion(
      id: _newId('insc'),
      userId: kDemoUserId,
      capsulaId: capsulaId,
      paid: paid,
      attended: false,
      xpAwarded: false,
      createdAt: DateTime.now(),
    );
    _inscripciones[capsulaId] = insc;
    return insc;
  }

  void cancelarInscripcion(String capsulaId) => _inscripciones.remove(capsulaId);

  String createCapsula({
    required String title,
    String? description,
    required DateTime startsAt,
    required Duration duration,
    required int capacity,
    required double priceUsd,
    required bool includedInMembership,
    String? meetingLink,
  }) {
    final id = _newId('cap');
    _capsulas.add(Capsula(
      id: id,
      title: title,
      description: description,
      hostId: kDemoUserId,
      hostName: _profile.fullName,
      startsAt: startsAt,
      endsAt: startsAt.add(duration),
      meetingLink: meetingLink,
      capacity: capacity,
      priceUsd: priceUsd,
      includedInMembership: includedInMembership,
      xpReward: 30,
      soulPointsReward: 15,
      status: 'scheduled',
    ));
    return id;
  }

  // ============================ COMUNIDAD ============================
  List<Post> feed() => List.of(_posts);

  Set<String> myReactions() => Set.of(_reactions);

  List<PostComment> postComments(String postId) =>
      List.of(_comments[postId] ?? const []);

  Post postDetail(String postId) => _posts.firstWhere((p) => p.id == postId);

  Post createPost({required String content, String? missionId}) {
    final post = Post(
      id: _newId('post'),
      userId: kDemoUserId,
      content: content,
      likesCount: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
      missionId: missionId,
      authorName: _profile.fullName,
      authorLevelName: _profile.levelName,
      authorIsFounder: _profile.isFounderBuddy,
    );
    _posts.insert(0, post);
    return post;
  }

  void toggleLike({required String postId, required bool isLiked}) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (isLiked) {
      _reactions.remove(postId);
      if (idx != -1) {
        _posts[idx] = _posts[idx].copyWith(
            likesCount: (_posts[idx].likesCount - 1).clamp(0, 1 << 30));
      }
    } else {
      _reactions.add(postId);
      if (idx != -1) {
        _posts[idx] =
            _posts[idx].copyWith(likesCount: _posts[idx].likesCount + 1);
      }
    }
  }

  PostComment addComment({required String postId, required String content}) {
    final comment = PostComment(
      id: _newId('c'),
      postId: postId,
      userId: kDemoUserId,
      content: content,
      createdAt: DateTime.now(),
      authorName: _profile.fullName,
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _posts[idx] =
          _posts[idx].copyWith(commentsCount: _posts[idx].commentsCount + 1);
    }
    return comment;
  }

  void deletePost(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    _comments.remove(postId);
  }

  // ============================ CHAT ============================
  List<InboxItem> inbox() => List.of(_inbox)
    ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

  Stream<List<Message>> messagesStream(String chatId) {
    final ctrl = _msgCtrls.putIfAbsent(
        chatId, () => StreamController<List<Message>>.broadcast());
    scheduleMicrotask(() {
      if (!ctrl.isClosed) ctrl.add(List.of(_messages[chatId] ?? const []));
    });
    return ctrl.stream;
  }

  Map<String, dynamic> otherUserProfile(String userId) {
    final u = seedOtherUsers[userId];
    if (u != null) return Map.of(u);
    return {
      'id': userId,
      'full_name': 'Soul',
      'avatar_url': null,
      'level_name': 'Explorador',
      'is_founder_buddy': false,
      'bio': null,
    };
  }

  String findOrCreateChat(String otherUserId) {
    final existing = _inbox.where((i) => i.otherUserId == otherUserId);
    if (existing.isNotEmpty) return existing.first.chatId;
    final chatId = _newId('chat');
    _inbox.add(InboxItem(
      chatId: chatId,
      otherUserId: otherUserId,
      otherUserName: otherUserProfile(otherUserId)['full_name'] as String?,
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    ));
    _messages[chatId] = [];
    return chatId;
  }

  void sendMessage({required String chatId, required String content}) {
    final msg = Message(
      id: _newId('m'),
      chatId: chatId,
      senderId: kDemoUserId,
      content: content,
      read: true,
      createdAt: DateTime.now(),
    );
    _messages.putIfAbsent(chatId, () => []).add(msg);
    final ctrl = _msgCtrls[chatId];
    if (ctrl != null && !ctrl.isClosed) ctrl.add(List.of(_messages[chatId]!));
    final idx = _inbox.indexWhere((i) => i.chatId == chatId);
    if (idx != -1) {
      final i = _inbox[idx];
      _inbox[idx] = InboxItem(
        chatId: i.chatId,
        otherUserId: i.otherUserId,
        otherUserName: i.otherUserName,
        otherUserAvatar: i.otherUserAvatar,
        otherUserLevel: i.otherUserLevel,
        otherIsFounder: i.otherIsFounder,
        lastMessageContent: content,
        lastMessageSenderId: kDemoUserId,
        lastMessageAt: DateTime.now(),
        unreadCount: 0,
      );
    }
  }

  void markChatAsRead(String chatId) {
    final list = _messages[chatId];
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (!m.read) {
        list[i] = Message(
          id: m.id,
          chatId: m.chatId,
          senderId: m.senderId,
          content: m.content,
          read: true,
          createdAt: m.createdAt,
        );
      }
    }
    final idx = _inbox.indexWhere((i) => i.chatId == chatId);
    if (idx != -1) {
      final i = _inbox[idx];
      _inbox[idx] = InboxItem(
        chatId: i.chatId,
        otherUserId: i.otherUserId,
        otherUserName: i.otherUserName,
        otherUserAvatar: i.otherUserAvatar,
        otherUserLevel: i.otherUserLevel,
        otherIsFounder: i.otherIsFounder,
        lastMessageContent: i.lastMessageContent,
        lastMessageSenderId: i.lastMessageSenderId,
        lastMessageAt: i.lastMessageAt,
        unreadCount: 0,
      );
    }
  }

  // ============================ RUEDA DE LA VIDA ============================
  RuedaVida ruedaActual() {
    final now = DateTime.now();
    final match = _ruedas
        .where((r) => r.month.year == now.year && r.month.month == now.month);
    return match.isEmpty
        ? RuedaVida.empty(kDemoUserId, DateTime(now.year, now.month, 1))
        : match.first;
  }

  List<RuedaVida> ruedaHistory() =>
      List.of(_ruedas)..sort((a, b) => b.month.compareTo(a.month));

  void saveRueda(RuedaVida rueda) {
    _ruedas.removeWhere((r) =>
        r.month.year == rueda.month.year && r.month.month == rueda.month.month);
    _ruedas.add(rueda);
  }

  // ============================ BUDDY ============================
  BuddyDashboard buddyDashboard() => _buddyDashboard;
  List<BuddyMonthlyIncome> buddyMonthlyIncome() => List.of(_buddyIncome);
  List<BuddyUpcomingCapsula> buddyUpcomingCapsulas() => List.of(_buddyUpcoming);
}
