// ignore_for_file: deprecated_member_use
// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // مكتبة فايربيس الأساسية
import 'PatientsListScreen.dart';
import 'doctors_screens.dart';
import 'appointments_screens.dart';
import 'receptions_screens.dart';
import 'surgeries_screens.dart';
import 'accounting_screens.dart';
import 'staff_screens.dart';
import 'firebase_options.dart'; // ملف الإعدادات الذي تم إنشاؤه للتو

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. تشغيل واجهة التطبيق
    runApp(const HospitalApp());
  } catch (e) {
    // التعامل مع أي خطأ في تهيئة Firebase
    debugPrint('خطأ في تهيئة Firebase: $e');
  }
}

class HospitalApp extends StatelessWidget {
  const HospitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نظام إدارة المستشفى',
      theme: ThemeData(
        useMaterial3: true, // تفعيل التصميم العصري لـ Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B), // لون أزرق مخضر طبي
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // لون خلفية هادئ
        fontFamily: 'Cairo', // تأكد من إضافة خطك في pubspec.yaml
      ),
      // ضبط اتجاه النص ليكون من اليمين لليسار (عربي)
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const DepartmentsListScreen(),
    );
  }
}

// ==========================================
// 1. البيانات الثابتة للأقسام والوحدات الإدارية
// ==========================================
class AppData {
  static final List<Map<String, dynamic>> departments = [
    {'id': 'Pediatrics', 'name': 'قسم الأطفال', 'icon': Icons.child_care},
    {
      'id': 'Gastroenterology',
      'name': 'قسم الهضمية',
      'icon': Icons.monitor_weight_outlined,
    },
    {'id': 'Neurology', 'name': 'قسم العصبية', 'icon': Icons.psychology},
    {
      'id': 'InternalMedicine',
      'name': 'قسم الداخلية',
      'icon': Icons.medical_services,
    },
    {'id': 'Hematology', 'name': 'قسم الدموية', 'icon': Icons.bloodtype},
    {'id': 'Obstetrics', 'name': 'قسم الولادة', 'icon': Icons.pregnant_woman},
    {
      'id': 'Radiology',
      'name': 'قسم الأشعة (طبق محوري، رنين، خلع)',
      'icon': Icons.sensors,
    },
    {'id': 'Cardiology', 'name': 'قسم القلبية', 'icon': Icons.favorite},
    {
      'id': 'Ophthalmology',
      'name': 'قسم العينية',
      'icon': Icons.remove_red_eye,
    },
  ];

  static final List<Map<String, dynamic>> managementModules = [
    {'name': 'إدارة الاستقبالات', 'icon': Icons.support_agent},
    {'name': 'إدارة المرضى', 'icon': Icons.sick},
    {'name': 'محاسبة', 'icon': Icons.account_balance_wallet},
    {'name': 'المواعيد', 'icon': Icons.calendar_month},
    {'name': 'العمليات', 'icon': Icons.local_hospital},
    {'name': 'الأطباء', 'icon': Icons.people_alt},
    {'name': 'إدارة موظفين', 'icon': Icons.badge},
  ];
}

// ==========================================
// 2. الشاشة الرئيسية: قائمة الأقسام
// ==========================================
class DepartmentsListScreen extends StatelessWidget {
  const DepartmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أقسام المستشفى',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      // التوسيط المخصص لتصميم عصري
      body: Center(
        child: ConstrainedBox(
          // تحديد أقصى عرض للقائمة لتكون في المنتصف ولا تتمدد بشكل مزعج
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: AppData.departments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dept = AppData.departments[index];
              return _buildModernListItem(
                context,
                title: dept['name'],
                icon: dept['icon'],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DepartmentDetailsScreen(
                        departmentName: dept['name'],
                        departmentId: dept['id'],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. شاشة إدارة القسم
// ==========================================
class DepartmentDetailsScreen extends StatelessWidget {
  final String departmentName;
  final String departmentId;
  const DepartmentDetailsScreen({
    super.key,
    required this.departmentName,
    required this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          departmentName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: AppData.managementModules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // هنا يتم تعريف المتغير module ليقرأ منه التطبيق
              final module = AppData.managementModules[index];

              return _buildModernListItem(
                context,
                title: module['name'],
                icon: module['icon'],
                iconColor: Theme.of(context).colorScheme.secondary,
                onTap: () {
                  // الكود الجديد الذي يوجهنا لشاشة المرضى
                  if (module['name'] == 'إدارة المرضى') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientsListScreen(
                          departmentName: departmentName,
                          departmentId: departmentId,
                        ),
                      ),
                    );
                    // 2. السطر الجديد: إذا ضغط على الأطباء
                  } else if (module['name'] == 'الأطباء') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorsListScreen(
                          departmentId: departmentId,
                          departmentName: departmentName,
                        ),
                      ),
                    );
                  }
                  // 3. السطر الجديد: إذا ضغط على المواعيد
                  else if (module['name'] == 'المواعيد') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentsListScreen(
                          departmentId: departmentId,
                          departmentName: departmentName,
                        ),
                      ),
                    );
                  }
                  // 4. السطر الجديد: إدارة الاستقبالات
                  else if (module['name'] == 'إدارة الاستقبالات') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceptionsListScreen(
                          departmentId: departmentId,
                          departmentName: departmentName,
                        ),
                      ),
                    );
                  }
                  // 5. السطر الجديد: العمليات
                  else if (module['name'] == 'العمليات') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurgeriesListScreen(
                          departmentId: departmentId,
                          departmentName: departmentName,
                        ),
                      ),
                    );
                  }
                  // 6. السطر الجديد: المحاسبة
                  else if (module['name'] == 'محاسبة') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountingListScreen(
                          departmentId: departmentId,
                          departmentName: departmentName,
                        ),
                      ),
                    );
                  }
                  // 7. السطر الأخير: إدارة الموظفين
                  else if (module['name'] == 'إدارة موظفين') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffListScreen(
                          departmentId: departmentId,
                          departmentName: departmentName,
                        ),
                      ),
                    );
                  } else {
                    // باقي الأقسام تظهر رسالة مؤقتة
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('شاشة ${module['name']} قيد التطوير'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. دالة بناء عنصر القائمة العصري (Widget)
// ==========================================
Widget _buildModernListItem(
  BuildContext context, {
  required String title,
  required IconData icon,
  required VoidCallback onTap,
  Color? iconColor,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 2,
          blurRadius: 8,
          offset: const Offset(0, 4), // ظل خفيف للأسفل
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).colorScheme.primary)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    ),
  );
}
