# Manual de Publicación en Google Play Store (Release Guide)

**Proyecto:** Soluro  
**Módulo:** Documentación de Release y Configuración Android (`docs/PLAYSTORE_RELEASE.md`)

---

## 1. Configuración de Firma Digital (App Signing)

Google Play Store exige que todo paquete de producción (*Android App Bundle* - `.aab`) esté firmado digitalmente con un almacén de claves criptográficas (*Keystore*).

### Paso 1: Generar el Keystore de Producción
Ejecuta el siguiente comando en tu terminal para generar un nuevo archivo de claves. Asegúrate de guardar la contraseña y el archivo en un lugar seguro:

```bash
keytool -genkey -v -keystore soluro_release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias soluro-key
```

> **IMPORTANTE:** Guarda una copia de seguridad externa de `soluro_release.jks`. Si pierdes este archivo o sus contraseñas, no podrás actualizar la aplicación en Google Play si no tienes activado Google Play App Signing.

---

### Paso 2: Crear el archivo de credenciales (`android/key.properties`)
Crea un archivo llamado `key.properties` dentro de la carpeta `android/` (**nunca lo subas a Git**).

Contenido de `android/key.properties`:
```properties
storePassword=TU_PASSWORD_DEL_KEYSTORE
keyPassword=TU_PASSWORD_DEL_ALIAS
keyAlias=soluro-key
storeFile=../soluro_release.jks
```

> **Regla de Seguridad:** Verifica que `android/key.properties` y `*.jks` estén presentes en `.gitignore` para evitar filtraciones de claves en repositorios públicos o privados.

---

### Paso 3: Configurar [android/app/build.gradle.kts](file:///c:/soluro_app/aplicacion_soluro_ago/android/app/build.gradle.kts)
Actualmente, el archivo `build.gradle.kts` firma la compilación release con las claves de debug:

```kotlin
// Estado actual:
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Para vincular `key.properties`, la configuración recomendada en Kotlin DSL es:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 2. Instrucciones de Compilación para Producción

### Versionado de la Aplicación
Antes de generar cada release para Play Store, actualiza la versión en [pubspec.yaml](file:///c:/soluro_app/aplicacion_soluro_ago/pubspec.yaml):

```yaml
version: 1.0.0+1
#        └──┬──┘ └┬┘
#           │     └── versionCode (Entero incremental obligatorio en cada subida: 1, 2, 3...)
#           └──────── versionName (Visible a los usuarios: 1.0.0, 1.0.1...)
```

### Comando Oficial de Compilación AAB
Google Play Store requiere el formato **Android App Bundle (.aab)**:

```bash
flutter build appbundle --release
```

El binario optimizado se generará en:
```
build/app/outputs/bundle/release/app-release.aab
```

### Análisis de Tamaño del Paquete
Para auditar qué componentes ocupan más espacio antes de subir a Play Console:

```bash
flutter build appbundle --release --analyze-size
```

---

## 3. Auditoría de Permisos Android ([AndroidManifest.xml](file:///c:/soluro_app/aplicacion_soluro_ago/android/app/src/main/AndroidManifest.xml))

A continuación se detalla la justificación funcional de cada permiso para responder con exactitud a los revisores de Google Play:

### 1. `POST_NOTIFICATIONS`
* **Declaración:** `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />`
* **Ámbito:** Android 13+ (API nivel 33 en adelante).
* **Justificación para Google Play:**  
  *«La aplicación requiere este permiso para enviar alertas locales programadas al usuario antes del vencimiento de sus códigos QR bancarios (alertas preventivas a los 3 días y el día de caducidad). Esta función garantiza que los cobros de los usuarios no sean rechazados por caducidad del QR.»*

### 2. `READ_EXTERNAL_STORAGE` (con `maxSdkVersion="32"`)
* **Declaración:** `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />`
* **Ámbito:** Android 12 y versiones anteriores (API ≤ 32).
* **Justificación para Google Play:**  
  *«Permite al usuario seleccionar imágenes desde su galería para registrar comprobantes/códigos QR y adjuntar fotografías descriptivas a las cotizaciones comerciales en dispositivos con Android 12 o inferior. En Android 13+ se utiliza el Photo Picker del sistema sin requerir permisos amplios de almacenamiento.»*

### 3. `WRITE_EXTERNAL_STORAGE` (con `maxSdkVersion="28"`)
* **Declaración:** `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />`
* **Ámbito:** Android 9 Pie y versiones anteriores (API ≤ 28).
* **Justificación para Google Play:**  
  *«Requerido exclusivamente en versiones heredadas de Android (API 28 o menor) para permitir al usuario guardar en el almacenamiento del dispositivo los documentos PDF generados de las cotizaciones y los archivos de respaldo local de su base de datos.»*

---

## 4. Guía para el Formulario de "Seguridad de los Datos" (Data Safety Section)

Al completar la ficha de la aplicación en Google Play Console, responde con las siguientes declaraciones fundamentadas en la arquitectura offline-first de Soluro:

### Pregunta 1: ¿Tu app recopila o comparte alguno de los tipos de datos de usuario obligatorios?
* **Respuesta:** **NO** (o "No recopila datos en servidores externos").
* **Explicación técnica:** Soluro es una aplicación 100% *Offline-First*. Todos los datos (códigos QR, cotizaciones, montos y direcciones) se almacenan localmente en la base de datos interna SQLite (`soluro_database.db`) en el dispositivo del usuario. La aplicación no transmite datos a ningún servidor externo, API de terceros, ni incluye SDKs de telemetría/analítica publicitaria.

### Pregunta 2: ¿La app comparte datos con terceros?
* **Respuesta:** **NO**. Los datos nunca se transfieren a empresas u organizaciones externas.

### Pregunta 3: Transferencia y Seguridad
* **Cifrado en tránsito:** Marcar como **No aplicable** o declarar que los datos no viajan a servidores remotos.
* **Eliminación de datos:** Indicar que el usuario tiene control total sobre sus datos:
  * Puede eliminar códigos QR, direcciones y cotizaciones individualmente dentro de la app (Soft Delete en SQLite).
  * El borrado de almacenamiento de la app o su desinstalación elimina todos los datos locales.

### Pregunta 4: Tipos de datos que manipula el usuario localmente:
* **Fotos y videos:** Sí (Fotos adjuntas en cotizaciones y capturas de códigos QR seleccionadas por el usuario). **Propósito:** Funcionalidad de la aplicación. **Almacenamiento:** Solo local.
* **Información financiera:** Sí (Nombres de bancos de cobro y referencias de cobro de cotizaciones). **Propósito:** Funcionalidad de la aplicación. **Almacenamiento:** Solo local, no se recopilan números de tarjeta de crédito ni cuentas bancarias completas.
