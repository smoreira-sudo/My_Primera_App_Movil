class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String? recetaCorte;
  final bool tienePromocion;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.recetaCorte,
    this.tienePromocion = false,
  });

  // Convertir un objeto Cliente a Mapa (para enviar a la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'recetaCorte': recetaCorte,
      'tienePromocion': tienePromocion,
    };
  }

  // Crear un objeto Cliente desde un Mapa (para leer desde la base de datos)
  factory Cliente.fromMap(Map<String, dynamic> map, String docId) {
    return Cliente(
      id: docId,
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      recetaCorte: map['recetaCorte'],
      tienePromocion: map['tienePromocion'] ?? false,
    );
  }
}