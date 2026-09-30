import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

/// Guards routes with an entity `:id` (e.g. `/accounts/:id/edit`).
///
/// - While the list is loading, shows a spinner instead of assuming the
///   entity doesn't exist.
/// - If the entity exists, builds the screen once (not on every view model
///   change).
/// - If the list loaded and the id is missing, shows [notFoundMessage] and
///   `replace`s the route with [fallbackRoute] so back doesn't return to
///   the invalid URL.
/// - If loading failed, reports the load error and also goes to
///   [fallbackRoute].
class EntityRouteGuard<T> extends StatefulWidget {
  final Listenable listenable;

  final String? entityId;

  final T? Function(String? id) find;

  final bool Function() isLoading;

  final bool Function() hasLoaded;

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
    // Navigation can't be triggered during initState/build.
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

    if (widget.isLoading()) return;

    final String message;
    if (widget.hasLoaded()) {
      message = widget.notFoundMessage;
    } else if (widget.errorMessage() != null) {
      message = widget.errorMessage()!;
    } else {
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
