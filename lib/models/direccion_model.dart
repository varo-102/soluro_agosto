class DireccionModel {
  final int? id;
  final String titulo;
  final String detalle;
  final String urlMaps;

  DireccionModel({
    this.id,
    required this.titulo,
    required this.detalle,
    required this.urlMaps,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'detalle': detalle,
      'url_maps': urlMaps,
    };
  }

  factory DireccionModel.fromMap(Map<String, dynamic> map) {
    return DireccionModel(
      id: map['id'] as int?,
      titulo: map['titulo'] as String? ?? '',
      detalle: map['detalle'] as String? ?? '',
      urlMaps: map['url_maps'] as String? ?? '',
    );
  }

  /// Format specified by requirements for [Copy Info]:
  /// text: <titulo>\n<detalle>\n<url_maps>
  String get formattedCopyText {
    return '$titulo\n$detalle\n$urlMaps';
  }
}
