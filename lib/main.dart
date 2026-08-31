import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_primera_app_movil/screens/servicios_screen.dart';
import 'package:my_primera_app_movil/screens/registrar_cliente_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  runApp(const ExclusiveBarberApp());
}

// -----------------------------------------------------------------------------
// MODELOS DE DATOS
// -----------------------------------------------------------------------------
class Barbero {
  final String id;
  final String nombre;
  final String especialidad;

  Barbero({required this.id, required this.nombre, required this.especialidad});
}

class Cita {
  final String cliente;
  final String telefono;
  final String corte;
  final double precio;
  final String barbero;
  final DateTime fecha;

  Cita({
    required this.cliente,
    required this.telefono,
    required this.corte,
    required this.precio,
    required this.barbero,
    required this.fecha,
  });
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

  final List<Barbero> _barberos = [
    Barbero(id: '1', nombre: 'Alex', especialidad: 'Master Barber'),
    Barbero(id: '2', nombre: 'Mateo', especialidad: 'Fade Specialist'),
  ];

  final List<Cita> _citas = [
    Cita(
      cliente: 'Carlos Mendoza',
      telefono: '0991234567',
      corte: 'Corte degradado medio',
      precio: 15.0,
      barbero: 'Alex',
      fecha: DateTime.now(),
    ),
    Cita(
      cliente: 'Juan Pérez',
      telefono: '0987654321',
      corte: 'Corte clásico con tijera',
      precio: 12.0,
      barbero: 'Mateo',
      fecha: DateTime.now(),
    ),
  ];

  void _agregarCita(Cita nuevaCita) {
    setState(() => _citas.add(nuevaCita));
  }

  void _agregarBarbero(Barbero nuevoBarbero) {
    setState(() => _barberos.add(nuevoBarbero));
  }

  void _cambiarPestana(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        citas: _citas,
        barberos: _barberos,
        onAgregarCita: _agregarCita,
        onIrAAgenda: () => _cambiarPestana(1),
        onIrAFinanzas: () => _cambiarPestana(3),
      ),
      AgendaScreen(citas: _citas),
      ClientesScreen(citas: _citas),
      FinanzasScreen(citas: _citas, barberos: _barberos),
      PerfilScreen(barberos: _barberos, onAgregarBarbero: _agregarBarbero),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _cambiarPestana,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF2E9DB),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF8C7355)), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF8C7355)), label: 'Agenda'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people, color: Color(0xFF8C7355)), label: 'Clientes'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF8C7355)), label: 'Finanzas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Color(0xFF8C7355)), label: 'Perfil'),
        ],
      ),
    );
  }
}

// ==========================================
// 1. PANTALLA INICIO (Actualizada)
// ==========================================
class HomeScreen extends StatefulWidget {
  final List<Cita> citas;
  final List<Barbero> barberos;
  final Function(Cita) onAgregarCita;
  final VoidCallback onIrAAgenda;
  final VoidCallback onIrAFinanzas;

