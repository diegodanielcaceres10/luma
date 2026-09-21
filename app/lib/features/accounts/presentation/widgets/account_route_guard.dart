import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../view_models/account_view_model.dart';

/// Protege las rutas que llevan un `:id` de cuenta (`/accounts/:id/edit` y
/// `/accounts/:id/balance`).
///
/// - Mientras la lista de cuentas todavía se está cargando (ej. se entró
///   directo por URL), muestra un spinner en vez de asumir que la cuenta
///   no existe.
/// - Si la cuenta existe, construye la pantalla con ella. Se resuelve una
///   sola vez: no reconstruye la pantalla cada vez que cambia el
///   [AccountViewModel].
/// - Si las cuentas ya cargaron y ese `:id` no existe, muestra un aviso y
///   reemplaza la ruta por `/accounts` (con `replace`, así "atrás" no vuelve
///   a la URL inválida).
/// - Si la carga de cuentas falló, no se puede afirmar que la cuenta no
///   exista: se avisa del error de carga y se manda igual a `/accounts`.
class AccountRouteGuard extends StatefulWidget {
  final AccountViewModel accountViewModel;
  final String? accountId;
  final Widget Function(BuildContext context, Account account) builder;

  const AccountRouteGuard({
    super.key,
    required this.accountViewModel,
    required this.accountId,
    required this.builder,
  });

  @override
  State<AccountRouteGuard> createState() => _AccountRouteGuardState();
}

class _AccountRouteGuardState extends State<AccountRouteGuard> {
  Account? _account;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _account = _findAccount();
    widget.accountViewModel.addListener(_onViewModelChanged);
    // La navegación no se puede disparar en pleno initState/build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfMissing());
  }

  @override
  void didUpdateWidget(covariant AccountRouteGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountViewModel != widget.accountViewModel) {
      oldWidget.accountViewModel.removeListener(_onViewModelChanged);
      widget.accountViewModel.addListener(_onViewModelChanged);
    }
    if (oldWidget.accountId != widget.accountId) {
      _account = _findAccount();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _redirectIfMissing());
    }
  }

  @override
  void dispose() {
    widget.accountViewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  Account? _findAccount() {
    for (final account in widget.accountViewModel.accounts) {
      if (account.id == widget.accountId) return account;
    }
    return null;
  }

  void _onViewModelChanged() {
    if (!mounted || _account != null) return;
    final found = _findAccount();
    if (found != null) {
      setState(() => _account = found);
      return;
    }
    _redirectIfMissing();
  }

  void _redirectIfMissing() {
    if (!mounted || _account != null || _redirecting) return;

    final vm = widget.accountViewModel;
    // Hay una carga en curso: esperar a que termine antes de decidir.
    if (vm.isLoading) return;

    final String message;
    if (vm.hasLoaded) {
      message = 'No encontramos esa cuenta.';
    } else if (vm.errorMessage != null) {
      message = vm.errorMessage!;
    } else {
      // La carga todavía no arrancó: esperar.
      return;
    }

    _redirecting = true;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
    context.replace('/accounts');
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    if (account == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.authAccent),
      );
    }
    return widget.builder(context, account);
  }
}
