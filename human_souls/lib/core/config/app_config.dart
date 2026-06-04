/// Configuración global de la app.
class AppConfig {
  AppConfig._();

  /// Cuando es `true`, la app usa datos de prueba en memoria y no requiere
  /// ninguna configuración de Supabase. Apagar con
  /// `--dart-define=USE_MOCK=false` (más las claves de Supabase) para usar el
  /// backend real.
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
}
