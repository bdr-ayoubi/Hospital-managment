import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1. شاشة عرض قائمة الموظفين
// ==========================================
class StaffListScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const StaffListScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('موظفو $departmentName'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId)
            .collection('Staff') // مجلد الموظفين
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('لا يوجد موظفون مسجلون في $departmentName'),
            );
          }

          final staff = snapshot.data!.docs;

          return ListView.builder(
            itemCount: staff.length,
            itemBuilder: (context, index) {
              var doc = staff[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.badge, color: Colors.white),
                  ),
                  title: Text(
                    data['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'الدور: ${data['role']} \nالمناوبة: ${data['shift']}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('Departments')
                        .doc(departmentId)
                        .collection('Staff')
                        .doc(doc.id)
                        .delete(),
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
            builder: (context) => AddStaffScreen(departmentId: departmentId),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة موظف'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==========================================
// 2. شاشة إضافة موظف جديد
// ==========================================
class AddStaffScreen extends StatefulWidget {
  final String departmentId;
  const AddStaffScreen({super.key, required this.departmentId});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedRole = 'ممرض/ة';
  String _selectedShift = 'صباحي';
  bool _isLoading = false;

  final List<String> _roles = [
    'ممرض/ة',
    'فني/ة',
    'إداري/ة',
    'سكرتاريا',
    'خدمات عامة',
  ];
  final List<String> _shifts = ['صباحي', 'مسائي', 'ليلي'];

  Future<void> _saveStaff() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Staff')
            .add({
              'name': _nameController.text.trim(),
              'role': _selectedRole,
              'shift': _selectedShift,
              'createdAt': FieldValue.serverTimestamp(),
            });
        setState(() => _isLoading = false);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة موظف جديد'),
        backgroundColor: Colors.blueGrey,
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
                  labelText: 'اسم الموظف الكامل',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الوظيفة / الدور',
                  border: OutlineInputBorder(),
                ),
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedShift,
                decoration: const InputDecoration(
                  labelText: 'المناوبة',
                  border: OutlineInputBorder(),
                ),
                items: _shifts
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedShift = v!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveStaff,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ البيانات'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
