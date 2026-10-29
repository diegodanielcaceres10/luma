# luma

A lightweight personal finance app for tracking income, expenses, budgets, and monthly spending insights.

## Stack

- **App**: Flutter (SDK `^3.5.3`), multiplataforma (Android, iOS, web, Linux, macOS, Windows).
- **Backend**: [Supabase](https://supabase.com) (auth, base de datos y storage).
- **Autenticación**: `supabase_flutter` + `google_sign_in` (Google Sign-In).
- **Navegación**: `go_router`.
- **Otras libs clave**: `pdf` + `printing` (exportar estadísticas en PDF),
  `flutter_colorpicker` (selector de color de categorías), `intl`
  (formateo de fechas/moneda).

## Estructura del repo

```
luma/
├── app/                  # Proyecto Flutter
│   ├── lib/
│   │   ├── app/          # App shell, router, theming
│   │   ├── core/         # Config, navegación, utils y widgets compartidos
│   │   └── features/     # Módulos por feature (ver abajo)
│   ├── assets/           # Imágenes, logo y fuentes
│   ├── scripts/          # Scripts de build, test y ejecución (.ps1 / .sh)
│   └── pubspec.yaml
└── db/
    └── migrations/       # Migraciones SQL del esquema de Supabase/Postgres
```

### Features (`app/lib/features`)

- `accounts` — cuentas del usuario (bancos, efectivo, tarjetas, etc.) y sus balances mensuales
- `auth` — login / registro (Supabase Auth + Google Sign-In) y preferencias del usuario
- `categories` — categorías de ingresos/gastos (color, ícono/emoji)
- `home` — dashboard / pantalla de inicio
- `invoices` — facturas asociadas a servicios
- `notifications` — notificaciones push: registro del token del dispositivo y avisos con la app abierta
- `services` — servicios recurrentes (suscripciones, facturas, etc.)
- `transactions` — movimientos (ingresos y gastos)
- `transfers` — transferencias entre cuentas

### Esquema de base de datos (`db/migrations/V001__initial_schema.sql`)

Tablas principales: `accounts`, `categories`, `transactions`, `services`,
`invoices`, `monthly_account_balances`, `device_tokens`.

### Notificaciones push

Un job de `pg_cron` invoca cada hora la Edge Function
`send-daily-notifications` (`supabase/functions/send-daily-notifications`).
Cuando la hora local en `NOTIFY_TIMEZONE` coincide con `NOTIFY_HOUR`, envía por
FCM a los dispositivos de `device_tokens`: facturas que vencen hoy, facturas
del mes sin cargar y cuentas con 5 días o más sin actualizar. La consulta es
`notifications_due` (`V003__push_notifications.sql`) y solo la puede ejecutar
`service_role`.

Puesta en marcha (una sola vez):

1. Aplicá `V002` y `V003` en Supabase y habilitá las extensiones `pg_cron` y
   `pg_net`.
2. En Firebase, generá una clave de cuenta de servicio (Configuración del
   proyecto → Cuentas de servicio) y guardala fuera del repo.
3. Configurá los secrets y desplegá la función (sin verificación de JWT; la
   autenticación es el header `x-cron-secret`):

```sh
supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)" \
  CRON_SECRET=<secreto> NOTIFY_TIMEZONE=Europe/Madrid NOTIFY_HOUR=9
supabase functions deploy send-daily-notifications --no-verify-jwt
```

4. En el SQL Editor, guardá el secreto en Vault y programá el job:

```sql
select vault.create_secret('<CRON_SECRET>', 'cron_secret');
select cron.schedule(
  'send-daily-notifications',
  '0 * * * *',
  $$ select net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-daily-notifications',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  ); $$
);
```

Para probar, primero con `{"dry_run": true, "force": true}` (lista lo que se
enviaría sin llamar a FCM) y después con `{"force": true}`:

```sh
curl -X POST https://<PROJECT_REF>.supabase.co/functions/v1/send-daily-notifications \
  -H "x-cron-secret: <secreto>" -d '{"dry_run": true, "force": true}'
```

Notas:

- Los avisos salen solo por push: no hay un camino local de respaldo, así que
  sin servidor (por ejemplo con el proyecto pausado) no llega ninguno.
- Con la app abierta en Android, el sistema no muestra el push por sí solo: la
  app lo muestra como una notificación local.
- Si la corrida de las 9:00 falla, no se reintenta hasta el día siguiente.
- Los tokens que FCM informa como inválidos se borran de `device_tokens`; el
  resto de los errores no borra nada.
- Los proyectos del plan gratuito de Supabase se pausan tras un período de
  inactividad, y mientras estén pausados no se envía nada.

#### Web (PWA)

La PWA recibe el mismo aviso diario por Web Push (Chrome, Edge y Android; no
se da soporte a iPhone/Safari). Usa las mismas piezas: el job de `pg_cron`, la
función y `device_tokens` (con `platform = 'web'`).

1. En Firebase → Configuración del proyecto → Tus apps, agregá una app Web y
   copiá `apiKey`, `appId`, `messagingSenderId` y `projectId`.
2. En Firebase → Cloud Messaging → Web Push certificates, generá el par de
   claves y copiá la clave pública (VAPID).
3. Cargá los cinco valores como secrets de GitHub: `FIREBASE_WEB_API_KEY`,
   `FIREBASE_WEB_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`,
   `FIREBASE_PROJECT_ID` y `FIREBASE_VAPID_KEY`. El workflow de Cloudflare
   Pages los pasa a la app (`--dart-define-from-file`) y
   `app/scripts/configure_web_push.sh` los escribe en
   `build/web/firebase-messaging-sw.js` después del build. Son valores
   públicos, como los de Supabase.
4. Volvé a desplegar la PWA, activá las notificaciones en Preferencias y
   aceptá el permiso del navegador. Verificá que aparezca una fila con
   `platform = 'web'` en `device_tokens` y probá con `dry_run` y `force`.

Notas de la versión web:

- Sin ninguna de las cinco variables, la PWA se publica sin push y el switch
  queda deshabilitado, como antes. Con solo algunas, el deploy falla para no
  publicar una configuración a medias.
- Con la PWA abierta y enfocada no se muestra el aviso; con la PWA cerrada o en
  segundo plano lo muestra el service worker.
- Si el navegador bloquea el permiso, el switch queda activado pero no llega
  nada: hay que habilitarlo desde la configuración del sitio.
- En desarrollo local (`flutter run -d chrome`) el service worker conserva sus
  marcadores y push no funciona; solo se prueba en el build desplegado.
- La versión del SDK de Firebase del service worker (10.14.1) está fijada en
  `app/web/firebase-messaging-sw.js`.

## Configuración

Las variables de entorno (Supabase y Google) no se empaquetan como archivo:
se compilan dentro de la app con `--dart-define-from-file`.

1. Copiá `app/.env.example` a `app/.env` (está en `.gitignore`) y completalo:
   `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID` y
   `GOOGLE_IOS_CLIENT_ID`. Para push en la PWA también van las cinco
   variables `FIREBASE_*` (ver "Web (PWA)" en Notificaciones push).
2. Pasá el archivo en cada comando, desde `app/`:

```sh
flutter run -d chrome --web-port=5005 --dart-define-from-file=.env
flutter build web --dart-define-from-file=.env
flutter build apk --dart-define-from-file=.env   # o scripts/build_apk.*
```

Solo van ahí valores públicos por diseño (URL y publishable key de Supabase,
client IDs de Google); la seguridad de los datos depende de las políticas RLS.
Nunca pongas una `service_role` key ni ningún secreto en estas variables: al
quedar compiladas, cualquiera puede extraerlas del build.

Si compilás en CI (por ejemplo GitHub Actions), definí esas variables como
secrets/variables y generá el `.env` antes del build, o pasá cada una con
`--dart-define=NOMBRE=valor`.

### Scripts

En `app/scripts/` hay un script por tarea, en PowerShell (`.ps1`) y en shell
(`.sh`). Se pueden ejecutar desde cualquier carpeta, por ejemplo desde la raíz
del repo, y todos muestran los mismos logs: qué hacen, el comando exacto,
el resultado y el tiempo total.

| Tarea | PowerShell | Shell |
| --- | --- | --- |
| Compilar un APK debug en `app/dist/` | `.\app\scripts\build_apk.ps1` (`-Install` lo instala con adb) | `./app/scripts/build_apk.sh` (`INSTALL=1`) |
| Ejecutar los tests | `.\app\scripts\test.ps1 [args de flutter test]` | `./app/scripts/test.sh [args de flutter test]` |
| Ejecutar la app en Chrome (puerto 5005) | `.\app\scripts\run.ps1` (`-Port`, `-Device`) | `./app/scripts/run.sh` (`PORT`, `DEVICE`) |

La compilación y la ejecución necesitan `app/.env` (ver Configuración).

### Crashlytics (Android)

Crashlytics necesita el `google-services.json` de la app Android registrada en
Firebase (`io.luma.app`). No se commitea (está en `app/android/.gitignore`) y
sin él el build de Android falla:

- **Local:** descargalo desde la consola de Firebase (Configuración del
  proyecto → tu app Android) y guardalo en `app/android/app/google-services.json`.
- **CI:** guardalo codificado en base64 como secret `GOOGLE_SERVICES_JSON_BASE64`
  (`base64 -w0 google-services.json` en Linux, `base64 -i google-services.json`
  en macOS). El workflow de distribución lo restaura antes de compilar.
