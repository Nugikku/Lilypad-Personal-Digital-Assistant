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

// ─── Peta Kategori: nama → (ikon, warna) ───────────────────────────────────
const Map<String, Map<String, dynamic>> kCategoryMeta = {
  'Food':        {'icon': Icons.restaurant,      'color': Color(0xFFFF7043)},
  'Transport':   {'icon': Icons.directions_car,  'color': Color(0xFF42A5F5)},
  'Shopping':    {'icon': Icons.shopping_bag,    'color': Color(0xFFAB47BC)},
  'Health':      {'icon': Icons.favorite,        'color': Color(0xFFEF5350)},
  'Education':   {'icon': Icons.school,          'color': Color(0xFF26A69A)},
  'Entertainment':{'icon': Icons.sports_esports, 'color': Color(0xFFFFCA28)},
  'Saving':      {'icon': Icons.savings,         'color': Color(0xFF66BB6A)},
  'Other':       {'icon': Icons.category,        'color': Color(0xFF78909C)},
};

class _FinanceScreenState extends State<FinanceScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // filter kategori aktif

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
      if (mounted) {
        LilySnackBar.show(context, message: 'Transaksi berhasil dihapus!', isSuccess: true);
      }
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

  // Kembalikan kategori yang sesuai dari data lama (fallback ke 'Other')
  String _normalizeCategory(String raw) {
    final match = kCategoryMeta.keys.firstWhere(
      (k) => k.toLowerCase() == raw.toLowerCase(),
      orElse: () => 'Other',
    );
    return match;
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food'; // default dropdown
    String selectedType = 'expense';
    // Simpan messenger SEBELUM dialog terbuka agar SnackBar muncul di depan
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                    // ── Dropdown Kategori ──
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCategory,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.onSurface,
                          ),
                          dropdownColor: AppColors.surface,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCategory = val);
                          },
                          items: kCategoryMeta.entries.map((entry) {
                            final meta = entry.value;
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: (meta['color'] as Color).withOpacity(0.2),
                                      border: Border.all(color: meta['color'] as Color, width: 1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(meta['icon'] as IconData, size: 16, color: meta['color'] as Color),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(entry.key, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
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
                    final title = titleController.text.trim();
                    final amountText = amountController.text.trim();
                    final category = selectedCategory;

                    // Validasi: form kosong
                    if (title.isEmpty || amountText.isEmpty) {
                      LilySnackBar.showWithMessenger(
                        messenger,
                        message: 'Semua kolom harus diisi terlebih dahulu!',
                        isSuccess: false,
                      );
                      return;
                    }

                    // Validasi: amount bukan angka
                    final amount = int.tryParse(amountText);
                    if (amount == null) {
                      LilySnackBar.showWithMessenger(
                        messenger,
                        message: 'Jumlah harus berupa angka yang valid!',
                        isSuccess: false,
                      );
                      return;
                    }

                    // Simpan transaksi
                    Navigator.pop(dialogContext);
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
                      LilySnackBar.showWithMessenger(
                        messenger,
                        message: 'Transaksi berhasil disimpan!',
                        isSuccess: true,
                      );
                    } catch (e) {
                      setState(() => _isLoading = false);
                      LilySnackBar.showWithMessenger(
                        messenger,
                        message: 'Gagal menyimpan transaksi. Silakan coba lagi.',
                        isSuccess: false,
                      );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            size: 14,
                            color: AppColors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TOTAL SALDO',
                            style: GoogleFonts.silkscreen(
                              fontSize: 11,
                              color: AppColors.onPrimaryContainer,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Jumlah Saldo
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _formatCurrency(totalSaldo),
                          style: GoogleFonts.silkscreen(
                            fontSize: 30,
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Divider retro
                      Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Bottom row: label + tombol +
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 16,
                                color: AppColors.onPrimaryContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dynamic balance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showAddTransactionDialog,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(
                                  color: AppColors.onPrimaryFixed,
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.onPrimaryFixed,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
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

                // Recent Activity Header
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.outlineVariant, width: 2),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'RECENT ACTIVITY',
                    style: GoogleFonts.silkscreen(fontSize: 20, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Filter Horizontal ──────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Chip "All"
                      _buildFilterChip('All', Icons.grid_view, const Color(0xFF455A64)),
                      ...kCategoryMeta.entries.map(
                        (e) => _buildFilterChip(e.key, e.value['icon'] as IconData, e.value['color'] as Color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Transaction items (filtered)
                Builder(builder: (_) {
                  final filtered = _selectedFilter == 'All'
                      ? _transactions
                      : _transactions.where((t) {
                          final cat = _normalizeCategory(t['category'] ?? '');
                          return cat == _selectedFilter;
                        }).toList();

                  if (_transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No transactions yet.\nAdd one using the + button.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Tidak ada transaksi di kategori $_selectedFilter.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: filtered.map((t) {
                      final isIncome = t['transaction_type'] == 'income';
                      final amountStr = '${isIncome ? '+' : '-'} ${_formatCurrency((t['amount'] as num).toInt())}';
                      final date = DateTime.parse(t['transaction_date']).toLocal();
                      final dateStr = DateFormat('MMM d, HH:mm').format(date);
                      final catKey = _normalizeCategory(t['category'] ?? '');
                      final meta = kCategoryMeta[catKey]!;

                      return _buildTransactionItem(
                        icon: meta['icon'] as IconData,
                        iconBg: (meta['color'] as Color).withOpacity(0.15),
                        iconColor: meta['color'] as Color,
                        category: catKey,
                        categoryColor: meta['color'] as Color,
                        title: t['title'] ?? 'Unknown',
                        dateStr: dateStr,
                        amount: amountStr,
                        isIncome: isIncome,
                        onDelete: () => _confirmDeleteTransaction(t['id'].toString()),
                      );
                    }).toList(),
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

  // ── Filter Chip Widget ───────────────────────────────────────────────────
  Widget _buildFilterChip(String label, IconData icon, Color color) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.4), offset: const Offset(2, 2), blurRadius: 0)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction Item Widget ──────────────────────────────────────────────
  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String category,
    required Color categoryColor,
    required String title,
    required String dateStr,
    required String amount,
    required bool isIncome,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon Kategori
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              border: Border.all(color: categoryColor, width: 2),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: categoryColor.withOpacity(0.3), offset: const Offset(2, 2), blurRadius: 0),
              ],
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // ── Badge Kategori ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.15),
                        border: Border.all(color: categoryColor, width: 1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isIncome ? AppColors.primary : AppColors.error,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
