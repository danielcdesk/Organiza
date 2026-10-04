import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onStart,
    required this.onRestore,
    required this.onPrivacy,
  });

  final VoidCallback onStart;
  final VoidCallback onRestore;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<_WelcomeTokens>() ?? const _WelcomeTokens();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.pagePadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const OrganizaWelcomeIllustration(),
                  SizedBox(height: tokens.largeGap),
                  Text(
                    'Suas finanças, só no seu aparelho.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(height: tokens.smallGap),
                  Text(
                    'Um lugar calmo para entender seu dinheiro e decidir o próximo passo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: tokens.largeGap),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onStart,
                      child: const Text('Começar'),
                    ),
                  ),
                  SizedBox(height: tokens.smallGap),
                  TextButton(
                    onPressed: onRestore,
                    child: const Text('Já tenho um backup'),
                  ),
                  SizedBox(height: tokens.largeGap),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Seus dados ficam neste aparelho. ',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Semantics(
                        link: true,
                        child: InkWell(
                          onTap: onPrivacy,
                          child: Text(
                            'Política de privacidade',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OrganizaWelcomeIllustration extends StatelessWidget {
  const OrganizaWelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'Símbolo vetorial do Organiza formado por círculos e linhas',
        child: SizedBox(
          width: 230,
          height: 230,
          child: CustomPaint(painter: _WelcomePainter(Theme.of(context))),
        ),
      );
}

class _WelcomePainter extends CustomPainter {
  const _WelcomePainter(this.theme);

  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final tertiary = theme.colorScheme.tertiary;
    final outline = theme.colorScheme.onSurface;
    final radius = size.shortestSide * .27;
    final orbit = Paint()
      ..color = primary.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .018;
    canvas.drawCircle(center, radius * 1.55, orbit);
    canvas.drawCircle(
        center, radius * 1.12, orbit..color = tertiary.withValues(alpha: .5));

    final core = Paint()..color = primary;
    canvas.drawCircle(center, radius, core);
    final inner = Paint()..color = theme.colorScheme.surface;
    canvas.drawCircle(center, radius * .72, inner);
    final mark = Paint()
      ..color = outline
      ..strokeWidth = size.shortestSide * .035
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      center.translate(-radius * .34, radius * .16),
      center.translate(0, -radius * .28),
      mark,
    );
    canvas.drawLine(
      center.translate(0, -radius * .28),
      center.translate(radius * .34, radius * .16),
      mark,
    );
    canvas.drawLine(
      center.translate(-radius * .34, radius * .16),
      center.translate(radius * .34, radius * .16),
      mark,
    );
    final dots = [
      (Offset(.12, .12), secondary),
      (Offset(.86, .27), tertiary),
      (Offset(.78, .86), primary),
    ];
    for (final dot in dots) {
      canvas.drawCircle(
        Offset(size.width * dot.$1.dx, size.height * dot.$1.dy),
        size.shortestSide * .055,
        Paint()..color = dot.$2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomePainter oldDelegate) =>
      oldDelegate.theme.colorScheme != theme.colorScheme;
}

class _WelcomeTokens {
  const _WelcomeTokens();
  final double pagePadding = 24;
  final double largeGap = 28;
  final double smallGap = 8;
}
