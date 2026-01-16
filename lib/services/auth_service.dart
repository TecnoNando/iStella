import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/usuario.dart';
import '../utils/password_hasher.dart';

class AuthService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Usuario? _currentUser;

  Usuario? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // Login con usuario y contraseña
  Future<Usuario?> login(String usuario, String password) async {
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('usuario', isEqualTo: usuario)
          .where('activo', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Usuario no encontrado');
      }

      final userDoc = querySnapshot.docs.first;
      final user = Usuario.fromFirestore(userDoc);

      // Verificar contraseña (soporta texto plano y hash para migración)
      bool passwordValid = false;

      // Intentar primero con hash
      if (PasswordHasher.verifyPassword(password, user.password)) {
        passwordValid = true;
      }
      // Si falla, intentar texto plano (para usuarios antiguos)
      else if (user.password == password) {
        passwordValid = true;
        // TODO: Actualizar a hash en el futuro
        print('⚠️ Usuario con contraseña sin hash detectado');
      }

      if (!passwordValid) {
        throw Exception('Contraseña incorrecta');
      }

      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      print('Error en login: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  // Crear usuario admin por defecto
  Future<void> createDefaultAdmin() async {
    try {
      // Verificar si ya existe el admin
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('usuario', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Admin ya existe');
        return;
      }

      // Hash de la contraseña
      final hashedPassword = PasswordHasher.hashPassword('f9AEwvwN');

      // Crear admin
      final admin = Usuario(
        id: '',
        nombre: 'Fernando Arráez',
        usuario: 'admin',
        password: hashedPassword,
        rol: 'admin',
        gruposAsignados: [],
        activo: true,
        fechaCreacion: DateTime.now(),
      );

      await _firestore.collection('usuarios').add(admin.toFirestore());
      print('✅ Usuario admin creado correctamente con contraseña hasheada');
    } catch (e) {
      print('Error al crear admin: $e');
    }
  }

  // Verificar si un usuario tiene acceso a un grupo
  bool hasAccessToGroup(String grupoId) {
    if (_currentUser == null) return false;
    if (_currentUser!.isAdmin) return true;
    return _currentUser!.gruposAsignados.contains(grupoId);
  }

  // Enviar correo de reestablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error al enviar correo de reset: $e');
      rethrow;
    }
  }

  // Abrir correo de soporte
  Future<void> sendSupportEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soporte@istella.com', // TODO: Cambiar por email real
      query:
          'subject=Consulta Soporte iStella&body=Hola, necesito ayuda con...',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw Exception('No se pudo abrir la app de correo');
    }
  }
}
