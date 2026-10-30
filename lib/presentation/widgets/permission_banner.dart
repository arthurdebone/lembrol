import 'package:flutter/material.dart';
import '../../platform/permissions/permission_manager.dart';

class PermissionBanner extends StatelessWidget {
  final SystemDiagnostics diagnostics;
  final VoidCallback onRequestPermissions;

  const PermissionBanner({
    super.key,
    required this.diagnostics,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isHealthy) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atenção às permissões de notificação',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                ...diagnostics.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $w',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: onRequestPermissions,
            child: const Text('Conceder', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
