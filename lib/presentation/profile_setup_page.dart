import 'dart:io';

import 'package:flutter/material.dart';

import '../services/local_image_service.dart';
import 'dialogs.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key, required this.onComplete});

  final void Function(String name, int incomeInCents, String? photoPath)
      onComplete;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  late final _name = TextEditingController();
  late final _income = TextEditingController();
  String? _photoPath;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 860;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surfaceContainerLowest,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 20 : 42,
                compact ? 26 : 48,
                compact ? 20 : 42,
                compact ? 30 : 48,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _intro(context, compact: true),
                          const SizedBox(height: 24),
                          _formCard(context),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _intro(context)),
                          const SizedBox(width: 72),
                          SizedBox(width: 448, child: _formCard(context)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _intro(BuildContext context, {bool compact = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.primary.withValues(alpha: .3)),
              ),
              child: Image.asset(
                'assets/branding/organiza-app-icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ORGANIZA',
              style: TextStyle(
                color: scheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        Text(
          'Seu dinheiro começa\naqui.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: compact ? 34 : 52,
                height: 1.02,
                letterSpacing: -2.2,
              ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: Text(
            'Crie seu perfil local para o Organiza adaptar o painel ao seu jeito. Seus dados ficam somente neste dispositivo.',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: compact ? 14 : 16,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _SetupBenefit(
              icon: Icons.lock_outline_rounded,
              label: '100% offline',
            ),
            _SetupBenefit(
              icon: Icons.tune_rounded,
              label: 'Do seu jeito',
            ),
            _SetupBenefit(
              icon: Icons.insights_outlined,
              label: 'Visão clara',
            ),
          ],
        ),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vamos começar',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 5),
                      Text(
                        'Só precisamos do seu nome. O restante pode ficar para depois.',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '1 / 1',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(child: _photoPicker(context)),
            const SizedBox(height: 22),
            TextField(
              key: const ValueKey('profile-setup-name'),
              controller: _name,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Como podemos chamar você?',
                hintText: 'Seu nome',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              key: const ValueKey('profile-setup-income'),
              controller: _income,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Quanto você ganha por mês? (opcional)',
                hintText: '0,00',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: 'R\$ ',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A renda ajuda nos resumos, mas você pode preencher depois.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('profile-setup-error'),
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              key: const ValueKey('profile-setup-submit'),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(_saving ? 'Salvando...' : 'Entrar no Organiza'),
            ),
            const SizedBox(height: 13),
            Text(
              'Você poderá editar esses dados em Configurações.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = LocalImageService.exists(_photoPath);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: scheme.primary.withValues(alpha: .14),
              backgroundImage: hasPhoto ? FileImage(File(_photoPath!)) : null,
              child: hasPhoto
                  ? null
                  : Icon(Icons.person_outline_rounded,
                      size: 42, color: scheme.primary),
            ),
            Positioned(
              right: -4,
              bottom: -2,
              child: Material(
                color: scheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _pickPhoto,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Icon(Icons.camera_alt_outlined,
                        size: 17, color: scheme.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _pickPhoto,
          icon: const Icon(Icons.add_a_photo_outlined, size: 17),
          label: Text(hasPhoto ? 'Trocar foto' : 'Adicionar foto (opcional)'),
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final path = await LocalImageService.pickAndStore();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  void _submit() {
    final name = _name.text.trim();
    final income = _income.text.trim().isEmpty ? 0 : parseMoney(_income.text);
    if (name.isEmpty) {
      setState(() => _error = 'Informe seu nome para continuar.');
      return;
    }
    if (income == null) {
      setState(() => _error = 'Informe uma renda mensal válida.');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    widget.onComplete(name, income, _photoPath);
  }
}

class _SetupBenefit extends StatelessWidget {
  const _SetupBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}
