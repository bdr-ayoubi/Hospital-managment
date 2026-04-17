import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1. شاشة عرض قائمة الاستقبالات (الزيارات الحالية)
// ==========================================
class ReceptionsListScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const ReceptionsListScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  // دالة لتحديد لون البطاقة حسب درجة الخطورة
  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'إسعاف (حالة حرجة)':
        return Colors.red[100]!;
      case 'مستعجل':
        return Colors.orange[100]!;
      default:
        return Colors.white; // طبيعي
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الاستقبال - $departmentName'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId)
            .collection('Receptions') // مجلد الاستقبالات
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('لا يوجد مرضى في قاعة الانتظار'));
          }

          final receptions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: receptions.length,
            itemBuilder: (context, index) {
              var doc = receptions[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                color: _getUrgencyColor(data['urgency'] ?? 'طبيعي'),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.how_to_reg, color: Colors.white),
                  ),
                  title: Text(
                    data['patientName'] ?? 'غير معروف',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'السبب: ${data['reason']} \nالخطورة: ${data['urgency']}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(
                    label: Text(
                      data['status'],
                      style: const TextStyle(fontSize: 12),
                    ),
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
                AddReceptionScreen(departmentId: departmentId),
          ),
        ),
        icon: const Icon(Icons.add_task),
        label: const Text('تسجيل دخول مريض'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==========================================
// 2. شاشة تسجيل زيارة جديدة (فورم الاستقبال)
// ==========================================
class AddReceptionScreen extends StatefulWidget {
  final String departmentId;

  const AddReceptionScreen({super.key, required this.departmentId});

  @override
  State<AddReceptionScreen> createState() => _AddReceptionScreenState();
}

class _AddReceptionScreenState extends State<AddReceptionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedPatientName;
  String _selectedUrgency = 'عادي (مراجعة)'; // القيمة الافتراضية

  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _urgencyLevels = [
    'عادي (مراجعة)',
    'مستعجل',
    'إسعاف (حالة حرجة)',
  ];

  Future<void> _saveReception() async {
    if (_formKey.currentState!.validate() && _selectedPatientId != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Receptions')
            .add({
              'patientId': _selectedPatientId,
              'patientName': _selectedPatientName,
              'reason': _reasonController.text.trim(),
              'urgency': _selectedUrgency,
              'status': 'في الانتظار', // المريض يمر بمرحلة الانتظار أولاً
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل دخول المريض بنجاح!')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المريض وإكمال البيانات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دخول مريض'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 1. اختيار المريض من القائمة
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
                      labelText: 'اختر المريض (يجب أن يكون مسجلاً مسبقاً)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: snapshot.data!.docs.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['patientName']),
                        onTap: () => _selectedPatientName = doc['patientName'],
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedPatientId = val),
                    validator: (v) => v == null ? 'مطلوب' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. سبب الزيارة
              TextFormField(
                controller: _reasonController,
                // --- هذان السطران لدعم اللغة العربية ---
                textDirection: TextDirection.rtl, // اتجاه الكتابة من اليمين
                textAlign: TextAlign.right, // محاذاة النص لليمين
                decoration: const InputDecoration(
                  labelText: 'سبب الزيارة / الشكوى',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // 3. درجة الخطورة
              DropdownButtonFormField<String>(
                initialValue: _selectedUrgency,
                decoration: const InputDecoration(
                  labelText: 'درجة الخطورة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning),
                ),
                items: _urgencyLevels.map((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedUrgency = val!),
              ),
              const SizedBox(height: 30),

              // 4. زر الحفظ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveReception,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'تسجيل الدخول للقسم',
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
