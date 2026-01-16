import 'package:flutter/material.dart';

class AppColors {
  // Colores oficiales del Club Deportivo Stella Maris
  static const primary = Color(0xFF1B2F5C); // Azul marino Stella Maris
  static const secondary = Color(0xFFC9A961); // Dorado/Oro del círculo
  static const accent = Color(0xFF0D1B3E); // Azul oscuro para contraste
  static const background = Color(0xFFF8F9FA); // Gris muy claro
  static const surface = Color(0xFFFFFFFF); // Blanco
  static const textPrimary = Color(0xFF1B2F5C); // Azul marino
  static const textSecondary = Color(0xFF6C757D); // Gris medio
  static const success = Color(0xFF28A745); // Verde para "presente"
  static const error = Color(0xFFDC3545); // Rojo para "ausente"
  static const warning = Color(0xFFFFC107); // Amarillo para advertencias
}

class AppStrings {
  static const appName = 'iStella';
  static const clubName = 'Club Deportivo Stella Maris';

  // Login Screen
  static const loginTitle = 'Bienvenido a iStella';
  static const loginSubtitle = 'Control de Asistencia';
  static const enterName = 'Nombre del entrenador';
  static const loginAsAdmin = 'Acceder como Administrador';
  static const loginButton = 'Acceder';

  // Home Screen
  static const homeTitle = 'Lista de Socios';
  static const markAttendance = 'Marcar Asistencia';
  static const generatePDF = 'Generar PDF';
  static const present = 'Presente';
  static const absent = 'Ausente';

  // Admin Panel
  static const adminPanel = 'Panel de Administración';
  static const manageSocios = 'Gestionar Socios';
  static const pdfTemplateEditor = 'Editor de Plantillas PDF';
  static const settings = 'Configuración';

  // PDF
  static const attendanceList = 'LISTA DE ASISTENCIA';
  static const date = 'Fecha';
  static const time = 'Hora';
  static const trainer = 'Entrenador';
  static const category = 'Categoría';
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double borderRadius = 12.0;
  static const double borderRadiusLarge = 20.0;

  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;

  static const double buttonHeight = 56.0;
}
