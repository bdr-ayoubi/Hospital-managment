// ignore_for_file: deprecated_member_use, use_build_context_synchronously, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 4. شاشة إضافة مريض جديد (Form)
// ==========================================
class AddPatientScreen extends StatefulWidget {
  final String departmentId; // لمعرفة أي قسم سنضيف المريض إليه

  const AddPatientScreen({
    super.key,
    required this.departmentId,
    required String patientId,
  });

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  // مفتاح للتحقق من صحة البيانات (Validation)
  final _formKey = GlobalKey<FormState>();

  // أدوات التقاط النصوص من المربعات
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  //final TextEditingController _doctorController = TextEditingController();
  String? _selectedDoctor; // لتخزين اسم الطبيب المختار

  bool _isLoading = false; // للتحكم في ظهور دائرة التحميل

  // دالة الحفظ في فايربيس
  Future<void> _savePatient() async {
    // التأكد من أن المستخدم كتب في جميع الحقول الإجبارية
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // إظهار دائرة التحميل

      try {
        // إرسال البيانات المكتوبة إلى فايربيس
        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Patients')
            .add({
              'patientName': _nameController.text.trim(),
              'age': int.tryParse(_ageController.text.trim()) ?? 0,
              'status': _statusController.text.trim(),
              'doctor': _selectedDoctor,
              'admissionDate': FieldValue.serverTimestamp(),
            });

        // إخفاء التحميل والعودة للشاشة السابقة بعد النجاح
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت إضافة المريض بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    // تنظيف المتحكمات من الذاكرة عند إغلاق الشاشة (مهم جداً لأداء التطبيق)
    _nameController.dispose();
    _ageController.dispose();
    _statusController.dispose();
    // _doctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة مريض جديد'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // ربط النموذج بالمفتاح
          child: ListView(
            children: [
              // مربع إدخال الاسم
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المريض',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال اسم المريض' : null,
              ),
              const SizedBox(height: 16),

              // مربع إدخال العمر
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'العمر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال العمر' : null,
              ),
              const SizedBox(height: 16),

              // مربع إدخال الحالة الطبية
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'الحالة الطبية (مثال: مستقر، إسعاف، مراجعة)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال الحالة الطبية' : null,
              ),
              const SizedBox(height: 16),

              // مربع إدخال اسم الطبيب
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Departments')
                    .doc(widget.departmentId)
                    .collection('Doctors')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  // تحويل بيانات الأطباء إلى قائمة من العناصر
                  var doctorsItems = snapshot.data!.docs.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc['name'], // القيمة التي ستخزن
                      child: Text(doc['name']), // النص الذي سيظهر
                    );
                  }).toList();

                  return DropdownButtonFormField<String>(
                    value: _selectedDoctor,
                    decoration: const InputDecoration(
                      labelText: 'اختر الدكتور المشرف',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_search),
                    ),
                    items: doctorsItems,
                    onChanged: (value) {
                      setState(() {
                        _selectedDoctor = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'الرجاء اختيار دكتور' : null,
                  );
                },
              ),
              const SizedBox(height: 30),

              // زر الحفظ
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _savePatient,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ بيانات المريض',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. شاشة تعديل بيانات المريض (Update)
// ==========================================
class EditPatientScreen extends StatefulWidget {
  final String departmentId; // اسم القسم
  final String patientId; // المعرف الفريد للمريض في فايربيس
  final Map<String, dynamic> currentData; // البيانات الحالية للمريض

  const EditPatientScreen({
    super.key,
    required this.departmentId,
    required this.patientId,
    required this.currentData,
  });

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _statusController;
  late TextEditingController _doctorController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // السحر يبدأ هنا: نملأ المتحكمات بالبيانات الحالية للمريض فور فتح الشاشة
    _nameController = TextEditingController(
      text: widget.currentData['patientName'],
    );
    _ageController = TextEditingController(
      text: widget.currentData['age']?.toString(),
    );
    _statusController = TextEditingController(
      text: widget.currentData['status'],
    );
    _doctorController = TextEditingController(
      text: widget.currentData['doctor'],
    );
  }

  // دالة تحديث البيانات في فايربيس
  Future<void> _updatePatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // بدلاً من add نستخدم update لتعديل الملف الموجود فقط
        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Patients')
            .doc(widget.patientId) // تحديد أي مريض سنعدل
            .update({
              'patientName': _nameController.text.trim(),
              'age': int.tryParse(_ageController.text.trim()) ?? 0,
              'status': _statusController.text.trim(),
              'doctor': _doctorController.text.trim(),
              // ملاحظة: لا نعدل تاريخ الدخول admissionDate ليبقى كما هو
            });

        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعديل البيانات بنجاح!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _statusController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل بيانات المريض'),
        backgroundColor:
            Colors.blue[700], // لون مختلف لتمييز التعديل عن الإضافة
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المريض',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال اسم المريض' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'العمر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال العمر' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'الحالة الطبية',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال الحالة' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _doctorController,
                // --- هذان السطران لدعم اللغة العربية ---
                textDirection: TextDirection.rtl, // اتجاه الكتابة من اليمين
                textAlign: TextAlign.right, // محاذاة النص لليمين
                decoration: const InputDecoration(
                  labelText: 'الطبيب المشرف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_hospital),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال الطبيب' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _updatePatient,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تحديث البيانات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
