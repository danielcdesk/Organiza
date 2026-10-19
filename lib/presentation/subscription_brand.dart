import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubscriptionBrand {
  const SubscriptionBrand(this.key, this.name, this.color, this.aliases);

  final String key;
  final String name;
  final Color color;
  final List<String> aliases;
  String get assetPath => 'assets/subscriptions/$key.svg';
}

const subscriptionBrands = <SubscriptionBrand>[
  SubscriptionBrand('spotify', 'Spotify', Color(0xFF1ED760), ['spotify']),
  SubscriptionBrand('netflix', 'Netflix', Color(0xFFE50914), ['netflix']),
  SubscriptionBrand('hbomax', 'HBO Max', Color(0xFF000000), ['hbo max']),
  SubscriptionBrand('hbo', 'HBO', Color(0xFF000000), ['hbo']),
  SubscriptionBrand('max', 'Max', Color(0xFF525252), ['max']),
  SubscriptionBrand(
      'youtubemusic', 'YouTube Music', Color(0xFFFF0000), ['youtube music']),
  SubscriptionBrand('youtube', 'YouTube', Color(0xFFFF0000), ['youtube']),
  SubscriptionBrand(
      'applemusic', 'Apple Music', Color(0xFFFA243C), ['apple music']),
  SubscriptionBrand('appletv', 'Apple TV', Color(0xFF000000), ['apple tv']),
  SubscriptionBrand('deezer', 'Deezer', Color(0xFFA238FF), ['deezer']),
  SubscriptionBrand(
      'paramountplus', 'Paramount+', Color(0xFF0064FF), ['paramount']),
  SubscriptionBrand(
      'crunchyroll', 'Crunchyroll', Color(0xFFFF5E00), ['crunchyroll']),
  SubscriptionBrand('twitch', 'Twitch', Color(0xFF9146FF), ['twitch']),
  SubscriptionBrand('notion', 'Notion', Color(0xFF000000), ['notion']),
  SubscriptionBrand('dropbox', 'Dropbox', Color(0xFF0061FF), ['dropbox']),
  SubscriptionBrand('icloud', 'iCloud', Color(0xFF3693F3), ['icloud']),
  SubscriptionBrand('duolingo', 'Duolingo', Color(0xFF58CC02), ['duolingo']),
  SubscriptionBrand('patreon', 'Patreon', Color(0xFF000000), ['patreon']),
  SubscriptionBrand(
      'soundcloud', 'SoundCloud', Color(0xFFFF5500), ['soundcloud']),
  SubscriptionBrand('tidal', 'TIDAL', Color(0xFF000000), ['tidal']),
  SubscriptionBrand('playstation', 'PlayStation', Color(0xFF0070D1),
      ['playstation', 'ps plus']),
];

String _normalizeBrandName(String input) => input
    .toLowerCase()
    .replaceAll(RegExp(r'[áàâãä]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[íìîï]'), 'i')
    .replaceAll(RegExp(r'[óòôõö]'), 'o')
    .replaceAll(RegExp(r'[úùûü]'), 'u')
    .replaceAll('ç', 'c');

SubscriptionBrand? subscriptionBrandFor(String name, String? iconKey) {
  if (iconKey == 'generic') return null;
  if (iconKey != null && iconKey != 'auto') {
    for (final brand in subscriptionBrands) {
      if (brand.key == iconKey) return brand;
    }
  }
  final normalized = _normalizeBrandName(name);
  for (final brand in subscriptionBrands) {
    if (brand.aliases.any((alias) => normalized.contains(alias))) return brand;
  }
  return null;
}

class SubscriptionBrandIcon extends StatelessWidget {
  const SubscriptionBrandIcon(
      {super.key, required this.name, this.iconKey, this.size = 42});

  final String name;
  final String? iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = subscriptionBrandFor(name, iconKey);
    final scheme = Theme.of(context).colorScheme;
    final foreground = brand == null
        ? scheme.primary
        : brand.color.computeLuminance() < .12 &&
                scheme.brightness == Brightness.dark
            ? Colors.white
            : brand.color;
    return Semantics(
      label: brand == null ? 'Assinatura' : 'Ícone ${brand.name}',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .21),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(size * .25),
        ),
        child: brand == null
            ? Icon(Icons.autorenew_rounded, size: size * .58, color: foreground)
            : SvgPicture.asset(brand.assetPath,
                colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn)),
      ),
    );
  }
}
