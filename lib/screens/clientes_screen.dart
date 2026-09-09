import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/cliente_model.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  String _busqueda = '';

  void _abrirFormularioCliente({Cliente? cliente}) {
    final nombreCtrl = TextEditingController(text: cliente?.nombre ?? '');
    final telefonoCtrl = TextEditingController(text: cliente?.telefono ?? '');
    final notasCtrl =
        TextEditingController(text: cliente?.notasGenerales ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nombre Completo'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingrese un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (10 dígitos)',
                    hintText: 'Ej: 0991234567',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Ingrese teléfono';
                    }
                    if (v.length < 10) {
                      return 'Debe tener exactamente 10 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notasCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notas del Cliente (Gustos, detalles)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB89B77),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final Map<String, dynamic> datos = {
                  'nombre': nombreCtrl.text.trim(),
                  'telefono': telefonoCtrl.text.trim(),
                  'notasGenerales': notasCtrl.text.trim(),
                  'barberiaId': 'barberia_default',
                };

                if (cliente == null) {
                  datos['totalVisitas'] = 0;
                  datos['fechaRegistro'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance
                      .collection('clientes')
                      .add(datos);
                } else {
                  await FirebaseFirestore.instance
                      .collection('clientes')
                      .doc(cliente.id)
                      .update(datos);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(cliente == null ? 'Guardar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _verPerfilCliente(Cliente cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cliente.nombre,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _abrirFormularioCliente(cliente: cliente);
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone, color: Color(0xFFB89B77)),
              title: Text(
                  cliente.telefono.isEmpty ? 'Sin teléfono' : cliente.telefono),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.star, color: Colors.amber),
              title: Text('Visitas registradas: ${cliente.totalVisitas}'),
              subtitle: const Text('Cliente frecuente para promociones'),
            ),
            if (cliente.notasGenerales.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('Notas: ${cliente.notasGenerales}',
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 16),
            const Text('Historial de Cortes & Fotos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('citas')
                  .where('clienteId', isEqualTo: cliente.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No hay fotos ni historial registrado aún.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final fecha = data['fechaHora'] is Timestamp
                        ? DateFormat('dd/MM/yyyy')
                            .format((data['fechaHora'] as Timestamp).toDate())
                        : '';
                    return ListTile(
                      leading: const Icon(Icons.content_cut),
                      title: Text('${data['corte']} - $fecha'),
                      subtitle: Text(
                          'Atendido por: ${data['barbero']} \nNota: ${data['notaCorte'] ?? "Sin nota"}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        backgroundColor: const Color(0xFFF4EFE6),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormularioCliente(),
        backgroundColor: const Color(0xFFB89B77),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label:
            const Text('Nuevo Cliente', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) =>
                  setState(() => _busqueda = val.toLowerCase().trim()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clientes')
                  .orderBy('nombre', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final clientes =
                    docs.map((d) => Cliente.fromFirestore(d)).where((c) {
                  return c.nombre.toLowerCase().contains(_busqueda) ||
                      c.telefono.contains(_busqueda);
                }).toList();

                // Orden alfabético local para garantizar orden de A a Z
                clientes.sort((a, b) =>
                    a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));

                if (clientes.isEmpty) {
                  return const Center(
                      child: Text('No se encontraron clientes.'));
                }

                return ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final c = clientes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFB89B77),
                          child: Text(
                            c.nombre.isNotEmpty
                                ? c.nombre[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(c.nombre,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Tel: ${c.telefono} • Visitas: ${c.totalVisitas}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _verPerfilCliente(c),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}