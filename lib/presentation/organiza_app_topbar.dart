part of 'organiza_app.dart';

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.hideValues,
    required this.onSearch,
    required this.onToggleValues,
    required this.onThemeChanged,
    required this.isFullscreen,
    required this.onToggleFullscreen,
  });

  final String title;
  final bool hideValues;
  final VoidCallback onSearch;
  final VoidCallback onToggleValues;
  final ValueChanged<ThemeMode> onThemeChanged;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) => Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Material(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: .38),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: onSearch,
                  borderRadius: BorderRadius.circular(13),
                  child: const SizedBox(
                    height: 42,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 13),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18),
                          SizedBox(width: 9),
                          Expanded(child: Text('Buscar no Organiza')),
                          _KeyHint('Ctrl K'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleValues,
              tooltip: hideValues ? 'Mostrar valores' : 'Ocultar valores',
              icon: Icon(hideValues
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
            ),
            IconButton(
              onPressed: onToggleFullscreen,
              tooltip: isFullscreen ? 'Sair da tela cheia' : 'Tela cheia',
              icon: Icon(isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded),
            ),
            PopupMenuButton<ThemeMode>(
              tooltip: 'Tema',
              icon: const Icon(Icons.brightness_6_outlined),
              onSelected: onThemeChanged,
              itemBuilder: (_) => const [
                PopupMenuItem(value: ThemeMode.system, child: Text('Sistema')),
                PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
                PopupMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
              ],
            ),
          ],
        ),
      );
}
