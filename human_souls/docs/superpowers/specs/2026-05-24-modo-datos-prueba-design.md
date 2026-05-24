# Modo datos de prueba (preview) — Diseño

**Fecha:** 2026-05-24
**Estado:** Aprobado, pendiente de plan de implementación
**Branch:** `feature/modo-datos-prueba`

## Objetivo

Hacer que la app **Human Souls** funcione de punta a punta con datos de prueba en
memoria —desde el login y el onboarding hasta cada pantalla y acción— para tener
una **vista previa interactiva** sin necesidad de un backend Supabase configurado.
Más adelante se conectará Supabase real; el código Supabase actual **no se borra**.

## Decisiones de producto (acordadas)

1. **Login visible:** se muestra la pantalla de login real, pero **cualquier
   credencial entra** como usuario demo (email/contraseña y botón de Google).
2. **Interactivo en memoria:** completar misiones, enviar chats, crear posts, dar
   like, mover los sliders de la Rueda, inscribirse, etc. **mutan el estado** y se
   reflejan al instante. Todo se **reinicia al cerrar la app**.
3. **Persona cambiable dentro de la app:** selector Free / Miembro / Buddy que
   cambia la UI en vivo (paywalls, chip de membresía, acceso al Dashboard Buddy).

## Enfoque arquitectónico (acordado: Opción B)

Flag global + store mock central. Cada provider/servicio arranca con un
early-return `if (AppConfig.useMock) return _mock...;` y **debajo queda intacto el
código Supabase actual**. Reconectar Supabase después = apagar el flag.

Se descartó la capa de repositorios (Opción A) por ser un refactor grande y
riesgoso en esta etapa, y los overrides de Riverpod (Opción C) porque el router y
varios servicios usan el singleton `supabase` global por fuera de Riverpod.

## El interruptor

- Nuevo: `lib/core/config/app_config.dart`
  ```dart
  class AppConfig {
    static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  }
  ```
- Con `useMock == true` la app **no requiere ninguna config de Supabase** y arranca
  sin backend.
- Reconectar Supabase: `--dart-define=USE_MOCK=false` (+ claves), sin tocar código.

## Archivos nuevos

### `lib/core/mock/mock_backend.dart`
Singleton con TODO el estado en memoria y los métodos de mutación. Contiene:
- Perfil demo (mutable: nombre, bio, nivel, XP, SP, membresía, flags de buddy).
- Misiones (daily/weekly/monthly) + completadas del usuario.
- Cápsulas + inscripciones del usuario.
- Posts + comentarios + likes (set de reacciones).
- Chats (inbox) + mensajes por chat.
- Ruedas de la vida (mes actual + historial).
- Datos de Dashboard Buddy (totales, ingresos mensuales, próximas cápsulas).

Métodos de mutación equivalentes a las acciones actuales: `submitMision`,
`validateMision`, `inscribir`, `cancelarInscripcion`, `createPost`, `toggleLike`,
`addComment`, `deletePost`, `sendMessage`, `markChatAsRead`, `findOrCreateChat`,
`saveRueda`, `createCapsula`, `updateProfile`, `setPersona`.

Expone `StreamController.broadcast` para lo que la UI consume como stream:
mensajes de un chat y el perfil. Las lecturas tipo `FutureProvider` devuelven
snapshots del store.

### `lib/core/mock/mock_session.dart`
`ChangeNotifier` que reemplaza a `supabase.auth` cuando `useMock`:
- `bool isLoggedIn`, `String userId`, `bool onboardingDone`.
- `signIn()` (acepta cualquier credencial), `signOut()`, `completeOnboarding()`.

### `lib/core/mock/seed_data.dart`
Datos demo en español, coherentes con la marca: ~8–10 posts realistas, 5–6
cápsulas (alguna en vivo, próximas y pasadas), misiones de cada cadencia, 3–4
chats con historial, ruedas de varios meses con valores variados, ingresos de
buddy de los últimos meses, y algunas completadas pendientes de validación (con
evidencia de texto) para poblar la cola del buddy.

## Auth, router y onboarding

