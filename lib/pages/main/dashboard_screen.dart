import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/mesh_background.dart';
import 'widgets/dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: PremiumHeader(
                  userName: 'Alex',
                  onProfileTap: () {},
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      PremiumStatCard(
                        title: 'Total Balance',
                        amount: '\$12,450.00',
                        icon: Icons.wallet_rounded,
                        color: AppColors.pureMint,
                      ),
                      PremiumStatCard(
                        title: 'Income',
                        amount: '\$4,200.00',
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.income,
                      ),
                      PremiumStatCard(
                        title: 'Expenses',
                        amount: '\$1,850.00',
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.expense,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassyQuickAction(
                        icon: Icons.add_rounded,
                        label: 'Add',
                        color: Colors.blueAccent,
                        onTap: () {},
                      ),
                      GlassyQuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'Bills',
                        color: Colors.orangeAccent,
                        onTap: () {},
                      ),
                      GlassyQuickAction(
                        icon: Icons.analytics_rounded,
                        label: 'Report',
                        color: Colors.purpleAccent,
                        onTap: () {},
                      ),
                      GlassyQuickAction(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Scan',
                        color: AppColors.pureMint,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recent Activity',
                  onActionTap: () {},
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final items = [
                      {
                        'title': 'Apple Music',
                        'category': 'Subscription',
                        'amount': '9.99',
                        'date': 'Today, 10:00 AM',
                        'icon': Icons.music_note_rounded,
                        'color': Colors.redAccent,
                        'isIncome': false,
                      },
                      {
                        'title': 'Salary Credit',
                        'category': 'Work',
                        'amount': '3,500.00',
                        'date': 'Yesterday',
                        'icon': Icons.payments_rounded,
                        'color': AppColors.income,
                        'isIncome': true,
                      },
                      {
                        'title': 'Starbucks Coffee',
                        'category': 'Food & Drink',
                        'amount': '15.50',
                        'date': 'Yesterday',
                        'icon': Icons.coffee_rounded,
                        'color': Colors.brown,
                        'isIncome': false,
                      },
                      {
                        'title': 'Amazon Order',
                        'category': 'Shopping',
                        'amount': '120.00',
                        'date': '2 days ago',
                        'icon': Icons.shopping_bag_rounded,
                        'color': Colors.orange,
                        'isIncome': false,
                      },
                    ];
                    
                    if (index >= items.length) return null;
                    final item = items[index];
                    
                    return PremiumTransactionTile(
                      title: item['title'] as String,
                      category: item['category'] as String,
                      amount: item['amount'] as String,
                      date: item['date'] as String,
                      icon: item['icon'] as IconData,
                      iconColor: item['color'] as Color,
                      isIncome: item['isIncome'] as bool,
                    );
                  },
                  childCount: 4,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}
