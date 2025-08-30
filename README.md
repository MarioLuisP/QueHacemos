# myapp

lib
├── l10n
│   ├── intl_en.arb
│   ├── intl_messages.arb
│   ├── intl_messages_all.dart
│   └── intl_messages_messages.dart
├── main.dart
└── src
    ├── data
    │   ├── database
    │   │   └── database_helper.dart
    │   └── repositories
    │       └── event_repository.dart
    ├── main.dart
    ├── models
    │   ├── events.dart
    │   ├── models.dart
    │   └── user_preferences.dart
    ├── navigation
    │   └── bottom_nav.dart
    ├── pages
    │   ├── calendar_page.dart
    │   ├── explore_page.dart
    │   ├── favorites_page.dart
    │   ├── home_page.dart
    │   ├── pages.dart
    │   └── settings_page.dart
    ├── providers
    │   ├── auth_provider.dart
    │   ├── category_constants.dart
    │   ├── event_data_builder.dart
    │   ├── event_filter_logic.dart
    │   ├── favorites_provider.dart
    │   ├── filter_criteria.dart
    │   ├── home_viewmodel.dart
    │   ├── mock_auth_provider.dart
    │   ├── notifications_provider.dart
    │   ├── preferences_provider.dart
    │   └── provider_config.dart
    ├── services
    │   ├── auth_service.dart
    │   ├── event_service.dart
    │   ├── mock_auth_service.dart
    │   ├── services.dart
    │   └── sync_service.dart
    ├── themes
    │   └── themes.dart
    ├── utils
    │   ├── colors.dart
    │   ├── dimens.dart
    │   ├── styles.dart
    │   └── utils.dart
    └── widgets
        ├── app_bars
        │   ├── main_app_bar.dart
        │   └── components
        │       ├── contact_button.dart
        │       ├── notifications_bell.dart
        │       └── user_avatar_widget.dart
        ├── cards
        │   ├── fast_event_card.dart
        │   ├── gold_shimmer_manager.dart
        │   ├── gold_shimmer_painter.dart
        │   ├── platinum_particles_manager.dart
        │   ├── platinum_particles_painter.dart
        │   └── unified_event_card_painter.dart
        ├── chips
        │   ├── event_chip_widget.dart
        │   └── filter_chips_widget.dart
        ├── contact_modal.dart
        ├── event_detail_modal.dart
        └── widgets.dart

ahora


lib/src/
├── cache/ # NUEVO: Gestión de cache
│ ├── event_cache_service.dart # Cache 203KB en memoria
│ ├── memory_filter_service.dart # Filtros sobre arrays puros
│ └── cache_models.dart # Structs optimizados
│
├── sync/ # NUEVO: Sync independiente
│ ├── clean_sync_service.dart # Job 1 vez/día, zero UI deps
│ ├── firestore_client.dart # Conexión Firebase limpia
│ └── sync_scheduler.dart # Timing y condiciones
│
├── providers/ # SIMPLIFICADOS
│ ├── simple_home_provider.dart # Reemplazo HomeViewModel (50 líneas)
│ ├── cache_provider.dart # Estado del cache
│ ├── favorites_provider.dart # ✅ MANTENER existente
│ └── preferences_provider.dart # 🔧 FIX: quitar auto-notify
│
├── data/ # MEJORADOS
│ ├── repositories/
│ │ ├── event_repository.dart # 🔧 + getCacheData()
│ │ └── cache_repository.dart # NUEVO: Queries optimizadas
│ └── database/
│ └── database_helper.dart # ✅ MANTENER schema
│
├── pages/ # NUEVOS + MIGRADOS
│ ├── clean_home_page.dart # NUEVO: ListView simple
│ ├── calendar_page.dart # ✅ MIGRAR con nuevo provider
│ ├── explore_page.dart # ✅ MIGRAR con nuevo provider
│ ├── favorites_page.dart # ✅ MIGRAR con nuevo provider
│ └── settings_page.dart # ✅ MANTENER
│
├── widgets/ # JOYAS EXISTENTES
│ ├── cards/
│ │ ├── fast_event_card.dart # ✨ MANTENER: cambiar data source
│ │ └── unified_*.dart # ✨ MANTENER: son joyas
│ ├── event_detail_modal.dart # ✨ MANTENER: cambiar query
│ └── ... # ✅ MANTENER todo lo demás
│
└── utils/ themes/ models/ # ✅ MANTENER TODO

C:\Users\Mario\AndroidStudioProjects\QueHacemos\lib>tree /f /a
Listado de rutas de carpetas
El número de serie del volumen es C62D-0816
C:.
|   firebase_options.dart
|   main.dart
|R
\---src
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