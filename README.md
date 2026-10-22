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
- `services` — servicios recurrentes (suscripciones, facturas, etc.)
- `transactions` — movimientos (ingresos y gastos)
- `transfers` — transferencias entre cuentas

### Esquema de base de datos (`db/migrations/V001__initial_schema.sql`)

Tablas principales: `accounts`, `categories`, `transactions`, `services`,
`invoices`, `monthly_account_balances`.

## Configuración

Las variables de entorno (Supabase y Google) no se empaquetan como archivo:
se compilan dentro de la app con `--dart-define-from-file`.

1. Copiá `app/.env.example` a `app/.env` (está en `.gitignore`) y completalo:
   `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_WEB_CLIENT_ID` y
   `GOOGLE_IOS_CLIENT_ID`.
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
