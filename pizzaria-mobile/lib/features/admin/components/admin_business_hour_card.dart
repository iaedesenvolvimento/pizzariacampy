import 'package:flutter/material.dart';

import '../core/admin_business_hour_presentation.dart';
import '../core/admin_radius.dart';
import '../core/admin_spacing.dart';
import '../core/admin_status.dart';

class AdminBusinessHourCard extends StatelessWidget {
  const AdminBusinessHourCard({
    required this.dayLabel,
    required this.isClosed,
    required this.opening,
    required this.closing,
    required this.onToggle,
    required this.onPickOpening,
    required this.onPickClosing,
    required this.onSave,
    this.isToday = false,
    this.isSaving = false,
    super.key,
  });

  final String dayLabel;
  final bool isClosed;
  final TimeOfDay opening;
  final TimeOfDay closing;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickOpening;
  final VoidCallback onPickClosing;
  final VoidCallback onSave;
  final bool isToday;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AdminRadius.medium),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(dayLabel, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: AdminSpacing.sm),
                            const Chip(label: Text('Hoje')),
                          ],
                        ],
                      ),
                      const SizedBox(height: AdminSpacing.sm),
                      Text(
                        isClosed
                            ? 'Sem pedidos neste dia'
                            : AdminBusinessHourPresentation.formatRange(opening, closing),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !isClosed,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            AdminStatusBadge(status: isClosed ? 'CLOSED' : 'READY'),
            if (!isClosed) ...[
              const SizedBox(height: AdminSpacing.md),
              Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPickOpening,
                    icon: const Icon(Icons.login_outlined),
                    label: Text('Abertura ${AdminBusinessHourPresentation.formatTime(opening)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPickClosing,
                    icon: const Icon(Icons.logout_outlined),
                    label: Text('Fechamento ${AdminBusinessHourPresentation.formatTime(closing)}'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AdminSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: Text(isSaving ? 'Salvando...' : 'Salvar alterações'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
