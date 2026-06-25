import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../models/menu_item.dart';
import '../models/user.dart';
import '../models/order.dart';

// ---------------------------------------------------------------------------
// 1. Add Menu Item Dialog
// ---------------------------------------------------------------------------

class AddMenuItemDialog extends StatefulWidget {
  final MenuItem? existingItem;

  const AddMenuItemDialog({super.key, this.existingItem});

  @override
 State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _categories = [
    'Kaalan Dishes',
    'Kaalan Snacks',
    'Beverages',
    'Extras',
    'Combo Meals',
  ];

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.existingItem!;
      _nameCtrl.text = item.name;
      _rateCtrl.text = item.rate.toStringAsFixed(2);
      _categoryCtrl.text = item.category;
      _stockCtrl.text = item.openingStock.toString();
      _descCtrl.text = item.description;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    await provider.saveMenuItem(
      id: widget.existingItem?.id,
      name: _nameCtrl.text.trim(),
      rate: double.tryParse(_rateCtrl.text.trim()) ?? 0,
      category: _categoryCtrl.text.trim(),
      openingStock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
      description: _descCtrl.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Edit Menu Item' : 'Add Menu Item',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _rateCtrl,
                  decoration: const InputDecoration(labelText: 'Rate'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Rate is required';
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Rate must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(_categoryCtrl.text) ? _categoryCtrl.text : null,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    setState(() => _categoryCtrl.text = v ?? '');
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'Category is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _stockCtrl,
                  decoration: const InputDecoration(labelText: 'Opening Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Stock is required';
                    final val = int.tryParse(v.trim());
                    if (val == null || val < 0) return 'Stock must be >= 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update' : 'Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Add Expense Dialog
// ---------------------------------------------------------------------------

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
 State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    await provider.addExpense(
      _descCtrl.text.trim(),
      double.tryParse(_amountCtrl.text.trim()) ?? 0,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Expense',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Amount is required';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Amount must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Add User Dialog
// ---------------------------------------------------------------------------

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
 State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'Staff';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final user = User(
      username: _emailCtrl.text.trim(),
      passwordHash: _passwordCtrl.text,
      role: _role,
    );
    await provider.createUser(user);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add User',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.length < 4) return 'Password must be at least 4 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Text('Role', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Staff'),
                      value: 'Staff',
                      groupValue: _role,
                      onChanged: (v) => setState(() => _role = v!),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Admin'),
                      value: 'Admin',
                      groupValue: _role,
                      onChanged: (v) => setState(() => _role = v!),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. EOD Summary Dialog
// ---------------------------------------------------------------------------

class EodSummaryDialog extends StatelessWidget {
  final Map<String, dynamic> summary;
  final AppProvider provider;

  const EodSummaryDialog({
    super.key,
    required this.summary,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalSales = (summary['totalSales'] as num?)?.toDouble() ?? 0;
    final orderCount = (summary['orderCount'] as num?)?.toInt() ?? 0;
    final expenses = (summary['totalExpenses'] as num?)?.toDouble() ?? 0;
    final netProfit = (summary['netProfit'] as num?)?.toDouble() ?? (totalSales - expenses);
    final refundCount = (summary['refundCount'] as num?)?.toInt() ?? 0;
    final refundAmount = (summary['refundAmount'] as num?)?.toDouble() ?? 0;

    final cashAmount = (summary['cashTotal'] as num?)?.toDouble() ?? 0;
    final upiAmount = (summary['upiTotal'] as num?)?.toDouble() ?? 0;
    final cardAmount = (summary['cardTotal'] as num?)?.toDouble() ?? 0;

    final dateStr = summary['date'] as String? ?? 'Today';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cokaRed, AppColors.cokaOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Day End Summary',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '\u{20B9}${totalSales.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$orderCount Order${orderCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Payment Breakdown', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _row('Cash', '\u{20B9}${cashAmount.toStringAsFixed(2)}', AppColors.successGreen),
              _row('UPI', '\u{20B9}${upiAmount.toStringAsFixed(2)}', AppColors.upiBlue),
              _row('Card', '\u{20B9}${cardAmount.toStringAsFixed(2)}', AppColors.cokaAmber),
              const Divider(height: 24),
              _row('Total Expenses', '\u{20B9}${expenses.toStringAsFixed(2)}', AppColors.cokaRed),
              const SizedBox(height: 4),
              _row(
                'Net Profit',
                '\u{20B9}${netProfit.toStringAsFixed(2)}',
                netProfit >= 0 ? AppColors.successGreen : AppColors.errorRed,
              ),
              if (refundCount > 0) ...[
                const Divider(height: 24),
                _row('Refunds ($refundCount)', '-\u{20B9}${refundAmount.toStringAsFixed(2)}', AppColors.errorRed),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await provider.executeEndOfDay();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Day ended successfully')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cokaRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('End Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Receipt Actions Dialog
// ---------------------------------------------------------------------------

class ReceiptActionsDialog extends StatelessWidget {
  final Order order;
  final AppProvider provider;

  const ReceiptActionsDialog({
    super.key,
    required this.order,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Order #${order.tokenNumber}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '\u{20B9}${order.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final success = await provider.printOrderReceipt(order);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Receipt sent to printer' : 'Print failed - check Bluetooth connection'),
                            backgroundColor: success ? null : AppColors.errorRed,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final success = await provider.sharePdfReceipt(order);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'PDF receipt shared' : 'Failed to generate PDF'),
                            backgroundColor: success ? null : AppColors.errorRed,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('PDF', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cokaAmber,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await provider.refundOrder(order);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order #${order.tokenNumber} marked as refunded')),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refund', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Order?'),
                          content: Text('Delete order #${order.tokenNumber} for Rs.${order.totalAmount.toStringAsFixed(0)}? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await provider.deleteOrder(order);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Order #${order.tokenNumber} deleted')),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}

// ---------------------------------------------------------------------------
// 6. Confirm Action Dialog
// ---------------------------------------------------------------------------

class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Date Range Picker Dialog (simplified)
// ---------------------------------------------------------------------------

class DateRangePickerDialog extends StatefulWidget {
  final Function(DateTime start, DateTime end) onSelected;

  const DateRangePickerDialog({super.key, required this.onSelected});

  @override
 State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
      helpText: isStart ? 'Select start date' : 'Select end date',
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) _startDate = _endDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Date Range',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _dateField(
              label: 'Start Date',
              date: _startDate,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 12),
            _dateField(
              label: 'End Date',
              date: _endDate,
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                widget.onSelected(_startDate, _endDate);
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField({required String label, required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
      ),
    );
  }
}
