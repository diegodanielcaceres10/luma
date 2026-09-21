import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

/// Protege las rutas que llevan un `:id` de una entidad (cuenta, categoría,
/// servicio…), como `/accounts/:id/edit`.
///
/// - Mientras la lista todavía se está cargando (ej. se entró directo por
///   URL), muestra un spinner en vez de asumir que la entidad no existe.
/// - Si la entidad existe, construye la pantalla con ella. Se resuelve una
///   sola vez: no reconstruye la pantalla cada vez que cambia el
///   view model.
/// - Si la lista ya cargó y ese `:id` no existe, muestra [notFoundMessage] y
///   reemplaza la ruta por [fallbackRoute] (con `replace`, así "atrás" no
///   vuelve a la URL inválida).
/// - Si la carga falló, no se puede afirmar que la entidad no exista: se
///   avisa del error de carga y se manda igual a [fallbackRoute].
class EntityRouteGuard<T> extends StatefulWidget {
  /// View model que notifica cuando cambia la lista (o su estado de carga).
  final Listenable listenable;

  /// `:id` de la ruta.
  final String? entityId;

  /// Busca la entidad por id en la lista ya cargada; `null` si no existe.
  final T? Function(String? id) find;

  final bool Function() isLoading;

  /// `true` si la lista se cargó con éxito al menos una vez.
  final bool Function() hasLoaded;

  /// Mensaje de error de la última carga fallida, si lo hubo.
  final String? Function() errorMessage;

  final String notFoundMessage;
  final String fallbackRoute;
  final Widget Function(BuildContext context, T entity) builder;

  const EntityRouteGuard({
    super.key,
    required this.listenable,
    required this.entityId,
    required this.find,
    required this.isLoading,
    required this.hasLoaded,
    required this.errorMessage,
    required this.notFoundMessage,
    required this.fallbackRoute,
    required this.builder,
  });

  @override
  State<EntityRouteGuard<T>> createState() => _EntityRouteGuardState<T>();
}

class _EntityRouteGuardState<T> extends State<EntityRouteGuard<T>> {
  T? _entity;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _entity = widget.find(widget.entityId);
    widget.listenable.addListener(_onChanged);
    // La navegación no se puede disparar en pleno initState/build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfMissing());
  }

  @override
  void didUpdateWidget(covariant EntityRouteGuard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onChanged);
      widget.listenable.addListener(_onChanged);
    }
    if (oldWidget.entityId != widget.entityId) {
      _entity = widget.find(widget.entityId);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _redirectIfMissing());
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted || _entity != null) return;
    final found = widget.find(widget.entityId);
    if (found != null) {
      setState(() => _entity = found);
      return;
    }
    _redirectIfMissing();
  }

  void _redirectIfMissing() {
    if (!mounted || _entity != null || _redirecting) return;

    // Hay una carga en curso: esperar a que termine antes de decidir.
    if (widget.isLoading()) return;

    final String message;
    if (widget.hasLoaded()) {
      message = widget.notFoundMessage;
    } else if (widget.errorMessage() != null) {
      message = widget.errorMessage()!;
    } else {
      // La carga todavía no arrancó: esperar.
      return;
    }

    _redirecting = true;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
    context.replace(widget.fallbackRoute);
  }

  @override
  Widget build(BuildContext context) {
    final entity = _entity;
    if (entity == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.authAccent),
      );
    }
    return widget.builder(context, entity);
  }
}
