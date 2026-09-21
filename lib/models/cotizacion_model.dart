import 'package:uuid/uuid.dart';
import 'sync_status.dart';

/// Modelo de un artículo o fila dentro de una cotización.
class CotizacionArticuloModel {
  final String id;
  final String cotizacionId;
  final int orden;
  final String descripcion;
  final double precio;
  final double cantidad;
  final DateTime createdAt;
  final DateTime updatedAt;

  CotizacionArticuloModel({
    String? id,
    required this.cotizacionId,
    required this.orden,
    this.descripcion = '',
    this.precio = 0.0,
    this.cantidad = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Subtotal de la fila: precio * cantidad
  double get subtotal => precio * cantidad;

  /// Indica si el artículo tiene datos significativos
  bool get hasContent =>
      descripcion.trim().isNotEmpty || precio > 0 || cantidad > 0;

  CotizacionArticuloModel copyWith({
    String? id,
    String? cotizacionId,
    int? orden,
    String? descripcion,
    double? precio,
    double? cantidad,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CotizacionArticuloModel(
      id: id ?? this.id,
      cotizacionId: cotizacionId ?? this.cotizacionId,
      orden: orden ?? this.orden,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cotizacion_id': cotizacionId,
      'orden': orden,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory CotizacionArticuloModel.fromJson(Map<String, dynamic> json) {
    return CotizacionArticuloModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      cotizacionId: (json['cotizacion_id'] ?? json['cotizacionId'] ?? '').toString(),
      orden: (json['orden'] as num?)?.toInt() ?? 1,
      descripcion: (json['descripcion'] as String?) ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  factory CotizacionArticuloModel.fromMap(Map<String, dynamic> map) =>
      CotizacionArticuloModel.fromJson(map);
}

/// Modelo principal de una Cotización de Soluro App.
class CotizacionModel {
  final String id;
  final String? userId;
  final int numero;
  final String titulo;
  final String notas;
  final List<CotizacionArticuloModel> articulos;
  final List<String> fotos;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
  final bool isDeleted;

  CotizacionModel({
    String? id,
    this.userId,
    required this.numero,
    String? titulo,
    this.notas = '',
    List<CotizacionArticuloModel>? articulos,
    List<String>? fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.syncStatus = SyncStatus.pending,
    this.lastSyncedAt,
    this.isDeleted = false,
  })  : id = id ?? const Uuid().v4(),
        titulo = titulo ?? 'Cotización $numero',
        articulos = articulos ?? [],
        fotos = fotos ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Crea una nueva cotización en blanco con 7 artículos vacíos por defecto.
  factory CotizacionModel.createEmpty({
    required int numero,
    String? userId,
  }) {
    final cotId = const Uuid().v4();
    final now = DateTime.now();
    final initialArticulos = List.generate(
      7,
      (index) => CotizacionArticuloModel(
        cotizacionId: cotId,
        orden: index + 1,
        descripcion: '',
        precio: 0.0,
        cantidad: 0.0,
        createdAt: now,
        updatedAt: now,
      ),
    );

    return CotizacionModel(
      id: cotId,
      userId: userId,
      numero: numero,
      titulo: 'Cotización $numero',
      notas: '',
      articulos: initialArticulos,
      fotos: const [],
      createdAt: now,
      updatedAt: now,
      isSynced: false,
      syncStatus: SyncStatus.pending,
      isDeleted: false,
    );
  }

  /// Total de unidades (suma de las cantidades de todas las filas).
  double get totalUnidades {
    double sum = 0.0;
    for (final item in articulos) {
      sum += item.cantidad;
    }
    return sum;
  }

  /// Monto total de la cotización (suma de subtotales de todas las filas).
  double get montoTotal {
    double sum = 0.0;
    for (final item in articulos) {
      sum += item.subtotal;
    }
    return sum;
  }

  /// Lista de artículos que tienen contenido (para omitir vacíos en el PDF).
  List<CotizacionArticuloModel> get articulosValidos {
    return articulos.where((item) => item.hasContent).toList();
  }

  /// Número de fotos adjuntas.
  int get fotosCount => fotos.length;

  CotizacionModel copyWith({
    String? id,
    String? userId,
    int? numero,
    String? titulo,
    String? notas,
    List<CotizacionArticuloModel>? articulos,
    List<String>? fotos,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    SyncStatus? syncStatus,
    DateTime? lastSyncedAt,
    bool? isDeleted,
  }) {
    return CotizacionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      numero: numero ?? this.numero,
      titulo: titulo ?? this.titulo,
      notas: notas ?? this.notas,
      articulos: articulos ?? this.articulos,
      fotos: fotos ?? this.fotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'numero': numero,
      'titulo': titulo,
      'notas': notas,
      'articulos': articulos.map((a) => a.toJson()).toList(),
      'fotos': fotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.toValue(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Para almacenamiento en la tabla `cotizaciones` de SQLite
  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'user_id': userId,
      'numero': numero,
      'titulo': titulo,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'sync_status': syncStatus.toValue(),
      'last_synced_at': lastSyncedAt?.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory CotizacionModel.fromJson(Map<String, dynamic> json) {
    final articulosJson = json['articulos'] as List<dynamic>? ?? [];
    final fotosJson = json['fotos'] as List<dynamic>? ?? [];

    return CotizacionModel(
      id: json['id']?.toString() ?? const Uuid().v4(),
      userId: (json['user_id'] ?? json['userId']) as String?,
      numero: (json['numero'] as num?)?.toInt() ?? 1,
      titulo: (json['titulo'] as String?) ?? 'Cotización 1',
      notas: (json['notas'] as String?) ?? '',
      articulos: articulosJson
          .map((a) => CotizacionArticuloModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      fotos: fotosJson.map((f) => f.toString()).toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isSynced: (json['is_synced'] ?? json['isSynced']) == 1 ||
          (json['is_synced'] ?? json['isSynced']) == true,
      syncStatus: SyncStatus.fromValue(
        (json['sync_status'] ?? json['syncStatus']) as String?,
      ),
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      isDeleted: (json['is_deleted'] ?? json['isDeleted']) == 1 ||
          (json['is_deleted'] ?? json['isDeleted']) == true,
    );
  }

  factory CotizacionModel.fromDbMap(
    Map<String, dynamic> map, {
    List<CotizacionArticuloModel> articulos = const [],
    List<String> fotos = const [],
  }) {
    return CotizacionModel(
      id: map['id']?.toString() ?? const Uuid().v4(),
      userId: map['user_id'] as String?,
      numero: (map['numero'] as num?)?.toInt() ?? 1,
      titulo: (map['titulo'] as String?) ?? 'Cotización 1',
      notas: (map['notas'] as String?) ?? '',
      articulos: articulos,
      fotos: fotos,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      isSynced: (map['is_synced'] as num?) == 1,
      syncStatus: SyncStatus.fromValue(map['sync_status'] as String?),
      lastSyncedAt: map['last_synced_at'] != null
          ? DateTime.parse(map['last_synced_at'] as String)
          : null,
      isDeleted: (map['is_deleted'] as num?) == 1,
    );
  }
}
