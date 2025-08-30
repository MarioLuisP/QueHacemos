graph TB
%% Inicialización
App[App Startup] --> DTM_Init[DailyTaskManager.initialize]
DTM_Init --> WM_Setup[WorkManager Setup]
WM_Setup --> Schedule_Tasks[Programar tareas diarias]

    %% Configuración de tareas
    Schedule_Tasks --> Sync_1AM[Sync Task - 1:00 AM]
    Schedule_Tasks --> Notif_11AM[Notification Task - 11:00 AM]
    
    %% Flujo de Sincronización (1 AM)
    Sync_1AM -->|WorkManager ejecuta| Sync_Check{¿shouldSync?}
    Sync_Check -->|No| Sync_NotNeeded[SyncResult.notNeeded]
    Sync_Check -->|Sí| Download[downloadDailyBatches]
    
    Download --> Events_Check{¿Eventos nuevos?}
    Events_Check -->|No| NoNewData[SyncResult.noNewData + Notif 'Todo actualizado']
    Events_Check -->|Sí| Process[_processEvents: insertEvents]
    
    Process --> Cleanup[_performCleanup]
    Cleanup --> CleanOld[cleanOldEvents]
    Cleanup --> RemoveDups[removeDuplicatesByCodes]
    
    RemoveDups --> UpdateTS[updateSyncTimestamp]
    UpdateTS --> SendNotifs[_sendSyncNotifications]
    SendNotifs --> MaintainSchedule[_maintainNotificationSchedules]
    MaintainSchedule --> RefreshHome[homeProvider?.refresh]
    RefreshHome --> SyncComplete[SyncResult.success + Stream]
    
    %% Flujo de Notificaciones (11 AM)
    Notif_11AM -->|WorkManager ejecuta| NotifReady{¿NotificationsReady?}
    NotifReady -->|No| NotifSkip[Skip - return true]
    NotifReady -->|Sí| TimeCheck{¿Hora >= 11?}
    
    TimeCheck -->|Sí| SendImmediate[sendImmediateNotificationForToday]
    TimeCheck -->|No| ScheduleToday[scheduleNotificationsForToday]
    
    %% Recovery System (App Open)
    App --> Recovery_Check[checkOnAppOpen]
    Recovery_Check -->|Hora >= 6 AM| Recovery_Loop{Para cada TaskType}
    Recovery_Loop --> NeedsExec{¿needsExecutionToday?}
    NeedsExec -->|Sí| ExecRecovery[_executeRecovery]
    NeedsExec -->|No| Recovery_Next[Siguiente tarea]
    ExecRecovery --> Recovery_Next
    Recovery_Next --> Recovery_Loop
    
    %% Mantenimiento de Notificaciones Programadas
    MaintainSchedule --> GetPending[getPendingScheduledNotifications]
    GetPending --> CheckEvents[Verificar eventos existentes]
    CheckEvents --> UpdateSchedule[Actualizar horarios si cambió fecha]
    CheckEvents --> DeleteOrphan[Eliminar notificaciones huérfanas]
    
    %% NotificationService - Programación
    ScheduleToday --> CalcTime[calculateNotificationTime]
    CalcTime --> FindEarliest[Encontrar evento más temprano]
    FindEarliest --> SetTime[Configurar 1 hora antes o 11 AM]
    SetTime --> GenMessage[generateDailyMessage]
    GenMessage --> ScheduleNotif[scheduleNotification]
    
    %% NotificationService - Inmediato
    SendImmediate --> GenImmediate[generateDailyMessage]
    GenImmediate --> ShowNotif[showNotification]
    ShowNotif --> SetBadge[setBadge]
    
    %% Tipos de Notificaciones
    SendNotifs --> NewEvents{¿> 0 eventos nuevos?}
    NewEvents -->|Sí| BasicNotif[🎭 Eventos nuevos en Córdoba]
    BasicNotif --> HighActivity{¿>= 10 eventos?}
    HighActivity -->|Sí| FireNotif[🔥 Semana cargada de cultura]
    HighActivity -->|No| CleanupCheck{¿> 5 eventos removidos?}
    FireNotif --> CleanupCheck
    CleanupCheck -->|Sí| CleanupNotif[🧹 Base de datos optimizada]
    
    %% Estados finales
    Sync_NotNeeded --> End1[Fin Sync]
    NoNewData --> End2[Fin Sync]
    SyncComplete --> End3[Fin Sync]
    NotifSkip --> End4[Fin Notificaciones]
    SetBadge --> End5[Fin Notificaciones]
    ScheduleNotif --> End6[Fin Notificaciones]
    
    %% Estilos
    classDef syncProcess fill:#416c80
    classDef notifProcess fill:#863991
    classDef recoveryProcess fill:#bd8e44
    classDef decision fill:#6e222d
    classDef endpoint fill:#3f8a3f
    class Sync_1AM,Download,Process,Cleanup,UpdateTS syncProcess
    class Notif_11AM,CalcTime,GenMessage,ScheduleNotif,ShowNotif notifProcess
    class Recovery_Check,ExecRecovery,Recovery_Loop recoveryProcess
    class Sync_Check,Events_Check,NotifReady,TimeCheck,NeedsExec decision
    class End1,End2,End3,End4,End5,End6 endpoint