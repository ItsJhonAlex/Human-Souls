import '../../models/buddy_dashboard.dart';
import '../../models/capsula.dart';
import '../../models/chat.dart';
import '../../models/mision.dart';
import '../../models/post.dart';
import '../../models/profile.dart';
import '../../models/rueda_vida.dart';
import 'mock_session.dart';

DateTime _daysFromNow(int d) => DateTime.now().add(Duration(days: d));
DateTime _hoursFromNow(int h) => DateTime.now().add(Duration(hours: h));
DateTime _firstOfMonth(int monthsAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - monthsAgo, 1);
}

/// Otros souls demo (no el usuario actual).
const seedOtherUsers = <String, Map<String, dynamic>>{
  'soul-ana': {
    'id': 'soul-ana',
    'full_name': 'Ana Beltrán',
    'avatar_url': null,
    'level_name': 'Buscadora',
    'is_founder_buddy': true,
    'bio': 'Acompaño procesos de cambio. Madre, caminante, eterna aprendiz.',
  },
  'soul-mateo': {
    'id': 'soul-mateo',
    'full_name': 'Mateo Ruiz',
    'avatar_url': null,
    'level_name': 'Explorador',
    'is_founder_buddy': false,
    'bio': 'Probando vivir con más presencia.',
  },
  'soul-lu': {
    'id': 'soul-lu',
    'full_name': 'Lucía Fern',
    'avatar_url': null,
    'level_name': 'Constructora',
    'is_founder_buddy': false,
    'bio': null,
  },
};

Profile seedDemoProfile() => const Profile(
      id: kDemoUserId,
      email: 'demo@humansouls.app',
      fullName: 'Daia Ramírez',
      username: 'daia',
      avatarUrl: null,
      bio: 'En camino. Aprendiendo a habitarme.',
      level: 2,
      levelName: 'Buscadora',
      xp: 240,
      soulPoints: 85,
      isBuddy: true,
      isFounderBuddy: true,
      membershipStatus: 'active',
      membershipPlan: 'monthly',
      membershipProvider: 'stripe',
      onboardingCompleted: false,
    );

List<Mision> seedMisiones() => [
      Mision(
        id: 'mis-intencion',
        title: 'Escribí tu intención',
        description:
            'Compartí en el feed una intención que quieras sostener esta semana.',
        tipo: MisionTipo.daily,
        xpReward: 15,
        soulPointsReward: 5,
        evidenceType: EvidenceType.post,
        active: true,
        startsAt: _daysFromNow(-3),
      ),
      Mision(
        id: 'mis-respira',
        title: 'Respirá 3 minutos',
        description:
            'Tomate 3 minutos para respirar conscientemente. Marcá cuando lo hayas hecho.',
        tipo: MisionTipo.daily,
        xpReward: 10,
        soulPointsReward: 3,
        evidenceType: EvidenceType.none,
        active: true,
        startsAt: _daysFromNow(-3),
      ),
      Mision(
        id: 'mis-gratitud',
        title: 'Carta de gratitud',
        description:
            'Escribí una reflexión sobre algo por lo que estés agradecida esta semana.',
        tipo: MisionTipo.weekly,
        xpReward: 30,
        soulPointsReward: 12,
        evidenceType: EvidenceType.text,
        active: true,
        startsAt: _daysFromNow(-3),
      ),
      Mision(
        id: 'mis-naturaleza',
        title: 'Encuentro con la naturaleza',
        description:
            'Pasá un rato al aire libre este mes y compartí una foto del momento.',
        tipo: MisionTipo.monthly,
        xpReward: 50,
        soulPointsReward: 20,
        evidenceType: EvidenceType.photo,
        active: true,
        startsAt: _firstOfMonth(0),
      ),
    ];

/// Completadas pendientes de validación, de OTROS usuarios (para la cola del buddy).
List<MisionCompletada> seedPendingCompletadas() => [
      MisionCompletada(
        id: 'comp-1',
        userId: 'soul-mateo',
        misionId: 'mis-gratitud',
        periodKey: 'pending',
        validated: false,
        createdAt: _hoursFromNow(-5),
        evidenceText:
            'Agradezco haber pedido ayuda esta semana. Me costó, pero lo hice.',
        mision: null,
        userName: 'Mateo Ruiz',
      ),
      MisionCompletada(
        id: 'comp-2',
        userId: 'soul-lu',
        misionId: 'mis-gratitud',
        periodKey: 'pending',
        validated: false,
        createdAt: _hoursFromNow(-9),
        evidenceText: 'Gracias a mi hermana por escucharme sin juzgar.',
        mision: null,
        userName: 'Lucía Fern',
      ),
    ];

