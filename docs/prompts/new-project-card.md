Actuá como asistente técnico. Estoy documentando este proyecto como una "ficha" dentro de mi portfolio (Nura, Angular). Necesito que generes dos cosas, basándote en el código real de este repo (README, package.json, estructura de carpetas, stack, etc.):

1. UN OBJETO TypeScript que implemente esta interfaz `ProjectItem` (te la paso tal cual, no la modifiques):

export interface ProjectItem {
id: string; // slug kebab-case, igual al nombre del repo
avatar?: string; // 'assets/projects/<id>/logo.png' (dejalo así, la imagen la pongo yo)
icon?: string; // SOLO si el proyecto no tiene logo propio (ej. challenges): usar un ícono Font Awesome, ej 'fa-solid fa-bolt'
title: string;
type: 'Mobile' | 'Web' | 'Fullstack' | 'Library' | 'Challenge';
shortDescription: string; // clave i18n: PROJECTS*CARD*<ID*UPPER>\_SHORT_DESC
coverImage: string; // 'assets/projects/<id>/cover.png' o '' si no hay
techStackPreview: string[]; // 3-5 tecnologías principales, para el chip preview
status: 'COMPLETED' | 'IN_PROGRESS' | 'ARCHIVED';
year: number;
fullDescription: string; // clave i18n: PROJECTS_CARD*<ID*UPPER>\_FULL_DESC
techStackFull?: { category: string; items: string[] }[];
keyFeatures: string[]; // claves i18n: PROJECTS_CARD*<ID*UPPER>\_FEATURE_1, \_2, ... (5-7 ítems)
challenges?: string[]; // claves i18n: PROJECTS_CARD*<ID_UPPER>\_CHALLENGE_1, \_2 (2-3 ítems)
gallery?: string[]; // rutas 'assets/projects/<id>/screen-\*.png' si aplica, si no omitir
links?: { repo: string; demo?: string; npm?: string; androidAPK?: string };
metrics?: { npmDownloads?: number; githubStars?: number; testCoverage?: string };
typeDetails?:
| { kind: 'mobile'; platforms: ('android'|'ios'|'web')[]; nativePlugins: string[]; buildTool: string }
| { kind: 'web'; deployUrl: string; pwa?: boolean; responsive: boolean }
| { kind: 'fullstack'; backendStack: string[]; databases: string[]; apiType: 'REST'|'GraphQL'|'gRPC'; deployment: string }
| { kind: 'library'; packageName: string; installCommand: string; registry: 'npm'|'other' }
| { kind: 'challenge'; platform: string; difficulty: 'easy'|'medium'|'hard'; topics: string[] };
}

Reglas:

- `id`: kebab-case, igual al nombre del repo GitHub.
- Todos los campos de texto libre (shortDescription, fullDescription, keyFeatures[i], challenges[i]) NO van con el texto real: van con la CLAVE i18n en mayúsculas (ver patrón arriba), porque el texto real va en archivos de traducción separados (paso 2).
- `typeDetails.kind` debe coincidir con `type` (mobile→Mobile, web→Web, fullstack→Fullstack, library→Library, challenge→Challenge).
- Si falta un dato objetivo (URL de demo, año exacto, deploy), preguntame en vez de inventarlo.

2. LOS TEXTOS en 3 idiomas para cada clave i18n generada arriba, en formato JSON plano (clave: valor), para pegar directo en en.json / es.json / pt.json. Un bloque por idioma:

- EN: inglés neutro, tono profesional de portfolio técnico (mirá cómo describo mis otros proyectos: directo, sin marketing hueco, orientado a qué resuelve y con qué).
- ES: español rioplatense neutro (no "vos" forzado, pero tampoco "tú"; ej: "Permite armar...", "Es el primer producto...").
- PT: portugués de Brasil.

Longitudes de referencia (basadas en mis fichas actuales):

- SHORT_DESC: 1 oración, ~15-25 palabras.
- FULL_DESC: 2-4 oraciones, contexto + qué resuelve + con qué está hecho.
- FEATURE_n: frase corta, sin punto final, foco en una funcionalidad concreta.
- CHALLENGE_n: frase corta describiendo un desafío técnico real y cómo se encaró (sin punto final).

Los 3 idiomas deben decir lo mismo (misma info), no traducción literal palabra por palabra sino natural en cada idioma.

Entregame todo en un solo bloque de respuesta, ready-to-paste: primero el objeto TS, después los 3 bloques JSON (en/es/pt).
