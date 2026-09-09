import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/clientes_screen.dart';
import 'screens/finanzas_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/main_layout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/agenda_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('es_ES', null);
  runApp(const ExclusiveBarberApp());
}

// -----------------------------------------------------------------------------
// MODELOS DE DATOS CON MULTI-TENANT, DÍAS LIBRES Y ESTADOS
// -----------------------------------------------------------------------------
class Barbero {
  final String id;
  final String nombre;
  final String especialidad;
  final List<int> diasDescanso;
  final String barberiaId;

  Barbero({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.diasDescanso,
    this.barberiaId = 'barberia_default',
  });

  factory Barbero.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final List<dynamic> desc = data['diasDescanso'] ?? [];
    return Barbero(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      especialidad: data['especialidad'] ?? 'Barbero',
      diasDescanso: desc.map((e) => (e as num).toInt()).toList(),
      barberiaId: data['barberiaId'] ?? 'barberia_default',
    );
  }
}

class Cita {
  final String id;
  final String cliente;
  final String telefono;
  final String corte;
  final double precio;
  final String barbero;
  final String barberoId;
  final DateTime fechaHora;
  final String estado;
  final int duracionMinutos;
  final String barberiaId;

  Cita({
    required this.id,
    required this.cliente,
    required this.telefono,
    required this.corte,
    required this.precio,
    required this.barbero,
    required this.barberoId,
    required this.fechaHora,
    required this.estado,
    required this.duracionMinutos,
    this.barberiaId = 'barberia_default',
  });

  factory Cita.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime fecha;
    if (data['fechaHora'] is Timestamp) {
      fecha = (data['fechaHora'] as Timestamp).toDate();
    } else if (data['fecha'] is String) {
      fecha = DateTime.tryParse(data['fecha']) ?? DateTime.now();
    } else {
      fecha = DateTime.now();
    }

    return Cita(
      id: doc.id,
      cliente: data['clienteNombre'] ?? data['cliente'] ?? 'Sin nombre',
      telefono: data['telefono'] ?? '',
      corte: data['corte'] ?? 'Servicio general',
      precio: (data['precio'] ?? 0.0).toDouble(),
      barbero: data['barberoNombre'] ?? data['nombreBarbero'] ?? data['barbero'] ?? 'Sin asignar',
      barberoId: data['barberoId'] ?? data['barbero'] ?? 'sin_asignar',
      fechaHora: fecha,
      estado: data['estado'] ?? 'pendiente',
      duracionMinutos: (data['duracionMinutos'] ?? 30).toInt(),
      barberiaId: data['barberiaId'] ?? 'barberia_default',
    );
  }
  DateTime get fechaFin => fechaHora.add(Duration(minutes: duracionMinutos));
}

class ExclusiveBarberApp extends StatelessWidget {
  const ExclusiveBarberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exclusive Barber',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB89B77),
        scaffoldBackgroundColor: const Color(0xFFF7F5F0),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFB89B77)),
              ),
            );
          }

          if (snapshot.hasData) {
            return const MainLayout();
          }

          return const AuthScreen();
        },
      ),
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

  void _cambiarPestana(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onIrAAgenda: () => _cambiarPestana(1),
        onIrAFinanzas: () => _cambiarPestana(3),
      ),
      const AgendaScreen(),
      const ClientesScreen(),
      const FinanzasScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _cambiarPestana,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFF2E9DB),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF8C7355)),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon:
                  Icon(Icons.calendar_today, color: Color(0xFF8C7355)),
              label: 'Agenda'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: Color(0xFF8C7355)),
              label: 'Clientes'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon:
                  Icon(Icons.account_balance_wallet, color: Color(0xFF8C7355)),
              label: 'Finanzas'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF8C7355)),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

// ==========================================
// 1. PANTALLA INICIO (SIN BOTÓN FLOTANTE)
// ==========================================

class HomeScreen extends StatefulWidget {
  final VoidCallback? onIrAAgenda;
  final VoidCallback? onIrAFinanzas;

