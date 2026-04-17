// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1. شاشة عرض قائمة الأطباء
// ==========================================
class DoctorsListScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const DoctorsListScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  void deleteDoctor(String docId) {
    FirebaseFirestore.instance
        .collection('Departments')
        .doc(departmentId)
        .collection('Doctors') // <-- هنا السحر: مجلد جديد خاص بالأطباء
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الأطباء - $departmentName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId)
            .collection('Doctors') // نقرأ من مجلد الأطباء
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('لا يوجد أطباء مسجلين في $departmentName'),
            );
          }

          final doctors = snapshot.data!.docs;

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              var doc = doctors[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    data['name'] ?? 'بدون اسم',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'التخصص الدقيق: ${data['specialty']}\nرقم الهاتف: ${data['phone']}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteDoctor(doc.id),
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
            builder: (context) => AddDoctorScreen(departmentId: departmentId),
          ),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة طبيب'),
      ),
    );
  }
}

// ==========================================
// 2. شاشة إضافة طبيب جديد
// ==========================================
class AddDoctorScreen extends StatefulWidget {
  final String departmentId;

  const AddDoctorScreen({super.key, required this.departmentId});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveDoctor() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Doctors') // نحفظ في مجلد الأطباء
            .add({
              'name': _nameController.text.trim(),
              'specialty': _specialtyController.text.trim(),
              'phone': _phoneController.text.trim(),
            });
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الطبيب بنجاح!')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة طبيب'),
        backgroundColor: Colors.teal,
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
                // --- هذان السطران لدعم اللغة العربية ---
                textDirection: TextDirection.rtl, // اتجاه الكتابة من اليمين
                textAlign: TextAlign.right, // محاذاة النص لليمين
                decoration: const InputDecoration(
                  labelText: 'اسم الطبيب',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                // --- هذان السطران لدعم اللغة العربية ---
                textDirection: TextDirection.rtl, // اتجاه الكتابة من اليمين
                textAlign: TextAlign.right, // محاذاة النص لليمين
                decoration: const InputDecoration(
                  labelText: 'التخصص الدقيق (مثال: جراحة أطفال)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveDoctor,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
