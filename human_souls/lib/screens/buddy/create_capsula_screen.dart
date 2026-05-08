import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/theme.dart';
import '../../providers/buddy_dashboard_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/common/soul_button.dart';
import '../../widgets/common/soul_text_field.dart';

class CreateCapsulaScreen extends ConsumerStatefulWidget {
  const CreateCapsulaScreen({super.key});

  @override
  ConsumerState<CreateCapsulaScreen> createState() =>
      _CreateCapsulaScreenState();
}

class _CreateCapsulaScreenState extends ConsumerState<CreateCapsulaScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _link = TextEditingController();
  final _capacity = TextEditingController(text: '30');
  final _price = TextEditingController(text: '0');

  DateTime? _startsAt;
  int _durationMinutes = 90;
  bool _includedInMembership = true;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _link.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SoulColors.turquoise,
            onPrimary: Colors.white,
            surface: SoulColors.midnight,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _startsAt ?? now.add(const Duration(hours: 2))),
      builder: (_, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: SoulColors.turquoise,
            onPrimary: Colors.white,
            surface: SoulColors.midnight,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (t == null) return;
    setState(
        () => _startsAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 3) {
      setState(() => _error = 'Ponele un título');
      return;
    }
    if (_startsAt == null) {
      setState(() => _error = 'Elegí fecha y hora');
      return;
    }
    if (_startsAt!.isBefore(DateTime.now())) {
      setState(() => _error = 'La fecha tiene que ser futura');
      return;
    }
    final cap = int.tryParse(_capacity.text.trim()) ?? 0;
    if (cap < 1) {
      setState(() => _error = 'Capacidad inválida');
      return;
    }
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await createCapsula(
        ref: ref,
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        startsAt: _startsAt!,
        duration: Duration(minutes: _durationMinutes),
        capacity: cap,
        priceUsd: price,
        includedInMembership: _includedInMembership,
        meetingLink: _link.text.trim().isEmpty ? null : _link.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: SoulColors.turquoise,
            content: Text('Cápsula creada ✨',
                style: TextStyle(
                    color: SoulColors.deepBlue, fontWeight: FontWeight.w700)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'No pudimos crearla: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
            child: Row(children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              const SizedBox(width: 4),
              Text('Nueva cápsula',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20)),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                SoulTextField(
                  controller: _title,
                  label: 'TÍTULO',
                  hint: 'Ej: Círculo de intenciones',
                  prefixIcon: Icons.title_rounded,
                  maxLength: 80,
                ),
                const SizedBox(height: 14),
                SoulTextField(
                  controller: _desc,
                  label: 'DESCRIPCIÓN',
                  hint: '¿De qué va a tratar la cápsula?',
                  maxLines: 4,
                  maxLength: 500,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('CUÁNDO'),
                const SizedBox(height: 6),
                _DateTimePicker(
                  startsAt: _startsAt,
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('DURACIÓN'),
                const SizedBox(height: 8),
                _DurationSelector(
                  value: _durationMinutes,
                  onChanged: (v) => setState(() => _durationMinutes = v),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: SoulTextField(
                    controller: _capacity,
                    label: 'CAPACIDAD',
                    prefixIcon: Icons.group_outlined,
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: SoulTextField(
                    controller: _price,
                    label: 'PRECIO USD',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                  )),
                ]),
                const SizedBox(height: 14),
                _IncludedSwitch(
                  value: _includedInMembership,
                  onChanged: (v) => setState(() => _includedInMembership = v),
                ),
                const SizedBox(height: 14),
                SoulTextField(
                  controller: _link,
                  label: 'LINK DE MEETING (OPCIONAL)',
                  hint: 'https://meet.google.com/…',
                  prefixIcon: Icons.videocam_rounded,
                  keyboardType: TextInputType.url,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: .4)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SoulButton(
              label: 'Crear cápsula',
              icon: Icons.auto_awesome,
              loading: _saving,
              onPressed: _submit,
            ),
          ),
        ]),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: SoulColors.textSecondary,
        ));
  }
}

class _DateTimePicker extends StatelessWidget {
  final DateTime? startsAt;
  final VoidCallback onTap;
  const _DateTimePicker({required this.startsAt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat("EEE d MMM · HH:mm", 'es');
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        const Icon(Icons.event_rounded, color: SoulColors.turquoise),
        const SizedBox(width: 12),
        Expanded(
            child: Text(
          startsAt != null ? fmt.format(startsAt!) : 'Elegí fecha y horario',
          style: TextStyle(
            fontSize: 15,
            color: startsAt != null
                ? SoulColors.textPrimary
                : SoulColors.textMuted,
            fontWeight: startsAt != null ? FontWeight.w600 : FontWeight.w400,
          ),
        )),
        const Icon(Icons.chevron_right_rounded, color: Colors.white70),
      ]),
    );
  }
}

class _DurationSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DurationSelector({required this.value, required this.onChanged});

  static const _options = [45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _options.map((m) {
        final selected = m == value;
        return ChoiceChip(
          label: Text('$m min'),
          selected: selected,
          onSelected: (_) => onChanged(m),
          labelStyle: TextStyle(
            color: selected ? Colors.white : SoulColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
          backgroundColor: SoulColors.glass,
          selectedColor: SoulColors.violet,
          side: BorderSide(
            color: selected ? Colors.transparent : SoulColors.glassBorder,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

class _IncludedSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _IncludedSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => onChanged(!value),
      child: Row(children: [
        Icon(
          value
              ? Icons.workspace_premium_rounded
              : Icons.local_activity_rounded,
          color: value ? SoulColors.gold : SoulColors.turquoise,
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                value
                    ? 'Incluida en la membresía'
                    : 'Pago individual por cápsula',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              value
                  ? 'Los miembros activos se inscriben gratis'
                  : 'Los usuarios pagan el precio que definiste',
              style: const TextStyle(
                  color: SoulColors.textSecondary, fontSize: 12),
            ),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: SoulColors.turquoise,
        ),
      ]),
    );
  }
}
