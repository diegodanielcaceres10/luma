import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/account_visuals.dart';
import '../../../../core/utils/category_visuals.dart' show colorFromHex;
import '../../../accounts/data/models/account.dart';
import '../view_models/monthly_balance_view_model.dart';

/// Contenido de la pestaña "Saldos iniciales". No tiene Scaffold propio —
/// vive dentro del Scaffold del HomeShell. Se llega acá desde el aviso en
/// el card de balance del Dashboard, para cargar a mano el saldo inicial
/// del mes en curso de cada cuenta que todavía no lo tiene.
class MonthlyBalanceTab extends StatefulWidget {
  final String userId;
  final List<Account> pendingAccounts;
  final MonthlyBalanceViewModel monthlyBalanceViewModel;
  final VoidCallback onDone;

  const MonthlyBalanceTab({
    super.key,
    required this.userId,
    required this.pendingAccounts,
    required this.monthlyBalanceViewModel,
    required this.onDone,
  });

  @override
  State<MonthlyBalanceTab> createState() => _MonthlyBalanceTabState();
}

class _MonthlyBalanceTabState extends State<MonthlyBalanceTab> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;

  static const _monthNames = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final account in widget.pendingAccounts)
        account.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = widget.monthlyBalanceViewModel;
    var allOk = true;

    for (final account in widget.pendingAccounts) {
      final value = double.parse(_controllers[account.id]!.text.trim());
      final ok = await vm.saveOpeningBalance(
        userId: widget.userId,
        accountId: account.id,
        openingBalance: value,
      );
      if (!ok) allOk = false;
    }

    if (!mounted) return;

    if (allOk) {
      widget.onDone();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? 'No se pudo guardar todo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.monthlyBalanceViewModel;
    final now = DateTime.now();
    final monthLabel = _monthNames[now.month - 1];

    return SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: widget.onDone,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.arrow_back_rounded,
                            color: AppColors.authTextPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Saldos iniciales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.authTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Completá el saldo con el que arrancó cada cuenta '
                  'en $monthLabel de ${now.year}.',
                  style: AppTextStyles.authSubtitle,
                ),
                const SizedBox(height: 20),
                for (final account in widget.pendingAccounts) ...[
                  _AccountBalanceField(
                    account: account,
                    controller: _controllers[account.id]!,
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.authAccent,
                      foregroundColor: AppColors.authBackgroundBottom,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: vm.isSubmitting ? null : _submit,
                    child: vm.isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.authBackgroundBottom,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountBalanceField extends StatelessWidget {
  final Account account;
  final TextEditingController controller;

  const _AccountBalanceField({
    required this.account,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(account.color, fallback: AppColors.authAccent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.85),
                child: Icon(accountIconFromName(account.icon),
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  account.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.authTextPrimary,
                  ),
                ),
              ),
              Text(
                account.currency,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.authTextFooter,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.authTextPrimary),
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.authBackgroundBottom,
              hintText: '0.00',
              hintStyle: TextStyle(color: AppColors.authTextFooter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.authCardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.authCardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: AppColors.authAccent),
              ),
            ),
            validator: (value) {
              final parsed = double.tryParse((value ?? '').trim());
              return parsed == null ? 'Ingresa un monto válido' : null;
            },
          ),
        ],
      ),
    );
  }
}
