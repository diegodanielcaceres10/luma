import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../home/presentation/view_models/app_lock_view_model.dart';
import '../../data/models/app_preferences.dart';
import '../view_models/preferences_view_model.dart';

const _currencyLabels = {
  'USD': 'USD — Dólar estadounidense',
  'EUR': 'EUR — Euro',
  'BRL': 'BRL — Real brasileño',
  'ARS': 'ARS — Peso argentino',
};

/// User preferences screen, opened from ProfileScreen. Each control saves
/// immediately; there is no "Guardar" button.
class PreferencesScreen extends StatefulWidget {
  final PreferencesViewModel viewModel;

  /// Tells whether the device supports biometric lock; the switch is shown
  /// disabled when it does not. On web, notifications and biometrics are
  /// always disabled.
  final AppLockViewModel appLockViewModel;

  /// Called when the back button is tapped.
  final VoidCallback onBack;

  const PreferencesScreen({
    super.key,
    required this.viewModel,
    required this.appLockViewModel,
    required this.onBack,
  });

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  void initState() {
    super.initState();
    // Preferences are loaded once at startup in app.dart, not per screen.
    widget.viewModel.addListener(_onViewModelChanged);

    // Re-checked on every open: the user may enable a device lock in system
    // settings while the app is running.
    widget.appLockViewModel.addListener(_onViewModelChanged);
    widget.appLockViewModel.refreshSupport();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    widget.appLockViewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final prefs = vm.preferences;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                title: 'Preferencias',
                size: ScreenHeaderSize.compact,
                onBack: widget.onBack,
              ),
              const SizedBox(height: 20),
              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.authAccent),
                  ),
                )
              else ...[
                const _SectionLabel('Moneda'),
                const SizedBox(height: 8),
                _PreferenceCard(
                  child: _Dropdown(
                    value: prefs.currencyCode,
                    items: kSupportedCurrencyCodes,
                    labelOf: (code) => _currencyLabels[code] ?? code,
                    onChanged: vm.setCurrencyCode,
                    icon: Icons.currency_exchange_rounded,
                    iconColor: AppColors.authAccent,
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Apariencia'),
                const SizedBox(height: 8),
                _PreferenceCard(
                  child: _SwitchRow(
                    label: 'Tema oscuro',
                    value: prefs.darkThemeEnabled,
                    onChanged: vm.setDarkThemeEnabled,
                    icon: Icons.dark_mode_outlined,
                    iconColor: const Color(0xFF8FA6C9),
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Notificaciones'),
                const SizedBox(height: 8),
                _PreferenceCard(
                  child: _SwitchRow(
                    label: 'Notificaciones habilitadas',
                    // Web cannot enable this, so never show a stored mobile value.
                    value: !kIsWeb && prefs.notificationsEnabled,
                    onChanged: kIsWeb ? null : vm.setNotificationsEnabled,
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFF4C9BE8),
                  ),
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Las notificaciones no están disponibles en la versión '
                      'web. Instalá la app en tu celular para activarlas.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.authTextFooter,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const _SectionLabel('Seguridad'),
                const SizedBox(height: 8),
                _PreferenceCard(
                  child: _SwitchRow(
                    label: 'Bloqueo con biometría',
                    value: !kIsWeb && prefs.biometricLockEnabled,
                    onChanged: kIsWeb
                        ? null
                        : (widget.appLockViewModel.isSupported
                            ? vm.setBiometricLockEnabled
                            : null),
                    icon: Icons.fingerprint_rounded,
                    iconColor: AppColors.authAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    kIsWeb
                        ? 'El bloqueo con biometría no está disponible en la '
                            'versión web. Instalá la app en tu celular para '
                            'activarlo.'
                        : widget.appLockViewModel.isSupported
                            ? 'Con esto activado, la app te va a pedir Face ID, '
                                'huella o el PIN del dispositivo al abrirla y al '
                                'volver de segundo plano después de un rato.'
                            : 'Para activar esto, primero configurá un bloqueo '
                                'de pantalla (PIN, patrón, huella o Face ID) en '
                                'los ajustes de tu dispositivo. Después volvé a '
                                'esta pantalla.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.authTextFooter,
                    ),
                  ),
                ),
              ],
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.authTextSecondary,
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final Widget child;

  const _PreferenceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: child,
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final String Function(String code) labelOf;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final Color? iconColor;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.authAccent;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: effectiveIconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.authBackgroundBottom,
              iconEnabledColor: AppColors.authTextSecondary,
              style: const TextStyle(
                color: AppColors.authTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              items: [
                for (final code in items)
                  DropdownMenuItem(value: code, child: Text(labelOf(code))),
              ],
              onChanged: (selected) {
                if (selected != null) onChanged(selected);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final Color? iconColor;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.authAccent;
    final isInteractive = onChanged != null;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(
                  alpha: isInteractive ? 0.14 : 0.08,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: effectiveIconColor.withValues(
                    alpha: isInteractive ? 0.3 : 0.15,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isInteractive
                    ? effectiveIconColor
                    : effectiveIconColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isInteractive
                    ? AppColors.authTextPrimary
                    : AppColors.authTextSecondary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.authAccent,
            activeTrackColor: AppColors.authAccent.withValues(alpha: 0.35),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
