import 'package:flutter/material.dart';

import '../../../categories/presentation/view_models/category_view_model.dart';
import '../../../invoices/presentation/view_models/invoice_view_model.dart';
import '../../../services/presentation/view_models/service_view_model.dart';
import '../view_models/month_comparison.dart';
import '../view_models/month_comparison_view_model.dart';
import '../widgets/month_comparison_view.dart';

/// Container of the month comparison: picks the months, asks the view model
/// to load them and joins its result with the categories, services and
/// invoices the app already keeps. All drawing is left to
/// [MonthComparisonView].
class MonthComparisonScreen extends StatefulWidget {
  final MonthComparisonViewModel comparisonViewModel;
  final CategoryViewModel categoryViewModel;
  final ServiceViewModel serviceViewModel;
  final InvoiceViewModel invoiceViewModel;

  /// Months to start with; the view model keeps the ones picked afterwards.
  final DateTime initialBefore;
  final DateTime initialAfter;
  final String currency;
  final VoidCallback onDone;

  const MonthComparisonScreen({
    super.key,
    required this.comparisonViewModel,
    required this.categoryViewModel,
    required this.serviceViewModel,
    required this.invoiceViewModel,
    required this.initialBefore,
    required this.initialAfter,
    required this.currency,
    required this.onDone,
  });

  @override
  State<MonthComparisonScreen> createState() => _MonthComparisonScreenState();
}

class _MonthComparisonScreenState extends State<MonthComparisonScreen> {
  late final Listenable _listenable = Listenable.merge([
    widget.comparisonViewModel,
    widget.categoryViewModel,
    widget.serviceViewModel,
    widget.invoiceViewModel,
  ]);

  @override
  void initState() {
    super.initState();
    // Always reloaded: the view model keeps the last result between visits.
    widget.comparisonViewModel.load(widget.initialBefore, widget.initialAfter);
  }

  bool get _dependenciesReady =>
      widget.categoryViewModel.hasLoaded &&
      widget.serviceViewModel.hasLoaded &&
      widget.invoiceViewModel.hasLoaded;

  bool get _dependenciesLoading =>
      widget.categoryViewModel.isLoading ||
      widget.serviceViewModel.isLoading ||
      widget.invoiceViewModel.isLoading;

  /// Retries what failed: the months, and any list that never loaded.
  void _retry() {
    final categories = widget.categoryViewModel;
    final services = widget.serviceViewModel;
    final invoices = widget.invoiceViewModel;

    if (!categories.hasLoaded && !categories.isLoading) {
      categories.loadCategories();
    }
    if (!services.hasLoaded && !services.isLoading) {
      services.loadServices();
    }
    if (!invoices.hasLoaded && !invoices.isLoading) {
      invoices.loadInvoices();
    }
    if (widget.comparisonViewModel.errorMessage != null) {
      widget.comparisonViewModel.retry();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.comparisonViewModel;

    return ListenableBuilder(
      listenable: _listenable,
      builder: (context, _) {
        final before = vm.beforeMonth ?? widget.initialBefore;
        final after = vm.afterMonth ?? widget.initialAfter;
        final beforeSnapshot = vm.before;
        final afterSnapshot = vm.after;

        final status = resolveComparisonStatus(
          sameMonth: vm.hasSameMonth,
          isLoading: vm.isLoading,
          errorMessage: vm.errorMessage,
          hasData: beforeSnapshot != null && afterSnapshot != null,
          dependenciesReady: _dependenciesReady,
          dependenciesLoading: _dependenciesLoading,
        );

        final comparison = status == ComparisonViewStatus.ready &&
                beforeSnapshot != null &&
                afterSnapshot != null
            ? MonthComparison.compute(
                before: beforeSnapshot,
                after: afterSnapshot,
                categories: widget.categoryViewModel.categories,
                services: widget.serviceViewModel.services,
                invoices: widget.invoiceViewModel.invoices,
              )
            : null;

        return MonthComparisonView(
          beforeMonth: before,
          afterMonth: after,
          status: status,
          comparison: comparison,
          currency: widget.currency,
          onBeforeChanged: (month) => vm.load(month, after),
          onAfterChanged: (month) => vm.load(before, month),
          onSwap: vm.swap,
          onRetry: _retry,
          onBack: widget.onDone,
        );
      },
    );
  }
}