  const HomeScreen({
    super.key,
    this.onIrAAgenda,
    this.onIrAFinanzas,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _diasSemana = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];
  final List<String> _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre'
  ];

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now().toLocal();
    final nombreDia = _diasSemana[ahora.weekday - 1];
    final nombreMes = _meses[ahora.month - 1];
    final fechaFormateada = '$nombreDia, ${ahora.day} de $nombreMes';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('citas').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data?.docs ?? [];

            final docsHoy = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final rawFecha = data['fechaHora'] ?? data['fecha'];
              if (rawFecha == null) return false;

              int? diaDoc, mesDoc, anioDoc;

              if (rawFecha is Timestamp) {
                final f = rawFecha.toDate().toLocal();
                diaDoc = f.day;
                mesDoc = f.month;
                anioDoc = f.year;
              } else if (rawFecha is String) {
                if (rawFecha.contains('/')) {
                  final partes = rawFecha.split(' ')[0].split('/');
                  if (partes.length == 3) {
                    diaDoc = int.tryParse(partes[0]);
                    mesDoc = int.tryParse(partes[1]);
                    anioDoc = int.tryParse(partes[2]);
                  }
                } else {
                  final f = DateTime.tryParse(rawFecha)?.toLocal();
                  if (f != null) {
                    diaDoc = f.day;
                    mesDoc = f.month;
                    anioDoc = f.year;
                  }
                }
              }

