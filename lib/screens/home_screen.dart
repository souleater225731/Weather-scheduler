import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'package:test1/screens/profile_page.dart' as profile;
import 'package:test1/screens/planner_page.dart' as planner;
import 'forecast_page.dart';
import 'clothing_page.dart';
import 'moodcast_page.dart';
import 'settings_page.dart';
import 'feedback_page.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleDarkMode;
  final MaterialColor themeColor;
  final Function(MaterialColor) changeThemeColor;
  final User? user;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.themeColor,
    required this.changeThemeColor,
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final weatherService = WeatherService();
  final double lat = 14.5995;
  final double lon = 120.9842;

  Map<String, dynamic>? currentWeather;
  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> dailyForecast = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    final current = await weatherService.getCurrentWeather(lat, lon);
    final hourly = await weatherService.getNext24HourForecast(lat, lon);
    final daily = await weatherService.get5DayForecast(lat, lon);

    setState(() {
      currentWeather = current;
      hourlyForecast = hourly;
      dailyForecast = daily;
      isLoading = false;
    });
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'rainy':
        return Icons.umbrella;
      case 'cloudy':
        return Icons.cloud;
      case 'stormy':
        return Icons.thunderstorm;
      case 'snowy':
        return Icons.ac_unit;
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      default:
        return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : const Color(0xFFF0FAFF),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const profile.ProfilePage(),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.feedback),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FeedbackPage(user: widget.user),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SettingsPage(
                                    isDarkMode: widget.isDarkMode,
                                    toggleDarkMode: widget.toggleDarkMode,
                                    currentColor: widget.themeColor,
                                    changeThemeColor: widget.changeThemeColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Current Weather
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            _getWeatherIcon(currentWeather!['condition']),
                            size: 80,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "It's ${currentWeather!['condition']}",
                            style: const TextStyle(fontSize: 24),
                          ),
                          Text(
                            '${currentWeather!['temperature']}°C',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Hourly Forecast',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: hourlyForecast.length,
                        itemBuilder: (context, index) {
                          final item = hourlyForecast[index];
                          final time = DateFormat('ha').format(item['time']);
                          final temp = '${item['temp']}°';
                          final icon = _getWeatherIcon(item['condition'].toString());
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(time, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                Icon(icon, size: 28, color: Colors.orange),
                                const SizedBox(height: 8),
                                Text(temp, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Upcoming Weather',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: dailyForecast.map((day) {
                        final date = DateTime.parse(day['date']);
                        final dayName = DateFormat('EEEE').format(date);
                        final temp = '${day['temp']}°';
                        final icon = _getWeatherIcon(day['condition']);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dayName,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text('${day['condition']} • $temp'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Bottom Nav
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navButton(
                            'assets/weather-news.png',
                            'Forecast',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForecastPage()),
                            ),
                          ),
                          _navButton(
                            'assets/weekly.png',
                            'Planner',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const planner.PlannerPage()),
                            ),
                          ),
                          _navButton(
                            'assets/brand.png',
                            'Clothing',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ClothingPage()),
                            ),
                          ),
                          _navButton(
                            'assets/dial.png',
                            'Moodcast',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MoodcastPage()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _navButton(String path, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Image.asset(path, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
