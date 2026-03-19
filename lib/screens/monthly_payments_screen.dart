import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/monthly_payment.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class MonthlyPaymentsScreen extends StatefulWidget {
  const MonthlyPaymentsScreen({super.key});

  @override
  State<MonthlyPaymentsScreen> createState() => _MonthlyPaymentsScreenState();
}

class _MonthlyPaymentsScreenState extends State<MonthlyPaymentsScreen> {
  List<MonthlyPayment> _payments = [];
  List<Student> _students = [];
  bool _isLoading = true;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final payments = await DatabaseService.getMonthlyPaymentsByMonth(
        _selectedMonth,
      );
      final students = await DatabaseService.getAllStudents();

      setState(() {
        _payments = payments;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
      }
    }
  }

  String _getStudentName(int studentId) {
    final student = _students.where((s) => s.id == studentId).firstOrNull;
    return student?.fullName ?? 'Неизвестный студент';
  }

  String _getStudentGroup(int studentId) {
    final student = _students.where((s) => s.id == studentId).firstOrNull;
    return student?.group ?? '';
  }

  Color _getPaymentStatusColor(bool isPaid) {
    return isPaid ? Colors.green : Colors.red;
  }

  String _getPaymentStatusText(bool isPaid) {
    return isPaid ? 'Оплачено' : 'Не оплачено';
  }

  Future<void> _togglePaymentStatus(MonthlyPayment payment) async {
    try {
      if (payment.isPaid) {
        // Отменить оплату
        await DatabaseService.updateMonthlyPayment(
          payment.copyWith(isPaid: false, updatedAt: DateTime.now()),
        );
      } else {
        // Отметить как оплаченное
        await DatabaseService.markMonthlyPaymentAsPaid(payment.id!);
      }
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Статус платежа обновлен')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления статуса: $e')),
        );
      }
    }
  }

  Future<void> _deletePayment(MonthlyPayment payment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Удалить платеж $payment.description?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await DatabaseService.deleteMonthlyPayment(payment.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Платеж удален')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
        }
      }
    }
  }

  double _getTotalAmount() {
    return _payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _getPaidAmount() {
    return _payments
        .where((payment) => payment.isPaid)
        .fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double _getUnpaidAmount() {
    return _getTotalAmount() - _getPaidAmount();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ежемесячные платежи',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2d3748),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  underline: const SizedBox(),
                  items: List.generate(6, (index) {
                    final date = DateTime.now().subtract(
                      Duration(days: 30 * index),
                    );
                    final month = DateFormat('yyyy-MM').format(date);
                    final displayMonth = DateFormat(
                      'MMMM yyyy',
                      'ru',
                    ).format(date);
                    return DropdownMenuItem(
                      value: month,
                      child: Text(displayMonth),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMonth = value;
                        _isLoading = true;
                      });
                      _loadData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics cards
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Общая сумма',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getTotalAmount().toStringAsFixed(2)} руб.',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.green.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Оплачено',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getPaidAmount().toStringAsFixed(2)} руб.',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  color: Colors.red.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'К оплате',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getUnpaidAmount().toStringAsFixed(2)} руб.',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView.separated(
                  itemCount: _payments.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final payment = _payments[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getPaymentStatusColor(payment.isPaid),
                        child: Icon(
                          payment.isPaid ? Icons.check : Icons.payment,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        payment.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Студент: ${_getStudentName(payment.studentId)}',
                          ),
                          Text(
                            'Группа: ${_getStudentGroup(payment.studentId)}',
                          ),
                          Text(
                            'Mесяц: ${DateFormat('MMMM yyyy', 'ru').format(DateTime.parse('${payment.month}-01'))}',
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${payment.amount.toStringAsFixed(2)} руб.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPaymentStatusColor(payment.isPaid),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getPaymentStatusText(payment.isPaid),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'toggle') {
                                _togglePaymentStatus(payment);
                              } else if (value == 'delete') {
                                _deletePayment(payment);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Row(
                                  children: [
                                    Icon(
                                      payment.isPaid
                                          ? Icons.close
                                          : Icons.check,
                                      color: payment.isPaid
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      payment.isPaid
                                          ? 'Отметить неоплаченным'
                                          : 'Отметить оплаченным',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Удалить'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
