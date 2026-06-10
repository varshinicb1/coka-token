import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/coka_logo_badge.dart';
import '../widgets/app_dialogs.dart';
import '../screens/bluetooth_pairing_screen.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatelessWidget {
  final AppProvider provider;

  const SettingsScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(context, theme),
          const SizedBox(height: 20),
          _buildSectionCard(
            context,
            theme,
            title: 'Preferences',
            icon: Icons.tune,
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle dark theme'),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? AppColors.cokaAmber : AppColors.cokaOrange,
                ),
                value: provider.isDarkMode,
                onChanged: (val) => provider.setDarkMode(val),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: provider.btService.isSupported
                      ? (provider.bluetoothConnected
                          ? AppColors.upiBlue
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5))
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                title: Text(
                  provider.btService.isSupported ? 'Bluetooth Printer' : 'Bluetooth Printer',
                ),
                subtitle: Text(
                  provider.btService.isSupported
                      ? (provider.bluetoothConnected ? 'Connected' : 'Not paired')
                      : 'Not available on this device',
                ),
                enabled: provider.btService.isSupported,
                trailing: const Icon(Icons.chevron_right),
                onTap: provider.btService.isSupported
                    ? () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BluetoothPairingScreen(),
                          ),
                        );
                        if (result == true && context.mounted) {
                          provider.setBluetoothConnected(true);
                        }
                      }
                    : null,
              ),
              const Divider(height: 1, indent: 72),
              SwitchListTile(
                title: const Text('Cloud Sync'),
                subtitle: const Text('Sync is automatic'),
                secondary: Icon(
                  Icons.cloud,
                  color: provider.isCloudSynced
                      ? AppColors.successGreen
                      : AppColors.cokaAmber,
                ),
                value: provider.isCloudSynced,
                onChanged: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            theme,
            title: 'Data',
            icon: Icons.storage,
            children: [
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export Sales CSV'),
                subtitle: const Text('Download sales report'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await provider.exportSalesCSV();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(Icons.summarize),
                title: const Text('End of Day Summary'),
                subtitle: const Text('View today\'s summary'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final summary = provider.getEodSummary();
                  showDialog(
                    context: context,
                    builder: (_) => EodSummaryDialog(
                      summary: summary,
                      provider: provider,
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Import Bank Statement'),
                subtitle: const Text('Upload CSV for reconciliation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final pickerResult = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv'],
                  );
                  if (pickerResult != null && pickerResult.files.isNotEmpty) {
                    final filePath = pickerResult.files.single.path;
                    if (filePath != null) {
                      await provider.importBankStatementCsv(filePath);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.reconciliationLog),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Icon(
                  Icons.restart_alt,
                  color: AppColors.errorRed,
                ),
                title: const Text('End of Day Reset'),
                subtitle: const Text('Reset token counter'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmActionDialog(
                      title: 'End of Day Reset',
                      message:
                          'This will reset the token counter. Continue?',
                      onConfirm: () {
                        provider.endOfDayReset();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token counter reset'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            theme,
            title: 'Account',
            icon: Icons.person,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    (provider.currentUser?.username.isNotEmpty == true
                            ? provider.currentUser!.username[0].toUpperCase()
                            : 'U'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                title: Text(
                  provider.currentUser?.username ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(provider.currentUser?.role ?? ''),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: AppColors.errorRed,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(color: AppColors.errorRed),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.errorRed,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ConfirmActionDialog(
                      title: 'Logout',
                      message: 'Are you sure you want to logout?',
                      onConfirm: () => provider.logout(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            theme,
            title: 'About',
            icon: Icons.info_outline,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const CokaLogoBadge(size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConfig.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version ${AppConfig.appVersion}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.companyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.appTagline,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const CokaLogoBadge(size: 64, showText: true),
          const SizedBox(height: 12),
          Text(
            'Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppConfig.appName} v${AppConfig.appVersion}',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
