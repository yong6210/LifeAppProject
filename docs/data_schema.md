# ISAR Data Schema Overview

## Session
- `id` (`Id`, auto-increment primary key)
- `type` (`String`, values: focus/rest/workout/sleep) - indexed for filters
- `startedAt` (`DateTime`) - indexed for range queries
- `endedAt` (`DateTime?`)
- `localDate` (`DateTime`) - indexed for day-level lookups
- `deviceId` (`String`) - hashed index for bucketing per device
- `tags` (`List<String>`)
- `note` (`String?`)
- `createdAt` / `updatedAt`

## DailySummaryLocal
- `id` (`Id`)
- `date` (`DateTime`) + composite index with `deviceId` (unique)
- `deviceId` (`String`)
- `focusMinutes`, `restMinutes`, `workoutMinutes`, `sleepMinutes`
- `updatedAt`

## Routine
- `id` (`Id`)
- `name` (`String`)
- `steps` (`List<RoutineStep>`, embedded)
- `colorTheme` (`String`)
- `createdAt` / `updatedAt`

### RoutineStep (embedded)
- `mode` (`String` focus/rest/workout/sleep)
- `durationMinutes` (`int`)
- `playSound` (`bool`)
- `soundId` (`String?`)

## Settings
- `id` (`Id`, fixed at 0)
- `theme`, `locale`, `deviceId`
- `soundIds` (`List<String>`)
- `presets` (`List<Preset>`, embedded)
- `notificationPrefs` (`NotificationPrefs`, embedded)
- `lastBackupAt`
- `focusMinutes`, `restMinutes`, `workoutMinutes`, `sleepMinutes`
- `lastMode`
- `createdAt` / `updatedAt`

### Preset (embedded)
- `id`, `name`, `mode`, `durationMinutes`, `autoPlaySound`, `soundId`

### NotificationPrefs (embedded)
- `focusComplete`, `restComplete`, `workoutComplete`, `sleepAlarm`

## ChangeLog
- `id` (`Id`)
- `entity` (`String`, collection name)
- `entityId` (`int`)
- `action` (`String`, created/updated/deleted) - indexed
- `occurredAt` (`DateTime`) - indexed
- `processed` (`bool`)

> These schemas are generated into `*.g.dart` using `isar_generator` 3.1.0+1 with analyzer overrides described in `docs/dependency_setup.md`.
