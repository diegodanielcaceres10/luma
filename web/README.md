# Luma Web

## Descripción

Sitio web público de Luma, una aplicación de finanzas personales. Es una landing page estática en español, con las páginas de política de privacidad y condiciones de uso. Está hecha con Angular (componentes standalone, signals y renderizado estático en el build) y Tailwind CSS.

La aplicación móvil y la base de datos viven en otras carpetas del repositorio (`app/`, `db/`, `supabase/`); consulta el [README principal](../README.md).

## Requisitos

- Node 22 (la versión exacta está en [`.nvmrc`](.nvmrc) y el rango permitido en `engines` de `package.json`).
- npm 10, que se instala junto con Node.
- Opcional: Docker y Docker Compose, para ejecutar el servidor de desarrollo en un contenedor.

## Instalación

Desde esta carpeta (`web/`):

```bash
npm ci
```

## Ejecución y scripts

| Comando                 | Qué hace                                                                    |
| ----------------------- | --------------------------------------------------------------------------- |
| `npm start`             | Servidor de desarrollo en `http://localhost:4200/`, con recarga automática. |
| `npm run start:local`   | Igual que el anterior, en el puerto 4200 (lo usan las pruebas e2e).         |
| `npm run build`         | Compila para producción en `dist/web/`, con `/luma/` como base href.        |
| `npm test`              | Pruebas unitarias con Vitest y cobertura (umbral mínimo del 80 %).          |
| `npm run lint`          | Análisis estático con ESLint.                                               |
| `npm run e2e`           | Levanta el sitio y ejecuta las pruebas de Cypress.                          |
| `npm run cy:open`       | Abre Cypress de forma interactiva.                                          |
| `npm run deps:unused`   | Detecta dependencias sin uso con Knip.                                      |
| `npm run check:version` | Comprueba que la versión de `package.json` supere la de la rama base.       |

Para usar Docker, desde la raíz del repositorio:

```bash
docker-compose up
```

El sitio queda disponible en `http://localhost:4200/`.

Para cambiar el puerto o el modo, copia `.env.example` a `.env` (en la raíz) y edita sus variables:

- `WEB_PORT`: puerto del equipo donde se publica el sitio (por defecto 4200).
- `APP_ENV`: `local` arranca el servidor de desarrollo; `dev` y `prod` ejecutan `npm run build` con la configuración `development` o `production` de Angular.

## Estructura del proyecto

```
web/
├── src/
│   ├── app/
│   │   ├── core/        # Configuración y servicios globales (analítica, consentimiento, SEO)
│   │   ├── shared/      # Componentes, directivas y utilidades reutilizables
│   │   └── features/    # Módulos por funcionalidad: landing y legal
│   ├── fonts/           # Tipografías autoalojadas
│   └── *.spec.ts        # Pruebas de reglas del proyecto (CI, estilos, accesibilidad, Docker)
├── public/              # Archivos estáticos: favicon, imágenes, robots.txt y sitemap.xml
├── cypress/             # Pruebas end-to-end
└── scripts/             # Utilidades de Node usadas por npm y por CI
```

Los alias `@core/*`, `@shared/*` y `@features/*` apuntan a las carpetas de `src/app`.

## Despliegue

El sitio se publica en GitHub Pages con el workflow **Web Deploy GitHub Pages** cada vez que cambia `web/` en `main`. El workflow ejecuta lint, pruebas y build antes de publicar, y después una auditoría de Lighthouse. Para volver a una versión anterior, consulta la sección «Rollback de la web» del [README principal](../README.md).
