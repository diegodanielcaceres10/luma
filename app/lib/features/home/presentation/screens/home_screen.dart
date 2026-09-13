import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../accounts/presentation/view_models/account_view_model.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../models/home_mock_data.dart';

class HomeScreen extends StatelessWidget {
  final AuthViewModel authViewModel;
  final AccountViewModel accountViewModel;

  const HomeScreen({
    super.key,
    required this.authViewModel,
    required this.accountViewModel,
  });

  static const _categories = [
    CategorySpend(
      label: 'Vivienda',
      amount: '650,00 €',
      percent: '52%',
      dotColor: AppColors.primary,
      icon: Icons.home_rounded,
    ),
    CategorySpend(
      label: 'Alimentación',
      amount: '280,40 €',
      percent: '23%',
      dotColor: AppColors.success,
      icon: Icons.restaurant_rounded,
    ),
    CategorySpend(
      label: 'Transporte',
      amount: '180,20 €',
      percent: '14%',
      dotColor: Color(0xFFF59E0B),
      icon: Icons.directions_car_rounded,
    ),
    CategorySpend(
      label: 'Ocio',
      amount: '95,60 €',
      percent: '8%',
      dotColor: AppColors.error,
      icon: Icons.sports_esports_rounded,
    ),
    CategorySpend(
      label: 'Otros',
      amount: '39,10 €',
      percent: '3%',
      dotColor: AppColors.textMuted,
      icon: Icons.more_horiz_rounded,
    ),
  ];

  static const _movements = [
    MovementItem(
      title: 'Salario',
      subtitle: 'Ingreso · 12 jun. 2025',
      amount: '+1.800,00 €',
      isIncome: true,
      icon: Icons.arrow_downward_rounded,
      iconColor: AppColors.success,
    ),
    MovementItem(
      title: 'Mercadona',
      subtitle: 'Alimentación · 11 jun. 2025',
      amount: '-54,30 €',
      isIncome: false,
      icon: Icons.restaurant_rounded,
      iconColor: AppColors.error,
    ),
    MovementItem(
      title: 'Gasolina',
      subtitle: 'Transporte · 10 jun. 2025',
      amount: '-70,00 €',
      isIncome: false,
      icon: Icons.directions_car_rounded,
      iconColor: AppColors.primary,
    ),
    MovementItem(
      title: 'Alquiler',
      subtitle: 'Vivienda · 5 jun. 2025',
      amount: '-650,00 €',
      isIncome: false,
      icon: Icons.home_rounded,
      iconColor: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: accountViewModel,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: authViewModel.displayName),
                const SizedBox(height: 20),
                _BalanceCard(
                  isLoading: accountViewModel.isLoading,
                  total: accountViewModel.totalBalance,
                  currency: accountViewModel.primaryCurrency,
                ),
                const SizedBox(height: 20),
                const _QuickActions(),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Gastos por categoría',
                  child: Column(
                    children:
                        _categories.map((c) => _CategoryRow(data: c)).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Últimos movimientos',
                  child: Column(
                    children:
                        _movements.map((m) => _MovementRow(data: m)).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buenos días,', style: AppTextStyles.subtitle),
              Text(
                '$name 👋',
                style: AppTextStyles.title.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 4),
              const Text(
                'Aquí tienes un resumen de tus finanzas de este mes.',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        //
        const IconButton(
          onPressed: null,
          icon: Icon(Icons.notifications_none_rounded),
          color: AppColors.text,
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isLoading;
  final double total;
  final String currency;

  const _BalanceCard({
    required this.isLoading,
    required this.total,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo total',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Icon(Icons.visibility_outlined, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 8),
          isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '${total.toStringAsFixed(2)} $currency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  color: Colors.greenAccent, size: 18),
              SizedBox(width: 4),
              Text(
                '+320,50 €',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'vs. mes anterior',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_rounded, 'Añadir\ningreso', AppColors.primary),
      (Icons.remove_rounded, 'Añadir\ngasto', AppColors.error),
      (Icons.bar_chart_rounded, 'Ver\nestadísticas', AppColors.primary),
      (Icons.credit_card_rounded, 'Categorías', AppColors.primary),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _QuickActionButton(
                  icon: a.$1,
                  label: a.$2,
                  color: a.$3,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextButton(
                onPressed: null,
                child: Row(
                  children: [
                    Text('Ver todos'),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySpend data;

  const _CategoryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: data.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Icon(data.icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(data.label, style: AppTextStyles.body)),
          Text(data.amount, style: AppTextStyles.body),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            child: Text(
              data.percent,
              textAlign: TextAlign.right,
              style: AppTextStyles.subtitle.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final MovementItem data;

  const _MovementRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: data.iconColor.withOpacity(0.15),
            child: Icon(data.icon, color: data.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: AppTextStyles.body),
                Text(
                  data.subtitle,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            data.amount,
            style: AppTextStyles.body.copyWith(
              color: data.isIncome ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Inicio'),
      (Icons.history_rounded, 'Movimientos'),
      (Icons.bar_chart_rounded, 'Estadísticas'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];

    return BottomAppBar(
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$1,
                    color: item.$1 == Icons.home_rounded
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.$1 == Icons.home_rounded
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
