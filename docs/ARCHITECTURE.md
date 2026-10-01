# Arquitectura de Software y Flujo de Datos

**Proyecto:** Soluro  
**Módulo:** Documentación de Arquitectura Técnica (`docs/ARCHITECTURE.md`)

---

## 1. Mapeo Estructural del Proyecto (`lib/`)

La estructura de la carpeta `lib/` está organizada por responsabilidades siguiendo los principios de separación de intereses y diseño desacoplado:

```
lib/
├── main.dart                       # Punto de entrada, inicialización asíncrona de servicios y enrutamiento base
├── models/                         # Entidades de dominio, contratos de datos y serialización
│   ├── cotizacion_model.dart       # Entidad CotizacionModel y CotizacionArticuloModel
│   ├── direccion_model.dart        # Entidad DireccionModel (sucursales y coordenadas)
│   ├── qr_code_model.dart          # Entidad QRCodeModel (datos bancarios y vigencias)
│   └── sync_status.dart            # Enumerador de sincronización en la nube (pending, synced, error)
├── repositories/                   # Capa de abstracción de datos (Patrón Repositorio)
│   ├── data_repository.dart        # Contrato abstracto (Interface) de operaciones CRUD
│   ├── local_data_repository.dart  # Implementación offline respaldada por SQLite
│   ├── repository_provider.dart    # Service Locator centralizado para inyección de repositorios
│   └── sync_data_repository.dart   # Implementación Cloud-Ready para sincronización en la nube (Soluro Pro)
├── services/                       # Servicios de infraestructura y hardware del dispositivo
│   ├── backup_service.dart         # Motor de empaquetado, exportación, inspección y restauración (.soluro)
│   ├── clipboard_service.dart      # Interacción con el portapapeles del sistema operativo
│   ├── cotizacion_pdf_service.dart # Motor de composición vectorial y renderizado de PDF
│   ├── database_helper.dart        # Singleton de SQLite, control de versiones, migraciones y WAL
│   ├── image_compression_service.dart # Compresión nativa de fotografías (800px / JPEG 70%)
│   ├── notification_service.dart   # Orquestador de notificaciones locales de vencimiento
│   └── quick_actions_service.dart  # Accesos directos dinámicos en el icono de la aplicación (App Shortcuts)
├── screens/                        # Capa de presentación (UI)
│   ├── main_screen.dart            # Navegación principal mediante IndexedStack y barra inferior
│   ├── backup/                     # Vistas de gestión de copias de seguridad
│   │   └── backup_restore_screen.dart # Dashboard de copias manuales, Drive y restauración
│   ├── cotizaciones/               # Módulo de cotizaciones y presupuestos
│   │   ├── cotizacion_screen.dart  # Formulario reactivo de cotización con guardado automático
│   │   ├── cotizacion_history_screen.dart # Historial con búsqueda y filtrado por fechas
│   │   └── cotizacion_pdf_preview_screen.dart # Visor de documento PDF y acciones de compartir
│   ├── direcciones/                # Módulo de sucursales
│   │   ├── direcciones_list_screen.dart # Listado de tarjetas de sucursales
│   │   └── add_direccion_modal.dart     # Modal centrado de creación/edición
│   └── qr/                         # Módulo de cobros QR
│       ├── qr_list_screen.dart     # Listado con badges de expiración y botón de copia rápida
│       ├── add_qr_modal.dart       # Modal centrado de registro con subida de imagen
│       └── full_screen_qr_viewer.dart # Visor a pantalla completa con bloqueo de brillo
└── theme/                          # Sistema de diseño y tokens visuales
    ├── app_colors.dart             # Paleta de colores oficial (Azul Profundo, Amarillo Sol, etc.)
    └── app_theme.dart              # Temas claros y oscuros de Material 3
```

---

## 2. Patrón de Arquitectura y Gestión de Estado

### Patrón Repositorio y Service Locator
Para evitar el acoplamiento directo entre los widgets de la interfaz y el motor de base de datos, Soluro implementa el **Patrón Repositorio**:

