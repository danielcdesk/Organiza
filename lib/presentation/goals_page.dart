import 'package:flutter/material.dart';

import '../application/organiza_store.dart';
import '../domain/financial_rules.dart';
import '../domain/models.dart';
import 'shared_widgets.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({
    super.key,
    required this.store,
    required this.hideValues,
    required this.onAdd,
    required this.onContribute,
    required this.onDelete,
  });

  final OrganizaStore store;
  final bool hideValues;
  final VoidCallback onAdd;
  final ValueChanged<FinancialGoal> onContribute;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final goals = store.financialGoals;
    final saved = goals.fold(0, (sum, item) => sum + item.savedInCents);
    final target = goals.fold(0, (sum, item) => sum + item.targetInCents);
    final completed =
        goals.where((item) => item.savedInCents >= item.targetInCents).length;
    String money(int cents) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(cents);

    return ListView(
      padding: pagePadding(context),
      children: [
        PageHeading(
          eyebrow: 'Planos que cabem na vida real',
          title: 'Metas',
          description:
              'Transforme objetivos em valores claros, acompanhe o avanço e registre cada aporte.',
          actions: [
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nova meta'),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _GoalOverview(
          saved: money(saved),
          target: money(target),
          completed: completed,
          total: goals.length,
          progress: target == 0 ? 0 : (saved / target).clamp(0, 1),
        ),
        const SizedBox(height: 14),
        if (goals.isEmpty)
          Panel(
            title: 'Seus objetivos',
            subtitle: 'Comece por uma reserva, viagem ou compra importante',
            child: EmptyState(
              icon: Icons.flag_outlined,
              title: 'Nenhuma meta criada',
              description:
                  'Defina um valor, um prazo opcional e acompanhe seu progresso sem planilhas paralelas.',
              actionLabel: 'Criar primeira meta',
              onAction: onAdd,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 1040
                  ? (constraints.maxWidth - 28) / 3
                  : constraints.maxWidth >= 680
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: goals
                    .map((goal) => SizedBox(
                          width: width,
                          child: _GoalCard(
                            goal: goal,
                            hideValues: hideValues,
                            onContribute: () => onContribute(goal),
                            onDelete: () => onDelete(goal.id),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _GoalOverview extends StatelessWidget {
  const _GoalOverview({
    required this.saved,
    required this.target,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String saved;
  final String target;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Theme.of(context).dividerColor,
                      ),
                      Text('${(value * 100).round()}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patrimônio reservado',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 5),
                    Text(saved,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.6)),
                    const SizedBox(height: 5),
                    Text('de $target em objetivos',
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$completed de $total',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('concluídas',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.hideValues,
    required this.onContribute,
    required this.onDelete,
  });

  final FinancialGoal goal;
  final bool hideValues;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ratio =
        (goal.savedInCents / goal.targetInCents).clamp(0, 1).toDouble();
    final remaining = goal.targetInCents - goal.savedInCents;
    final done = remaining <= 0;
    final deadline = goal.deadline;
    final days = deadline?.difference(DateTime.now()).inDays;
    String money(int cents) =>
        hideValues ? '••••••' : FinancialRules.formatBrl(cents);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconTile(
                  icon: goalIcon(goal.iconKey),
                  color: done
                      ? const Color(0xFF258A5A)
                      : Theme.of(context).colorScheme.primary),
              const Spacer(),
              if (done) const StatusPill(label: 'Concluída'),
              PopupMenuButton<String>(
                tooltip: 'Ações da meta',
                onSelected: (value) {
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Excluir meta')),
                ],
              ),
            ]),
            const SizedBox(height: 18),
            Text(goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('${money(goal.savedInCents)} de ${money(goal.targetInCents)}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 9,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Text('${(ratio * 100).round()}% alcançado',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                deadline == null
                    ? 'Sem prazo'
                    : days! < 0
                        ? 'Prazo encerrado'
                        : '$days dias restantes',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: done ? null : onContribute,
                icon: Icon(done ? Icons.check_rounded : Icons.add_rounded,
                    size: 17),
                label: Text(done ? 'Objetivo alcançado' : 'Registrar aporte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData goalIcon(String key) => switch (key) {
      'home' => Icons.home_work_outlined,
      'travel' => Icons.flight_takeoff_rounded,
      'education' => Icons.school_outlined,
      'car' => Icons.directions_car_outlined,
      _ => Icons.savings_outlined,
    };
