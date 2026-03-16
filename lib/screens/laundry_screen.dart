import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/laundry.dart';
import '../models/student.dart';
import '../models/monthly_payment.dart';
import '../services/database_service.dart';

class LaundryScreen extends StatefulWidget {
  const LaundryScreen({super.key});

  @override
  State<LaundryScreen> createState() => _LaundryScreenState();
}

class _LaundryScreenState extends State<LaundryScreen> {
  List<Laundry> _laundry = [];
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final laundry = await DatabaseService.getAllLaundry();
      final students = await DatabaseService.getAllStudents();

      setState(() {
        _laundry = laundry;
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

  Future<void> _showLaundryDialog({Laundry? laundry}) async {
    final selectedStudent = laundry?.studentId;
    final performedAtController = TextEditingController(
      text: laundry != null
          ? DateFormat('yyyy-MM-dd').format(laundry.performedAt)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    Student? currentStudent = _students.isNotEmpty && selectedStudent != null
        ? _students.firstWhere((s) => s.id == selectedStudent)
        : null;
    LaundryType selectedType = laundry?.type ?? LaundryType.washLinen;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            laundry == null ? 'Добавить стирку' : 'Редактировать стирку',
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
                DropdownButtonFormField<LaundryType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Тип стирки',
                    border: OutlineInputBorder(),
                  ),
                  items: LaundryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: performedAtController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Дата выполнения',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: laundry?.performedAt ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      performedAtController.text = DateFormat(
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

        final newLaundry = Laundry(
          id: laundry?.id,
          studentId: studentId,
          type: selectedType,
          performedAt: DateFormat(
            'yyyy-MM-dd',
          ).parse(performedAtController.text),
        );

        if (laundry == null) {
          await DatabaseService.insertLaundry(newLaundry);

          // Добавить ежемесячный платеж для студента
          await _addMonthlyPaymentForLaundry(studentId, selectedType);
        } else {
          // Update functionality would need to be added to DatabaseService
          await DatabaseService.insertLaundry(newLaundry);

          // Добавить ежемесячный платеж для студента
          await _addMonthlyPaymentForLaundry(studentId, selectedType);
        }

        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Стирка добавлена. Платеж ${selectedType.price} руб. добавлен за текущий месяц',
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

  Future<void> _deleteLaundry(Laundry laundry) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Удалить запись о стирке от ${DateFormat('dd.MM.yyyy').format(laundry.performedAt)}?',
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
        await DatabaseService.deleteLaundry(laundry.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Запись о стирке удалена')),
          );
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

  Future<void> _addMonthlyPaymentForLaundry(
    int studentId,
    LaundryType laundryType,
  ) async {
    try {
      final now = DateTime.now();
      final month = DateFormat('yyyy-MM').format(now);
      final description = 'Оплата за стирку: ${laundryType.displayName}';

      // Проверить, существует ли уже такой платеж за этот месяц
      final existingPayment = await DatabaseService.getExistingMonthlyPayment(
        studentId,
        month,
        description,
      );

      if (existingPayment != null) {
        // Если платеж существует, обновить его сумму
        final updatedPayment = existingPayment.copyWith(
          amount: existingPayment.amount + laundryType.price,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.updateMonthlyPayment(updatedPayment);
      } else {
        // Создать новый платеж
        final payment = MonthlyPayment(
          studentId: studentId,
          amount: laundryType.price,
          month: month,
          description: description,
          createdAt: DateTime.now(),
        );
        await DatabaseService.insertMonthlyPayment(payment);
      }
    } catch (e) {
      debugPrint('Ошибка при добавлении ежемесячного платежа: $e');
    }
  }

  Map<LaundryType, int> _getLaundryStats() {
    final stats = <LaundryType, int>{};
    for (final type in LaundryType.values) {
      stats[type] = _laundry.where((l) => l.type == type).length;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _getLaundryStats();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Стирка',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2d3748),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showLaundryDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить стирку'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistics cards
          SizedBox(
            height: 120,
            child: Row(
              children: LaundryType.values.map((type) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Card(
                      color: const Color(0xFF764ba2).withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_laundry_service,
                              color: const Color(0xFF764ba2),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.displayName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stats[type] ?? 0}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF764ba2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                  itemCount: _laundry.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final laundry = _laundry[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF764ba2),
                        child: const Icon(
                          Icons.local_laundry_service,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        _getStudentName(laundry.studentId),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Группа: ${_getStudentGroup(laundry.studentId)}',
                          ),
                          Text('Тип: ${laundry.type.displayName}'),
                          Text(
                            'Дата: ${DateFormat('dd.MM.yyyy').format(laundry.performedAt)}',
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        onPressed: () => _deleteLaundry(laundry),
                        icon: const Icon(Icons.delete, color: Colors.red),
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
