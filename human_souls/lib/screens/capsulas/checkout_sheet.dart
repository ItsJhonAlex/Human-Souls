import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/theme.dart';
import '../../core/services/payments_service.dart';
import '../../models/capsula.dart';
import '../../providers/capsulas_provider.dart';

void showCheckoutSheet(BuildContext context, WidgetRef ref, Capsula capsula) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CheckoutSheet(capsula: capsula),
  );
}

/// Abre el webview interno para completar un pago con url dada.
/// Devuelve `true` si detectó la URL de éxito.
Future<bool?> showCheckoutWebView(BuildContext context, {required String url}) {
  return Navigator.of(context).push<bool>(MaterialPageRoute(
    builder: (_) => _CheckoutWebView(url: url),
  ));
}

class CheckoutSheet extends ConsumerStatefulWidget {
  final Capsula capsula;
  const CheckoutSheet({super.key, required this.capsula});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _startCheckout(String provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = provider == 'mercadopago'
          ? await paymentsService.createMercadoPagoCheckout(
              capsulaId: widget.capsula.id)
          : await paymentsService.createStripeCheckout(
              capsulaId: widget.capsula.id);

      if (!mounted) return;
      Navigator.pop(context);

      if (kIsWeb) {
        await launchUrl(Uri.parse(session.url), webOnlyWindowName: '_blank');
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _CheckoutWebView(url: session.url),
        ));
        // Cuando vuelve, refrescar inscripciones por si el webhook ya corrió.
        ref.invalidate(myInscripcionesProvider);
      }
    } catch (e) {
      setState(() =>
          _error = 'No pudimos iniciar el pago. Probá de nuevo o contactanos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.capsula;
    return Container(
      decoration: const BoxDecoration(
        color: SoulColors.midnight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(height: 20),
        Text('Elegí cómo pagar',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 22)),
        const SizedBox(height: 6),
        Text('${c.title} · USD ${c.priceUsd.toStringAsFixed(0)}',
            style: const TextStyle(color: SoulColors.textSecondary)),
        const SizedBox(height: 24),
        _PaymentTile(
          title: 'MercadoPago',
          subtitle: 'Tarjeta, débito, dinero en cuenta · Argentina',
          emoji: '🇦🇷',
          onTap: _loading ? null : () => _startCheckout('mercadopago'),
          isPrimary: true,
        ),
        const SizedBox(height: 12),
        _PaymentTile(
          title: 'Tarjeta internacional',
          subtitle: 'Stripe · Visa, Mastercard, Amex',
          emoji: '💳',
          onTap: _loading ? null : () => _startCheckout('stripe'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 18),
        const Text(
            'El pago es procesado de forma segura por el proveedor elegido.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SoulColors.textMuted, fontSize: 11)),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: CircularProgressIndicator(color: SoulColors.turquoise),
          ),
      ]),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String title, subtitle, emoji;
  final VoidCallback? onTap;
  final bool isPrimary;
  const _PaymentTile({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isPrimary ? SoulColors.ctaGradient : null,
            color: isPrimary ? null : SoulColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? Colors.transparent : SoulColors.glassBorder,
            ),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isPrimary ? Colors.white70 : SoulColors.textMuted,
                        )),
                  ]),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
          ]),
        ),
      ),
    );
  }
}

// =====================================================================
// WEBVIEW para completar el pago (mobile)
// =====================================================================
class _CheckoutWebView extends StatefulWidget {
  final String url;
  const _CheckoutWebView({required this.url});
  @override
  State<_CheckoutWebView> createState() => _CheckoutWebViewState();
}

class _CheckoutWebViewState extends State<_CheckoutWebView> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(SoulColors.deepBlue)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onNavigationRequest: (req) {
          // Si la URL de vuelta es la nuestra de "success" o "cancel", cerramos.
          if (req.url.contains('/pago/exito') ||
              req.url.contains('/pago/cancelado')) {
            Navigator.of(context).pop(req.url.contains('/pago/exito'));
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoulColors.deepBlue,
      appBar: AppBar(
        backgroundColor: SoulColors.deepBlue,
        title: const Text('Completar pago'),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_progress < 100)
          LinearProgressIndicator(
            value: _progress / 100,
            color: SoulColors.turquoise,
            backgroundColor: Colors.transparent,
          ),
      ]),
    );
  }
}
