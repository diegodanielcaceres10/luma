import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../app_lock/presentation/view_models/app_lock_view_model.dart';
import '../../data/models/app_preferences.dart';
import '../view_models/preferences_view_model.dart';

const _currencyLabels = {
  'USD': 'USD — Dólar estadounidense',
  'EUR': 'EUR — Euro',
  'BRL': 'BRL — Real brasileño',
  'ARS': 'ARS — Peso argentino',
};

/// Pantalla de preferencias del usuario. Se abre como ruta propia (push)
/// desde ProfileScreen — ver router.dart ('/profile/preferences').
///
/// Cada control guarda su valor al toque (no hay botón "Guardar"). De
/// todas las preferencias, solo el bloqueo con biometría ya cambia el
/// comportamiento real de la app (ver AppLockViewModel) — moneda, tema y
/// notificaciones por ahora solo se guardan.
class PreferencesScreen extends StatefulWidget {
  final PreferencesViewModel viewModel;

  /// Se usa para saber si el dispositivo soporta biometría/bloqueo de
  /// pantalla (`appLockViewModel.isSupported`) y para refrescar ese
  /// chequeo al entrar a esta pantalla — ver `initState` y
  /// `AppLockViewModel.refreshSupport`. Si no está soportado, el switch de
  /// biometría se muestra pero deshabilitado. En web (`kIsWeb`), tanto
  /// notificaciones como biometría se muestran siempre deshabilitadas
  /// (no hay soporte nativo), con una leyenda propia que lo explica.
  final AppLockViewModel appLockViewModel;

  /// Se llama al tocar "atrás". Se recibe por parámetro (en vez de usar
  /// `context.goBack()` acá adentro) para seguir el mismo patrón de
  /// callback que el resto de las pantallas con formulario.
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
    // No se llama a loadPreferences() acá: igual que el resto de los
    // ViewModels (ver CategoryViewModel/AccountViewModel), la carga
    // inicial la dispara una sola vez app.dart al arrancar la app, no cada
    // pantalla que los usa.
    widget.viewModel.addListener(_onViewModelChanged);

    // Este sí se re-chequea cada vez que se abre la pantalla: a diferencia
    // de las preferencias, "¿el dispositivo tiene bloqueo de pantalla
    // configurado?" puede cambiar en cualquier momento (el usuario puede
    // ir a Ajustes del sistema y configurarlo sin cerrar la app) — ver
    // AppLockViewModel.refreshSupport.
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            children: [
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded,
                      color: AppColors.authTextPrimary),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Preferencias',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ),
            ],
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
              ),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Notificaciones'),
            const SizedBox(height: 8),
            _PreferenceCard(
              child: _SwitchRow(
                label: 'Notificaciones habilitadas',
                value: prefs.notificationsEnabled,
                onChanged: kIsWeb ? null : vm.setNotificationsEnabled,
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
                    fontSize: 12,
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
                value: prefs.biometricLockEnabled,
                onChanged: kIsWeb
                    ? null
                    : (widget.appLockViewModel.isSupported
                        ? vm.setBiometricLockEnabled
                        : null),
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
                  fontSize: 12,
                  color: AppColors.authTextFooter,
                ),
              ),
            ),
          ],
          if (vm.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.authTextSecondary,
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final Widget child;

  const _PreferenceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final String Function(String code) labelOf;
  final ValueChanged<String> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.authBackgroundBottom,
        iconEnabledColor: AppColors.authTextSecondary,
        style: const TextStyle(
          color: AppColors.authTextPrimary,
          fontSize: 15,
        ),
        items: [
          for (final code in items)
            DropdownMenuItem(value: code, child: Text(labelOf(code))),
        ],
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.authTextPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.authAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
