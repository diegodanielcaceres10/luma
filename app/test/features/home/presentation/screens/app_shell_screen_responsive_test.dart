import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:luma/features/home/presentation/screens/app_shell_screen.dart';

void main() {
  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AppShellScreen(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  const Scaffold(body: Text('Dashboard Page')),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets(
      'renders mobile layout with BottomNav and header on narrow screens',
      (tester) async {
    await setViewport(tester, const Size(400, 800));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // On mobile, the bottom nav icons/labels are rendered
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    // Hamburger menu icon in LumaHeader exists on mobile
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    // Sidebar-only destinations (Cuentas, Categorías) are NOT in the body (they are in drawer)
    expect(find.text('Cuentas'), findsNothing);
    expect(find.text('Categorías'), findsNothing);
  });

  testWidgets('renders compact sidebar on tablet screens (600-1023px)',
      (tester) async {
    await setViewport(tester, const Size(800, 800));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // No hamburger menu in header
    expect(find.byIcon(Icons.menu_rounded), findsNothing);

    // Sidebar is rendered with compact width (72 px)
    final sidebarFinder = find.byType(Container).first;
    expect(tester.getSize(sidebarFinder).width, 72.0);

    // Destined icons are in the compact sidebar
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.sell_outlined), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byIcon(Icons.request_page_outlined), findsOneWidget);
    expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    // Labels are inside tooltips, not visible text
    expect(find.text('Cuentas'), findsNothing);
  });

  testWidgets('renders full persistent sidebar on desktop screens (>= 1024px)',
      (tester) async {
    await setViewport(tester, const Size(1200, 800));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // No hamburger menu in header
    expect(find.byIcon(Icons.menu_rounded), findsNothing);

    // Full sidebar width is 240 px
    final sidebarFinder = find.byType(Container).first;
    expect(tester.getSize(sidebarFinder).width, 240.0);

    // All navigation item text labels are visible directly in sidebar
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Cuentas'), findsOneWidget);
    expect(find.text('Categorías'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Facturas'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets(
      'renders wide persistent sidebar on wide desktop screens (>= 1440px) and centers content at max 1200px',
      (tester) async {
    await setViewport(tester, const Size(1600, 900));
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Wide sidebar width is 260 px
    final sidebarFinder = find.byType(Container).first;
    expect(tester.getSize(sidebarFinder).width, 260.0);

    // Content page is capped at 1200 px and centered in the remaining 1340 px
    // (1600 - 260 = 1340 available; 1340 - 1200 = 140; 140 / 2 = 70 px left/right margin)
    final pageFinder = find.byType(Scaffold).last;
    final pageRect = tester.getRect(pageFinder);
    expect(pageRect.width, 1200.0);
    expect(pageRect.left, 260.0 + 70.0);
  });
}