List<Capsula> seedCapsulas() => [
      Capsula(
        id: 'cap-live',
        title: 'Círculo de Soul Buddies',
        description:
            'Un espacio en vivo para compartir dónde estás y hacia dónde querés ir.',
        hostId: 'soul-ana',
        hostName: 'Ana Beltrán',
        startsAt: _hoursFromNow(-1),
        endsAt: _hoursFromNow(1),
        meetingLink: 'https://meet.example.com/circulo',
        capacity: 50,
        priceUsd: 0,
        includedInMembership: true,
        xpReward: 30,
        soulPointsReward: 15,
        status: 'live',
        inscripcionesCount: 23,
      ),
      Capsula(
        id: 'cap-prox1',
        title: 'Rueda de la Vida en profundidad',
        description: 'Taller práctico para leer tu Rueda y definir un foco.',
        hostId: 'soul-ana',
        hostName: 'Ana Beltrán',
        startsAt: _daysFromNow(2),
        endsAt: _daysFromNow(2).add(const Duration(hours: 1, minutes: 30)),
        meetingLink: 'https://meet.example.com/rueda',
        capacity: 40,
        priceUsd: 0,
        includedInMembership: true,
        xpReward: 30,
        soulPointsReward: 15,
        status: 'scheduled',
        inscripcionesCount: 12,
      ),
      Capsula(
        id: 'cap-prox2',
        title: 'Masterclass: Hábitos que sostienen',
        description: 'Cápsula especial con cupo limitado. Entrada individual.',
        hostId: 'soul-ana',
        hostName: 'Ana Beltrán',
        startsAt: _daysFromNow(6),
        endsAt: _daysFromNow(6).add(const Duration(hours: 2)),
        meetingLink: 'https://meet.example.com/habitos',
        capacity: 20,
        priceUsd: 15,
        includedInMembership: false,
        xpReward: 40,
        soulPointsReward: 18,
        status: 'scheduled',
        inscripcionesCount: 8,
      ),
      Capsula(
        id: 'cap-pasada',
        title: 'Meditación guiada de cierre',
        description: 'Una práctica para soltar lo que ya cumplió su ciclo.',
        hostId: 'soul-ana',
        hostName: 'Ana Beltrán',
        startsAt: _daysFromNow(-7),
        endsAt: _daysFromNow(-7).add(const Duration(hours: 1)),
        meetingLink: 'https://meet.example.com/cierre',
        capacity: 50,
        priceUsd: 0,
        includedInMembership: true,
        xpReward: 30,
        soulPointsReward: 15,
        status: 'ended',
        inscripcionesCount: 31,
      ),
    ];

List<Post> seedPosts() => [
      Post(
        id: 'post-1',
        userId: 'soul-ana',
        content:
            'Esta semana mi intención es escuchar más y aconsejar menos. ¿Cuál es la tuya?',
        likesCount: 18,
        commentsCount: 2,
        createdAt: _hoursFromNow(-2),
        missionId: 'mis-intencion',
        authorName: 'Ana Beltrán',
        authorLevelName: 'Buscadora',
        authorIsFounder: true,
      ),
      Post(
        id: 'post-2',
        userId: kDemoUserId,
        content: 'Quiero empezar a moverme todos los días, aunque sea poquito.',
        likesCount: 7,
        commentsCount: 1,
        createdAt: _hoursFromNow(-6),
        missionId: 'mis-intencion',
        authorName: 'Daia Ramírez',
        authorLevelName: 'Buscadora',
        authorIsFounder: true,
      ),
      Post(
        id: 'post-3',
        userId: 'soul-mateo',
        content:
            'Hoy respiré tres minutos antes de una reunión difícil. Cambió todo.',
        likesCount: 12,
        commentsCount: 0,
        createdAt: _hoursFromNow(-20),
        authorName: 'Mateo Ruiz',
        authorLevelName: 'Explorador',
      ),
      Post(
        id: 'post-4',
        userId: 'soul-lu',
        content: 'Gracias a esta comunidad por recordarme que no estoy sola.',
        likesCount: 25,
        commentsCount: 0,
        createdAt: _daysFromNow(-2),
        authorName: 'Lucía Fern',
        authorLevelName: 'Constructora',
      ),
    ];

Map<String, List<PostComment>> seedComments() => {
      'post-1': [
        PostComment(
          id: 'c-1',
          postId: 'post-1',
          userId: 'soul-mateo',
          content: 'La mía es animarme a descansar sin culpa.',
          createdAt: _hoursFromNow(-1),
          authorName: 'Mateo Ruiz',
        ),
        PostComment(
          id: 'c-2',
          postId: 'post-1',
          userId: kDemoUserId,
          content: 'Hermoso. La mía es mover el cuerpo cada día.',
          createdAt: _hoursFromNow(-1),
          authorName: 'Daia Ramírez',
        ),
      ],
      'post-2': [
        PostComment(
          id: 'c-3',
          postId: 'post-2',
          userId: 'soul-ana',
          content: 'Te acompaño en eso. Un paso a la vez ✨',
          createdAt: _hoursFromNow(-5),
          authorName: 'Ana Beltrán',
        ),
      ],
    };

