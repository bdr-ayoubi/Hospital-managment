//العملبات
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1. شاشة عرض قائمة العمليات الجراحية
// ==========================================
class SurgeriesListScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const SurgeriesListScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مجدولة':
        return Colors.blue;
      case 'قيد الإجراء':
        return Colors.orange;
      case 'تمت بنجاح':
        return Colors.green;
      case 'ملغاة':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('العمليات - $departmentName'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId)
            .collection('Surgeries') // مجلد العمليات
            .orderBy('surgeryDate') // ترتيب حسب الأقرب
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('لا توجد عمليات مجدولة في $departmentName'),
            );
          }

          final surgeries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: surgeries.length,
            itemBuilder: (context, index) {
              var doc = surgeries[index];
              var data = doc.data() as Map<String, dynamic>;
              DateTime date = (data['surgeryDate'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[800],
                    child: const Icon(Icons.masks, color: Colors.white),
                  ),
                  title: Text(
                    'عملية: ${data['surgeryName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'المريض: ${data['patientName']} \nالجراح: ${data['doctorName']} \nالغرفة: ${data['room']} | الموعد: ${date.year}-${date.month}-${date.day}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(
                      data['status'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(data['status']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddSurgeryScreen(departmentId: departmentId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('جدولة عملية'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==========================================
// 2. شاشة جدولة عملية جديدة (الفورم)
// ==========================================
class AddSurgeryScreen extends StatefulWidget {
  final String departmentId;

  const AddSurgeryScreen({super.key, required this.departmentId});

  @override
  State<AddSurgeryScreen> createState() => _AddSurgeryScreenState();
}

class _AddSurgeryScreenState extends State<AddSurgeryScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedDoctorName;
  String? _selectedRoom;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _surgeryNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final List<String> _rooms = [
    'غرفة العمليات الكبرى 1',
    'غرفة العمليات الكبرى 2',
    'غرفة العمليات الصغرى',
    'غرفة العناية المركزة',
  ];

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveSurgery() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      setState(() => _isLoading = true);
      try {
        final surgeryDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Surgeries')
            .add({
              'surgeryName': _surgeryNameController.text.trim(),
              'patientId': _selectedPatientId,
              'patientName': _selectedPatientName,
              'doctorName': _selectedDoctorName,
              'room': _selectedRoom,
              'surgeryDate': surgeryDateTime,
              'notes': _notesController.text.trim(),
              'status': 'مجدولة', // الحالة الافتراضية
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت جدولة العملية بنجاح!')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إكمال جميع البيانات والتاريخ والوقت'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدولة عملية جديدة'),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // اسم العملية
              TextFormField(
                controller: _surgeryNameController,
                // --- هذان السطران لدعم اللغة العربية ---
                textDirection: TextDirection.rtl, // اتجاه الكتابة من اليمين
                textAlign: TextAlign.right, // محاذاة النص لليمين
                decoration: const InputDecoration(
                  labelText: 'اسم العملية (مثال: استئصال زائدة دودية)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.masks),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // اختيار المريض
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Departments')
                    .doc(widget.departmentId)
                    .collection('Patients')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedPatientId,
                    decoration: const InputDecoration(
                      labelText: 'اختر المريض',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: snapshot.data!.docs
                        .map(
                          (doc) => DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(doc['patientName']),
                            onTap: () =>
                                _selectedPatientName = doc['patientName'],
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedPatientId = val),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // اختيار الجراح
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Departments')
                    .doc(widget.departmentId)
                    .collection('Doctors')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedDoctorName,
                    decoration: const InputDecoration(
                      labelText: 'اختر الجراح',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    items: snapshot.data!.docs
                        .map(
                          (doc) => DropdownMenuItem<String>(
                            value: doc['name'],
                            child: Text(doc['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDoctorName = val),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // اختيار الغرفة
              DropdownButtonFormField<String>(
                initialValue: _selectedRoom,
                decoration: const InputDecoration(
                  labelText: 'غرفة العمليات',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
                items: _rooms
                    .map(
                      (room) => DropdownMenuItem<String>(
                        value: room,
                        child: Text(room),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedRoom = val),
                validator: (v) => v == null ? 'مطلوب' : null,
              ),
              const SizedBox(height: 24),

              // التواريخ والأوقات
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _selectedDate == null
                            ? 'تاريخ العملية'
                            : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime == null
                            ? 'وقت العملية'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // زر الحفظ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveSurgery,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'جدولة العملية',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
