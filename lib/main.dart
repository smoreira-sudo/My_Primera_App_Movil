import 'package:flutter/material.dart';
import 'package:my_primera_app_movil/screens/servicios_screen.dart';
import 'package:my_primera_app_movil/screens/registrar_cliente_screen.dart';

void main() {
  runApp(const ExclusiveBarberApp());
}

class ExclusiveBarberApp extends StatelessWidget {
  const ExclusiveBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exclusive Barber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4EFE6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB89B77),
          primary: const Color(0xFFB89B77),
          surface: const Color(0xFFF4EFE6),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AgendaScreen(),
    ClientesScreen(),
    FinanzasScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF2E9DB),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF8C7355)),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF8C7355)),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFF8C7355)),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF8C7355)),
            label: 'Finanzas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF8C7355)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 1. PANTALLA INICIO (Dashboard Completo)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¡Hola, Alex!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Domingo, 2 de Agosto', style: TextStyle(color: Colors.grey)),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/corte.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircleAvatar(
                      backgroundColor: Color(0xFFECE3D2),
                      child: Icon(Icons.person, color: Colors.grey),
                    );
                  },
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.calendar_today,
                  title: 'Citas Hoy',
                  value: '0',
                  iconBg: const Color(0xFFF5EFE6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.payments_outlined,
                  title: 'Ingresos Hoy',
                  value: '\$0',
                  iconBg: const Color(0xFFE8F5E9),
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Sin citas hoy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Toca para crear una nueva cita', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegistrarClienteScreen()),
          );
        },
        backgroundColor: const Color(0xFFB89B77),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Cliente Presencial', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  static Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconBg,
    Color iconColor = Colors.brown,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. PANTALLA AGENDA
// ==========================================
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});

  final List<Map<String, String>> clientesEjemplo = const [
    {
      'nombre': 'Carlos Mendoza',
      'telefono': '0991234567',
      'corte': 'Corte degradado medio con barba delineada',
    },
    {
      'nombre': 'Juan Pérez',
      'telefono': '0987654321',
      'corte': 'Corte clásico con tijera',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mi Agenda',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${clientesEjemplo.length} citas',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  FloatingActionButton.small(
                    onPressed: () {},
                    backgroundColor: const Color(0xFFB89B77),
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _filterChip('Hoy', isSelected: true),
                    _filterChip('Semana'),
                    _filterChip('Próximas'),
                    _filterChip('Pasadas'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: clientesEjemplo.length,
                  itemBuilder: (context, index) {
                    final cliente = clientesEjemplo[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFB89B77),
                          child: Text(
                            cliente['nombre']![0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          cliente['nombre']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(cliente['corte']!),
                        trailing: Text(
                          cliente['telefono']!,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _filterChip(String text, {bool isSelected = false}) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB89B77) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. PANTALLA CLIENTES
// ==========================================
class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  final List<Map<String, String>> clientesEjemplo = const [
    {
      'nombre': 'Carlos Mendoza',
      'telefono': '0991234567',
      'corte': 'Corte degradado medio con barba delineada',
    },
    {
      'nombre': 'Juan Pérez',
      'telefono': '0987654321',
      'corte': 'Corte clásico con tijera',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes y Recetas'),
      ),
      body: ListView.builder(
        itemCount: clientesEjemplo.length,
        itemBuilder: (context, index) {
          final cliente = clientesEjemplo[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFB89B77),
                child: Text(
                  cliente['nombre']![0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(cliente['nombre']!),
              subtitle: Text(cliente['corte']!),
              trailing: Text(cliente['telefono']!),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. PANTALLA FINANZAS
// ==========================================
class FinanzasScreen extends StatelessWidget {
  const FinanzasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finanzas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Hoy', style: TextStyle(color: Colors.grey)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('PDF'),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFB89B77),
                foregroundColor: Colors.white,
                side: BorderSide.none,
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.payments, color: Colors.green),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INGRESOS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('\$0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(title: 'Citas', value: '0'),
                _StatColumn(title: 'Promedio', value: '\$0'),
                _StatColumn(title: 'Pendientes', value: '0'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String title;
  final String value;
  const _StatColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(radius: 4, backgroundColor: Colors.brown),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

// ==========================================
// 5. PANTALLA PERFIL
// ==========================================
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.asset(
                  'assets/images/corte.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.account_circle, size: 100, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Exclusive Barber',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'contacto@exclusivebarber.com',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star_border, color: Colors.black87),
                        SizedBox(width: 8),
                        Text('Plan Gratuito', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Text('0/10', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB89B77),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Actualizar APP', style: TextStyle(fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsGroup([
          _buildListTile(Icons.content_cut, 'Mis Servicios', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ServiciosScreen()),
            );
          }),
          _buildListTile(Icons.notifications_none, 'Notificaciones', () {}),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Formato de hora'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('24h', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Switch(value: false, onChanged: (v) {}),
                const Text('12h', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _buildSettingsGroup([
          _buildListTile(Icons.help_outline, 'Ayuda', () {}),
          _buildListTile(Icons.email_outlined, 'Contactar Soporte', () {}),
          _buildListTile(Icons.description_outlined, 'Términos y Privacidad', () {}),
        ]),
        const SizedBox(height: 16),
        _buildSettingsGroup([
          _buildListTile(Icons.logout, 'Cerrar Sesión', () {}, color: Colors.orange),
          _buildListTile(Icons.delete_outline, 'Eliminar cuenta', () {}, color: Colors.red),
        ]),
      ],
    );
  }

  static Widget _buildSettingsGroup(List<Widget> tiles) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: tiles),
    );
  }

  static Widget _buildListTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}