              return diaDoc == ahora.day &&
                  mesDoc == ahora.month &&
                  anioDoc == ahora.year;
            }).toList();

            int totalCitas = docsHoy.length;
            int completadas = 0;
            int pendientes = 0;
            double ingresosHoy = 0.0;
            int sumaMinutos = 0;
            int citasConDuracion = 0;
            Map<String, int> cortesPorBarbero = {};
            Map<String, double> ingresosPorBarbero = {};

            for (var doc in docsHoy) {
              final data = doc.data() as Map<String, dynamic>;
              final estado = data['estado'] ?? 'pendiente';

              if (estado == 'completada') {
                completadas++;
                final double precio = (data['precio'] ?? 0.0).toDouble();
                ingresosHoy += precio;

                if (data['inicioAtencion'] != null && data['finAtencion'] != null) {
                  DateTime inicio = (data['inicioAtencion'] as Timestamp).toDate();
                  DateTime fin = (data['finAtencion'] as Timestamp).toDate();
                  int duracion = fin.difference(inicio).inMinutes;

                  if (duracion > 0) {
                    sumaMinutos += duracion;
                    citasConDuracion++;
                  }
                } else if (data['duracionMinutos'] != null) {
                  sumaMinutos += (data['duracionMinutos'] as num).toInt();
                  citasConDuracion++;
                }

                // CORRECCIÓN AQUÍ: Lee primero barberoNombre / nombreBarbero para mostrar el texto legible
                final barbero = data['barberoNombre'] ??
                    data['nombreBarbero'] ??
                    data['barbero'] ??
                    'Sin asignar';

                cortesPorBarbero[barbero] =
                    (cortesPorBarbero[barbero] ?? 0) + 1;
                ingresosPorBarbero[barbero] =
                    (ingresosPorBarbero[barbero] ?? 0.0) + precio;
              } else {
                pendientes++;
              }
            }

            String barberoTop = 'N/A';
            double maxIngreso = -1.0;
            ingresosPorBarbero.forEach((barbero, ingreso) {
              if (ingreso > maxIngreso) {
                maxIngreso = ingreso;
                barberoTop = barbero;
              }
            });

            int promedioMinutos = citasConDuracion > 0
                ? (sumaMinutos / citasConDuracion).round()
                : 0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Bienvenido a Exclusive Barber Shop!',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fechaFormateada,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onIrAAgenda,
                          child: _buildHeaderCard(
                            title: 'Citas Hoy',
                            value: '$totalCitas',
                            icon: Icons.calendar_today,
                            iconBg: const Color(0xFFF7EFE9),
                            iconColor: const Color(0xFFB8977E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onIrAFinanzas,
                          child: _buildHeaderCard(
                            title: 'Ingresos Hoy',
                            value: '\$${ingresosHoy.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet,
                            iconBg: const Color(0xFFE8F5E9),
                            iconColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderCard(
                          title: 'Completadas',
                          value: '$completadas / $totalCitas',
                          icon: Icons.check_circle_outline,
                          iconBg: Colors.green.shade50,
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderCard(
                          title: 'Pendientes',
                          value: '$pendientes',
                          icon: Icons.pending_actions,
                          iconBg: Colors.orange.shade50,
                          iconColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderCard(
                          title: 'Barbero Top',
                          value: barberoTop,
                          icon: Icons.star_outline,
                          iconBg: Colors.amber.shade50,
                          iconColor: Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeaderCard(
                          title: 'Tiempo Medio',
                          value: '$promedioMinutos min',
                          icon: Icons.timer_outlined,
                          iconBg: Colors.blue.shade50,
                          iconColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Resumen del Equipo (Barberos)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),

                  if (cortesPorBarbero.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            'Sin cortes registrados hoy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    )
                  else
                    ...cortesPorBarbero.entries.map((entry) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFB8977E),
                            child: Text(
                              entry.key.isNotEmpty
                                  ? entry.key[0].toUpperCase()
                                  : 'B',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(entry.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Barbero',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${entry.value} cortes',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const Text('Ver detalle',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                          onTap: widget.onIrAFinanzas,
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  _buildCitasPorDiasCard(allDocs),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCitasPorDiasCard(List<QueryDocumentSnapshot> allDocs) {
    final ahora = DateTime.now().toLocal();
    final diasAbrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    final diasSemana = List.generate(7, (i) {
      return ahora.add(Duration(days: i - 3));
    });

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: Color(0xFFB8977E), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Citas por Días',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Color(0xFFB8977E)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: diasSemana.map((fecha) {
                final esHoy = fecha.year == ahora.year &&
                    fecha.month == ahora.month &&
                    fecha.day == ahora.day;

                final totalCitasDia = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rawFecha = data['fechaHora'] ?? data['fecha'];
                  if (rawFecha == null) return false;

                  int? diaDoc, mesDoc, anioDoc;

                  if (rawFecha is Timestamp) {
                    final f = rawFecha.toDate().toLocal();
                    diaDoc = f.day;
                    mesDoc = f.month;
                    anioDoc = f.year;
                  } else if (rawFecha is String) {
                    if (rawFecha.contains('/')) {
                      final partes = rawFecha.split(' ')[0].split('/');
                      if (partes.length == 3) {
                        diaDoc = int.tryParse(partes[0]);
                        mesDoc = int.tryParse(partes[1]);
                        anioDoc = int.tryParse(partes[2]);
                      }
                    } else {
                      final f = DateTime.tryParse(rawFecha)?.toLocal();
                      if (f != null) {
                        diaDoc = f.day;
                        mesDoc = f.month;
                        anioDoc = f.year;
                      }
                    }
                  }

                  return diaDoc == fecha.day &&
                      mesDoc == fecha.month &&
                      anioDoc == fecha.year;
                }).length;

                final nombreDia = diasAbrev[fecha.weekday - 1];
                final diaNum = fecha.day.toString().padLeft(2, '0');
                final mesNum = fecha.month.toString().padLeft(2, '0');

                return Column(
                  children: [
                    Container(
                      height: 4,
                      width: 32,
                      decoration: BoxDecoration(
                        color: esHoy
                            ? const Color(0xFFB8977E)
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      nombreDia,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: esHoy ? FontWeight.bold : FontWeight.normal,
                        color: esHoy ? Colors.black : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      '$diaNum/$mesNum',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      width: 32,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: esHoy
                            ? const Color(0xFFF5F0EB)
                            : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$totalCitasDia',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              esHoy ? const Color(0xFFB8977E) : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}