- **`app_router.dart`**: `redirect` y `_AuthRefreshNotifier` usan `mockSession`
  cuando `useMock` (en vez de `supabase.auth.currentUser` / `onAuthStateChange`).
  `OnboardingFlag.ensure()` lee de `mockSession` / `MockBackend`.
- **`main.dart`**: `Supabase.initialize(...)` queda dentro de `if (!AppConfig.useMock)`.
  El locale y timeago se inicializan siempre.
- **`auth_service.dart`** (y/o `auth_provider`): login/signup/google → en mock
  llaman a `mockSession.signIn()`.
- **`onboarding_screen.dart`**: guardar perfil, publicar intención y completar la
  primera misión escriben en `MockBackend`. El perfil demo arranca con
  `onboarding_completed = false`, así cada arranque fresco muestra el flujo
  completo login → onboarding → mundo. (Invertible con una constante.)

## Ramas mock en providers y servicios

Cada provider/acción arranca con `if (AppConfig.useMock) return _mock...;`; debajo
queda el código Supabase actual sin cambios. Archivos afectados:

- `providers/profile_provider.dart` — `currentProfileProvider`, `profileStreamProvider`.
- `providers/misiones_provider.dart` — listados, completadas del período, cola de
  validación, `submitMision`, `validateMision`, `pickImageForEvidence`.
- `providers/capsulas_provider.dart` — próximas/pasadas/detalle/inscripciones,
  `inscribirGratis`, `cancelarInscripcion`.
- `providers/community_provider.dart` — feed, reacciones, comentarios, detalle,
  `createPost`, `toggleLike`, `addComment`, `deletePost`.
- `providers/chat_provider.dart` — inbox, stream de mensajes, `findOrCreateChat`,
  `sendMessage`, `markChatAsRead`, perfil del otro usuario.
- `providers/rueda_vida_provider.dart` — rueda actual, historial, `saveRueda`.
- `providers/buddy_dashboard_provider.dart` — dashboard, ingresos, próximas,
  `createCapsula`.
- `providers/stats_provider.dart` — `profileStatsProvider`.
- `core/services/payments_service.dart`, `core/services/membership_service.dart`.

Las mutaciones tocan `MockBackend` y se reflejan al instante vía `ref.invalidate`
o stream, igual que el flujo actual.

## Selector de persona

- Card **"Modo demo"** en `perfil_screen.dart`, visible solo si `useMock`, con 3
  chips: **Free / Miembro / Buddy**.
- Al cambiar, `MockBackend.setPersona()` ajusta `membershipStatus`, `isBuddy`,
  `isFounderBuddy` (y nivel/SP acordes) y notifica → la UI reacciona: aparece/
  desaparece la card de Dashboard Buddy, cambian paywalls y el chip de membresía.

## Decisiones de alcance (fiel vs. simplificado)

- **Pagos** (cápsulas y membresía): en mock **no abren webview**; simulan éxito →
  marcan inscripción/membresía como activa y muestran confirmación.
- **Subida de avatar**: en mock es un no-op amable (SnackBar "disponible al
  conectar el backend"); se mantienen los avatares con iniciales. No se implementa
  render de imágenes en memoria en esta etapa.
- **Evidencia de misiones con foto**: se prioriza evidencia de **texto** (la cola
  de validación la muestra). La selección de foto se acepta pero no se persiste
  imagen.
- **Realtime**: se simula con `StreamController` en memoria (los mensajes nuevos
  aparecen al instante en el chat abierto).

## Reconectar Supabase más adelante

Poner `AppConfig.useMock = false` (o `--dart-define=USE_MOCK=false` + claves). El
código Supabase queda debajo de cada rama; no se borra nada.

## Verificación

- `flutter analyze` limpio.
- Reemplazar el `test/widget_test.dart` roto (hoy es la plantilla del contador y
  falla) por un smoke test real del arranque en modo mock.
- Recorrido manual: login → onboarding → mundo → cada tab → cambiar persona →
  acciones (completar misión, postear, chatear, inscribirse, editar rueda,
  dashboard de buddy).

## Fuera de alcance

- Conexión real a Supabase (tablas, RPCs, Edge Functions, Storage, RLS).
- Persistencia entre sesiones del estado mock (se reinicia al cerrar).
- Render de imágenes subidas (avatar/evidencia) en modo mock.
