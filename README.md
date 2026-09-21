# luma
A lightweight personal finance app for tracking income, expenses, budgets, and monthly spending insights.

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
