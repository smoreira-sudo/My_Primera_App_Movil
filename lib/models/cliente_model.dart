import 'package:cloud_firestore/cloud_firestore.dart';

class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String notasGenerales;
  final int totalVisitas;
  final DateTime? ultimaVisita;
  final String barberiaId;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.notasGenerales = '',
    this.totalVisitas = 0,
    this.ultimaVisita,
    this.barberiaId = 'barberia_default',
  });

  factory Cliente.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Cliente(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      telefono: data['telefono'] ?? '',
      notasGenerales: data['notasGenerales'] ?? '',
      totalVisitas: (data['totalVisitas'] ?? 0).toInt(),
      ultimaVisita: data['ultimaVisita'] != null 
          ? (data['ultimaVisita'] as Timestamp).toDate() 
          : null,
      barberiaId: data['barberiaId'] ?? 'barberia_default',
    );
  }
}