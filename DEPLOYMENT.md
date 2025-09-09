# Guía de Despliegue - YouTube Downloader App

## Despliegue para Android

### 1. Preparación del APK

```bash
# Generar APK de release
flutter build apk --release

# El APK se generará en: build/app/outputs/flutter-apk/app-release.apk
```

### 2. Generar APK Bundle (recomendado para Google Play)

```bash
# Generar AAB (Android App Bundle)
flutter build appbundle --release

# El AAB se generará en: build/app/outputs/bundle/release/app-release.aab
```

### 3. Firmar la aplicación (opcional pero recomendado)

```bash
# Crear keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configurar signing en android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<location of the keystore file>
```

### 4. Instalación en dispositivo

```bash
# Instalar directamente en dispositivo conectado
flutter install --release
```

## Despliegue para Web

### 1. Construir para producción

```bash
# Generar build optimizado para web
flutter build web --release

# Los archivos se generarán en: build/web/
```

### 2. Desplegar en servidor web

#### Opción A: GitHub Pages

1. Crear repositorio en GitHub
2. Subir el contenido de `build/web/` a la rama `gh-pages`
3. Activar GitHub Pages en la configuración del repositorio

#### Opción B: Firebase Hosting

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Inicializar Firebase
firebase init hosting

# Desplegar
firebase deploy
```

#### Opción C: Netlify

1. Conectar repositorio a Netlify
2. Configurar directorio de build: `build/web`
3. Comando de build: `flutter build web`

#### Opción D: Vercel

1. Conectar repositorio a Vercel
2. Configurar directorio de salida: `build/web`
3. Comando de build: `flutter build web`

### 3. Configuración de CORS (si es necesario)

Para evitar problemas de CORS con la API de YouTube, puedes configurar un proxy:

```javascript
// En tu servidor web
app.use('/api/youtube', proxy('https://www.googleapis.com'));
```

## Configuración de Variables de Entorno

### Para Android

Crear archivo `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="youtube_api_key">TU_API_KEY_AQUI</string>
</resources>
```

### Para Web

Crear archivo `.env` en la raíz del proyecto:

```
YOUTUBE_API_KEY=TU_API_KEY_AQUI
```

## Optimizaciones de Rendimiento

### Android

1. **ProGuard**: Habilitar ofuscación de código
2. **R8**: Optimización de recursos
3. **Splitting**: Dividir APK por arquitectura

### Web

1. **Tree Shaking**: Eliminar código no utilizado
2. **Code Splitting**: Dividir el bundle
3. **Caching**: Configurar headers de caché
4. **Compression**: Habilitar gzip/brotli

## Monitoreo y Analytics

### Firebase Analytics (recomendado)

```yaml
# En pubspec.yaml
dependencies:
  firebase_analytics: ^10.7.4
  firebase_core: ^2.24.2
```

### Configuración básica

```dart
// En main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

## Troubleshooting

### Problemas comunes en Android

1. **Error de permisos**: Verificar AndroidManifest.xml
2. **Error de signing**: Verificar keystore y passwords
3. **Error de API**: Verificar API key en strings.xml

### Problemas comunes en Web

1. **Error de CORS**: Configurar proxy o headers
2. **Error de descarga**: Verificar permisos del navegador
3. **Error de build**: Verificar dependencias web

## Seguridad

### Recomendaciones

1. **API Key**: Nunca exponer en código fuente
2. **HTTPS**: Usar siempre en producción
3. **Validación**: Validar inputs del usuario
4. **Rate Limiting**: Implementar límites de uso

### Configuración de seguridad para web

```html
<!-- En web/index.html -->
<meta http-equiv="Content-Security-Policy" content="default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval'">
```

## Soporte

Para problemas específicos de despliegue, consulta:

- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Android Deployment](https://developer.android.com/guide/app-bundle)
- [Web Deployment](https://flutter.dev/docs/deployment/web)
