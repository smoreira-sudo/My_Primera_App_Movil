import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Servicio {
  final String id;
  final String nombre;
  final double precio;
  final int duracion; // en minutos
  final bool activo;

  Servicio({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.duracion,
    this.activo = true,
  });

  factory Servicio.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Servicio(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      precio: (data['precio'] ?? 0.0).toDouble(),
      duracion: (data['duracion'] ?? 30).toInt(),
      activo: data['activo'] ?? true,
    );
  }
}

class ServiciosScreen extends StatelessWidget {
  const ServiciosScreen({super.key});

  void _mostrarFormularioServicio(BuildContext context, {Servicio? servicio}) {
    final nombreCtrl = TextEditingController(text: servicio?.nombre ?? '');
    final precioCtrl = TextEditingController(text: servicio != null ? servicio.precio.toStringAsFixed(2) : '');
    final duracionCtrl = TextEditingController(text: servicio != null ? servicio.duracion.toString() : '30');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                servicio == null ? 'Nuevo Servicio' : 'Editar Servicio',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del servicio (ej. Corte + Barba)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Precio (\$)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: duracionCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duración (min)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB89B77),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty || precioCtrl.text.isEmpty) return;

                    final datos = {
                      'nombre': nombreCtrl.text,
                      'precio': double.tryParse(precioCtrl.text) ?? 0.0,
                      'duracion': int.tryParse(duracionCtrl.text) ?? 30,
                      'activo': servicio?.activo ?? true,
                    };

                    if (servicio == null) {
                      await FirebaseFirestore.instance.collection('servicios').add(datos);
                    } else {
                      await FirebaseFirestore.instance.collection('servicios').doc(servicio.id).update(datos);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(servicio == null ? 'Guardar Servicio' : 'Actualizar Servicio'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _eliminarServicio(BuildContext context, String id) async {
    await FirebaseFirestore.instance.collection('servicios').doc(id).delete();
  }

  void _toggleEstadoServicio(String id, bool estadoActual) async {
    await FirebaseFirestore.instance.collection('servicios').doc(id).update({
      'activo': !estadoActual,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Servicios'),
        backgroundColor: const Color(0xFFF4EFE6),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('servicios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFB89B77)));
          }

          final docs = snapshot.data?.docs ?? [];
          final servicios = docs.map((d) => Servicio.fromFirestore(d)).toList();

          if (servicios.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No tienes servicios registrados.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _mostrarFormularioServicio(context),
                    child: const Text('Crear mi primer servicio'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: servicios.length,
            itemBuilder: (context, index) {
              final servicio = servicios[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF2E9DB),
                    child: Icon(
                      Icons.content_cut,
                      color: servicio.activo ? const Color(0xFF8C7355) : Colors.grey,
                    ),
                  ),
                  title: Text(
                    servicio.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: servicio.activo ? null : TextDecoration.lineThrough,
                      color: servicio.activo ? Colors.black : Colors.grey,
                    ),
                  ),
                  subtitle: Text('${servicio.duracion} min • \$${servicio.precio.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: servicio.activo,
                        activeThumbColor: const Color(0xFFB89B77),
                        onChanged: (v) => _toggleEstadoServicio(servicio.id, servicio.activo),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'editar') {
                            _mostrarFormularioServicio(context, servicio: servicio);
                          } else if (val == 'eliminar') {
                            _eliminarServicio(context, servicio.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'editar', child: Text('Editar')),
                          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioServicio(context),
        backgroundColor: const Color(0xFFB89B77),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}