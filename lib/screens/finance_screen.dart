import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/lily_snackbar.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  int _totalIncome = 0;
  int _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    globalRefreshTrigger.addListener(_fetchTransactions);
  }

  @override
  void dispose() {
    globalRefreshTrigger.removeListener(_fetchTransactions);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    globalRefreshTrigger.value++;
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('transactions')
          .select()
          .order('transaction_date', ascending: false);

      int income = 0;
      int expense = 0;
      for (var item in data) {
        if (item['transaction_type'] == 'income') {
          income += (item['amount'] as num).toInt();
        } else {
          expense += (item['amount'] as num).toInt();
        }
      }

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(data);
        _totalIncome = income;
        _totalExpense = expense;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(context, message: 'Gagal memuat transaksi. Silakan coba lagi.', isSuccess: false);
      }
    }
  }

  Future<void> _deleteTransaction(String id) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('transactions').delete().eq('id', id);
      _fetchTransactions();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(context, message: 'Gagal menghapus transaksi. Silakan coba lagi.', isSuccess: false);
      }
    }
  }

  Future<void> _confirmDeleteTransaction(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text('HAPUS TRANSAKSI?', style: GoogleFonts.silkscreen(color: AppColors.error, fontSize: 14)),
        content: Text('Transaksi ini akan dihapus permanen dan tidak bisa dikembalikan.', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('BATAL', style: GoogleFonts.silkscreen(color: AppColors.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('HAPUS', style: GoogleFonts.silkscreen(color: AppColors.onError)),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteTransaction(id);
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.zero,
              ),
              title: Text(
                'NEW TRANSACTION',
                style: GoogleFonts.silkscreen(color: AppColors.primary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedType = 'income'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'income'
                                    ? AppColors.primaryContainer
                                    : Colors.transparent,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'INCOME',
                                style: GoogleFonts.silkscreen(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedType = 'expense'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == 'expense'
                                    ? AppColors.errorContainer
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selectedType == 'expense'
                                      ? AppColors.error
                                      : AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'EXPENSE',
                                style: GoogleFonts.silkscreen(
                                  color: selectedType == 'expense'
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: GoogleFonts.plusJakartaSans(),
                      decoration: const InputDecoration(
                        labelText: 'Title (e.g. Nasi Goreng)',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(),
                      decoration: const InputDecoration(
                        labelText: 'Amount (e.g. 35000)',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      style: GoogleFonts.plusJakartaSans(),
                      decoration: const InputDecoration(
                        labelText: 'Category (e.g. Food)',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.silkscreen(color: AppColors.error),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () async {
                    final title = titleController.text;
                    final amountText = amountController.text;
                    final category = categoryController.text;

                    if (title.isNotEmpty &&
                        amountText.isNotEmpty &&
                        category.isNotEmpty) {
                      final amount = int.tryParse(amountText);
                      if (amount != null) {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
                          await _supabase.from('transactions').insert({
                            'title': title,
                            'amount': amount,
                            'category': category,
                            'transaction_type': selectedType,
                            'user_id': _supabase.auth.currentUser!.id,
                          });
                          _fetchTransactions();
                        } catch (e) {
                          setState(() => _isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    }
                  },
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.silkscreen(color: AppColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  Widget _buildCategoryChart() {
    // Hitung total pemasukan dan pengeluaran dalam 7 hari terakhir
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    double weeklyIncome = 0;
    double weeklyExpense = 0;

    for (var t in _transactions) {
      final dateStr = t['transaction_date'] as String?;
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && date.isAfter(oneWeekAgo)) {
          final amount = (t['amount'] as num).toDouble();
          if (t['transaction_type'] == 'income') {
            weeklyIncome += amount;
          } else {
            weeklyExpense += amount;
          }
        }
      }
    }

    final total = weeklyIncome + weeklyExpense;

    // Jika tidak ada transaksi minggu ini, tampilkan pesan kosong
    if (total == 0) return const SizedBox.shrink();

    final incomePct = (weeklyIncome / total * 100);
    final expensePct = (weeklyExpense / total * 100);

    const incomeColor = Color(0xFF4CAF50);
    const expenseColor = Color(0xFFE53935);

    return PixelContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PEMASUKAN VS PENGELUARAN',
            style: GoogleFonts.silkscreen(fontSize: 11, color: AppColors.primary),
          ),
          Text(
            '7 HARI TERAKHIR',
            style: GoogleFonts.silkscreen(fontSize: 9, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                height: 130,
                width: 130,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 30,
                    sections: [
                      if (weeklyIncome > 0)
                        PieChartSectionData(
                          color: incomeColor,
                          value: weeklyIncome,
                          title: '${incomePct.toStringAsFixed(1)}%',
                          radius: 38,
                          titleStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                      if (weeklyExpense > 0)
                        PieChartSectionData(
                          color: expenseColor,
                          value: weeklyExpense,
                          title: '${expensePct.toStringAsFixed(1)}%',
                          radius: 38,
                          titleStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend & Detail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pemasukan
                    _buildChartLegendItem(
                      color: incomeColor,
                      label: 'Pemasukan',
                      pct: incomePct,
                      amount: weeklyIncome.toInt(),
                    ),
                    const SizedBox(height: 12),
                    // Pengeluaran
                    _buildChartLegendItem(
                      color: expenseColor,
                      label: 'Pengeluaran',
                      pct: expensePct,
                      amount: weeklyExpense.toInt(),
                    ),
                    const SizedBox(height: 12),
                    // Divider
                    Container(height: 2, color: AppColors.primary),
                    const SizedBox(height: 8),
                    // Selisih
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Selisih: ${_formatCurrency((weeklyIncome - weeklyExpense).toInt())}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: weeklyIncome >= weeklyExpense
                                  ? incomeColor
                                  : expenseColor,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildChartLegendItem({
    required Color color,
    required String label,
    required double pct,
    required int amount,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label  ${pct.toStringAsFixed(1)}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                _formatCurrency(amount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final totalSaldo = _totalIncome - _totalExpense;

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.primaryContainer,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINANCE',
                          style: GoogleFonts.silkscreen(
                            fontSize: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your coins, stay cozy.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Total Saldo Card
                PixelContainer(
                  backgroundColor: AppColors.primaryContainer,
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL SALDO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimaryContainer,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(totalSaldo),
                            style: GoogleFonts.silkscreen(
                              fontSize: 28,
                              color: AppColors.onPrimaryFixed,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 16,
                                    color: AppColors.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dynamic balance',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onPrimaryContainer,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _showAddTransactionDialog,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.primary,
                                        offset: Offset(2, 2),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        right: -16,
                        bottom: -16,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.2,
                            child: Icon(
                              Icons.payments,
                              size: 100,
                              color: AppColors.onPrimaryFixed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Pemasukan / Pengeluaran
                Row(
                  children: [
                    Expanded(
                      child: PixelContainer(
                        borderWidth: 4,
                        shadowOffsetX: 2,
                        shadowOffsetY: 2,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PEMASUKAN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatCurrency(_totalIncome),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PixelContainer(
                        borderWidth: 4,
                        shadowOffsetX: 2,
                        shadowOffsetY: 2,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PENGELUARAN',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatCurrency(_totalExpense),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Chart
                if (_transactions.isNotEmpty) _buildCategoryChart(),

                const SizedBox(height: 16),

                // Recent Activity
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT ACTIVITY',
                        style: GoogleFonts.silkscreen(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Transaction items
                if (_transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No transactions yet.\nAdd one using the + button.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ..._transactions.map((t) {
                    final isIncome = t['transaction_type'] == 'income';
                    final amountStr =
                        '${isIncome ? '+' : '-'} ${_formatCurrency((t['amount'] as num).toInt())}';
                    final date = DateTime.parse(
                      t['transaction_date'],
                    ).toLocal();
                    final dateStr = DateFormat('MMM d, HH:mm').format(date);

                    return _buildTransactionItem(
                      icon: isIncome ? Icons.work : Icons.restaurant,
                      iconBg: isIncome
                          ? AppColors.primaryContainer
                          : AppColors.secondaryContainer,
                      iconColor: isIncome
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSecondaryContainer,
                      title: t['title'] ?? 'Unknown',
                      subtitle: '${t['category']} • $dateStr',
                      amount: amountStr,
                      isIncome: isIncome,
                      onDelete: () => _confirmDeleteTransaction(t['id'].toString()),
                    );
                  }),

                const SizedBox(height: 16),

                // Action buttons
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _showAddTransactionDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 4,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.onSurface,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_circle,
                                  color: AppColors.onPrimary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'NEW ENTRY',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onPrimary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required bool isIncome,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              border: Border.all(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isIncome ? AppColors.primary : AppColors.error,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