/// Chats demo: chatId -> mensajes. El "otro usuario" se deduce del inbox.
List<InboxItem> seedInbox() => [
      InboxItem(
        chatId: 'chat-ana',
        otherUserId: 'soul-ana',
        otherUserName: 'Ana Beltrán',
        otherUserLevel: 'Buscadora',
        otherIsFounder: true,
        lastMessageContent: 'Cuando quieras coordinamos una llamada 🙌',
        lastMessageSenderId: 'soul-ana',
        lastMessageAt: _hoursFromNow(-3),
        unreadCount: 1,
      ),
      InboxItem(
        chatId: 'chat-mateo',
        otherUserId: 'soul-mateo',
        otherUserName: 'Mateo Ruiz',
        otherUserLevel: 'Explorador',
        lastMessageContent: 'Vos: ¡Genial! Nos vemos en la cápsula.',
        lastMessageSenderId: kDemoUserId,
        lastMessageAt: _daysFromNow(-1),
        unreadCount: 0,
      ),
    ];

Map<String, List<Message>> seedMessages() => {
      'chat-ana': [
        Message(
          id: 'm-1',
          chatId: 'chat-ana',
          senderId: kDemoUserId,
          content: 'Hola Ana! Gracias por la cápsula de ayer, me llegó mucho.',
          read: true,
          createdAt: _hoursFromNow(-4),
        ),
        Message(
          id: 'm-2',
          chatId: 'chat-ana',
          senderId: 'soul-ana',
          content: 'Qué alegría leerte 💛',
          read: true,
          createdAt: _hoursFromNow(-4),
        ),
        Message(
          id: 'm-3',
          chatId: 'chat-ana',
          senderId: 'soul-ana',
          content: 'Cuando quieras coordinamos una llamada 🙌',
          read: false,
          createdAt: _hoursFromNow(-3),
        ),
      ],
      'chat-mateo': [
        Message(
          id: 'm-4',
          chatId: 'chat-mateo',
          senderId: 'soul-mateo',
          content: '¿Vas a la masterclass de hábitos?',
          read: true,
          createdAt: _daysFromNow(-1),
        ),
        Message(
          id: 'm-5',
          chatId: 'chat-mateo',
          senderId: kDemoUserId,
          content: '¡Genial! Nos vemos en la cápsula.',
          read: true,
          createdAt: _daysFromNow(-1),
        ),
      ],
    };

/// Ruedas del usuario: mes actual + 2 anteriores.
List<RuedaVida> seedRuedas() => [
      RuedaVida(
        userId: kDemoUserId,
        month: _firstOfMonth(0),
        salud: 7, familia: 8, amor: 6, amistad: 7,
        trabajo: 5, finanzas: 6, crecimiento: 8, espiritualidad: 7,
      ),
      RuedaVida(
        userId: kDemoUserId,
        month: _firstOfMonth(1),
        salud: 6, familia: 7, amor: 6, amistad: 6,
        trabajo: 5, finanzas: 5, crecimiento: 7, espiritualidad: 6,
      ),
      RuedaVida(
        userId: kDemoUserId,
        month: _firstOfMonth(2),
        salud: 5, familia: 7, amor: 5, amistad: 6,
        trabajo: 4, finanzas: 5, crecimiento: 6, espiritualidad: 5,
      ),
    ];

BuddyDashboard seedBuddyDashboard() => const BuddyDashboard(
      buddyId: kDemoUserId,
      fullName: 'Daia Ramírez',
      isFounderBuddy: true,
      capsulasTotal: 14,
      capsulasRealizadas: 11,
      capsulasProximas: 3,
      inscripcionesPagas: 64,
      soulsAlcanzadas: 210,
      ingresosBrutosUsd: 960,
      ingresosBuddyUsd: 672,
      feePlataformaUsd: 288,
      misionesValidadas: 48,
      pendientesValidacion: 2,
    );

List<BuddyMonthlyIncome> seedBuddyMonthlyIncome() => [
      BuddyMonthlyIncome(
        month: _firstOfMonth(0),
        ingresosBrutosUsd: 240,
        ingresosBuddyUsd: 168,
        soulsPagas: 16,
        capsulasConIngreso: 3,
      ),
      BuddyMonthlyIncome(
        month: _firstOfMonth(1),
        ingresosBrutosUsd: 360,
        ingresosBuddyUsd: 252,
        soulsPagas: 24,
        capsulasConIngreso: 4,
      ),
      BuddyMonthlyIncome(
        month: _firstOfMonth(2),
        ingresosBrutosUsd: 360,
        ingresosBuddyUsd: 252,
        soulsPagas: 24,
        capsulasConIngreso: 4,
      ),
    ];

List<BuddyUpcomingCapsula> seedBuddyUpcoming() => [
      BuddyUpcomingCapsula(
        capsulaId: 'cap-prox1',
        title: 'Rueda de la Vida en profundidad',
        startsAt: _daysFromNow(2),
        endsAt: _daysFromNow(2).add(const Duration(hours: 1, minutes: 30)),
        capacity: 40,
        priceUsd: 0,
        status: 'scheduled',
        inscritosTotal: 12,
        inscritosPagos: 12,
      ),
      BuddyUpcomingCapsula(
        capsulaId: 'cap-prox2',
        title: 'Masterclass: Hábitos que sostienen',
        startsAt: _daysFromNow(6),
        endsAt: _daysFromNow(6).add(const Duration(hours: 2)),
        capacity: 20,
        priceUsd: 15,
        status: 'scheduled',
        inscritosTotal: 8,
        inscritosPagos: 6,
      ),
    ];
