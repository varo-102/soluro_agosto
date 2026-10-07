# Política de Privacidad de Soluro

**Última actualización:** 6 de octubre de 2026  
**Aplicación:** Soluro  
**Identificador de paquete (Package ID):** `com.getsoluro.soluro`  
**Contacto de privacidad y soporte:** contacto@getsoluro.com  
**Sitio web oficial:** https://getsoluro.com  
**URL de esta política:** https://getsoluro.com/privacidad

---

## 1. Introducción y Compromiso de Privacidad

En **Soluro**, la privacidad de nuestros usuarios es una prioridad fundamental. Esta Política de Privacidad describe cómo se gestiona, almacena y protege la información al utilizar nuestra aplicación móvil en dispositivos Android.

Soluro ha sido diseñada bajo una arquitectura **100% Offline-First (Local en el Dispositivo)**. Esto significa que **Soluro no recopila, no transmite ni almacena datos personales en servidores externos, nubes propias ni bases de datos remotas**. Toda la información que ingresas pertenece exclusivamente a ti y permanece guardada únicamente en la memoria interna de tu dispositivo.

---

## 2. Información que Gestiona la Aplicación

Soluro no requiere la creación de cuentas de usuario, inicio de sesión mediante redes sociales, contraseñas en la nube ni suscripciones para su funcionamiento. Los tipos de información que la app gestiona localmente son:

### A. Cotizaciones Comerciales y Presupuestos
* **Datos incluidos:** Nombres de clientes o referencias, fechas, listas de productos o servicios, cantidades, precios unitarios, subtotales, totales y observaciones.
* **Almacenamiento:** Se guardan exclusivamente en la base de datos interna SQLite (`soluro_database.db`) en el almacenamiento protegido del dispositivo.

### B. Códigos QR Bancarios y de Cobro
* **Datos incluidos:** Título o descripción del código QR, categoría, banco asociado, fecha de vencimiento e imágenes del código QR.
* **Almacenamiento:** Los registros se guardan en la base de datos local y las imágenes capturadas o seleccionadas se almacenan en el directorio privado de la app (`app_flutter/qr_images`).

### C. Registro de Direcciones
* **Datos incluidos:** Nombres de ubicaciones, referencias y detalles de direcciones guardadas por el usuario para su gestión operativa.
* **Almacenamiento:** Guardados estrictamente de forma local en el dispositivo.

### D. Fotografías Adjuntas a Cotizaciones
* **Datos incluidos:** Fotos que el usuario decide asociar a una cotización para documentar un trabajo, producto o servicio.
* **Almacenamiento:** Directorio privado de la app (`app_flutter/cotizaciones_fotos`).

---

## 3. Permisos del Dispositivo y su Justificación

Soluro solicita únicamente los permisos estrictamente necesarios para su funcionamiento en el dispositivo. En ningún momento se accede a sensores o datos privados sin la acción directa y voluntaria del usuario:

| Permiso | Finalidad | ¿Se envían datos al exterior? |
| :--- | :--- | :--- |
| **Cámara** (`android.permission.CAMERA`) | Permite al usuario capturar fotografías para adjuntarlas a cotizaciones o registrar códigos QR directamente con el lente. | **No**, las fotos se procesan y almacenan únicamente en el dispositivo. |
| **Acceso a Fotos y Galería** (`READ_EXTERNAL_STORAGE` / Photo Picker) | Permite seleccionar imágenes ya existentes en la galería para asociarlas a un QR o cotización. | **No**, la app solo lee los archivos que el usuario selecciona explícitamente. |
| **Escritura en Almacenamiento** (`WRITE_EXTERNAL_STORAGE`, en Android ≤ 9) | Requerido únicamente en versiones heredadas de Android para exportar archivos PDF de cotizaciones y archivos de respaldo local al almacenamiento del usuario. | **No**, la descarga se realiza de manera local en el teléfono. |

---

## 4. Servicios de Terceros, Analítica y Publicidad

* **Sin Publicidad:** Soluro no integra bibliotecas de publicidad de terceros (como Google AdMob, Unity Ads, etc.) ni rastreadores de comportamiento.
* **Sin Rastreo ni Telemetría:** No recopilamos identificadores de publicidad (`Advertising ID`), identificadores únicos del dispositivo (`IMEI`, `Android ID`), direcciones IP ni perfiles de uso.
* **Sin Venta de Datos:** Al no existir almacenamiento en servidores ni recopilación de datos, Soluro **no vende, no alquila, no comercializa ni comparte información de ningún tipo con terceros**.

---

## 5. Exportación, Compartición y Copias de Seguridad

El usuario mantiene el control absoluto sobre la distribución y respaldo de sus datos:

1. **Exportación de Documentos (PDF / Compartir):** Cuando el usuario decide compartir una cotización en formato PDF o una imagen de un código QR mediante aplicaciones externas (como WhatsApp, Correo Electrónico o Telegram), esta acción es realizada de forma voluntaria a través de la hoja de compartir del sistema operativo Android (`share_plus`). El tratamiento de dicha información fuera de Soluro se rige por la política de privacidad de la aplicación receptora seleccionada por el usuario.
2. **Copias de Seguridad Locales:** La aplicación permite generar un archivo de respaldo empaquetado (`.soluro`) que el usuario puede guardar en la carpeta de su preferencia o transferir manualmente a otro dispositivo.
3. **Respaldo del Sistema Android:** Si el usuario tiene habilitado el respaldo automático de Google en su dispositivo Android (Google Drive Auto Backup), las configuraciones locales y base de datos pueden ser respaldadas bajo las políticas de seguridad y cifrado de la cuenta de Google del propio usuario.

---

## 6. Retención y Eliminación de Datos

* **Control individual:** Puedes eliminar cotizaciones, códigos QR o direcciones en cualquier momento desde la interfaz de la aplicación.
* **Eliminación total:** Dado que no existe almacenamiento en la nube ni cuentas remotas, para eliminar de manera definitiva e irreversible todos los datos almacenados por Soluro, basta con:
  1. Borrar los datos de la aplicación desde **Ajustes de Android > Aplicaciones > Soluro > Almacenamiento > Borrar datos**, o bien
  2. **Desinstalar la aplicación** de tu dispositivo.

---

## 7. Privacidad de Menores

Soluro es una herramienta de productividad y gestión comercial. La aplicación no está dirigida a menores de 13 años (o la edad mínima legal en tu jurisdicción) y no recopila datos de ninguna persona, incluidos menores.

---

## 8. Modificaciones a esta Política de Privacidad

Podemos actualizar esta Política de Privacidad de forma periódica en caso de incorporar nuevas funcionalidades o para cumplir con normativas legales o de Google Play. Cualquier actualización será publicada en esta misma página con la fecha de entrada en vigor actualizada.

---

## 9. Contacto y Consultas

Si tienes alguna pregunta, inquietud o sugerencia respecto a esta Política de Privacidad o el tratamiento de tus datos en Soluro, puedes comunicarte con nosotros a través de:

* **Correo electrónico:** contacto@getsoluro.com
* **Sitio web:** https://getsoluro.com

