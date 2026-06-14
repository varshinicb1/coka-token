import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/stat_card.dart';

class BankReconciliationScreen extends StatelessWidget {
  final AppProvider provider;

  const BankReconciliationScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statements = provider.bankStatements;
    final matchedCount = statements.where((s) => s.isMatched && s.confidence != 'CONFLICT').length;
    final conflictCount = statements.where((s) => s.confidence == 'CONFLICT').length;
    final unmatchedCount = statements.length - matchedCount - conflictCount;
    final log = provider.reconciliationLog;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.cokaOrange.withValues(alpha: 0.1), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Statements',
                      icon: Icons.receipt_long,
                      value: '${statements.length}',
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Matched',
                      icon: Icons.check_circle,
                      value: '$matchedCount',
                      color: AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: unmatchedCount > 0 ? 'Unmatched' : 'All Clear',
                      icon: unmatchedCount > 0 ? Icons.error_outline : Icons.verified,
                      value: '${unmatchedCount + conflictCount}',
                      color: unmatchedCount > 0 ? AppColors.cokaAmber : AppColors.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _importCsv(context),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('Import CSV', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: statements.isEmpty ? null : () => provider.autoMatchReconciliation(),
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Auto Match', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (log.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cokaOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cokaOrange.withValues(alpha: 0.2)),
            ),
            child: Text(
              log,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.cokaOrange.withValues(alpha: 0.9),
                fontFamily: 'monospace',
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text('Bank Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
              const Spacer(),
              if (statements.isNotEmpty)
                GestureDetector(
                  onTap: () => provider.resetReconciliation(),
                  child: Text('Clear', style: TextStyle(fontSize: 12, color: AppColors.errorRed.withValues(alpha: 0.7))),
                ),
            ],
          ),
        ),
        Expanded(
          child: statements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
                      const SizedBox(height: 12),
                      Text(
                        'No statements loaded',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Import a CSV to start reconciliation',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.25), fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: statements.length,
                  itemBuilder: (context, index) {
                    final stmt = statements[index];
                    return _buildStatementCard(stmt, theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatementCard(dynamic stmt, ThemeData theme) {
    final isMatched = stmt.isMatched;
    final confidence = stmt.confidence as String;
    final isConflict = confidence == 'CONFLICT';

    IconData statusIcon;
    Color statusColor;
    if (isMatched && !isConflict) {
      statusIcon = Icons.check_circle;
      statusColor = AppColors.successGreen;
    } else if (isConflict) {
      statusIcon = Icons.warning_amber_rounded;
      statusColor = AppColors.cokaAmber;
    } else {
      statusIcon = Icons.hourglass_empty;
      statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    }

    Color confidenceColor;
    switch (confidence) {
      case 'HIGH':
        confidenceColor = AppColors.successGreen;
      case 'MEDIUM':
        confidenceColor = AppColors.cokaAmber;
      case 'CONFLICT':
        confidenceColor = AppColors.cokaOrange;
      default:
        confidenceColor = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    }

    Color paymentColor;
    switch (stmt.paymentType as String) {
      case 'UPI':
        paymentColor = AppColors.upiBlue;
      case 'Card':
        paymentColor = AppColors.cokaAmber;
      default:
        paymentColor = AppColors.successGreen;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, size: 20, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stmt.description as String,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        stmt.dateString as String,
                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: paymentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stmt.paymentType as String,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: paymentColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stmt.statementId as String,
                        style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.3), fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\u20B9${(stmt.amount as double).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: confidenceColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    confidence,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: confidenceColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null && result.files.single.bytes != null) {
      final content = String.fromCharCodes(result.files.single.bytes!);
      await provider.importBankStatementCsv(content);
    }
  }
}
