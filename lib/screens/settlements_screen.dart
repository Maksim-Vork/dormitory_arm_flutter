import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/settlement.dart';
import '../models/student.dart';
import '../models/room.dart';
import '../services/database_service.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  List<Settlement> _settlements = [];
  List<Student> _students = [];
  List<Room> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final settlements = await DatabaseService.getAllSettlements();
      final students = await DatabaseService.getAllStudents();
      final rooms = await DatabaseService.getAllRooms();

      setState(() {
        _settlements = settlements;
        _students = students;
        _rooms = rooms;
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

  Future<void> _showSettlementDialog({Settlement? settlement}) async {
    final selectedStudent = settlement?.studentId;
    final selectedRoom = settlement?.roomId;
    final startDateController = TextEditingController(
      text: settlement != null
          ? DateFormat('yyyy-MM-dd').format(settlement.startDate)
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final endDate = settlement?.endDate;
    final endDateController = TextEditingController(
      text: endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : '',
    );

    Student? currentStudent = _students.isNotEmpty && selectedStudent != null
        ? _students.firstWhere((s) => s.id == selectedStudent)
        : null;
    Room? currentRoom = _rooms.isNotEmpty && selectedRoom != null
        ? _rooms.firstWhere((r) => r.id == selectedRoom)
        : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            settlement == null
                ? 'Добавить заселение'
                : 'Редактировать заселение',
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
                      child: Text(student.fullName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      currentStudent = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Room>(
                  initialValue: currentRoom,
                  decoration: const InputDecoration(
                    labelText: 'Комната',
                    border: OutlineInputBorder(),
                  ),
                  items: _rooms.map((room) {
                    return DropdownMenuItem(
                      value: room,
                      child: Text('${room.number} (${room.capacity} чел.)'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      currentRoom = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Дата заселения',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: settlement?.startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      startDateController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Дата выселения (опционально)',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                    hintText: 'Оставьте пустым для активного заселения',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: settlement?.endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      endDateController.text = DateFormat(
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

    if (result == true && currentStudent != null && currentRoom != null) {
      try {
        final studentId = currentStudent?.id;
        final roomId = currentRoom?.id;
        if (studentId == null || roomId == null) return;

        final newSettlement = Settlement(
          id: settlement?.id,
          studentId: studentId,
          roomId: roomId,
          startDate: DateFormat('yyyy-MM-dd').parse(startDateController.text),
          endDate: endDateController.text.isNotEmpty
              ? DateFormat('yyyy-MM-dd').parse(endDateController.text)
              : null,
        );

        if (settlement == null) {
          await DatabaseService.insertSettlement(newSettlement);
        } else {
          await DatabaseService.updateSettlement(newSettlement);
        }

        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                settlement == null
                    ? 'Заселение добавлено'
                    : 'Заселение обновлено',
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

  Future<void> _deleteSettlement(Settlement settlement) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: const Text('Удалить это заселение?'),
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
        await DatabaseService.deleteSettlement(settlement.id!);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Заселение удалено')));
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

  String _getRoomNumber(int roomId) {
    final room = _rooms.where((r) => r.id == roomId).firstOrNull;
    return room?.number ?? 'Неизвестная комната';
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
                'Заселения',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2d3748),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showSettlementDialog,
                icon: const Icon(Icons.add),
                label: const Text('Добавить заселение'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
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
                  itemCount: _settlements.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final settlement = _settlements[index];
                    final isActive =
                        settlement.endDate == null ||
                        settlement.endDate!.isAfter(DateTime.now());

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isActive ? Colors.green : Colors.grey,
                        child: Icon(
                          isActive ? Icons.bed : Icons.bed_outlined,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        _getStudentName(settlement.studentId),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Комната: ${_getRoomNumber(settlement.roomId)}'),
                          Text(
                            'Заселение: ${DateFormat('dd.MM.yyyy').format(settlement.startDate)}',
                          ),
                          if (settlement.endDate != null)
                            Text(
                              'Выселение: ${DateFormat('dd.MM.yyyy').format(settlement.endDate!)}',
                            )
                          else
                            const Text(
                              'Активное заселение',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _showSettlementDialog(settlement: settlement),
                            icon: const Icon(Icons.edit, color: Colors.blue),
                          ),
                          IconButton(
                            onPressed: () => _deleteSettlement(settlement),
                            icon: const Icon(Icons.delete, color: Colors.red),
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
