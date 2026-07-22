import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import '../screens/notes_screen.dart';
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToFinance;
  const DashboardScreen({super.key, this.onNavigateToFinance});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _todaySchedules = [];
  Map<String, dynamic>? _latestNote;
  int _totalSaldo = 0;
  int _todayExpense = 0;
  String _username = '';

  // Weather variables
  String _weatherTemp = '--';
  String _weatherCity = 'LOKASI';
  String _weatherCondition = 'Loading...';
  IconData _weatherIcon = Icons.cloud;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    globalRefreshTrigger.addListener(_fetchDashboardData);
  }

  @override
  void dispose() {
    globalRefreshTrigger.removeListener(_fetchDashboardData);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    globalRefreshTrigger.value++;
    await _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final user = _supabase.auth.currentUser;
      final isGoogleAuth = user?.appMetadata['provider'] == 'google';
      final fetchedUsername =
          user?.userMetadata?['username'] ??
          user?.userMetadata?['full_name'] ??
          user?.userMetadata?['name'] ??
          (isGoogleAuth ? 'Kawan' : 'Kawan');

      // Fetch Schedules for today
      final schedulesData = await _supabase
          .from('schedules')
          .select()
          .eq('event_date', nowStr)
          .order('event_time', ascending: true);

      // Fetch Latest Note
      final notesData = await _supabase
          .from('notes')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      // Fetch all transactions to calculate total saldo and today's expense
      final transactionsData = await _supabase.from('transactions').select();

      int income = 0;
      int expense = 0;
      int todayExpense = 0;

      for (var item in transactionsData) {
        final amount = (item['amount'] as num).toInt();
        if (item['transaction_type'] == 'income') {
          income += amount;
        } else {
          expense += amount;
          // Check if transaction is today
          final tDate = DateTime.parse(item['transaction_date']).toLocal();
          if (DateFormat('yyyy-MM-dd').format(tDate) == nowStr) {
            todayExpense += amount;
          }
        }
      }

      setState(() {
        _todaySchedules = List<Map<String, dynamic>>.from(schedulesData);
        if (notesData.isNotEmpty) {
          _latestNote = Map<String, dynamic>.from(notesData[0]);
        }
        _totalSaldo = income - expense;
        _todayExpense = todayExpense;
        _username = fetchedUsername;
        _isLoading = false;
      });

      // Fetch Weather
      final prefs = await SharedPreferences.getInstance();
      final cityName = prefs.getString('weather_city') ?? 'Klaten';
      final lat = prefs.getDouble('weather_lat') ?? -7.7;
      final lon = prefs.getDouble('weather_lon') ?? 110.6;

      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,is_day&timezone=auto',
      );
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final current = weatherData['current'];
        final code = current['weather_code'];
        final isDay = (current['is_day'] ?? 1) == 1;

        String condition = 'Tidak Diketahui';
        IconData icon = Icons.device_unknown;

        if (code == 0 || code == 1) {
          condition = 'Cerah';
          icon = isDay ? Icons.wb_sunny : Icons.nights_stay;
        } else if (code == 2 || code == 3) {
          condition = 'Berawan';
          icon = Icons.cloud;
        } else if (code >= 45 && code <= 48) {
          condition = 'Berkabut';
          icon = Icons.foggy;
        } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
          condition = 'Hujan';
          icon = Icons.water_drop;
        } else if (code >= 95 && code <= 99) {
          condition = 'Badai';
          icon = Icons.thunderstorm;
        }

        setState(() {
          _weatherTemp = '${current['temperature_2m'].round()}°C';
          _weatherCity = cityName.toUpperCase();
          _weatherCondition = condition;
          _weatherIcon = icon;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final dateStr = DateFormat('EEEE, d MMMM').format(now).toUpperCase();

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.primaryContainer,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DASHBOARD',
              style: GoogleFonts.silkscreen(
                fontSize: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Digital Clock Card
            PixelContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'WAKTU LOKAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const Icon(Icons.schedule, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    timeStr,
                    style: GoogleFonts.silkscreen(
                      fontSize: 48,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
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
            const SizedBox(height: 16),

            // Weather Card
            PixelContainer(
              backgroundColor: AppColors.secondaryContainer,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUACA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weatherCondition,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '$_weatherTemp • $_weatherCity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Icon(_weatherIcon, size: 64, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mascot Dialogue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 4),
                    color: AppColors.tertiaryFixed,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.primary,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDRBCxEFUSfkWnwC4FfkvLQmH_8suXG-UDSM9qH2Aw_-CEixTiRsZJDGHl0YRdCGLrIl37FktxWS6xnGOpAKpwoJ5gDFBeL_6kBrJ_1Ax0xyc4dxKZ3VXFBBU-_Z4xw4HClXVaW6X1NZifw0WYS4dNu2J4ON11e4nNkuAH-mAV6Vx2wfN_fOy2dXsJsLG3Sw_uq6OcgxGj_xrWpJeK54l9LiUkC-oD4ENkHHv0TutTUIZZPm38WGkx8C_rFcbvNgmby-UfIMu9GFg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.eco, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PixelContainer(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _todaySchedules.isNotEmpty
                          ? '"Halo $_username! Jangan lupa hari ini ada jadwal: ${_todaySchedules.first['title']}. 🐸"'
                          : '"Halo $_username! Wah, tidak ada jadwal hari ini! Waktunya rebahan santai! 🐸"',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Schedule List
            PixelContainer(
              shadowOffsetX: 6,
              shadowOffsetY: 6,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JADWAL HARI INI',
                    style: GoogleFonts.silkscreen(
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    height: 4,
                    color: AppColors.primary,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                  ),
                  if (_todaySchedules.isEmpty)
                    Text(
                      'Tidak ada jadwal hari ini.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  else
                    ..._todaySchedules.map(
                      (s) => _buildTaskItem(
                        title: s['title'] ?? '',
                        time: '${s['event_time']} • ${s['location'] ?? ''}',
                        isDone: s['is_done'] == true,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes Preview
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesScreen()),
                );
                _fetchDashboardData();
              },
              child: PixelContainer(
                backgroundColor: AppColors.tertiaryFixed,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_note, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'CATATAN TERBARU',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onTertiaryFixed,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _latestNote != null
                          ? (_latestNote!['title'] ?? 'Untitled')
                          : 'Belum ada catatan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onTertiaryFixed,
                      ),
                    ),
                    if (_latestNote != null &&
                        _latestNote!['body'] != null &&
                        _latestNote!['body'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _latestNote!['body'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: AppColors.onTertiaryFixedVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (_latestNote == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tekan di sini untuk mulai menulis!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: AppColors.onTertiaryFixedVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Finance Summary
            PixelContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          'TOTAL SALDO ANDA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToFinance,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatCurrency(_totalSaldo),
                    style: GoogleFonts.silkscreen(
                      fontSize: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PENGELUARAN HARI INI: ${_formatCurrency(_todayExpense)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String time,
    required bool isDone,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primary
                  : AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.primary, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.primary,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: isDone
                ? const Icon(
                    Icons.close,
                    color: AppColors.surfaceContainerLowest,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: isDone ? 0.6 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationThickness: 3,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          time,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.6,
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
    );
  }
}
