import 'package:buy_control/app/theme/app_spacing.dart';
import 'package:buy_control/app/widgets/app_text.dart';
import 'package:buy_control/features/backup/presentation/controllers/backup_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Cobre a tela com um aviso de progresso enquanto o [BackupController]
/// está ocupado (baixando, comparando, enviando…), bloqueando toques.
class BackupBusyOverlay extends StatelessWidget {
  final Widget child;

  const BackupBusyOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BackupController>(
      builder: (c) => Stack(
        children: [
          child,
          if (c.isBusy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
                          const SizedBox(width: AppSpacing.lg),
                          Flexible(child: AppText(c.busyMessage!)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
