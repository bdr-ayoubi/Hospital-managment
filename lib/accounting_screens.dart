import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==========================================
// 1. شاشة عرض قائمة الفواتير (المحاسبة)
// ==========================================
class AccountingListScreen extends StatelessWidget {
  final String departmentId;
  final String departmentName;

  const AccountingListScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  // تحديد لون الفاتورة حسب حالة الدفع
  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'مدفوعة بالكامل':
        return Colors.green;
      case 'غير مدفوعة':
        return Colors.red;
      case 'دفعة جزئية':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المحاسبة - $departmentName'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId)
            .collection('Invoices') // مجلد الفواتير
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('لا توجد فواتير مسجلة في $departmentName'),
            );
          }

          final invoices = snapshot.data!.docs;

          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              var doc = invoices[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.receipt_long, color: Colors.green[800]),
                  ),
                  title: Text(
                    data['patientName'] ?? 'غير معروف',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'الخدمة: ${data['serviceDescription']} \nالتاريخ: ${(data['createdAt'] as Timestamp).toDate().toString().substring(0, 10)}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${data['amount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['status'],
                        style: TextStyle(
                          color: _getPaymentStatusColor(data['status']),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
            builder: (context) => AddInvoiceScreen(departmentId: departmentId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('إصدار فاتورة'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ==========================================
// 2. شاشة إصدار فاتورة جديدة (الفورم)
// ==========================================
class AddInvoiceScreen extends StatefulWidget {
  final String departmentId;

  const AddInvoiceScreen({super.key, required this.departmentId});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPatientId;
  String? _selectedPatientName;
  String _paymentStatus = 'غير مدفوعة'; // الحالة الافتراضية

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'غير مدفوعة',
    'دفعة جزئية',
    'مدفوعة بالكامل',
  ];

  Future<void> _saveInvoice() async {
    if (_formKey.currentState!.validate() && _selectedPatientId != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('Departments')
            .doc(widget.departmentId)
            .collection('Invoices')
            .add({
              'patientId': _selectedPatientId,
              'patientName': _selectedPatientName,
              'amount':
                  double.tryParse(_amountController.text.trim()) ??
                  0.0, // تحويل النص إلى رقم عشري
              'serviceDescription': _serviceController.text.trim(),
              'status': _paymentStatus,
              'createdAt': FieldValue.serverTimestamp(),
            });

        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إصدار الفاتورة بنجاح!')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إكمال جميع البيانات واختيار المريض'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إصدار فاتورة جديدة'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // اختيار المريض (لربط الفاتورة بملفه)
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

              // وصف الخدمة
              TextFormField(
                controller: _serviceController,
                // --- هذان السطران لدعم اللغة العربية ---
                textDirection: TextDirection.rtl, // اتجاه الكتابة من اليمين
                textAlign: TextAlign.right, // محاذاة النص لليمين
                decoration: const InputDecoration(
                  labelText: 'وصف الخدمة (مثال: كشفية، صورة أشعة، تحاليل)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ), // لوحة مفاتيح للأرقام
                decoration: const InputDecoration(
                  labelText: 'المبلغ الإجمالي',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // حالة الدفع
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'حالة الدفع',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items: _statusOptions
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _paymentStatus = val!),
              ),
              const SizedBox(height: 30),

              // زر الحفظ
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _isLoading ? null : _saveInvoice,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ وإصدار الفاتورة',
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
