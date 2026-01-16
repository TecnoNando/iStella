import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/user_profile_card.dart';
import '../utils/constants.dart';
import 'agenda_screen.dart';
import 'messages_screen.dart';
import 'socios_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final usuario = authService.currentUser;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // List of screens for the bottom navigation
    final List<Widget> screens = [
      const _DashboardTab(),
      const SociosScreen(), // Gimnastas
      const AgendaScreen(),
      const MessagesScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.primary.withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: AppColors.primary),
              label: 'Gimnastas',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(
                Icons.calendar_month,
                color: AppColors.primary,
              ),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
              label: 'Mensajes',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firebaseService = context.watch<FirebaseService>();
    final usuario = authService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'iStella',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(usuario: usuario),
                ),
              );
            },
            tooltip: 'Configuración',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta de Usuario Premium
              UserProfileCard(
                usuario: usuario,
                onTap: () {
                  // Navegar a settings o perfil reducido
                  // Por ahora no hace nada o abre settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(usuario: usuario),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 2. Resumen (Stats)
              StreamBuilder(
                stream: firebaseService.getSociosStream(),
                builder: (context, sociosSnapshot) {
                  return StreamBuilder(
                    stream: firebaseService.getGruposStream(),
                    builder: (context, gruposSnapshot) {
                      final totalSocios = sociosSnapshot.data?.length ?? 0;
                      final totalGrupos = gruposSnapshot.data?.length ?? 0;

                      return Row(
                        children: [
                          Expanded(
                            child: _ModernStatCard(
                              title: 'Gimnastas',
                              value: '$totalSocios',
                              icon: Icons.people,
                              color: Colors.blueAccent,
                              gradient: const LinearGradient(
                                colors: [Colors.blueAccent, Colors.lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ModernStatCard(
                              title: 'Grupos Activos',
                              value: '$totalGrupos',
                              icon: Icons.group_work,
                              color: Colors.purpleAccent,
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.purpleAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // 3. Sección "Hoy" (Agenda del día simulada)
              const Text(
                'Hoy en Stella Maris',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildModernCard(
                child: Column(
                  children: [
                    _buildTimelineItem(
                      time: '16:00',
                      title: 'Entrenamiento Grupo A',
                      subtitle: 'Pabellón Principal',
                      icon: Icons.sports_gymnastics,
                      color: Colors.orange,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      time: '17:30',
                      title: 'Entrenamiento Grupo B',
                      subtitle: 'Sala de Baile',
                      icon: Icons.music_note,
                      color: Colors.pink,
                      isLast: false,
                    ),
                    _buildTimelineItem(
                      time: '19:00',
                      title: 'Reunión Técnica',
                      subtitle: 'Sala de Juntas',
                      icon: Icons.meeting_room,
                      color: Colors.teal,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Comunicados / Novedades
              const Text(
                'Novedades',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'INFO',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Hace 2h',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '¡Bienvenido a la nueva App!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hemos actualizado iStella con nuevas funciones para mejorar la gestión del club. Explora las secciones de Gimnastas y Agenda.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {},
              ),

              const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[100])),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
