import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/accounts/data/models/account.dart';
import 'package:luma/features/accounts/presentation/view_models/account_view_model.dart';
import 'package:luma/features/accounts/presentation/view_models/monthly_balance_view_model.dart';
import 'package:luma/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:luma/features/categories/presentation/view_models/category_view_model.dart';
import 'package:luma/features/home/presentation/screens/dashboard_screen.dart';
import 'package:luma/features/home/presentation/widgets/dashboard/balance_card.dart';
import 'package:luma/features/home/presentation/widgets/dashboard/dashboard_status_views.dart';
import 'package:luma/features/home/presentation/widgets/dashboard/recent_movements.dart';
import 'package:luma/features/invoices/presentation/view_models/invoice_view_model.dart';
import 'package:luma/features/services/data/models/service.dart';
import 'package:luma/features/services/presentation/view_models/service_view_model.dart';
import 'package:luma/features/transactions/data/models/transaction_entry.dart';
import 'package:luma/features/transactions/presentation/view_models/transaction_view_model.dart';

class FakeAuthVM extends ChangeNotifier implements AuthViewModel {
  @override
  String get displayName => 'Diego Test';
  @override
  String get initials => 'DT';
  @override
  bool get isAuthenticated => true;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  String? get userId => 'u-1';
  @override
  String? get email => 'test@luma.com';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAccountVM extends ChangeNotifier implements AccountViewModel {
  List<Account> accountsList;
  FakeAccountVM({this.accountsList = const []});

  @override
  bool get hasLoaded => true;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  List<Account> get activeAccounts => accountsList;
  @override
  double get totalBalance => 500000;
  @override
  String get primaryCurrency => 'ARS';
  @override
  Future<void> loadAccounts() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTransactionVM extends ChangeNotifier implements TransactionViewModel {
  @override
  bool get isLoading => false;
  @override
  double get netResultWithUncontrolled => 12500;
  @override
  List<TransactionEntry> get recentMovements => const [];
  @override
  Future<void> loadCurrentMonth() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCategoryVM extends ChangeNotifier implements CategoryViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMonthlyBalanceVM extends ChangeNotifier
    implements MonthlyBalanceViewModel {
  @override
  bool get isLoading => false;
  @override
  bool get checked => true;
  @override
  List<Account> pendingAccounts(List<Account> accounts) => [];
  @override
  Future<void> checkCurrentMonth() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvoiceVM extends ChangeNotifier implements InvoiceViewModel {
  @override
  bool get isLoading => false;
  @override
  int get pendingCountForCurrentMonth => 0;
  @override
  double pendingAmountForCurrentMonth(dynamic services) => 0;
  @override
  Future<void> loadInvoices() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeServiceVM extends ChangeNotifier implements ServiceViewModel {
  @override
  bool get isLoading => false;
  @override
  List<Service> get activeServices => [];
  @override
  Future<void> loadServices() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget buildDashboard({required List<Account> accounts}) {
    return MaterialApp(
      home: Scaffold(
        body: DashboardScreen(
          authViewModel: FakeAuthVM(),
          accountViewModel: FakeAccountVM(accountsList: accounts),
          transactionViewModel: FakeTransactionVM(),
          categoryViewModel: FakeCategoryVM(),
          monthlyBalanceViewModel: FakeMonthlyBalanceVM(),
          invoiceViewModel: FakeInvoiceVM(),
          serviceViewModel: FakeServiceVM(),
          onOpenMonthlyBalance: (_) {},
          onOpenAddTransaction: (_) {},
          onGoToAccounts: () {},
          onManageAccounts: () {},
          onGoToInvoices: () {},
          onGoToTransfers: () {},
        ),
      ),
    );
  }

  testWidgets('renders single column on mobile screen (< 768px)',
      (tester) async {
    await setViewport(tester, const Size(400, 800));

    final testAccount = Account(
      id: 'acc-1',
      name: 'Banco Galicia',
      balance: 500000,
      isActive: true,
      balanceUpdatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildDashboard(accounts: [testAccount]));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardBalanceCard), findsOneWidget);
    expect(find.byType(DashboardRecentMovements), findsOneWidget);

    // In single column layout, it uses a ListView
    expect(find.byType(ListView), findsOneWidget);

    // Balance Card and Recent Movements are stacked vertically
    final cardCenter = tester.getCenter(find.byType(DashboardBalanceCard));
    final movementsCenter =
        tester.getCenter(find.byType(DashboardRecentMovements));
    expect(movementsCenter.dy, greaterThan(cardCenter.dy));
    // Their horizontal centers are aligned on mobile
    expect(cardCenter.dx, closeTo(movementsCenter.dx, 1.0));
  });

  testWidgets('renders two columns side-by-side on desktop screen (>= 1024px)',
      (tester) async {
    await setViewport(tester, const Size(1200, 800));

    final testAccount = Account(
      id: 'acc-1',
      name: 'Banco Galicia',
      balance: 500000,
      isActive: true,
      balanceUpdatedAt: DateTime.now(),
    );

    await tester.pumpWidget(buildDashboard(accounts: [testAccount]));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardBalanceCard), findsOneWidget);
    expect(find.byType(DashboardRecentMovements), findsOneWidget);

    // In desktop layout, Balance Card is in the left column and Movements in the right column
    final cardRect = tester.getRect(find.byType(DashboardBalanceCard));
    final movementsRect = tester.getRect(find.byType(DashboardRecentMovements));

    // Right column starts after left column
    expect(movementsRect.left, greaterThan(cardRect.right));
  });

  testWidgets(
      'renders centered card with max-width when no accounts on desktop',
      (tester) async {
    await setViewport(tester, const Size(1200, 800));

    await tester.pumpWidget(buildDashboard(accounts: []));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardNoAccountsCard), findsOneWidget);

    // The card is constrained to a reasonable max width (520 px)
    final cardSize = tester.getSize(find.byType(DashboardNoAccountsCard));
    expect(cardSize.width, lessThanOrEqualTo(520.0));
  });
}
