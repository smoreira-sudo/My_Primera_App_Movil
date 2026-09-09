import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'servicios_screen.dart';
import 'package:firebase_core/firebase_core.dart';

// Modelo local de Barbero para el parsing
class Barbero {
  final String id;
  final String nombre;
  final String especialidad;
  final List<int> diasDescanso;

  Barbero({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.diasDescanso,
  });

  factory Barbero.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Barbero(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      especialidad: data['especialidad'] ?? 'Barbero',
      diasDescanso: List<int>.from(data['diasDescanso'] ?? []),
    );
  }
}

class PerfilScreen extends StatefulWidget {
  final String rol;

  const PerfilScreen({super.key, this.rol = 'barbero'});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Datos de contacto de soporte
  final String _whatsappSoporte = '593992303053';
  final String _emailSoporte = 'alexandericardo21@outlook.com';

  bool _cargandoImagen = false;

  // Método para generar e imprimir el reporte PDF de todos los clientes
  Future<void> _imprimirListaClientes(
      List<QueryDocumentSnapshot> clientes) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Reporte General de Clientes',
                      style: const pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Exclusive Barber',
                      style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Cliente', 'Teléfono', 'Visitas', 'Notas / Estilo'],
              data: clientes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return [
                  data['nombre'] ?? 'Sin nombre',
                  data['telefono'] ?? 'N/A',
                  '${data['totalVisitas'] ?? 1}',
                  data['notasCorte'] ?? 'Sin notas',
                ];
              }).toList(),
              headerStyle: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.brown600),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Total Clientes Registrados: ${clientes.length}',
                  style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            )
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Clientes_Promociones.pdf',
    );
  }

  void _mostrarGestionBarberos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _GestionBarberosModal(),
    );
  }

  // Lanzador universal para WhatsApp, Web y Correo
  Future<void> _abrirUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      final bool lanzado = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (!lanzado) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se encontró una aplicación para abrir el enlace.'),
          ),
        );
      }
    }
  }

  void _contactarSoporteWhatsApp() {
    final url =
        'https://api.whatsapp.com/send?phone=$_whatsappSoporte&text=Hola,%20requiero%20asistencia%20tecnica%20con%20Exclusive%20Barber.';
    _abrirUrl(url);
  }

  void _contactarSoporteEmail() {
    final url =
        'mailto:$_emailSoporte?subject=Soporte%20Tecnico%20Exclusive%20Barber';
    _abrirUrl(url);
  }

  // Modal para seleccionar Cámara o Galería para la Foto
  void _seleccionarOpcionFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFFB89B77)),
              title: const Text('Elegir de la Galería'),
              onTap: () {
                Navigator.pop(context);
                _procesarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFB89B77)),
              title: const Text('Tomar Foto con Cámara'),
              onTap: () {
                Navigator.pop(context);
                _procesarImagen(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _procesarImagen(ImageSource origen) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: origen,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() => _cargandoImagen = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('perfiles')
            .child('${user.uid}.jpg');

        await ref.putFile(File(pickedFile.path));
        final photoURL = await ref.getDownloadURL();

        await user.updatePhotoURL(photoURL);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoImagen = false);
    }
  }

  // Modal para editar Nombre del Admin / Barbería
  void _editarPerfilAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    final nombreCtrl = TextEditingController(
      text: user?.displayName ?? 'Exclusive Barber Admin',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Datos de Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Barbería / Admin',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB89B77)),
            onPressed: () async {
              final nuevoNombre = nombreCtrl.text.trim();
              if (nuevoNombre.isNotEmpty) {
                if (user != null) {
                  await user.updateDisplayName(nuevoNombre);
                }
                setState(() {});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarCierreSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacionCuenta() {
    final confirmacionCtrl = TextEditingController();
    bool errorTexto = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Text(
              'Eliminar Cuenta',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta acción desactivará tu usuario. Los registros operativos e historial se mantendrán seguros.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Escribe "ELIMINAR" para confirmar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmacionCtrl,
                  decoration: InputDecoration(
                    hintText: 'ELIMINAR',
                    errorText: errorTexto ? 'Texto incorrecto' : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  if (confirmacionCtrl.text.trim() != 'ELIMINAR') {
                    setStateModal(() => errorTexto = true);
                    return;
                  }

                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(user.uid)
                        .set({
                      'estado': 'cuenta_eliminada',
                      'fechaEliminacion': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                    await user.delete();
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Eliminar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final esAdmin = widget.rol == 'admin'; // <--- AGREGA ESTA LÍNEA AQUÍ

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('barberos').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Encabezado Editable del Administrador
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFB89B77),
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: _cargandoImagen
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : (user?.photoURL == null
                                ? const Icon(Icons.store,
                                    size: 40, color: Colors.white)
                                : null),
                      ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                          onPressed: _seleccionarOpcionFoto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user?.displayName ?? 'Exclusive Barber Admin',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Colors.grey),
                        onPressed: _editarPerfilAdmin,
                      ),
                    ],
                  ),
                  Text(
                    user?.email ?? 'ID Barbería: barberia_default',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // NUEVA SECCIÓN: Módulo de Reportes de Clientes Promocionales e Impresión
            if (esAdmin)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clientes')
                    .snapshots(),
                builder: (context, snapshot) {
                  final clientes = snapshot.data?.docs ?? [];

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reporte General de Clientes',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${clientes.length} clientes en base de datos',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: clientes.isEmpty
                                ? null
                                : () => _imprimirListaClientes(clientes),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB89B77),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.print,
                                color: Colors.white, size: 16),
                            label: const Text('Imprimir',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // NUEVA SECCIÓN: Top Clientes (Los Más Frecuentes)
            if (esAdmin) ...[
              const Text(
                'Top Clientes Promocionales',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clientes')
                    .orderBy('totalVisitas', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ));
                  }

                  final topClientes = snapshot.data?.docs ?? [];

                  if (topClientes.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text('Sin clientes registrados aún.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: topClientes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value.data() as Map<String, dynamic>;
                      final nombre = data['nombre'] ?? 'Cliente';
                      final telefono = data['telefono'] ?? 'Sin número';
                      final visitas = data['totalVisitas'] ?? 1;

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: index == 0
                                ? const Color(0xFFFFD700)
                                : index == 1
                                    ? const Color(0xFFC0C0C0)
                                    : const Color(0xFFCD7F32),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(nombre,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Teléfono: $telefono'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB89B77)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$visitas visitas',
                              style: const TextStyle(
                                  color: Color(0xFFB89B77),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),

            // Módulo: Gestión Operativa
            if (esAdmin)  
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined,
                        color: Color(0xFFB89B77)),
                    title: Text('Gestión de Barberos ($count)'),
                    subtitle: const Text('Configura nombres y días libres'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _mostrarGestionBarberos(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.content_cut, color: Color(0xFFB89B77)),
                    title: const Text('Mis Servicios'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ServiciosScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bloque: Soporte & Ayuda
            const Text(
              'Soporte & Ayuda',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading:
                        const Icon(Icons.chat_outlined, color: Colors.green),
                    title: const Text('Contactar por WhatsApp'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _contactarSoporteWhatsApp,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.email_outlined, color: Colors.blue),
                    title: const Text('Enviar Correo Técnico'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _contactarSoporteEmail,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: Colors.grey),
                    title: const Text('Términos y Privacidad'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Exclusive Barber App',
                        applicationVersion: '1.0.0',
                        applicationLegalese:
                            '© 2026 Todos los derechos reservados.',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bloque: Cuenta & Sesión
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text('Cerrar Sesión'),
                    onTap: _confirmarCierreSesion,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Eliminar Cuenta',
                        style: TextStyle(color: Colors.red)),
                    onTap: _confirmarEliminacionCuenta,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Modal de Gestión de Barberos con Límite de 3 y Creación de Credenciales Directas

class _GestionBarberosModal extends StatefulWidget {
  const _GestionBarberosModal();

  @override
  State<_GestionBarberosModal> createState() => _GestionBarberosModalState();
}

class _GestionBarberosModalState extends State<_GestionBarberosModal> {
  final nombreCtrl = TextEditingController();
  final especCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  int? _diaLibreSeleccionado;
  String? _barberoIdEditando;
  bool _cargando = false;

  final Map<int, String> _diasSemana = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  void _limpiarFormulario() {
    nombreCtrl.clear();
    especCtrl.clear();
    emailCtrl.clear();
    passwordCtrl.clear();
    setState(() {
      _diaLibreSeleccionado = null;
      _barberoIdEditando = null;
    });
  }

  void _cargarParaEditar(Barbero b, Map<String, dynamic> data) {
    setState(() {
      _barberoIdEditando = b.id;
      nombreCtrl.text = b.nombre;
      especCtrl.text = b.especialidad;
      emailCtrl.text = data['email'] ?? '';
      passwordCtrl.clear(); // La contraseña no se muestra por seguridad
      _diaLibreSeleccionado =
          b.diasDescanso.isNotEmpty ? b.diasDescanso.first : null;
    });
  }

  void _mostrarAviso(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarOActualizarBarbero(int conteoActual) async {
    final nombre = nombreCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    if (nombre.isEmpty) {
      _mostrarAviso(
          'Campo Requerido', 'Por favor ingresa el nombre del barbero.');
      return;
    }

    // Validación del límite de 3 barberos
    if (_barberoIdEditando == null && conteoActual >= 3) {
      _mostrarAviso(
        'Límite de Equipo Alcanzado (3/3)',
        'Tu plan permite un máximo de 3 barberos activos. Si eliminas a un integrante, su cupo queda liberado automáticamente.',
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      List<int> descansos = [];
      if (_diaLibreSeleccionado != null) {
        descansos.add(_diaLibreSeleccionado!);
      }

      if (_barberoIdEditando == null) {
        // --- CREAR NUEVO BARBERO Y SU CUENTA ---
        if (email.isEmpty || password.length < 6) {
          _mostrarAviso('Credenciales Inválidas',
              'Ingresa un correo válido y una contraseña de al menos 6 caracteres.');
          setState(() => _cargando = false);
          return;
        }

        // Crear cuenta en Firebase Auth usando una app secundaria (mantiene activa la sesión Admin)
        FirebaseApp appSecundaria = await Firebase.initializeApp(
          name: 'RegistroBarberoTemp',
          options: Firebase.app().options,
        );

        UserCredential userCredential = await FirebaseAuth.instanceFor(
                app: appSecundaria)
            .createUserWithEmailAndPassword(email: email, password: password);

        String uid = userCredential.user!.uid;
        await userCredential.user!.updateDisplayName(nombre);
        await appSecundaria.delete();

        // Guardar documento del barbero en Firestore usando su UID
        await FirebaseFirestore.instance.collection('barberos').doc(uid).set({
          'uid': uid,
          'nombre': nombre,
          'email': email,
          'rol': 'barbero',
          'especialidad':
              especCtrl.text.trim().isEmpty ? 'Barbero' : especCtrl.text.trim(),
          'diasDescanso': descansos,
          'barberiaId': 'barberia_default',
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      } else {
        // --- EDITAR BARBERO EXISTENTE ---
        await FirebaseFirestore.instance
            .collection('barberos')
            .doc(_barberoIdEditando)
            .update({
          'nombre': nombre,
          'especialidad':
              especCtrl.text.trim().isEmpty ? 'Barbero' : especCtrl.text.trim(),
          'diasDescanso': descansos,
        });
      }

      _limpiarFormulario();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Barbero y cuenta guardados con éxito.')),
        );
      }
    } catch (e) {
      _mostrarAviso('Error', 'No se pudo procesar la solicitud: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = _barberoIdEditando != null;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('barberos').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final conteoActual = docs.length;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      esEdicion
                          ? 'Editar Barbero'
                          : 'Nuevo Barbero ($conteoActual/3)',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (esEdicion)
                      TextButton(
                        onPressed: _limpiarFormulario,
                        child: const Text('Cancelar edición',
                            style: TextStyle(color: Colors.grey)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre Completo'),
                ),
                TextField(
                  controller: especCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Especialidad (Ej: Fade, Barba)'),
                ),
                if (!esEdicion) ...[
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo de Acceso',
                      hintText: 'barbero1@exclusivebarber.com',
                    ),
                  ),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña (mín. 6 caracteres)',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _diaLibreSeleccionado,
                  decoration: const InputDecoration(
                      labelText: 'Día de descanso (Opcional)'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('Ninguno (Trabaja toda la semana)'),
                    ),
                    ..._diasSemana.entries.map(
                      (e) => DropdownMenuItem<int>(
                          value: e.key, child: Text(e.value)),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _diaLibreSeleccionado = val),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando
                        ? null
                        : () => _guardarOActualizarBarbero(conteoActual),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB89B77),
                      foregroundColor: Colors.white,
                    ),
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(esEdicion ? Icons.save : Icons.person_add),
                    label: Text(esEdicion
                        ? 'Guardar Cambios'
                        : 'Crear Barbero y Acceso'),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Equipo Registrado',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final b = Barbero.fromFirestore(d);
                    String textoDescanso = 'Trabaja toda la semana';
                    if (b.diasDescanso.isNotEmpty) {
                      textoDescanso =
                          'Descansa: ${b.diasDescanso.map((day) => _diasSemana[day]).join(", ")}';
                    }

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${b.especialidad}\n$textoDescanso\nCorreo: ${data['email'] ?? 'Sin correo'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _cargarParaEditar(b, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('barberos')
                                .doc(b.id)
                                .delete(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
