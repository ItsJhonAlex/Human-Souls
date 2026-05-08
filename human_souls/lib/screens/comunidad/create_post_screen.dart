import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/theme.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _ctrl = TextEditingController();
  Uint8List? _imgBytes;
  String? _imgExt;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (f != null) {
      final bytes = await f.readAsBytes();
      setState(() {
        _imgBytes = bytes;
        _imgExt = f.name.split('.').last.toLowerCase();
      });
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.length < 3) {
      setState(() => _error = 'Escribí un poco más para compartir');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await createPost(
        ref: ref,
        content: text,
        imageBytes: _imgBytes,
        imageExt: _imgExt,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'No se pudo publicar. Probá de nuevo.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
            child: Row(children: [
              IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close_rounded)),
              const SizedBox(width: 4),
              Text('Compartir',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20)),
              const Spacer(),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                GlassCard(
                  child: TextField(
                    controller: _ctrl,
                    maxLength: 800,
                    maxLines: 10,
                    minLines: 5,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                    cursorColor: SoulColors.turquoise,
                    decoration: const InputDecoration(
                      hintText: '¿Qué querés compartir con tu comunidad?',
                      hintStyle: TextStyle(color: SoulColors.textMuted),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: SoulColors.textMuted),
                    ),
                  ),
                ),
                if (_imgBytes != null) ...[
                  const SizedBox(height: 12),
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(_imgBytes!,
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _imgBytes = null;
                          _imgExt = null;
                        }),
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
                  ]),
                ] else ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: SoulColors.glass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: SoulColors.glassBorder),
                      ),
                      child: const Row(children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: SoulColors.turquoise),
                        SizedBox(width: 10),
                        Text('Agregar una imagen',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SoulButton(
              label: 'Publicar',
              icon: Icons.send_rounded,
              loading: _submitting,
              onPressed: _submit,
            ),
          ),
        ]),
      ),
    );
  }
}
