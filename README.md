# 📱 Checador Flutter - Aplicación Móvil

Aplicación móvil desarrollada en Flutter para el Sistema Checador. Esta app se conecta al mismo backend Express.js que utiliza el frontend Angular.

## 🚀 Características

- ✅ Autenticación de usuarios
- ✅ Módulos por rol:
  - **Administrador**: Gestión completa del sistema
  - **Alumno**: Consulta de horarios
  - **Maestro**: Dashboard y gestión de asistencias
  - **Jefe de Grupo**: Consulta de horarios y asistencias
  - **Checador**: Control de asistencia
- ✅ Sincronización con el backend en tiempo real
- ✅ Interfaz moderna y responsive

## 📋 Requisitos

- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Android Studio / VS Code con extensiones de Flutter
- Backend corriendo (ver carpeta `back/`)

## 🛠️ Instalación

### 1. Instalar dependencias

```bash
cd flutter
flutter pub get
```

### 2. Configurar URL del backend

Edita el archivo `lib/config/environment.dart` y actualiza la URL del backend:

```dart
class Environment {
  static const String apiUrl = 'https://checador-backend-faf7.onrender.com/api';
  // O para desarrollo local:
  // static const String apiUrl = 'http://localhost:3000/api';
}
```

### 3. Ejecutar la aplicación

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en dispositivo/emulador
flutter run

# Ejecutar en modo release
flutter run --release
```

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── config/
│   └── environment.dart     # Configuración de URLs
├── models/                  # Modelos de datos
│   ├── usuario.dart
│   ├── horario.dart
│   └── asistencia.dart
├── services/                # Servicios API
│   ├── auth_service.dart
│   ├── horario_service.dart
│   └── asistencia_service.dart
├── providers/               # State management
│   └── auth_provider.dart
├── screens/                 # Pantallas
│   ├── login/
│   ├── admin/
│   ├── alumno/
│   ├── maestro/
│   ├── jefe/
│   └── checador/
├── widgets/                 # Widgets reutilizables
└── routes/                  # Configuración de rutas
    └── app_router.dart
```

## 🔐 Autenticación

La app utiliza el mismo sistema de autenticación que el frontend Angular:
- Login con email y contraseña
- Tokens almacenados localmente
- Navegación basada en roles

## 🌐 API Backend

La app se conecta al mismo backend Express.js:
- Base URL: Configurada en `lib/config/environment.dart`
- Endpoints: `/api/auth/login`, `/api/horarios`, `/api/asistencias`, etc.

## 📦 Build

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 🐛 Troubleshooting

### Error de conexión al backend
- Verifica que el backend esté corriendo
- Revisa la URL en `environment.dart`
- Verifica permisos de internet en el dispositivo

### Error de dependencias
```bash
flutter clean
flutter pub get
```

## 📚 Recursos

- [Documentación Flutter](https://flutter.dev/docs)
- [Backend API](../back/README.md)
- [Frontend Angular](../front/README.md)

