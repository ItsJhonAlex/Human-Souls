import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/theme.dart';
import '../../models/mision.dart';
import '../../providers/misiones_provider.dart';
import '../../widgets/common/soul_button.dart';
import '../../widgets/common/soul_text_field.dart';

void showMisionDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Mision mision,
  MisionCompletada? existing,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MisionDetailSheet(mision: mision, existing: existing),
  );
}

class MisionDetailSheet extends ConsumerStatefulWidget {
  final Mision mision;
  final MisionCompletada? existing;
  const MisionDetailSheet({
    super.key,
    required this.mision,
    required this.existing,
  });

  @override
  ConsumerState<MisionDetailSheet> createState() => _MisionDetailSheetState();
}

class _MisionDetailSheetState extends ConsumerState<MisionDetailSheet> {
  final _textCtrl = TextEditingController();
  Uint8List? _imgBytes;
  String? _imgExt;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  bool get _isDone => widget.existing?.validated == true;
  bool get _isInReview =>
      widget.existing != null && widget.existing!.validated == false;

  Future<void> _pickImage() async {
    final res = await pickImageForEvidence();
    if (res != null) {
      setState(() {
        _imgBytes = res.bytes;
        _imgExt = res.ext;
      });
    }
  }

  Future<void> _submit() async {
    final m = widget.mision;

    if (m.evidenceType == EvidenceType.text ||
        m.evidenceType == EvidenceType.post) {
      if (_textCtrl.text.trim().length < 10) {
        setState(() => _error = 'Contanos un poco más (mín. 10 caracteres)');
        return;
      }
    }
    if (m.evidenceType == EvidenceType.photo && _imgBytes == null) {
      setState(() => _error = 'Subí una foto que respalde tu misión');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await submitMision(
        ref: ref,
        mision: m,
        evidenceText:
            _textCtrl.text.trim().isEmpty ? null : _textCtrl.text.trim(),
        evidenceFileBytes: _imgBytes,
        evidenceFileExt: _imgExt,
      );
      if (!mounted) return;
      Navigator.pop(context);

      final autoValidated = m.evidenceType == EvidenceType.none;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              autoValidated ? SoulColors.turquoise : SoulColors.gold,
          content: Text(
            autoValidated
                ? '¡Misión completada! +${m.xpReward} XP · +${m.soulPointsReward} SP'
                : 'Enviado. Un Soul Buddy lo va a validar pronto ✨',
            style: const TextStyle(
              color: SoulColors.deepBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = 'No pudimos enviarla. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mision;
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
        decoration: const BoxDecoration(
          color: SoulColors.midnight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 28 + mq.viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tipo + recompensa
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: SoulColors.ctaGradient,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(m.tipo.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      )),
                ),
                const Spacer(),
                Row(children: [
                  const Icon(Icons.bolt_rounded,
                      size: 16, color: SoulColors.gold),
                  const SizedBox(width: 3),
                  Text('+${m.xpReward} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SoulColors.gold,
                      )),
                  const SizedBox(width: 10),
                  const Icon(Icons.favorite_rounded,
                      size: 14, color: SoulColors.pink),
                  const SizedBox(width: 3),
                  Text('+${m.soulPointsReward}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SoulColors.pink,
                      )),
                ]),
              ]),

              const SizedBox(height: 16),
              Text(m.title,
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text(m.description,
                  style: const TextStyle(
                    color: SoulColors.textSecondary,
                    fontSize: 14,
                    height: 1.45,
                  )),

              const SizedBox(height: 22),

              if (_isDone)
                _DoneBanner()
              else if (_isInReview)
                _InReviewBanner()
              else
                _EvidenceForm(
                  mision: m,
                  textCtrl: _textCtrl,
                  imgBytes: _imgBytes,
                  onPickImage: _pickImage,
                  onClearImage: () => setState(() {
                    _imgBytes = null;
                    _imgExt = null;
                  }),
                ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: .4),
                    ),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
              ],

              if (!_isDone && !_isInReview) ...[
                const SizedBox(height: 20),
                SoulButton(
                  label: m.evidenceType == EvidenceType.none
                      ? 'Marcar como completada'
                      : 'Enviar mi misión',
                  icon: m.evidenceType == EvidenceType.none
                      ? Icons.check_rounded
                      : Icons.send_rounded,
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// BANNERS
// =====================================================================
class _DoneBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SoulColors.turquoise.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SoulColors.turquoise.withValues(alpha: .4)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: SoulColors.turquoise, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ya completaste esta misión',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              const Text('Volvés a verla cuando se renueve el período.',
                  style:
                      TextStyle(color: SoulColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _InReviewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SoulColors.gold.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SoulColors.gold.withValues(alpha: .5)),
      ),
      child: Row(children: [
        const Icon(Icons.hourglass_top_rounded,
            color: SoulColors.gold, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('En revisión por un Soul Buddy',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              const Text(
                'En breve vas a recibir tu XP y Soul Points.',
                style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// =====================================================================
// EVIDENCE FORM
// =====================================================================
class _EvidenceForm extends StatelessWidget {
  final Mision mision;
  final TextEditingController textCtrl;
  final Uint8List? imgBytes;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const _EvidenceForm({
    required this.mision,
    required this.textCtrl,
    required this.imgBytes,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    switch (mision.evidenceType) {
      case EvidenceType.none:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SoulColors.glass,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Icon(Icons.auto_awesome, color: SoulColors.turquoise),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Esta misión se completa automáticamente al tocar el botón.',
                style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
              ),
            ),
          ]),
        );
      case EvidenceType.text:
      case EvidenceType.post:
        return SoulTextField(
          controller: textCtrl,
          label: mision.evidenceType == EvidenceType.post
              ? 'TU PUBLICACIÓN'
              : 'TU REFLEXIÓN',
          hint: mision.evidenceType == EvidenceType.post
              ? 'Lo que quieras compartir con la comunidad…'
              : 'Escribí en pocas líneas…',
          maxLines: 6,
          maxLength: 500,
        );
      case EvidenceType.photo:
        if (imgBytes != null) {
          return Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(imgBytes!,
                  width: double.infinity, height: 220, fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onClearImage,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ),
          ]);
        }
        return GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: SoulColors.glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SoulColors.glassBorder,
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: const Column(children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 36, color: Colors.white70),
              SizedBox(height: 10),
              Text('Subí una foto de evidencia',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('JPG o PNG',
                  style: TextStyle(fontSize: 12, color: SoulColors.textMuted)),
            ]),
          ),
        );
      case EvidenceType.audio:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SoulColors.glass,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Icon(Icons.mic_off_rounded, color: SoulColors.textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'La grabación de audio llega en una próxima versión. '
                'Por ahora podés dejar una nota escrita.',
                style: TextStyle(color: SoulColors.textSecondary, fontSize: 13),
              ),
            ),
          ]),
        );
    }
  }
}
