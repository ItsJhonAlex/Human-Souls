import '../../main.dart';

/// Sesión de checkout para una suscripción.
class SubscriptionCheckout {
  final String url;          // URL a la que redirigir o abrir en webview
  final String provider;     // 'stripe' | 'mercadopago'
  final String referenceId;  // session_id (Stripe) o preapproval_id (MP)
  const SubscriptionCheckout({
    required this.url,
    required this.provider,
    required this.referenceId,
  });
}

class MembershipService {
  /// Crea una Stripe Checkout Session en modo subscription.
  /// plan: 'monthly' | 'quarterly'
  Future<SubscriptionCheckout> createStripeSubscription({
    required String plan,
  }) async {
    final res = await supabase.functions.invoke(
      'create-stripe-subscription',
      body: {'plan': plan},
    );
    if (res.status != 200 || res.data == null) {
      throw Exception('No se pudo crear la suscripción: ${res.data}');
    }
    final data = res.data as Map<String, dynamic>;
    return SubscriptionCheckout(
      url: data['url'] as String,
      provider: 'stripe',
      referenceId: data['session_id'] as String,
    );
  }

  /// Crea un preapproval de MercadoPago (suscripción en ARS).
  /// plan: 'monthly' | 'quarterly'
  Future<SubscriptionCheckout> createMercadoPagoSubscription({
    required String plan,
  }) async {
    final res = await supabase.functions.invoke(
      'create-mp-preapproval',
      body: {'plan': plan},
    );
    if (res.status != 200 || res.data == null) {
      throw Exception('No se pudo crear la suscripción: ${res.data}');
    }
    final data = res.data as Map<String, dynamic>;
    return SubscriptionCheckout(
      url: data['init_point'] as String,
      provider: 'mercadopago',
      referenceId: data['preapproval_id'] as String,
    );
  }

  /// Cancela la suscripción activa del usuario.
  /// Deja acceso hasta el fin del período por defecto.
  Future<void> cancelSubscription({bool immediately = false}) async {
    final res = await supabase.functions.invoke(
      'cancel-subscription',
      body: {'immediately': immediately},
    );
    if (res.status != 200) {
      throw Exception('No se pudo cancelar: ${res.data}');
    }
  }
}

final membershipService = MembershipService();
