import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coka_logo_badge.dart';
import '../utils/date_utils.dart' as date_utils;

class CustomerDisplayScreen extends StatefulWidget {
  final AppProvider provider;

  const CustomerDisplayScreen({super.key, required this.provider});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  AppProvider get provider => widget.provider;

  @override
  Widget build(BuildContext context) {
    final today = date_utils.DateUtils.getTodayDateString();
    final todayOrders = provider.orders
      .where((o) => o.dateString == today && !o.isRefunded)
      .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final displayOrders = todayOrders.length > 10 ? todayOrders.sublist(todayOrders.length - 10) : todayOrders;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CokaLogoBadge(size: 48, showText: true),
              const SizedBox(height: 16),
              Text('COIMBATORE ORIGINAL KAALAN ADDA',
                  style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(today, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3))),
              const SizedBox(height: 24),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('NOW SERVING', style: TextStyle(fontSize: 20, color: AppColors.successGreen.withValues(alpha: 0.8), letterSpacing: 4, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('TOKEN', style: TextStyle(fontSize: 24, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 6)),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('#${todayOrders.isNotEmpty ? todayOrders.last.tokenNumber : '---'}',
                          style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    Text('${todayOrders.length} orders today',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (displayOrders.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RECENT TOKENS', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), letterSpacing: 2)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: displayOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: displayOrders[i] == todayOrders.last ? AppColors.successGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: displayOrders[i] == todayOrders.last ? Border.all(color: AppColors.successGreen) : null,
                            ),
                            child: Center(
                              child: Text('#${displayOrders[i].tokenNumber}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: displayOrders[i] == todayOrders.last ? AppColors.successGreen : Colors.white,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('COKA', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.2), letterSpacing: 4)),
            ],
          ),
        ),
      ),
    );
  }
}
