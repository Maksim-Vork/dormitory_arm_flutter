import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../services/database_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> _payments = [];
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final payments = await DatabaseService.getAllPayments();
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

  Future<void> _showPaymentDialog({Payment? payment}) async {
    final selectedStudent = payment?.studentId;
    final amountController = TextEditingController(
      text: payment?.amount.toString() ?? '',
    );
    final paidAtController = TextEditingController(
      text: payment != null
          ? DateFormat('yyyy-MM-dd').format(payment.paidAt)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    Student? currentStudent = _students.isNotEmpty && selectedStudent != null
        ? _students.firstWhere((s) => s.id == selectedStudent)
        : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            payment == null ? 'Добавить платеж' : 'Редактировать платеж',
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Student>(
                  initialValue: currentStudent,
                  decoration: const InputDecoration(
                    labelText: 'Студент',
                    border: OutlineInputBorder(),
                  ),
                  items: _students.map((student) {
                    return DropdownMenuItem(
                      value: student,
                      child: Text('${student.fullName} (${student.group})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      currentStudent = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Сумма',
                    border: OutlineInputBorder(),
                    prefixText: '₽ ',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: paidAtController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Дата оплаты',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: payment?.paidAt ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      paidAtController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );

    if (result == true && currentStudent != null) {
      try {
        final studentId = currentStudent?.id;
        if (studentId == null) return;

        final amount = double.tryParse(amountController.text);
        if (amount == null || amount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Введите корректную сумму')),
            );
          }
          return;
        }

        final newPayment = Payment(
          id: payment?.id,
          studentId: studentId,
          amount: amount,
          paidAt: DateFormat('yyyy-MM-dd').parse(paidAtController.text),
        );

        if (payment == null) {
          await DatabaseService.insertPayment(newPayment);
        } else {
          await DatabaseService.updatePayment(newPayment);
        }

        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                payment == null ? 'Платеж добавлен' : 'Платеж обновлен',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
        }
      }
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Удалить платеж от ${DateFormat('dd.MM.yyyy').format(payment.paidAt)}?',
        ),
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
        await DatabaseService.deletePayment(payment.id!);
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

  String _getStudentName(int studentId) {
    final student = _students.where((s) => s.id == studentId).firstOrNull;
    return student?.fullName ?? 'Неизвестный студент';
  }

  String _getStudentGroup(int studentId) {
    final student = _students.where((s) => s.id == studentId).firstOrNull;
    return student?.group ?? '';
  }

  double _getTotalAmount() {
    return _payments.fold(0.0, (sum, payment) => sum + payment.amount);
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
                'Платежи',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2d3748),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить платеж'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667eea).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Color(0xFF667eea), size: 32),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Общая сумма платежей',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    Text(
                      '₽ ${_getTotalAmount().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF667eea),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                        backgroundColor: Colors.green,
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        _getStudentName(payment.studentId),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Группа: ${_getStudentGroup(payment.studentId)}',
                          ),
                          Text(
                            'Дата оплаты: ${DateFormat('dd.MM.yyyy').format(payment.paidAt)}',
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
                                '₽${payment.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _showPaymentDialog(payment: payment),
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deletePayment(payment),
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ],
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
