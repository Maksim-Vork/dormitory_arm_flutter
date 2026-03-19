import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/monthly_payment.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<MonthlyPayment> _currentMonthPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      debugPrint('Загрузка статистики...');
      final stats = await DatabaseService.getStatistics();
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      debugPrint('Загрузка платежей за месяц: $currentMonth');
      final payments = await DatabaseService.getMonthlyPaymentsByMonth(
        currentMonth,
      );

      debugPrint('Статистика: $stats');
      debugPrint('Платежи: ${payments.length}');

      setState(() {
        _stats = stats;
        _currentMonthPayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки статистики: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки статистики: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Панель управления',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2d3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Общая статистика общежития',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_stats['total_students'] == 0 && _stats['total_rooms'] == 0)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Нет данных',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте студентов, комнаты и заселения\nчтобы увидеть статистику',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadStatistics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Текущие платежи за месяц
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea),
                          const Color(0xFF764ba2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Платежи за ${DateFormat('MMMM', 'ru').format(DateTime.now())}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Текущий месяц',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPaymentStat(
                              'Общая сумма',
                              '${_getTotalPayments().toStringAsFixed(0)} руб.',
                              Icons.wallet,
                            ),
                            _buildPaymentStat(
                              'Оплачено',
                              '${_getPaidPayments().toStringAsFixed(0)} руб.',
                              Icons.check_circle,
                            ),
                            _buildPaymentStat(
                              'К оплате',
                              '${_getUnpaidPayments().toStringAsFixed(0)} руб.',
                              Icons.pending,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Общая статистика
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          '👤 Студенты',
                          '${_stats['total_students'] ?? 0}',
                          'Всего студентов',
                          Colors.blue,
                          Icons.person,
                        ),
                        _buildStatCard(
                          '🏠 Комнаты',
                          '${_stats['total_rooms'] ?? 0}',
                          'Всего комнат',
                          Colors.green,
                          Icons.meeting_room,
                        ),
                        _buildStatCard(
                          '🛏 Заселения',
                          '${_stats['active_settlements'] ?? 0}',
                          'Активных заселений',
                          Colors.orange,
                          Icons.bed,
                        ),
                        _buildStatCard(
                          '🧺 Стирка',
                          '${_stats['total_laundry'] ?? 0}',
                          'Всего стирок',
                          Colors.purple,
                          Icons.local_laundry_service,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double _getTotalPayments() {
    return _currentMonthPayments.fold(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
  }

  double _getPaidPayments() {
    return _currentMonthPayments
        .where((payment) => payment.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _getUnpaidPayments() {
    return _getTotalPayments() - _getPaidPayments();
  }

  Widget _buildPaymentStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
