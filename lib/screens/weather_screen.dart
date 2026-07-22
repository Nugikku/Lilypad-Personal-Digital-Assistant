import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/pixel_container.dart';
import '../main.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  String _cityName = 'Klaten';
  double _latitude = -7.7;
  double _longitude = 110.6;

  String _temperature = '--';
  String _humidity = '--';
  String _windSpeed = '--';
  String _chanceOfRain = '--';
  int _weatherCode = -1;
  int _isDay = 1;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    globalRefreshTrigger.addListener(_fetchWeatherData);
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cityName = prefs.getString('weather_city') ?? 'Klaten';
      _latitude = prefs.getDouble('weather_lat') ?? -7.7;
      _longitude = prefs.getDouble('weather_lon') ?? 110.6;
    });
    _fetchWeatherData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    globalRefreshTrigger.removeListener(_fetchWeatherData);
    super.dispose();
  }

  Future<void> _saveLocationAndFetch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=1&language=en&format=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('weather_city', result['name']);
          await prefs.setDouble('weather_lat', result['latitude']);
          await prefs.setDouble('weather_lon', result['longitude']);

          setState(() {
            _cityName = result['name'];
            _latitude = result['latitude'];
            _longitude = result['longitude'];
          });

          _searchController.clear();
          await _fetchWeatherData();
        } else {
          setState(() {
            _errorMessage = 'Kota tidak ditemukan.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mencari kota.';
        _isLoading = false;
      });
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.primary, width: 4),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          'ATUR LOKASI',
          style: GoogleFonts.silkscreen(color: AppColors.primary),
        ),
        content: TextField(
          controller: _searchController,
          style: GoogleFonts.plusJakartaSans(),
          decoration: const InputDecoration(
            labelText: 'Nama Kota',
            hintText: 'Misal: Jakarta',
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          onSubmitted: (val) {
            Navigator.pop(context);
            _saveLocationAndFetch(val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
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
            onPressed: () {
              Navigator.pop(context);
              _saveLocationAndFetch(_searchController.text);
            },
            child: Text(
              'SIMPAN',
              style: GoogleFonts.silkscreen(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWeatherData() async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$_latitude&longitude=$_longitude&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,is_day&daily=precipitation_probability_max&timezone=auto',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final daily = data['daily'];

        setState(() {
          _temperature = '${current['temperature_2m'].round()}';
          _humidity = '${current['relative_humidity_2m']}%';
          _windSpeed = '${current['wind_speed_10m']}';

          final rainProb =
              (daily['precipitation_probability_max'] as List).firstOrNull ?? 0;
          _chanceOfRain = '$rainProb%';

          _weatherCode = current['weather_code'];
          _isDay = current['is_day'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengambil data cuaca.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getWeatherDetails(int code, bool isDay) {
    if (code == 0 || code == 1) {
      return {
        'condition': 'CERAH',
        'icon': isDay ? Icons.wb_sunny : Icons.nights_stay,
        'tip': isDay
            ? '"Matahari bersinar cerah! Cocok untuk menjemur pakaian, jangan lupa minum air putih!"'
            : '"Malam yang cerah dan berbintang! Waktu yang pas untuk beristirahat dengan tenang."',
        'color': isDay ? Colors.orangeAccent : Colors.indigoAccent,
      };
    } else if (code == 2 || code == 3) {
      return {
        'condition': 'BERAWAN',
        'icon': Icons.cloud,
        'tip':
            '"Cuaca sangat sejuk berawan. Waktu yang pas untuk jalan-jalan santai!"',
        'color': Colors.lightBlueAccent,
      };
    } else if (code >= 45 && code <= 48) {
      return {
        'condition': 'BERKABUT',
        'icon': Icons.foggy,
        'tip': '"Hati-hati jika di jalan, cuaca sedang berkabut tebal."',
        'color': Colors.grey,
      };
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return {
        'condition': 'HUJAN',
        'icon': Icons.water_drop,
        'tip':
            '"Sepertinya sedang hujan! Jangan lupa bawa payung daunmu jika ingin keluar."',
        'color': Colors.blueAccent,
      };
    } else if (code >= 95 && code <= 99) {
      return {
        'condition': 'BADAI',
        'icon': Icons.thunderstorm,
        'tip':
            '"Ada badai petir di luar! Lebih aman tetap berada di dalam ruangan."',
        'color': Colors.deepPurple,
      };
    } else {
      return {
        'condition': 'TIDAK DIKETAHUI',
        'icon': Icons.device_unknown,
        'tip':
            '"Cuaca sedang tidak menentu, tetap waspada dan jaga kesehatan!"',
        'color': AppColors.primary,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherDetails = _getWeatherDetails(_weatherCode, _isDay == 1);
    final String conditionStr = weatherDetails['condition'];
    final IconData conditionIcon = weatherDetails['icon'];
    final String tipStr = weatherDetails['tip'];
    final Color conditionColor = weatherDetails['color'];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryFixed, AppColors.background],
        ),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.primaryContainer,
              onRefresh: () async {
                globalRefreshTrigger.value++;
                await _fetchWeatherData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Main weather card
                    PixelContainer(
                      borderColor: AppColors.onSecondaryFixed,
                      shadowOffsetX: 8,
                      shadowOffsetY: 8,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Location badge
                          Transform.rotate(
                            angle: -0.03,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer,
                                border: Border.all(
                                  color: AppColors.onSecondaryFixed,
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.onSecondaryFixed,
                                    offset: Offset(2, 2),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                'CURRENT LOCATION',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onTertiaryContainer,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _cityName.toUpperCase(),
                                style: GoogleFonts.silkscreen(
                                  fontSize: 28,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _showLocationDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Weather icon + temperature
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  conditionIcon,
                                  size: 72,
                                  color: conditionColor,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_temperature°C',
                                    style: GoogleFonts.silkscreen(
                                      fontSize: 48,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                  Text(
                                    conditionStr,
                                    style: GoogleFonts.silkscreen(
                                      fontSize: 20,
                                      color: conditionColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Lily mascot tip
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: conditionColor.withValues(alpha: 0.1),
                              border: Border.all(
                                color: conditionColor.withValues(alpha: 0.5),
                                width: 2,
                                strokeAlign: BorderSide.strokeAlignInside,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBTo9q1N_yfs_FI9UV8CIkD2qj2qn79a6DiptG4fJHVOpcxH04v1pvw_TfvibGLHYdRDxLOCYedJAbDDnTs8FiXndNjjfAR27MaMYEgjJ9fV13FcFgl7zqD6K0FFfG2HWAOBtbMU1SC050dOyu0j72N3HQPGeBToIKhnQP64H9CyireAGe38MChrWOMzby4NCQwWIbeznLE1CWNLLM0kh6pCM-GKXEYNzBP2InwnpkfWZBP1yK9Jpb10vf5_TsyGl-BmTTCdNXL_A',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.eco,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PixelContainer(
                                    borderColor: AppColors.onSecondaryFixed,
                                    borderWidth: 2,
                                    shadowOffsetX: 2,
                                    shadowOffsetY: 2,
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      tipStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stat cards
                    _buildStatCard(
                      icon: Icons.water_drop,
                      iconBg: AppColors.primaryFixed,
                      label: 'HUMIDITY',
                      value: _humidity,
                      progressPercent:
                          int.tryParse(_humidity.replaceAll('%', '')) != null
                          ? int.parse(_humidity.replaceAll('%', '')) / 100
                          : 0,
                      progressColor: AppColors.secondary,
                    ),
                    const SizedBox(height: 12),

                    _buildStatCard(
                      icon: Icons.air,
                      iconBg: AppColors.tertiaryFixed,
                      label: 'WIND',
                      value: _windSpeed,
                      unit: 'km/h',
                      showDirection: true,
                    ),
                    const SizedBox(height: 12),

                    _buildStatCard(
                      icon: Icons.umbrella,
                      iconBg: AppColors.errorContainer,
                      label: 'CHANCE OF RAIN',
                      value: _chanceOfRain,
                      progressPercent:
                          int.tryParse(_chanceOfRain.replaceAll('%', '')) !=
                              null
                          ? int.parse(_chanceOfRain.replaceAll('%', '')) / 100
                          : 0,
                      progressColor: AppColors.error,
                    ),
                    const SizedBox(height: 12),


                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
    String? unit,
    double? progressPercent,
    Color? progressColor,
    bool showDirection = false,
  }) {
    return PixelContainer(
      borderColor: AppColors.onSecondaryFixed,
      borderWidth: 3,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  border: Border.all(
                    color: AppColors.onSecondaryFixed,
                    width: 2,
                  ),
                ),
                child: Icon(icon, color: AppColors.onSecondaryFixed, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.silkscreen(
                  fontSize: 24,
                  color: AppColors.onSurface,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (progressPercent != null && progressPercent >= 0) ...[
            const SizedBox(height: 12),
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                border: Border.all(color: AppColors.onSecondaryFixed, width: 2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercent.clamp(0.0, 1.0),
                child: Container(color: progressColor ?? AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
