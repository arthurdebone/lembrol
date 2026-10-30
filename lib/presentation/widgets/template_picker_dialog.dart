import 'package:flutter/material.dart';
import '../../core/constants/app_templates.dart';

class TemplatePickerDialog extends StatelessWidget {
  const TemplatePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Modelos de Lembretes'),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha um modelo inicial para personalizar antes de salvar:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...AppTemplates.initialTemplates.map((template) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      _getTemplateIcon(template.category),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    template.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${template.description}\nIntervalo: ${template.intervalMinutes} min • Categoria: ${template.category}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.of(context).pop(template);
                  },
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  IconData _getTemplateIcon(String category) {
    switch (category) {
      case 'Hidratação':
        return Icons.water_drop_rounded;
      case 'Visão e Descanso':
        return Icons.visibility_rounded;
      case 'Postura e Ergonomia':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.alarm_rounded;
    }
  }
}
