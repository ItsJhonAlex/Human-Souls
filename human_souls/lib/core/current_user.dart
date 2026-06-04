import '../main.dart';
import 'config/app_config.dart';
import 'mock/mock_session.dart';

/// Id del usuario actual, agnóstico al modo (mock vs Supabase).
/// Usar esto en vez de `supabase.auth.currentUser?.id` en la UI.
String? currentUserId() => AppConfig.useMock
    ? (MockSession.instance.isLoggedIn ? MockSession.instance.userId : null)
    : supabase.auth.currentUser?.id;
