import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../main.dart';
import '../widgets/lily_snackbar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedCountryCode = 'en.indonesian'; // Default: Indonesia

  final Map<String, String> _countries = {
    'en.indonesian': 'Indonesia',
    'en.usa': 'United States',
    'en.japanese': 'Japan',
    'en.uk': 'United Kingdom',
    'en.australian': 'Australia',
  };
  int selectedDay = DateTime.now().day;
  DateTime currentMonth = DateTime.now();

  // Cache for holidays to prevent redundant API calls
  final Map<String, List<Map<String, dynamic>>> _holidayCache = {};

  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    globalRefreshTrigger.addListener(_fetchSchedules);
  }

  @override
  void dispose() {
    globalRefreshTrigger.removeListener(_fetchSchedules);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    globalRefreshTrigger.value++;
    await _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch from Supabase
      final data = await _supabase
          .from('schedules')
          .select()
          .order('event_date', ascending: true);
      List<Map<String, dynamic>> combinedSchedules =
          List<Map<String, dynamic>>.from(data);

      // 2. Fetch Public Holidays
      try {
        final cacheKey =
            '${_selectedCountryCode}_${currentMonth.year}_${currentMonth.month}';

        if (_holidayCache.containsKey(cacheKey)) {
          combinedSchedules.addAll(_holidayCache[cacheKey]!);
        } else {
          final startOfMonth = DateTime(
            currentMonth.year,
            currentMonth.month,
            1,
          );
          final endOfMonth = DateTime(
            currentMonth.year,
            currentMonth.month + 1,
            0,
            23,
            59,
            59,
          );

          final apiKey = dotenv.env['GOOGLE_CALENDAR_API_KEY'] ?? '';

          if (apiKey.isNotEmpty) {
            final calendarId =
                '$_selectedCountryCode#holiday@group.v.calendar.google.com';
            final encodedCalendarId = Uri.encodeComponent(calendarId);
            final url = Uri.parse(
              'https://www.googleapis.com/calendar/v3/calendars/$encodedCalendarId/events'
              '?key=$apiKey'
              '&timeMin=${startOfMonth.toUtc().toIso8601String()}'
              '&timeMax=${endOfMonth.toUtc().toIso8601String()}'
              '&singleEvents=true'
              '&orderBy=startTime',
            );

            final response = await http.get(url);
            if (response.statusCode == 200) {
              final Map<String, dynamic> data = json.decode(response.body);
              final items = data['items'] as List<dynamic>?;
              final List<Map<String, dynamic>> fetchedHolidays = [];

              if (items != null) {
                for (var e in items) {
                  final startMap = e['start'] as Map<String, dynamic>?;
                  if (startMap != null) {
                    final dateStr = startMap['date'] ?? startMap['dateTime'];
                    if (dateStr != null) {
                      final start = DateTime.parse(dateStr).toLocal();
                      fetchedHolidays.add({
                        'id': 'holiday_${e['id']}',
                        'title': e['summary'] ?? 'Holiday',
                        'event_date': DateFormat('yyyy-MM-dd').format(start),
                        'event_time': 'All Day',
                        'location': '',
                        'is_google': true,
                        'is_holiday': true,
                      });
                    }
                  }
                }
              }
              _holidayCache[cacheKey] = fetchedHolidays;
              combinedSchedules.addAll(fetchedHolidays);
            } else {
              debugPrint('Failed to fetch holidays: ${response.statusCode}');
            }
          }
        }
      } catch (e) {
        debugPrint('Gagal fetch Holidays: $e');
      }

      setState(() {
        _schedules = combinedSchedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(
          context,
          message: 'Gagal memuat jadwal. Silakan coba lagi.',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _deleteSchedule(String id) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('schedules').delete().eq('id', id);
      _fetchSchedules();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(
          context,
          message: 'Gagal menghapus jadwal. Silakan coba lagi.',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _saveHolidayToDB(Map<String, dynamic> event) async {
    setState(() => _isLoading = true);
    try {
      final dateStr = event['event_date'] as String;
      await _supabase.from('schedules').insert({
        'title': event['title'],
        'event_date': dateStr,
        'start_time': '00:00:00', // Default for full day event
        'user_id': _supabase.auth.currentUser!.id,
      });
      _fetchSchedules();
      if (mounted) {
        LilySnackBar.show(
          context,
          message: 'Hari Libur Disimpan ke Jadwal!',
          isSuccess: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        LilySnackBar.show(
          context,
          message: 'Gagal menyimpan hari libur. Silakan coba lagi.',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _confirmDeleteSchedule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.error, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'HAPUS JADWAL?',
          style: GoogleFonts.silkscreen(color: AppColors.error, fontSize: 14),
        ),
        content: Text(
          'Jadwal ini akan dihapus permanen.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'BATAL',
              style: GoogleFonts.silkscreen(color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'HAPUS',
              style: GoogleFonts.silkscreen(color: AppColors.onError),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteSchedule(id);
  }

  void _showAddScheduleDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();
    final locationController = TextEditingController();
    // Simpan messenger SEBELUM dialog terbuka agar SnackBar muncul di depan
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.primary, width: 4),
            borderRadius: BorderRadius.zero,
          ),
          title: Text(
            'NEW PLAN',
            style: GoogleFonts.silkscreen(color: AppColors.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Date: ${DateFormat('MMMM d, yyyy').format(DateTime(currentMonth.year, currentMonth.month, selectedDay))}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.plusJakartaSans(),
                  decoration: const InputDecoration(
                    labelText: 'Event Title',
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
                  controller: timeController,
                  style: GoogleFonts.plusJakartaSans(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9: AaMmPp]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Time (e.g. 10:00 AM)',
                    hintText: '10:00 AM',
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
                  controller: locationController,
                  style: GoogleFonts.plusJakartaSans(),
                  decoration: const InputDecoration(
                    labelText: 'Location',
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
                final title = titleController.text.trim();

                // Validasi: judul kosong
                if (title.isEmpty) {
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.errorContainer,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Judul acara tidak boleh kosong!'),
                          ),
                        ],
                      ),
                    ),
                  );
                  return;
                }

                final eventDate = DateTime(
                  currentMonth.year,
                  currentMonth.month,
                  selectedDay,
                );
                final dateStr = DateFormat('yyyy-MM-dd').format(eventDate);

                Navigator.pop(dialogContext);
                setState(() => _isLoading = true);
                try {
                  await _supabase.from('schedules').insert({
                    'title': title,
                    'event_date': dateStr,
                    'event_time': timeController.text.trim(),
                    'location': locationController.text.trim(),
                    'user_id': _supabase.auth.currentUser!.id,
                  });
                  _fetchSchedules();
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryContainer,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Jadwal berhasil disimpan!'),
                          ),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                  setState(() => _isLoading = false);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.errorContainer,
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Gagal menyimpan jadwal. Silakan coba lagi.',
                            ),
                          ),
                        ],
                      ),
                    ),
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
  }

  @override
  Widget build(BuildContext context) {
    // Filter events for the selected day
    final selectedDateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(currentMonth.year, currentMonth.month, selectedDay));
    final dayEvents = _schedules
        .where((s) => s['event_date'] == selectedDateStr)
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.primaryContainer,
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calendar Card
            PixelContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month header
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.primary, width: 4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavButton(Icons.chevron_left, () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month - 1,
                            );
                          });
                          _fetchSchedules();
                        }),
                        Text(
                          DateFormat(
                            'MMMM yyyy',
                          ).format(currentMonth).toUpperCase(),
                          style: GoogleFonts.silkscreen(
                            fontSize: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        _buildNavButton(Icons.chevron_right, () {
                          setState(() {
                            currentMonth = DateTime(
                              currentMonth.year,
                              currentMonth.month + 1,
                            );
                          });
                          _fetchSchedules();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Country Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 2),
                      color: AppColors.surface,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountryCode,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primary,
                        ),
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        items: _countries.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text('Holidays: ${entry.value}'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCountryCode = newValue;
                            });
                            _fetchSchedules();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Days of week header
                  Row(
                    children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),

                  // Calendar grid
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    _buildCalendarGrid(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Selected date plans
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${DateFormat('MMM').format(currentMonth).toUpperCase()} $selectedDay\nPLANS',
                  style: GoogleFonts.silkscreen(
                    fontSize: 22,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: _showAddScheduleDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      border: Border.all(color: AppColors.primary, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.primary,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TAMBAH\nJADWAL',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.6,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 4,
              color: AppColors.primary,
              margin: const EdgeInsets.only(top: 8),
            ),
            const SizedBox(height: 12),

            // Plans List or Empty state
            if (dayEvents.isEmpty)
              PixelContainer(
                backgroundColor: AppColors.surfaceContainerLow,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 80,
                  child: Center(
                    child: Text(
                      'No plans scheduled for this date.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...dayEvents.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PixelContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tertiaryContainer,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            event['event_time'] ?? '--:--',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onTertiaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3),
                                    child: Icon(
                                      Icons.label_outline,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event['title'] ?? 'Untitled',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  if (event['is_holiday'] == true)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.beach_access,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    )
                                  else if (event['is_google'] == true)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.g_mobiledata,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                    ),
                                ],
                              ),
                              if (event['location'] != null &&
                                  event['location'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 1),
                                        child: Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          event['location'],
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (event['is_done'] == true)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.secondary,
                          ),
                        if (event['is_google'] != true)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                _confirmDeleteSchedule(event['id']),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.save_alt,
                              color: AppColors.primary,
                            ),
                            tooltip: 'Simpan ke Jadwal',
                            onPressed: () => _saveHolidayToDB(event),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ), // Column
      ), // SingleChildScrollView
    ); // RefreshIndicator
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primary,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
          color: AppColors.surfaceContainerLowest,
        ),
        child: Icon(icon, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(
      currentMonth.year,
      currentMonth.month,
    );

    // 0 = Sunday, 1 = Monday ... 6 = Saturday (Flutter DateTime weekday is 1=Mon, 7=Sun)
    // To match our header [SUN, MON...], we adjust.
    int firstWeekdayIndex = firstDayOfMonth.weekday;
    if (firstWeekdayIndex == 7) firstWeekdayIndex = 0; // Make Sunday 0

    final List<int?> days = [];

    // Empty cells before the 1st
    for (int i = 0; i < firstWeekdayIndex; i++) {
      days.add(null);
    }

    // Days of the month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(i);
    }

    // Trailing empty cells
    while (days.length % 7 != 0) {
      days.add(null);
    }

    final rows = <Widget>[];
    for (int r = 0; r < days.length; r += 7) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(7, (c) {
              final dayIndex = r + c;
              final day = dayIndex < days.length ? days[dayIndex] : null;
              return Expanded(child: _buildDayCell(day));
            }),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildDayCell(int? day) {
    if (day == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: Text(
            '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppColors.outlineVariant,
            ),
          ),
        ),
      );
    }

    final isSelected = day == selectedDay;

    // Check if this specific date has an event or holiday
    final dateStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(currentMonth.year, currentMonth.month, day));

    final dayEvents = _schedules
        .where((s) => s['event_date'] == dateStr)
        .toList();
    final hasEvent = dayEvents.isNotEmpty;
    final isHoliday = dayEvents.any((s) => s['is_holiday'] == true);

    return GestureDetector(
      onTap: () => setState(() => selectedDay = day),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: AppColors.primary,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : (isHoliday ? FontWeight.w800 : FontWeight.w400),
                  color: isSelected
                      ? AppColors.primary
                      : (isHoliday ? Colors.redAccent : AppColors.onSurface),
                ),
              ),
              if (hasEvent)
                Positioned(
                  bottom: 2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isHoliday
                          ? Colors.redAccent
                          : AppColors.secondaryContainer,
                      border: Border.all(
                        color: isHoliday ? Colors.red : AppColors.primary,
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
