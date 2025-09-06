# myapp

Tech Stack - QuehaCeMos Córdoba
Frontend:

Flutter 3.32.6
Dart 3.8.1
Provider (state management)
Material Design 3

Backend & Data:

Firebase Firestore (cloud database)
SQLite (local cache)
Firebase Auth + Google Sign-In
Firebase Analytics

Key Dependencies:

cached_network_image (image handling)
shared_preferences (local storage)
flutter_local_notifications (push notifications)
url_launcher (external links)
share_plus (content sharing)

Architecture:

Repository pattern (data layer)
Provider pattern (state management)
Event-driven cache system
Daily sync with offline-first approach

Development:

Android Studio
Java 21
Android SDK 35
Git version control

Deployment:

Google Play Store
Firebase Console (backend management)

C:\Users\Mario\AndroidStudioProjects\QueHacemos\lib>tree /f /a
Listado de rutas de carpetas
El número de serie del volumen es C62D-0816
C:.
|   firebase_options.dart
|   main.dart
|
src>

+---cache
|       cache_models.dart
|       event_cache_service.dart
|
+---data
|   +---database
|   |       database_helper.dart
|   |
|   \---repositories
|           event_repository.dart
|
+---mock
|       mock_events.dart
|
+---models
|       user_preferences.dart
|
+---navigation
|       bottom_nav.dart
|
+---pages
|       calendar_page.dart
|       explore_page.dart
|       favorites_page.dart
|       home_page.dart
|       pages.dart
|       settings_page.dart
|
+---providers
|       auth_provider.dart
|       favorites_provider.dart
|       notifications_provider.dart
|       simple_home_provider.dart
|
+---services
|       auth_service.dart
|       daily_task_manager.dart
|       first_install_service.dart
|       notification_config_service.dart
|       notification_service.dart
|
+---sync
|       firestore_client.dart
|       sync_service.dart
|
+---themes
|       themes.dart
|
+---utils
|       colors.dart
|       dimens.dart
|       styles.dart
|
\---widgets
|   contact_modal.dart
|   notification_card_widget.dart
|
+---app_bars
|   |   main_app_bar.dart
|   |
|   \---components
|           notifications_bell.dart
|           user_avatar_mock.dart
|
+---cards
|       event_card_widget.dart
|       event_detail_modal.dart
|
\---chips
event_chip_widget.dart
filter_chips_widget.dart
event_chip_widget.dart
filter_chips_widget.dart



$ flutter build apk --release --split-per-abi --target lib/src/main.dart

$ flutter run -t lib/src/main.dart

## 🔧 Configuración de Firebase para iOS

Esta app usa Firebase para autenticación, base de datos, etc.  
Para compilar en iOS, necesitás agregar manualmente el archivo de configuración de Firebase.

### 📄 Paso 1: Obtener el archivo `GoogleService-Info.plist`
1. Tienes que tener el archivo `GoogleService-Info.plist`.

### 📁 Paso 2: Colocar el archivo en el proyecto
Copiá el archivo en la siguiente ruta dentro del repo:
ios/
└── Runner/
    └── GoogleService-Info.plist  ← Aquí va tu PLIST

> ⚠️ **Importante**: Este archivo está ignorado en `.gitignore`, así que no se incluye en el repositorio.


para android

android/
└── app/
    └── google-services.json  ← Aquí va tu JSON

    🎯 SECUENCIA MAÑANA:

Abrir CloudShell
source ~/setup-flutter.sh ← OBLIGATORIO
Ver los mensajes de confirmación

source ~/setup-flutter.sh
fc

flutter run -t lib/src/main.dart
# Para correr:
flutter run

# Para compilar:
flutter build apk --release --split-per-abi