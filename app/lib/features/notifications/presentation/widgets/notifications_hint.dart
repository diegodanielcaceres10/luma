import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/view_models/preferences_view_model.dart';

/// Short note under a screen header that tells whether notifications are on
/// and links to Preferencias. Rebuilds when the preference changes.
class NotificationsHint extends StatelessWidget {
  final PreferencesViewModel preferencesViewModel;
  final VoidCallback onOpenPreferences;

  const NotificationsHint({
    super.key,
    required this.preferencesViewModel,
    required this.onOpenPreferences,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferencesViewModel,
      builder: (context, _) => NotificationsHintText(
        enabled: preferencesViewModel.preferences.notificationsEnabled,
        // Notifications are not available on web.
        supported: !kIsWeb,
        onOpenPreferences: onOpenPreferences,
      ),
    );
  }
}

/// Presentational part of [NotificationsHint], kept separate so it can be
/// tested without a [PreferencesViewModel].
class NotificationsHintText extends StatefulWidget {
  final bool enabled;
  final bool supported;
  final VoidCallback onOpenPreferences;

  const NotificationsHintText({
    super.key,
    required this.enabled,
    required this.supported,
    required this.onOpenPreferences,
  });

  @override
  State<NotificationsHintText> createState() => _NotificationsHintTextState();
}

class _NotificationsHintTextState extends State<NotificationsHintText> {
  late final TapGestureRecognizer _linkTap;

  @override
  void initState() {
    super.initState();
    _linkTap = TapGestureRecognizer()
      ..onTap = () => widget.onOpenPreferences();
  }

  @override
  void dispose() {
    _linkTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 12,
      color: AppColors.authTextFooter,
    );
    const linkStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.authAccent,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.authAccent,
    );

    final TextSpan span;
    if (!widget.supported) {
      span = const TextSpan(
        text: 'Las notificaciones no están disponibles en la versión web. '
            'Instalá la app en tu celular para activarlas.',
      );
    } else if (widget.enabled) {
      span = TextSpan(
        children: [
          const TextSpan(
            text: 'Las notificaciones están activadas. Podés cambiarlas en ',
          ),
          TextSpan(
            text: 'Preferencias',
            style: linkStyle,
            recognizer: _linkTap,
          ),
          const TextSpan(text: '.'),
        ],
      );
    } else {
      span = TextSpan(
        children: [
          const TextSpan(
            text: 'Activá las notificaciones para que te avisemos de '
                'facturas que vencen, facturas sin cargar y cuentas sin '
                'actualizar. ',
          ),
          TextSpan(
            text: 'Ir a Preferencias',
            style: linkStyle,
            recognizer: _linkTap,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(span, style: baseStyle),
    );
  }
}
