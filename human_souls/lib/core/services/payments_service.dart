import '../../main.dart';
import '../config/app_config.dart';

/// Respuesta de creación de checkout.
class CheckoutSession {
  final String url; // URL a la que redirigir (o abrir en webview)
  final String provider; // 'mercadopago' | 'stripe'
  final String referenceId; // preference_id (MP) o session_id (Stripe)
  final bool isMock;
  const CheckoutSession({
    required this.url,
    required this.provider,
    required this.referenceId,
    this.isMock = false,
  });
}

class PaymentsService {
  /// Crea una preferencia de MercadoPago para una cápsula.
  /// Llama a la Edge Function 'create-mp-preference'.
  Future<CheckoutSession> createMercadoPagoCheckout({
    required String capsulaId,
  }) async {
    if (AppConfig.useMock) {
      return CheckoutSession(
          url: '', provider: 'mock', referenceId: capsulaId, isMock: true);
    }
    final res = await supabase.functions.invoke(
      'create-mp-preference',
      body: {'capsula_id': capsulaId},
    );
    if (res.status != 200 || res.data == null) {
      throw Exception('No se pudo crear la preferencia: ${res.data}');
    }
    final data = res.data as Map<String, dynamic>;
    return CheckoutSession(
      url: data['init_point'] as String,
      provider: 'mercadopago',
      referenceId: data['preference_id'] as String,
    );
  }

  /// Crea una Checkout Session de Stripe para una cápsula.
  /// Llama a la Edge Function 'create-stripe-checkout'.
  Future<CheckoutSession> createStripeCheckout({
    required String capsulaId,
  }) async {
    if (AppConfig.useMock) {
      return CheckoutSession(
          url: '', provider: 'mock', referenceId: capsulaId, isMock: true);
    }
    final res = await supabase.functions.invoke(
      'create-stripe-checkout',
      body: {'capsula_id': capsulaId},
    );
    if (res.status != 200 || res.data == null) {
      throw Exception('No se pudo crear el checkout: ${res.data}');
    }
    final data = res.data as Map<String, dynamic>;
    return CheckoutSession(
      url: data['url'] as String,
      provider: 'stripe',
      referenceId: data['session_id'] as String,
    );
  }
}

final paymentsService = PaymentsService();
