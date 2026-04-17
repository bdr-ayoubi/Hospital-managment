// ignore_for_file: file_names
// ignore_for_file: Patients_List_Screen

import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Card,
        Center,
        CircleAvatar,
        CircularProgressIndicator,
        Colors,
        ConnectionState,
        EdgeInsets,
        FloatingActionButton,
        FontWeight,
        Icon,
        IconButton,
        Icons,
        ListTile,
        ListView,
        MainAxisSize,
        Row,
        Scaffold,
        StatelessWidget,
        StreamBuilder,
        Text,
        TextStyle,
        Widget,
        MaterialPageRoute;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import 'AddPatientScreen.dart';

class PatientsListScreen extends StatelessWidget {
  // 1. إضافة متغير لاستقبال اسم القسم
  final String departmentName;
  final String departmentId;
  const PatientsListScreen({
    super.key,
    required this.departmentName,
    required this.departmentId,
  });

  // دالة لحذف مريض (Delete)
  void deletePatient(String docId) {
    FirebaseFirestore.instance
        .collection('Departments')
        .doc(departmentName) // استخدام اسم القسم الديناميكي
        .collection('Patients')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة المرضى - $departmentName'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // StreamBuilder هو السحر الذي يراقب التغييرات لحظة بلحظة
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Departments')
            .doc(departmentId) // استخدم ID الإنجليزي هنا
            .collection('Patients')
            .orderBy(
              'admissionDate',
              descending: true,
            ) // ترتيب من الأحدث للأقدم
            .snapshots(),
        builder: (context, snapshot) {
          // 1. حالة التحميل (بينما يجلب البيانات من الإنترنت)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. حالة وجود خطأ
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في جلب البيانات!'));
          }

          // 3. حالة عدم وجود مرضى
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد مرضى مسجلين حالياً.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // 4. حالة النجاح: عرض قائمة المرضى (Read)
          final patients = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              // استخراج بيانات الملف (Document)
              var patientDoc = patients[index];
              var patientData = patientDoc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    patientData['patientName'] ?? 'بدون اسم',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'الحالة: ${patientData['status']} \nالطبيب: ${patientData['doctor']}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زر التعديل (Update) -
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPatientScreen(
                                departmentId: departmentId, // اسم القسم
                                patientId:
                                    patientDoc.id, // رقم الملف في السحابة
                                currentData:
                                    patientData, // نمرر البيانات الحالية لكي تظهر في المربعات
                              ),
                            ),
                          );
                        },
                      ),
                      // زر الحذف (Delete)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deletePatient(patientDoc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // زر الإضافة (Create)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPatientScreen(
                departmentId:
                    departmentId, // تمرير ID القسم لإضافة مريض جديد فيه
                patientId: '',
              ),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مريض'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
