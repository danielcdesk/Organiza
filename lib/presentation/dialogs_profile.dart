part of 'dialogs.dart';

class ProfileInput {
  const ProfileInput({
    required this.name,
    required this.incomeInCents,
    this.photoPath,
  });

  final String name;
  final int incomeInCents;
  final String? photoPath;
}

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({
    super.key,
    this.initialName = '',
    this.initialIncomeInCents = 0,
    this.initialPhotoPath,
  });

  final String initialName;
  final int initialIncomeInCents;
  final String? initialPhotoPath;

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _income = TextEditingController(
    text: widget.initialIncomeInCents == 0
        ? ''
        : (widget.initialIncomeInCents / 100)
            .toStringAsFixed(2)
            .replaceAll('.', ','),
  );
  String? _photoPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Seu perfil local'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _profilePreview(context),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Como podemos chamar você?',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _income,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Quanto você ganha por mês?',
                    prefixIcon: Icon(Icons.payments_outlined),
                    prefixText: 'R\$ ',
                    helperText: 'Fica salvo somente neste dispositivo.',
                  ),
                ),
                _DialogError(_error),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Salvar perfil'),
          ),
        ],
      );

  Widget _profilePreview(BuildContext context) => Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: .16),
            backgroundImage: LocalImageService.exists(_photoPath)
                ? FileImage(File(_photoPath!))
                : null,
            child: LocalImageService.exists(_photoPath)
                ? null
                : Icon(Icons.person_outline_rounded,
                    size: 35, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: Text(_photoPath == null ? 'Adicionar foto' : 'Trocar foto'),
          ),
        ],
      );

  Future<void> _pickPhoto() async {
    final path = await LocalImageService.pickAndStore();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  void _submit() {
    final name = _name.text.trim();
    final income = parseMoney(_income.text) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Informe seu nome.');
      return;
    }
    Navigator.pop(
      context,
      ProfileInput(name: name, incomeInCents: income, photoPath: _photoPath),
    );
  }
}