```
┌──────────────────────┐
│  Capa Presentation  │  (Screens, Modals, Widgets)
└──────────┬───────────┘
           │ consume
           ▼
┌──────────────────────┐
│  DataRepository      │  (Contrato Abstracto)
└──────────┬───────────┘
           │
     ┌─────┴────────────────────────┐
     ▼                              ▼
┌────────────────────────┐   ┌───────────────────────────┐
│ LocalDataRepository    │   │ SyncDataRepository (Pro)  │
│ (Persistencia SQLite)  │   │ (Firebase / Cloud Sync)   │
└──────────┬─────────────┘   └─────────────┬─────────────┘
           │                               │
           ▼                               ▼
┌────────────────────────┐   ┌───────────────────────────┐
│ DatabaseHelper (Local) │   │ Cloud Backend (Remoto)    │
└────────────────────────┘   └───────────────────────────┘
```

* **Inyección desacoplada:** La capa de presentación nunca llama directamente a `DatabaseHelper`. Solicita las operaciones a `RepositoryProvider.instance`.
* **Transición fluida a Soluro Pro:** Cambiar de persistencia local pura a sincronización en la nube solo requiere reasignar `RepositoryProvider.instance = SyncDataRepository()` en el arranque, sin alterar un solo widget de la aplicación.

### Estrategia de Gestión de Estado
Soluro favorece el rendimiento y la ausencia de dependencias externas pesadas (evitando sobrecargas como Bloc o Redux para un modelo offline-first ágil):
1. **Reactividad Ligera:** Uso de `ValueNotifier<ThemeMode>` para cambios instantáneos entre modo claro y oscuro sin redibujar el árbol innecesariamente.
2. **Ciclo de Vida Controlado:** Cada pantalla administra su estado local mediante `StatefulWidget`, notificando cambios a los repositorios.
3. **Autoguardado con Debounce:** En el módulo de cotizaciones, la edición de campos de texto y artículos dispara un `Timer` de 800 ms (`debounceTimer`) que sincroniza automáticamente con SQLite sin congelar la interfaz ni saturar el disco.

---

## 3. Flujo de Datos y Persistencia Local

### Motor SQLite y Archivo Físico
* **Base de datos:** `soluro_database.db`.
* **Ubicación:** `getDatabasesPath()` (`/data/user/0/com.getsoluro.soluro/databases/soluro_database.db`).
* **Modo WAL (Write-Ahead Logging):** SQLite opera en modo WAL para permitir lecturas concurrentes sin bloquear escrituras.
* **Checkpointing para Respaldos:** Antes de generar cualquier copia de seguridad o exportación, `DatabaseHelper.checkpointWal()` ejecuta `PRAGMA wal_checkpoint(FULL)`, asegurando que todas las transacciones de `soluro_database.db-wal` queden consolidadas en el archivo `.db` principal.

### Sistema de Borrado Lógico (Soft Delete)
Todos los registros eliminados por el usuario no se borran físicamente de inmediato. Se actualiza `is_deleted = 1` y `updated_at = now()`.
* **Beneficio 1:** Permite sincronización bidireccional segura con la nube sin pérdida de trazabilidad.
* **Beneficio 2:** Facilita la recuperación de datos ante eliminaciones accidentales.

### Pipeline de Copias de Seguridad (.soluro)
El servicio `BackupService` genera un archivo empaquetado comprimido con formato propio basado en ZIP:
1. **`manifest.json`:** Contiene metadatos de integridad (versión de formato, fecha, conteo de QRs, direcciones, cotizaciones y multimedia).
2. **`database/soluro_database.db`:** Copia íntegra de la base de datos SQLite consolidada.
3. **`files/`:** Contiene las fotos comprimidas de artículos (`cotizaciones_fotos/`) y las imágenes de códigos QR (`qr_images/`).
4. **Restauración Silenciosa al Primer Inicio:** Al instalar la app, `MainScreen` busca automáticamente copias existentes en directorios accesibles (Descargas/Documentos). Si detecta una, la restaura transparentemente sin interrumpir al usuario con diálogos invasivos.