  const HomeScreen({
    super.key,
    required this.citas,
    required this.barberos,
    required this.onAgregarCita,
    required this.onIrAAgenda,
    required this.onIrAFinanzas,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFB89B77)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _mostrarTrabajosBarbero(BuildContext context, Barbero barbero, List<Cita> trabajos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trabajos de ${barbero.nombre}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Total cortes hoy: ${trabajos.length}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              trabajos.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No registra trabajos en esta fecha.')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: trabajos.length,
                      itemBuilder: (context, index) {
                        final trabajo = trabajos[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF2E9DB),
                            child: Icon(Icons.content_cut, color: Color(0xFF8C7355)),
                          ),
                          title: Text(trabajo.cliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(trabajo.corte),
                          trailing: Text(
                            '\$${trabajo.precio.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final citasDelDia = widget.citas.where((c) =>
      c.fecha.year == _selectedDate.year &&
      c.fecha.month == _selectedDate.month &&
      c.fecha.day == _selectedDate.day
    ).toList();

    final double ingresosHoy = citasDelDia.fold(0, (sum, item) => sum + item.precio);

    String fechaFormateada = DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(_selectedDate);
    fechaFormateada = fechaFormateada[0].toUpperCase() + fechaFormateada.substring(1);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¡Hola, Alex!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Text(fechaFormateada, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/corte.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const CircleAvatar(
                    backgroundColor: Color(0xFFECE3D2),
                    child: Icon(Icons.person, color: Colors.grey),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onIrAAgenda,
                  borderRadius: BorderRadius.circular(16),
                  child: _buildMetricCard(
                    icon: Icons.calendar_today,
                    title: 'Citas Hoy',
                    value: citasDelDia.length.toString(),
                    iconBg: const Color(0xFFF5EFE6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: widget.onIrAFinanzas,
                  borderRadius: BorderRadius.circular(16),
                  child: _buildMetricCard(
                    icon: Icons.payments_outlined,
                    title: 'Ingresos Hoy',
                    value: '\$${ingresosHoy.toStringAsFixed(2)}',
                    iconBg: const Color(0xFFE8F5E9),
                    iconColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Resumen del Equipo (Barberos)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...widget.barberos.map((barbero) {
            final trabajosBarbero = citasDelDia.where((c) => c.barbero == barbero.nombre).toList();
            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                onTap: () => _mostrarTrabajosBarbero(context, barbero, trabajosBarbero),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFB89B77),
                  child: Text(barbero.nombre[0], style: const TextStyle(color: Colors.white)),
                ),
                title: Text(barbero.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(barbero.especialidad),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${trabajosBarbero.length} cortes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const Text('Ver detalle', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegistrarClienteScreen()),
          );
          if (res != null && res is Cita) {
            widget.onAgregarCita(res);
          }
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
            CircleAvatar(backgroundColor: iconBg, child: Icon(icon, color: iconColor)),
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
  final List<Cita> citas;
  const AgendaScreen({super.key, required this.citas});

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
              Text('Mi Agenda (${citas.length})', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    final cita = citas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFB89B77),
                          child: Text(cita.cliente[0], style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(cita.cliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${cita.corte} • Barbero: ${cita.barbero}'),
                        trailing: Text(cita.telefono, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
}

// ==========================================
// 3. PANTALLA CLIENTES
// ==========================================
class ClientesScreen extends StatelessWidget {
  final List<Cita> citas;
  const ClientesScreen({super.key, required this.citas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes y Recetas')),
      body: ListView.builder(
        itemCount: citas.length,
        itemBuilder: (context, index) {
          final cita = citas[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFB89B77),
                child: Text(cita.cliente[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(cita.cliente),
              subtitle: Text(cita.corte),
              trailing: Text(cita.telefono),
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
  final List<Cita> citas;
  final List<Barbero> barberos;

  const FinanzasScreen({super.key, required this.citas, required this.barberos});

  @override
  Widget build(BuildContext context) {
    final double ingresosTotales = citas.fold(0, (sum, c) => sum + c.precio);
    final double promedioCita = citas.isNotEmpty ? ingresosTotales / citas.length : 0;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Finanzas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.payments, color: Colors.green)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INGRESOS TOTALES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text('\$${ingresosTotales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(title: 'Cortes Totales', value: citas.length.toString()),
                _StatColumn(title: 'Ticket Promedio', value: '\$${promedioCita.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Ingresos por Barbero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...barberos.map((barbero) {
          final citasBarbero = citas.where((c) => c.barbero == barbero.nombre).toList();
          final ingresosBarbero = citasBarbero.fold(0.0, (sum, c) => sum + c.precio);

          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFB89B77),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(barbero.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${citasBarbero.length} cortes realizados'),
              trailing: Text('\$${ingresosBarbero.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            ),
          );
        }),
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
  final List<Barbero> barberos;
  final Function(Barbero) onAgregarBarbero;

  const PerfilScreen({super.key, required this.barberos, required this.onAgregarBarbero});

  void _mostrarDialogoNuevoBarbero(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final especCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Nuevo Barbero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre del Barbero')),
            TextField(controller: especCtrl, decoration: const InputDecoration(labelText: 'Especialidad (ej. Fade)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nombreCtrl.text.isNotEmpty) {
                onAgregarBarbero(Barbero(
                  id: DateTime.now().toString(),
                  nombre: nombreCtrl.text,
                  especialidad: especCtrl.text.isEmpty ? 'Barbero' : especCtrl.text,
                ));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB89B77), foregroundColor: Colors.white),
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

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
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, size: 100, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Exclusive Barber', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('contacto@exclusivebarber.com', style: TextStyle(color: Colors.grey)),
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
          _buildListTile(Icons.badge_outlined, 'Gestión de Barberos (${barberos.length})', () => _mostrarDialogoNuevoBarbero(context)),
          _buildListTile(Icons.content_cut, 'Mis Servicios', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ServiciosScreen()));
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