import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'notification_service.dart';
import '../models/user_preferences.dart';
import '../services/daily_task_manager.dart';
import 'package:workmanager/workmanager.dart';

enum NotificationConfigState {
  idle,
  detectingPlatform,
  requestingPermissions,
  initializingService,
  configuringWorkManager,
  savingPreferences,
  success,
  errorPermissionDenied,
  errorInitializationFailed,
  errorWorkManagerFailed,
  errorUnknown
}

class NotificationConfigurationService {
  static bool _isConfiguring = false;
  
  /// Configura completamente el sistema de notificaciones
  /// Esta es la ÚNICA función pública - maneja todo el proceso costoso
  static Future<NotificationConfigState> configureNotifications() async {
    if (_isConfiguring) {
      print('🔄 Ya hay una configuración en proceso');
      return NotificationConfigState.idle;
    }
    
    _isConfiguring = true;
    
    try {
      print('\n🚀 === INICIANDO CONFIGURACIÓN DE NOTIFICACIONES ===');
      
      // PASO 1: Detectar plataforma
      final platformInfo = await _detectPlatform();
      if (platformInfo == null) {
        return _finishWithState(NotificationConfigState.errorUnknown);
      }
      
      // PASO 2: Manejar permisos según plataforma
      final permissionsResult = await _handlePermissions(platformInfo);
      if (permissionsResult != NotificationConfigState.initializingService) {
        return _finishWithState(permissionsResult);
      }
      
      // PASO 3: Inicializar NotificationService
      final initResult = await _initializeNotificationService();
      if (initResult != NotificationConfigState.configuringWorkManager) {
        return _finishWithState(initResult);
      }
      
      // PASO 4: Configurar WorkManager/DailyTaskManager
      final workManagerResult = await _configureWorkManager();
      if (workManagerResult != NotificationConfigState.savingPreferences) {
        return _finishWithState(workManagerResult);
      }
      
      // PASO 5: Guardar estado en preferencias
      final prefsResult = await _saveNotificationState();
      if (prefsResult != NotificationConfigState.success) {
        return _finishWithState(prefsResult);
      }
      
      print('✅ === CONFIGURACIÓN COMPLETADA EXITOSAMENTE ===\n');
      return _finishWithState(NotificationConfigState.success);
      
    } catch (e, stackTrace) {
      print('💥 ERROR INESPERADO en configuración: $e');
      print('📍 Stack trace: $stackTrace');
      return _finishWithState(NotificationConfigState.errorUnknown);
    }
  }
  
  static NotificationConfigState _finishWithState(NotificationConfigState state) {
    _isConfiguring = false;
    return state;
  }
  