---

## 4. Catálogo de Modelos y Entidades de Datos

### 1. `QRCodeModel` ([lib/models/qr_code_model.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/models/qr_code_model.dart))
Representa un código QR de cobro bancario.

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | `String` (UUID v4) | Identificador único universal |
| `userId` | `String?` | Identificador del usuario propietario (para versión Pro) |
| `banco` | `String` | Nombre de la entidad financiera o etiqueta del QR |
| `referencia` | `String` | Concepto de cobro o referencia asociada |
| `fechaExpiracion`| `DateTime` | Fecha y hora en la que caduca el QR |
| `rutaImagen` | `String` | Ruta en el sandbox local a la imagen del QR |
| `createdAt` | `DateTime` | Timestamp ISO-8601 de creación |
| `updatedAt` | `DateTime` | Timestamp ISO-8601 de última actualización |
| `isSynced` | `bool` | Indicador de sincronización con la nube |
| `syncStatus` | `SyncStatus` | Estado (`pending`, `synced`, `error`) |
| `isDeleted` | `bool` | Indicador de borrado lógico (0 = activo, 1 = eliminado) |

*Propiedades calculadas:* `daysRemaining` (días restantes), `isExpired` (vencido), `isNearExpiration` (≤ 3 días), `statusText`, `statusColorText`, `statusColorBg`, `formattedCopyText`.

---

### 2. `DireccionModel` ([lib/models/direccion_model.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/models/direccion_model.dart))
Representa una sucursal, oficina o dirección física del negocio.

| Campo | Tipo | Descripción |
| :--- | :--- | :--- |
| `id` | `String` (UUID v4) | Identificador único |
| `userId` | `String?` | Identificador de usuario |
| `titulo` | `String` | Nombre de la sucursal (ej. "Sucursal Central") |
| `detalle` | `String` | Dirección física detallada |
| `urlMaps` | `String` | Enlace directo a Google Maps |
| `createdAt` / `updatedAt` | `DateTime` | Fechas de auditoría |
| `isSynced` / `syncStatus` | `bool` / `SyncStatus` | Metadatos de sincronización cloud |
| `isDeleted` | `bool` | Borrado lógico |

---

### 3. `CotizacionModel` y `CotizacionArticuloModel` ([lib/models/cotizacion_model.dart](file:///c:/soluro_app/aplicacion_soluro_ago/lib/models/cotizacion_model.dart))
Estructura de presupuestos comerciales y sus ítems tabulares.

#### `CotizacionModel`
* **`id` (`String` UUID v4):** Clave primaria.
* **`numero` (`int`):** Folio correlativo autoincremental de la cotización.
* **`titulo` (`String`):** Título del presupuesto o nombre del cliente.
* **`notas` (`String`):** Observaciones, términos y condiciones comerciales.
* **`articulos` (`List<CotizacionArticuloModel>`):** Lista ordenada de artículos cotizados.
* **`fotos` (`List<String>`):** Rutas locales a las fotografías comprimidas de respaldo.
* **`montoTotal` (`double`):** Propiedad calculada que suma los subtotales de todos los ítems.
* **`totalUnidades` (`double`):** Sumatoria de cantidades de todos los artículos.

#### `CotizacionArticuloModel`
* **`id` (`String` UUID v4):** Clave primaria del ítem.
* **`cotizacionId` (`String`):** Llave foránea hacia la cotización contenedora.
* **`orden` (`int`):** Secuencia visual en la tabla (1 a 7 o más).
* **`descripcion` (`String`):** Detalle del producto o servicio.
* **`precio` (`double`):** Precio unitario.
* **`cantidad` (`double`):** Cantidad presupuestada.
* **`subtotal` (`double`):** `precio * cantidad`.
