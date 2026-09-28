---
name: gestor-cotizaciones
description: Prepara borradores de RFQ, lee la bandeja (Outlook) vía guardián, registra cotizaciones llegadas por cualquier canal, homologa contra TdR y propone correos de ajuste.
---
# Gestor de cotizaciones
## Correo agnóstico (activo: Outlook)
Proveedor activo: **Outlook / Microsoft 365** (ver `policies/config-correo-outlook.md`).
`buscar_hilos` → `outlook_email_search`; `leer_mensaje` → `read_resource`; `crear_borrador` → `outlook_create_draft` (nuevo) o `outlook_create_reply_draft` (respuesta); edición → `outlook_update_draft`. **Nunca envíes ni reenvíes** (`outlook_send_*`, `outlook_forward_mail` prohibidos).
Los borradores no llevan adjuntos: pon el TdR en el cuerpo (HTML con tablas, sin imágenes/span) y/o un enlace de SharePoint de solo lectura.
## Envío de RFQ
Selecciona contactos por especialidad/desempeño en `proveedores`; crea un borrador por proveedor con el TdR y las pautas de formato; asunto con código RFQ. Registra en `rfq_envios` cuando la persona confirme el envío.
## Recepción (multicanal)
- **Buzón Outlook:** busca respuestas por código RFQ y adjuntos; crea un Ingreso por mensaje y por adjunto (`correo` / `anexo_correo`).
- **Cargas del gestor** (WhatsApp, físico, verbal, otros): llegan vía CPO con `templates/registro-ingreso-manual.md`; crea Ingreso `whatsapp` / `fisico` / `llamada_reunion` / `carga_directa`.
- Cada Ingreso → `guardian-seguridad` → guarda solo el JSON en `cotizaciones` y `cotizacion_items` (lugar, fecha, volumen, precio, condiciones) con `ingreso_id` y `provisional=true` si la fuente es `declarado`.
- Detecta duplicados (mismo hash por dos canales) y versiones (`reemplaza_a`); si hay conflicto entre canales, muestra la discrepancia y pide confirmación.
- Fuente `declarado` ⇒ prepara borrador de correo al proveedor pidiendo **ratificación escrita** de precio, plazo y condiciones.
## Homologación (Fase 2)
Compara cada cotización con el TdR: ítems, cantidades, unidades, marcas, plazos, garantías, IGV, transporte, exclusiones. Si el TdR es **Tipo 2** (`templates/tdr-tipo2-sistema.md`), homologa también contra los **criterios de evaluación y aceptación cuantificados** de su Sección 6 (cobertura, ruido, precisión, etc.): una oferta que no los cumple o no los declara queda `HOMOLOGADA_CON_OBSERVACIONES` o `NO_HOMOLOGADA`, no solo por precio/ítems. Estados: `HOMOLOGADA` / `HOMOLOGADA_CON_OBSERVACIONES` / `NO_HOMOLOGADA`. Redacta consultas de aclaración al proveedor (borrador).
## Ajuste y negociación (Fase 2)
Aplica P01–P03: consulta `v_mejor_precio_historico` y `condiciones_cerradas`; propone borradores con evidencia (precio previo, fecha, volumen). No cambies condiciones críticas unilateralmente.
