import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Tamaño del título de [ScreenHeader]. Hoy la app usa dos:
/// - [large]: el título grande de las pestañas de primer nivel y de las
///   pantallas con subtítulo ("Cuentas", "Actualizar saldo").
/// - [compact]: el título chico de listas y formularios ("Categorías",
///   "Nueva categoría").
enum ScreenHeaderSize { large, compact }

/// Encabezado compartido de las pantallas: botón de volver (opcional),
/// título, subtítulo (opcional) y un botón de acción a la derecha
/// (opcional).
///
/// La acción es un slot ([action]) para que cada pantalla ponga lo que
/// necesite; hay dos listas para usar en este mismo archivo:
/// - [HeaderAddButton]: el "+" de las listas, que lleva al formulario de
///   alta.
/// - [HeaderMenuButton]: los tres puntos, que despliegan más opciones.
///
/// No agrega padding exterior ni espacio inferior: quien lo usa decide
/// el margen de la pantalla y la separación con el contenido que sigue
/// (igual que las filas de título que reemplaza).
///
/// Ejemplo (lista con alta):
/// ```dart
/// ScreenHeader(
///   title: 'Cuentas',
///   subtitle: 'Gestiona tus cuentas.',
///   onBack: () => context.pop(),
///   action: HeaderAddButton(onPressed: () => context.push('/accounts/new')),
/// )
/// ```
class ScreenHeader extends StatelessWidget {
  final String title;

  /// Texto secundario debajo del título. `null` no dibuja nada.
  final String? subtitle;

  /// Acción del botón de volver. `null` oculta el botón — para las
  /// pestañas de primer nivel, donde no hay a dónde volver.
  final VoidCallback? onBack;

  /// `false` deja el botón de volver visible pero deshabilitado, para
  /// cuando la pantalla está ocupada (ej. guardando) y volver no debe
  /// interrumpirla. Sin efecto si [onBack] es `null`.
  final bool backEnabled;

  /// Widget a la derecha del título — ver [HeaderAddButton] y
  /// [HeaderMenuButton]. `null` no dibuja nada.
  final Widget? action;

  final ScreenHeaderSize size;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.backEnabled = true,
    this.action,
    this.size = ScreenHeaderSize.large,
  });

  TextStyle get _titleStyle => switch (size) {
        ScreenHeaderSize.large => AppTextStyles.authTitle,
        ScreenHeaderSize.compact => const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.authTextPrimary,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final action = this.action;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null) ...[
              _BackButton(onPressed: backEnabled ? onBack : null),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 8),
              action,
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.authSubtitle),
        ],
      ],
    );
  }
}

/// Botón de volver de [ScreenHeader]. Mismo look que el que se repetía
/// en cada pantalla (flecha en un `InkWell` redondo), con tooltip.
class _BackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Volver',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.arrow_back_rounded,
            color: onPressed == null
                ? AppColors.authTextPrimary.withValues(alpha: 0.4)
                : AppColors.authTextPrimary,
          ),
        ),
      ),
    );
  }
}

/// Acción "+" para [ScreenHeader.action]: en las listas, lleva al
/// formulario de creación.
class HeaderAddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  /// Qué se crea, para lectores de pantalla y hover ("Nueva cuenta").
  final String tooltip;

  const HeaderAddButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Agregar',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: const Icon(Icons.add_rounded),
      color: AppColors.authTextPrimary,
    );
  }
}

/// Una opción de [HeaderMenuButton].
class HeaderMenuItem<T> {
  /// Lo que recibe [HeaderMenuButton.onSelected] al elegirla.
  final T value;
  final String label;
  final IconData? icon;

  /// Pinta la opción con el color de gasto, para acciones que borran o
  /// no se pueden deshacer.
  final bool destructive;

  const HeaderMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
  });
}

/// Acción de tres puntos para [ScreenHeader.action]: despliega un menú
/// con más opciones ([items]); al elegir una se llama a [onSelected] con
/// su [HeaderMenuItem.value].
class HeaderMenuButton<T> extends StatelessWidget {
  final List<HeaderMenuItem<T>> items;
  final ValueChanged<T> onSelected;

  /// `false` deshabilita el botón (ej. mientras la pantalla guarda).
  final bool enabled;

  final String tooltip;

  const HeaderMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    this.enabled = true,
    this.tooltip = 'Más opciones',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      enabled: enabled,
      tooltip: tooltip,
      onSelected: onSelected,
      color: AppColors.authBackgroundBottom,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.authCardBorder),
      ),
      icon: Icon(
        Icons.more_vert_rounded,
        color: enabled
            ? AppColors.authTextPrimary
            : AppColors.authTextPrimary.withValues(alpha: 0.4),
      ),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: _MenuItemContent(item: item),
          ),
      ],
    );
  }
}

class _MenuItemContent extends StatelessWidget {
  final HeaderMenuItem<dynamic> item;

  const _MenuItemContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final color =
        item.destructive ? AppColors.authExpense : AppColors.authTextPrimary;

    return Row(
      children: [
        if (item.icon != null) ...[
          Icon(item.icon, size: 20, color: color),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Text(
            item.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
