# YouTube Downloader App

Una aplicación de Flutter para buscar videos de YouTube y descargarlos en formato MP3. Compatible con Android y Web.

## Características

- 🔍 Búsqueda de videos de YouTube
- ✅ Selección múltiple de videos
- 📱 Interfaz moderna y intuitiva
- 🎵 Descarga en formato MP3
- 📊 Estado de descarga en tiempo real
- 🔄 Reintento de descargas fallidas

## Requisitos Previos

1. **Flutter SDK**: Instala Flutter desde [flutter.dev](https://flutter.dev/docs/get-started/install)
2. **Android Studio / VS Code**: Para desarrollo
3. **API Key de YouTube**: Necesaria para buscar videos
4. **Navegador web moderno**: Para ejecutar la versión web

## Instalación

1. **Clona el repositorio**:
   ```bash
   git clone <url-del-repositorio>
   cd youtube_downloader_app
   ```

2. **Instala las dependencias**:
   ```bash
   flutter pub get
   ```

3. **Configura la API Key de YouTube**:
   - Ve a [Google Cloud Console](https://console.cloud.google.com/)
   - Crea un nuevo proyecto o selecciona uno existente
   - Habilita la YouTube Data API v3
   - Crea credenciales (API Key)
   - Reemplaza `'TU_API_KEY_AQUI'` en `lib/services/youtube_service.dart` con tu API key real

4. **Ejecuta la aplicación**:
   
   **Para Android:**
   ```bash
   flutter run -d android
   ```
   
   **Para Web:**
   ```bash
   flutter run -d chrome
   ```

## Configuración de Permisos

### Android
Agrega los siguientes permisos en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### Web
La aplicación web no requiere configuración de permisos adicionales. Las descargas se manejan directamente a través del navegador.

## Uso

1. **Búsqueda**: Ingresa el nombre de una canción o video en la barra de búsqueda
2. **Selección**: Toca los videos que deseas descargar
3. **Descarga**: Presiona el botón de descarga en la barra superior
4. **Seguimiento**: Monitorea el progreso de las descargas

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/
│   └── youtube_video.dart    # Modelo de datos para videos
├── providers/
│   └── youtube_provider.dart # Gestión de estado
├── screens/
│   ├── home_screen.dart      # Pantalla principal
│   └── download_screen.dart  # Pantalla de descargas
├── services/
│   └── youtube_service.dart  # Servicios de API
└── widgets/
    ├── search_bar.dart       # Widget de búsqueda
    ├── video_card.dart       # Tarjeta de video
    └── download_item.dart    # Item de descarga
```

## Dependencias Principales

- `provider`: Gestión de estado
- `http`: Peticiones HTTP
- `youtube_explode_dart`: Extracción de URLs de YouTube
- `cached_network_image`: Carga de imágenes con caché
- `permission_handler`: Manejo de permisos (solo Android)
- `path_provider`: Acceso a directorios del sistema (solo Android)
- `url_launcher`: Abrir enlaces externos

## Notas Importantes

⚠️ **Limitaciones de la API de YouTube**:
- La API gratuita tiene límites de cuota diaria
- Algunos videos pueden no estar disponibles para descarga
- Respeta los términos de servicio de YouTube

⚠️ **Consideraciones Legales**:
- Solo descarga contenido que tengas permiso para usar
- Respeta los derechos de autor
- Esta aplicación es solo para uso educativo

## Solución de Problemas

### Error de API Key
- Verifica que la API key esté correctamente configurada
- Asegúrate de que la YouTube Data API v3 esté habilitada

### Error de Permisos (Android)
- Verifica que los permisos estén configurados correctamente
- En Android 11+, considera usar `MANAGE_EXTERNAL_STORAGE`

### Error de Descarga (Web)
- Verifica que el navegador permita descargas
- Algunos navegadores pueden bloquear descargas automáticas

### Error de Descarga
- Verifica la conexión a internet
- Algunos videos pueden tener restricciones de descarga

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## Contacto

Si tienes preguntas o sugerencias, no dudes en contactarme.
