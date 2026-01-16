import 'package:flutter/material.dart';

class AppColors {
  // Colores estilo iPasen (Verde corporativo y pasteles)
  static const primary = Color(0xFF00583D); // Verde oscuro corporativo
  static const secondary = Color(0xFFC8E6C9); // Verde muy claro / pastel
  static const accent = Color(0xFF1B5E20); // Verde intermedio

  static const background = Color(0xFFF9FAFB); // Blanco roto / Gris muy claro
  static const cardBackground = Color(0xFFFFFFFF); // Blanco puro

  // Colores de tarjetas
  static const cardGreenLight = Color(
    0xFFD1E7DD,
  ); // Fondo verde pastel (Agenda)
  static const cardRedLight = Color(0xFFF8D7DA); // Fondo rojo pastel (Alertas)
  static const cardTextGreen = Color(0xFF0f5132); // Texto verde oscuro
  static const cardTextRed = Color(0xFF842029); // Texto rojo oscuro

  static const textPrimary = Color(0xFF212529); // Negro suave
  static const textSecondary = Color(0xFF6C757D); // Gris

  static const success = Color(0xFF198754); // Verde éxito
  static const error = Color(0xFFDC3545); // Rojo error
  static const warning = Color(0xFFFFC107); // Amarillo warning
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
