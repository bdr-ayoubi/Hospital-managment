// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ستحتاج لإضافة حزمة intl في pubspec.yaml لاحقاً لتنسيق التاريخ

// ==========================================
// 1. شاشة إضافة موعد جديد
// ==========================================
class AddAppointmentScreen extends StatefulWidget {
  final String departmentId;

  const AddAppointmentScreen({super.key, required this.departmentId});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedPatientName;
  String? _selectedDoctorName;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  // دالة لاختيار التاريخ
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // لا يمكن حجز موعد في الماضي
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // دالة لاختيار الوقت
  Future<void> _pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // دالة حفظ الموعد
  Future<void> _saveAppointment() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      setState(() => _isLoading = true);
      try {
        // دمج التاريخ والوقت في متغير واحد
        final appointmentDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );

        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Appointments') // إنشاء مجلد المواعيد
            .add({
              'patientId': _selectedPatientId,
              'patientName': _selectedPatientName,
              'doctorName': _selectedDoctorName,
              'appointmentDate': appointmentDateTime,
              'notes': _notesController.text.trim(),
              'status': 'قادم', // حالة الموعد الافتراضية
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حجز الموعد بنجاح!')));
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
        title: const Text('حجز موعد جديد'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. قائمة اختيار المريض
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
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['patientName']),
                        onTap: () => _selectedPatientName =
                            doc['patientName'], // نحفظ الاسم أيضاً
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedPatientId = val),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. قائمة اختيار الطبيب
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
                      labelText: 'اختر الطبيب',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.medical_services),
                    ),
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc['name'],
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDoctorName = val),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  );
                },
              ),
              const SizedBox(height: 24),

              // 3. أزرار التاريخ والوقت
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _selectedDate == null
                            ? 'اختر التاريخ'
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
                            ? 'اختر الوقت'
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. ملاحظات إضافية
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات حول الموعد (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // زر الحفظ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveAppointment,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تأكيد الحجز', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. شاشة عرض قائمة المواعيد
// ==========================================
class AppointmentsListScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const AppointmentsListScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المواعيد - $departmentName'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId)
            .collection('Appointments')
            .orderBy('appointmentDate') // ترتيب حسب الأقرب
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا توجد مواعيد في $departmentName'));
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              var doc = appointments[index];
              var data = doc.data() as Map<String, dynamic>;

              // تحويل التوقيت من فايربيس إلى توقيت فلاتر
              DateTime date = (data['appointmentDate'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.event, color: Colors.white),
                  ),
                  title: Text(
                    'المريض: ${data['patientName']} | الطبيب: ${data['doctorName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'التاريخ: ${date.year}-${date.month}-${date.day} \nالوقت: ${date.hour}:${date.minute}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(
                      data['status'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
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
            builder: (context) =>
                AddAppointmentScreen(departmentId: departmentId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('حجز موعد'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
