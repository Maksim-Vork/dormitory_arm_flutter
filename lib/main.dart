import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/students_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/settlements_screen.dart';
import 'screens/laundry_screen.dart';
import 'screens/monthly_payments_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('=== ЗАПУСК ПРИЛОЖЕНИЯ ===');
  debugPrint('Инициализация локализации...');
  await initializeDateFormatting('ru_RU');
  debugPrint('Локализация инициализирована');

  debugPrint('Инициализация базы данных...');
  try {
    await DatabaseService.database;
    debugPrint('База данных успешно инициализирована');
  } catch (e) {
    debugPrint('ОШИБКА инициализации базы данных: $e');
    rethrow;
  }

  debugPrint('Запуск приложения...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'АРМ Общежития Колледжа',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const StudentsScreen(),
    const RoomsScreen(),
    const SettlementsScreen(),
    const LaundryScreen(),
    const MonthlyPaymentsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      'Панель управления',
      Icons.dashboard_outlined,
      Icons.dashboard,
    ),
    NavigationItem('Студенты', Icons.person_outline, Icons.person),
    NavigationItem('Комнаты', Icons.meeting_room_outlined, Icons.meeting_room),
    NavigationItem('Заселение', Icons.bed_outlined, Icons.bed),
    NavigationItem(
      'Стирка',
      Icons.local_laundry_service_outlined,
      Icons.local_laundry_service,
    ),
    NavigationItem(
      'Платежи',
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.apartment, size: 28),
            const SizedBox(width: 12),
            Text(
              '🏢 АРМ Общежития Колледжа',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
      ),
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 24),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Material(
                    color: isSelected
                        ? const Color(0xFF667eea).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? const Color(0xFF667eea)
                                  : Colors.grey[600],
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF667eea)
                                      : Colors.grey[700],
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  NavigationItem(this.title, this.icon, this.selectedIcon);
}
