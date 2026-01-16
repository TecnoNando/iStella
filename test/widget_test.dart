import 'package:flutter_test/flutter_test.dart';
import 'package:istella/main.dart';
import 'package:istella/services/firebase_service.dart';
import 'package:istella/services/auth_service.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final firebaseService = FirebaseService();
    final authService = AuthService();

    await tester.pumpWidget(
      MyApp(firebaseService: firebaseService, authService: authService),
    );

    // Verify that login screen is shown
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
