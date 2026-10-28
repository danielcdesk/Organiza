import 'package:flutter/material.dart';

/// A recognizable local mark for common subscriptions; no remote image is used.
class SubscriptionPlatformMark extends StatelessWidget {
  const SubscriptionPlatformMark({
    super.key,
    required this.name,
    required this.category,
  });

  final String name;
  final String category;

  @override
  Widget build(BuildContext context) {
    final platform = _platformFor(name);
    if (platform == null) {
      final categoryName = category.trim().toLowerCase();
      final icon = categoryName.contains('lazer')
          ? Icons.subscriptions_outlined
          : categoryName.contains('saúde')
              ? Icons.favorite_outline_rounded
              : Icons.autorenew_rounded;
      return ExcludeSemantics(
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon,
              size: 20, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: platform.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: platform.icon == null
            ? Text(
                platform.label,
                style: TextStyle(
                  color: platform.foreground,
                  fontSize: platform.label.length > 1 ? 13 : 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              )
            : Icon(platform.icon, size: 22, color: platform.foreground),
      ),
    );
  }
}

typedef _PlatformStyle = ({
  String label,
  Color background,
  Color foreground,
  IconData? icon,
});

_PlatformStyle? _platformFor(String name) {
  final value = name.trim().toLowerCase();
  if (value.contains('netflix')) {
    return (
      label: 'N',
      background: const Color(0xFF171717),
      foreground: const Color(0xFFE50914),
      icon: null
    );
  }
  if (value.contains('spotify')) {
    return (
      label: '',
      background: const Color(0xFF1ED760),
      foreground: const Color(0xFF111111),
      icon: Icons.graphic_eq_rounded
    );
  }
  if (value.contains('youtube')) {
    return (
      label: '',
      background: const Color(0xFFFF0033),
      foreground: Colors.white,
      icon: Icons.play_arrow_rounded
    );
  }
  if (value.contains('disney')) {
    return (
      label: 'D+',
      background: const Color(0xFF102A59),
      foreground: Colors.white,
      icon: null
    );
  }
  if (value.contains('prime video') || value.contains('amazon prime')) {
    return (
      label: 'P',
      background: const Color(0xFF0F79AF),
      foreground: Colors.white,
      icon: null
    );
  }
  if (value.contains('amazon music')) {
    return (
      label: '',
      background: const Color(0xFF0F79AF),
      foreground: Colors.white,
      icon: Icons.music_note_rounded
    );
  }
  if (value.contains('hbo') || value == 'max' || value.startsWith('max ')) {
    return (
      label: 'M',
      background: const Color(0xFF5C2D91),
      foreground: Colors.white,
      icon: null
    );
  }
  if (value.contains('globoplay')) {
    return (
      label: '',
      background: const Color(0xFFE64A3C),
      foreground: Colors.white,
      icon: Icons.play_arrow_rounded
    );
  }
  if (value.contains('crunchyroll')) {
    return (
      label: 'C',
      background: const Color(0xFFF47521),
      foreground: Colors.white,
      icon: null
    );
  }
  if (value.contains('apple music')) {
    return (
      label: '',
      background: const Color(0xFFFA233B),
      foreground: Colors.white,
      icon: Icons.music_note_rounded
    );
  }
  if (value.contains('deezer')) {
    return (
      label: '',
      background: const Color(0xFF7F41C6),
      foreground: Colors.white,
      icon: Icons.graphic_eq_rounded
    );
  }
  if (value.contains('chatgpt')) {
    return (
      label: '',
      background: const Color(0xFF0E806B),
      foreground: Colors.white,
      icon: Icons.auto_awesome_rounded
    );
  }
  if (value.contains('canva')) {
    return (
      label: 'C',
      background: const Color(0xFF00C4CC),
      foreground: const Color(0xFF102A40),
      icon: null
    );
  }
  if (value.contains('duolingo')) {
    return (
      label: 'D',
      background: const Color(0xFF58CC02),
      foreground: const Color(0xFF173B02),
      icon: null
    );
  }
  if (value.contains('microsoft 365') || value.contains('office 365')) {
    return (
      label: '',
      background: const Color(0xFF1766BF),
      foreground: Colors.white,
      icon: Icons.apps_rounded
    );
  }
  return null;
}
