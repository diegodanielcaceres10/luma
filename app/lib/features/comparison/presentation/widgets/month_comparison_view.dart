import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/layout/screen_header.dart';
import '../../../transactions/presentation/view_models/transactions_filters.dart';
import '../view_models/month_comparison.dart';
import '../view_models/month_comparison_view_model.dart';
import 'comparison_card.dart';
import 'comparison_month_selector.dart';
import 'comparison_notice.dart';

enum ComparisonViewStatus { loading, error, sameMonth, ready }

/// Decides what the comparison screen shows. Categories, services and
/// invoices are loaded by their own view models, so the comparison is only
/// ready once they are in too.
///
/// Order matters: the same month needs no data, loading wins over any error,
/// and dependencies that are not loaded and not loading have failed.
ComparisonViewStatus resolveComparisonStatus({
  required bool sameMonth,
  required bool isLoading,
  required String? errorMessage,
  required bool hasData,
  required bool dependenciesReady,
  required bool dependenciesLoading,
}) {
  if (sameMonth) return ComparisonViewStatus.sameMonth;
  if (isLoading) return ComparisonViewStatus.loading;
  if (!dependenciesReady) {
    return dependenciesLoading
        ? ComparisonViewStatus.loading
        : ComparisonViewStatus.error;
  }
  if (errorMessage != null) return ComparisonViewStatus.error;
  if (hasData) return ComparisonViewStatus.ready;
  return ComparisonViewStatus.loading;
}

/// The comparison screen without any state of its own: it draws whatever
/// [status] and [comparison] say.
class MonthComparisonView extends StatelessWidget {
  final DateTime beforeMonth;
  final DateTime afterMonth;
  final ComparisonViewStatus status;
  final MonthComparison? comparison;
  final String currency;
  final ValueChanged<DateTime> onBeforeChanged;
  final ValueChanged<DateTime> onAfterChanged;
  final VoidCallback onSwap;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const MonthComparisonView({
    super.key,
    required this.beforeMonth,
    required this.afterMonth,
    required this.status,
    required this.comparison,
    required this.currency,
    required this.onBeforeChanged,
    required this.onAfterChanged,
    required this.onSwap,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final hasCurrentMonth = TransactionsFilters.isCurrentMonth(beforeMonth) ||
        TransactionsFilters.isCurrentMonth(afterMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: 'Comparar meses',
                  subtitle:
                      'Compara ingresos, gastos, categorías y servicios entre dos meses.',
                  onBack: onBack,
                ),
                const SizedBox(height: 20),
                ComparisonMonthSelector(
                  before: beforeMonth,
                  after: afterMonth,
                  onBeforeChanged: onBeforeChanged,
                  onAfterChanged: onAfterChanged,
                  onSwap: onSwap,
                ),
                if (hasCurrentMonth) ...[
                  const SizedBox(height: 12),
                  const ComparisonNotice(
                    message:
                        'El mes en curso todavía no terminó: sus valores son parciales.',
                  ),
                ],
                const SizedBox(height: 20),
                ..._body(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _body() {
    switch (status) {
      case ComparisonViewStatus.loading:
        return const [_LoadingBlock()];
      case ComparisonViewStatus.error:
        return [_ErrorBlock(onRetry: onRetry)];
      case ComparisonViewStatus.sameMonth:
        return const [ComparisonNotice(message: 'Elegí dos meses distintos')];
      case ComparisonViewStatus.ready:
        final result = comparison;
        if (result == null || result.isEmpty) {
          return const [
            ComparisonNotice(message: 'No hay datos en esos meses.'),
          ];
        }
        return [
          ComparisonCard(
            title: 'Resumen',
            beforeMonth: beforeMonth,
            afterMonth: afterMonth,
            rows: result.summary,
            currency: currency,
          ),
          if (result.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            ComparisonCard(
              title: 'Categorías',
              beforeMonth: beforeMonth,
              afterMonth: afterMonth,
              rows: result.categories,
              currency: currency,
            ),
          ],
          if (result.services.isNotEmpty) ...[
            const SizedBox(height: 16),
            ComparisonCard(
              title: 'Servicios',
              beforeMonth: beforeMonth,
              afterMonth: afterMonth,
              rows: result.services,
              currency: currency,
            ),
          ],
        ];
    }
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.authAccent,
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorBlock({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.authCardFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.authCardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.authExpense.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.authExpense.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.authExpense,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            MonthComparisonViewModel.loadErrorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.authTextSecondary,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.authAccent,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
