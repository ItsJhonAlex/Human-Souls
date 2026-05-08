/// Variables de entorno. En producción reemplazar por --dart-define o flutter_dotenv.
///
/// Ejemplo con dart-define:
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ... \
///               --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
///               --dart-define=MP_PUBLIC_KEY=APP_USR-...
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR-PROJECT.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR-ANON-KEY',
  );

  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_YOUR_KEY',
  );

  static const mercadopagoPublicKey = String.fromEnvironment(
    'MP_PUBLIC_KEY',
    defaultValue: 'APP_USR-YOUR-KEY',
  );

  static const zoomApiKey = String.fromEnvironment('ZOOM_API_KEY', defaultValue: '');
}