  /// PASO 1: Detecta plataforma y versión Android
  static Future<_PlatformInfo?> _detectPlatform() async {
    try {
      print('🔍 PASO 1: Detectando plataforma...');
      
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        print('📱 Plataforma: Android ${androidInfo.version.release}');
        print('🔢 SDK: $sdkInt');
        
        if (sdkInt >= 33) {
          print('✅ Android 13+ detectado - Permisos POST_NOTIFICATIONS requeridos');
          return _PlatformInfo(PlatformType.androidNew, sdkInt);
        } else {
          print('✅ Android <13 detectado - Permisos automáticos');
          return _PlatformInfo(PlatformType.androidOld, sdkInt);
        }
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        print('🍎 Plataforma: iOS ${iosInfo.systemVersion}');
        print('✅ iOS detectado - Permisos manejados por NotificationService');
        return _PlatformInfo(PlatformType.ios, 0);
      } else {
        print('❌ Plataforma no soportada: ${Platform.operatingSystem}');
        return null;
      }
    } catch (e) {
      print('💥 ERROR detectando plataforma: $e');
      return null;
    }
  }
  
  /// PASO 2: Maneja permisos según plataforma
  static Future<NotificationConfigState> _handlePermissions(_PlatformInfo platformInfo) async {
    try {
      print('🔐 PASO 2: Manejando permisos...');
      
      switch (platformInfo.type) {
        case PlatformType.androidOld:
          print('⏭️  Android <13: Saltando solicitud de permisos');
          return NotificationConfigState.initializingService;
          
        case PlatformType.androidNew:
          return await _requestAndroidPermissions();
          
        case PlatformType.ios:
          print('⏭️  iOS: Permisos serán manejados por NotificationService.initialize()');
          return NotificationConfigState.initializingService;
      }
    } catch (e) {
      print('💥 ERROR manejando permisos: $e');
      return NotificationConfigState.errorUnknown;
    }
  }
  
  /// Solicita permisos específicos de Android 13+
  static Future<NotificationConfigState> _requestAndroidPermissions() async {
    try {
      print('📋 Solicitando permiso POST_NOTIFICATIONS...');
      
      final android = NotificationService.resolveAndroid();
      if (android == null) {
        print('❌ No se pudo resolver AndroidNotificationPlugin');
        return NotificationConfigState.errorUnknown;
      }
      
      final permissionGranted = await android.requestNotificationsPermission();
      print('🎯 Resultado permiso: $permissionGranted');
      
      if (permissionGranted == true) {
        print('✅ Permisos Android concedidos');
        return NotificationConfigState.initializingService;
      } else if (permissionGranted == false) {
        print('❌ Permisos Android denegados por el usuario');
        return NotificationConfigState.errorPermissionDenied;
      } else {
        print('⚠️  Permisos Android: resultado null (posible error del sistema)');
        // En algunos casos null puede significar "ya otorgado", intentamos continuar
        return NotificationConfigState.initializingService;
      }
    } catch (e) {
      print('💥 ERROR solicitando permisos Android: $e');
      return NotificationConfigState.errorPermissionDenied;
    }
  }
  
  /// PASO 3: Inicializa NotificationService (tareas baratas)
  static Future<NotificationConfigState> _initializeNotificationService() async {
    try {
      print('⚙️  PASO 3: Inicializando NotificationService...');
      
      final initialized = await NotificationService.initialize();
      print('🎯 Resultado inicialización: $initialized');
      
      if (initialized) {
        print('✅ NotificationService inicializado correctamente');
        return NotificationConfigState.configuringWorkManager;
      } else {
        print('❌ Falló la inicialización de NotificationService');
        return NotificationConfigState.errorInitializationFailed;
      }
    } catch (e) {
      print('💥 ERROR inicializando NotificationService: $e');
      return NotificationConfigState.errorInitializationFailed;
    }
  }
  
  /// PASO 4: Configura WorkManager y DailyTaskManager
  static Future<NotificationConfigState> _configureWorkManager() async {
    try {
      print('🔄 PASO 4: Configurando WorkManager...');
      
      // Primero cancelar cualquier tarea previa
      await Workmanager().cancelAll();
      print('🧹 WorkManager: tareas previas canceladas');
      
      // Inicializar DailyTaskManager
      final dailyTaskManager = DailyTaskManager();
      dailyTaskManager.initialize();
      print('✅ DailyTaskManager inicializado');
      
      return NotificationConfigState.savingPreferences;
    } catch (e) {
      print('💥 ERROR configurando WorkManager: $e');
      return NotificationConfigState.errorWorkManagerFailed;
    }
  }
  
  /// PASO 5: Guarda el estado final en SharedPreferences
  static Future<NotificationConfigState> _saveNotificationState() async {
    try {
      print('💾 PASO 5: Guardando estado en preferencias...');
      
      await UserPreferences.setNotificationsReady(true);
      print('✅ Estado guardado: notificationsReady = true');
      
      // Verificar que se guardó correctamente
      final verification = await UserPreferences.getNotificationsReady();
      print('🔍 Verificación: notificationsReady = $verification');
      
      if (verification) {
        return NotificationConfigState.success;
      } else {
        print('❌ Error: no se pudo verificar el estado guardado');
        return NotificationConfigState.errorUnknown;
      }
    } catch (e) {
      print('💥 ERROR guardando preferencias: $e');
      return NotificationConfigState.errorUnknown;
    }
  }
  
  /// Verifica si las notificaciones ya están configuradas
  static Future<bool> isAlreadyConfigured() async {
    try {
      final isReady = await UserPreferences.getNotificationsReady();
      print('🔍 Verificación configuración existente: $isReady');
      return isReady;
    } catch (e) {
      print('💥 ERROR verificando configuración: $e');
      return false;
    }
  }
  
  /// Desactiva completamente las notificaciones
  static Future<void> disableNotifications() async {
    try {
      print('\n🔴 === DESACTIVANDO NOTIFICACIONES ===');
      
      print('🧹 Cancelando todas las tareas de WorkManager...');
      await Workmanager().cancelAll();
      
      print('💾 Guardando estado: notificationsReady = false');
      await UserPreferences.setNotificationsReady(false);
      
      final verification = await UserPreferences.getNotificationsReady();
      print('🔍 Verificación: notificationsReady = $verification');
      print('✅ === NOTIFICACIONES DESACTIVADAS ===\n');
    } catch (e) {
      print('💥 ERROR desactivando notificaciones: $e');
    }
  }
}

class _PlatformInfo {
  final PlatformType type;
  final int androidSdk;
  
  _PlatformInfo(this.type, this.androidSdk);
}

enum PlatformType {
  androidOld,   // Android <13
  androidNew,   // Android 13+
  ios
}