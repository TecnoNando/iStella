import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Si ya está inicializado (Android), continuar
    print('Firebase ya inicializado o error: $e');
  }

  // Inicializar servicio de actualizaciones
  await UpdateService.initialize();

  // Crear servicios
  final firebaseService = FirebaseService();
  final authService = AuthService();

  // Crear datos de ejemplo y admin por defecto
  await firebaseService.createSampleData();
  await authService.createDefaultAdmin();

  runApp(MyApp(firebaseService: firebaseService, authService: authService));
}

class MyApp extends StatelessWidget {
  final FirebaseService firebaseService;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.firebaseService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>.value(value: firebaseService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
      ],
      child: MaterialApp(
        title: 'iStella',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const LoginScreen(),
      ),
    );
  }
}
