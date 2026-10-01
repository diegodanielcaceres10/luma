import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../data/models/account.dart';
import '../view_models/monthly_balance_view_model.dart';

const _kWarningColor = Color(0xFFFBBF24);

/// Label for an account option in a dropdown. Accounts without an opening
/// balance for the current month can't be picked, so the reason is shown.
Widget accountOptionLabel(String text, {required bool isPending}) {
  if (!isPending) return Text(text);

  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.authTextFooter),
      ),
      const Text(
        'Falta cargar el saldo inicial',
        style: TextStyle(
          color: _kWarningColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

/// Shows [child] only once [account] has its opening balance for the current
/// month. Until then it blocks the screen: moving the balance first would
/// distort the difference computed when the opening balance is finally
/// entered.
class OpeningBalanceGate extends StatefulWidget {
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final Account account;
  final VoidCallback onCompleteBalance;
  final VoidCallback onBack;
  final Widget child;

  const OpeningBalanceGate({
    super.key,
    required this.monthlyBalanceViewModel,
    required this.account,
    required this.onCompleteBalance,
    required this.onBack,
    required this.child,
  });

  @override
  State<OpeningBalanceGate> createState() => _OpeningBalanceGateState();
}

class _OpeningBalanceGateState extends State<OpeningBalanceGate> {
  @override
  void initState() {
    super.initState();
    final viewModel = widget.monthlyBalanceViewModel;
    if (!viewModel.checked && !viewModel.isLoading) {
      // Deferred: notifying listeners during initState would throw.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => viewModel.checkCurrentMonth());
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.monthlyBalanceViewModel;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.checked &&
            !viewModel.isAccountPending(widget.account.id)) {
          return widget.child;
        }

        if (!viewModel.checked) {
          return viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.authAccent),
                )
              : _BlockedView(
                  title: 'No pudimos verificar el saldo inicial',
                  message: 'Revisá tu conexión e intentá de nuevo.',
                  actionLabel: 'Reintentar',
                  onAction: viewModel.checkCurrentMonth,
                  onBack: widget.onBack,
                );
        }

        return _BlockedView(
          title: 'Falta cargar el saldo inicial',
          message: 'Antes de registrar movimientos o actualizar el saldo de '
              '${widget.account.name}, cargá su saldo inicial de este mes.',
          actionLabel: 'Cargar saldo inicial',
          onAction: widget.onCompleteBalance,
          onBack: widget.onBack,
        );
      },
    );
  }
}

class _BlockedView extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onBack;

  const _BlockedView({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          ScreenHeader(
            title: title,
            size: ScreenHeaderSize.compact,
            onBack: onBack,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: _kWarningColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.authTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.authAccent,
              foregroundColor: AppColors.authBackgroundBottom,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
