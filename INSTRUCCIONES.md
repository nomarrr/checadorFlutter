# 📱 Instrucciones de Desarrollo - App Flutter

## 🚀 Inicio Rápido

### 1. Instalar Flutter

Si aún no tienes Flutter instalado:

1. Descarga Flutter desde: https://flutter.dev/docs/get-started/install
2. Agrega Flutter a tu PATH
3. Verifica la instalación:
```bash
flutter doctor
```

### 2. Configurar el Proyecto

```bash
cd flutter
flutter pub get
```

### 3. Configurar URL del Backend

Edita `lib/config/environment.dart`:

**Para producción (Render):**
```dart
static const String apiUrl = 'https://checador-backend-faf7.onrender.com/api';
```

**Para desarrollo local:**
- **Emulador Android**: `http://10.0.2.2:3000/api`
- **Dispositivo físico**: `http://[TU_IP_LOCAL]:3000/api`
  - Encuentra tu IP con: `ipconfig` (Windows) o `ifconfig` (Mac/Linux)

### 4. Ejecutar la App

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release
```

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── config/
│   └── environment.dart        # Configuración de URLs
├── models/                     # Modelos de datos
│   ├── usuario.dart
│   ├── horario.dart
│   └── asistencia.dart
├── services/                   # Servicios API
│   ├── auth_service.dart
│   ├── horario_service.dart
│   └── asistencia_service.dart
├── providers/                  # State management (Provider)
│   └── auth_provider.dart
├── screens/                    # Pantallas de la app
│   ├── login/
│   │   └── login_screen.dart
│   ├── admin/
│   │   └── admin_dashboard_screen.dart
│   ├── alumno/
│   │   └── alumno_horario_screen.dart
│   ├── maestro/
│   │   └── maestro_dashboard_screen.dart
│   ├── jefe/
│   │   └── jefe_horario_screen.dart
│   └── checador/
│       └── checador_control_screen.dart
└── routes/
    └── app_router.dart         # Configuración de rutas
```

## 🔐 Autenticación

La app utiliza el mismo sistema de autenticación que el frontend Angular:

- **Login**: Email y contraseña
- **Token**: Almacenado en `SharedPreferences`
- **Usuario**: Almacenado en `SharedPreferences`
- **Navegación**: Basada en el rol del usuario

## 🌐 Conexión con el Backend

La app se conecta al mismo backend Express.js que el frontend Angular:

- **Base URL**: Configurada en `lib/config/environment.dart`
- **Endpoints**: 
  - `/api/auth/login` - Login
  - `/api/horarios` - Horarios
  - `/api/asistencias/*` - Asistencias

## 🎨 Roles y Navegación

### Administrador
- Dashboard con opciones de gestión
- Acceso a todas las funcionalidades (próximamente)

### Alumno
- Consulta de horarios
- Visualización de su horario semanal

### Maestro
- Dashboard con horarios asignados
- Gestión de asistencias (próximamente)

### Jefe de Grupo
- Consulta de horarios del grupo
- Visualización de asistencias (próximamente)

### Checador
- Control de asistencia
- Registro de asistencias (Presente/Falta/Retardo)

## 🛠️ Comandos Útiles

### Desarrollo
```bash
# Limpiar build
flutter clean

# Obtener dependencias
flutter pub get

# Actualizar dependencias
flutter pub upgrade

# Verificar código
flutter analyze

# Formatear código
flutter format lib/
```

### Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Testing
```bash
# Ejecutar tests
flutter test

# Ejecutar con cobertura
flutter test --coverage
```

## 🐛 Troubleshooting

### Error: "Unable to find a suitable Android SDK"
```bash
flutter doctor --android-licenses
```

### Error de conexión al backend
1. Verifica que el backend esté corriendo
2. Revisa la URL en `environment.dart`
3. Para emulador Android, usa `10.0.2.2` en lugar de `localhost`
4. Para dispositivo físico, usa la IP de tu computadora

### Error: "Package not found"
```bash
flutter clean
flutter pub get
```

### Error de permisos (Android)
Verifica que `android/app/src/main/AndroidManifest.xml` tenga:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## 📦 Dependencias Principales

- **http**: Cliente HTTP para llamadas API
- **provider**: State management
- **shared_preferences**: Almacenamiento local
- **go_router**: Navegación y routing
- **intl**: Formateo de fechas y números

## 🔄 Próximas Mejoras

- [ ] Gestión completa de usuarios (Admin)
- [ ] Gestión de horarios (Admin)
- [ ] Consulta de asistencias (Admin)
- [ ] Registro de asistencias (Maestro)
- [ ] Visualización de asistencias del grupo (Jefe)
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Sincronización automática

## 📚 Recursos

- [Documentación Flutter](https://flutter.dev/docs)
- [Backend API](../back/README.md)
- [Frontend Angular](../front/README.md)

