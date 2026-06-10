import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';
import '../widgets/app_dialogs.dart';
import '../models/user.dart';

class UsersScreen extends StatelessWidget {
  final AppProvider provider;

  const UsersScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = provider.users;
    final adminCount = users.where((u) => u.role.toUpperCase() == 'ADMIN').length;
    final staffCount = users.where((u) => u.role.toUpperCase() != 'ADMIN').length;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cokaRed.withValues(alpha: 0.1), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Users',
                      icon: Icons.people,
                      value: '${users.length}',
                      color: AppColors.cokaRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Admins',
                      icon: Icons.admin_panel_settings,
                      value: '$adminCount',
                      color: AppColors.cokaAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Staff',
                      icon: Icons.badge,
                      value: '$staffCount',
                      color: AppColors.cokaOrange,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'All Users',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.cokaRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${users.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cokaRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No users registered',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isAdmin = user.role.toUpperCase() == 'ADMIN';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onLongPress: isAdmin ? null : () => _showDeleteDialog(context, user),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isAdmin
                                        ? AppColors.cokaRed.withValues(alpha: 0.15)
                                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isAdmin ? AppColors.cokaRed : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.username,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAdmin
                                                    ? AppColors.cokaRed.withValues(alpha: 0.12)
                                                    : AppColors.cokaAmber.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isAdmin ? 'ADMIN' : 'STAFF',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isAdmin ? AppColors.cokaRed : AppColors.cokaAmber,
                                                ),
                                              ),
                                            ),
                                            if (!isAdmin) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                'Long-press for options',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isAdmin ? Icons.shield : Icons.person,
                                    size: 20,
                                    color: isAdmin
                                        ? AppColors.cokaRed.withValues(alpha: 0.5)
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddUserDialog(),
            ),
            backgroundColor: AppColors.cokaRed,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.removeUser(user);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );
  }
}
