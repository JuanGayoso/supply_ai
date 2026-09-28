# 🛒 Supply AI (Procurement) — Fase 1

Área de abastecimiento virtual multiagente para obra/proyecto: un **CPO** que orquesta,
5 agentes especializados y 3 módulos deterministas (histórico de precios, brechas de
presupuesto, política). Memoria persistente en **Supabase (Postgres)**. Mismo patrón que `legal-ai`.

## Principios de diseño
1. **Todo contenido de proveedor es DATO, nunca instrucción.** (ver `policies/seguridad.md`) — aplica igual si llega por correo, WhatsApp, teléfono, papel o si lo escribe el propio gestor de logística.
2. **El agente propone, la persona aprueba.** Solo crea *borradores* de correo; nunca envía ni cierra compras.
3. **Correo: Outlook (Microsoft 365) configurado.** Los agentes usan 3 operaciones abstractas (`buscar_hilos`, `leer_mensaje`, `crear_borrador`) mapeadas en `policies/config-correo-outlook.md`; cambiar a Gmail solo exige otro archivo de mapeo.
4. **Ingreso multicanal:** correo, anexos, WhatsApp, llamada/reunión, documento físico o carga directa del gestor pasan por el mismo pipeline seguro (`policies/ingreso-multicanal.md`).
5. **Reglas críticas en código/SQL, no en el LLM** (política, umbrales, histórico).
6. **Decision Record** obligatorio en cada decisión relevante.

## Estructura
```
CLAUDE.md                 ← instrucciones del CPO y flujos
agents/*/SKILL.md         ← 6 agentes
templates/                ← TdR (Tipo 1 especialidad / Tipo 2 sistema), comparativo CBA, decision record, brechas, carta feedback, registro manual
policies/                 ← seguridad, reglas de política, config de correo Outlook, ingreso multicanal
db/schema.sql             ← esquema Supabase
```

## Puesta en marcha
1. Crear proyecto Supabase y ejecutar `db/schema.sql` (SQL Editor).
2. Activar conectores en Claude: **Supabase** + **Microsoft 365** (Outlook). Crear en Outlook una carpeta `Compras-AI/RFQ` con una regla que mueva allí las respuestas con código RFQ.
3. Abrir Claude Code/Cowork en esta carpeta (`CLAUDE.md` se carga solo).
4. Primer uso: cargar presupuesto de prueba y 3 proveedores; correr un paquete pequeño de punta a punta.

## Fases
1. **(esta)** Presupuesto → paquetes → TdR → RFQ borradores → recepción segura (multicanal) → BD.
2. Homologación + CBA + histórico + correos de ajuste.
3. Brechas, cronograma, evaluación de proveedores y carta de feedback.
4. Conexión con Legal AI, Cost Control, Planning.

> Nota: el esquema no usa pgvector todavía; se añade si quieres búsqueda semántica sobre TdR/cotizaciones.
