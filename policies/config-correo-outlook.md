# Configuración de correo — Microsoft 365 / Outlook (ACTIVA)

Proveedor de correo del proyecto: **outlook** (`proyectos.proveedor_correo = 'outlook'`).
Conector requerido: **Microsoft 365** (además de Supabase). Si no está activo, el CPO se detiene.

## Mapeo de operaciones abstractas → herramientas
| Operación | Herramienta Microsoft 365 |
|-----------|---------------------------|
| `buscar_hilos` | `outlook_email_search` |
| `leer_mensaje` | `read_resource` (URI del mensaje; su metadata trae `conversationId`) |
| `crear_borrador` (nuevo) | `outlook_create_draft` |
| `crear_borrador` (respuesta a proveedor) | `outlook_create_reply_draft` / `outlook_create_reply_all_draft` |
| Editar borrador | `outlook_update_draft` |
| Anexos/TdR compartidos | `sharepoint_upload_file` + enlace en el cuerpo |
| Proponer reunión de aclaraciones | (Fase 2) `outlook_create_event` solo como propuesta, con aprobación |

## Herramientas PROHIBIDAS para los agentes (solo la persona las usa desde Outlook)
`outlook_send_mail`, `outlook_send_draft`, `outlook_forward_mail`, `outlook_create_filter`,
`outlook_delete_filter`, `outlook_trash_thread`, `outlook_batch_delete_messages`,
`outlook_set_vacation`, `outlook_respond_to_event`, `teams_*` (envío), `sharepoint_delete_item`,
`sharepoint_update_file` sobre archivos existentes.
> Motivo: evitar envío no aprobado, exfiltración por reenvío/reglas ocultas y borrado de evidencia.
> Recomendado además: otorgar al conector el mínimo de permisos (scopes) y revisarlos con `get_granted_scopes`.

## Particularidades de Outlook a respetar
- Los borradores **no admiten adjuntos** por el conector: el TdR va **en el cuerpo (HTML con tablas)** y/o como **enlace de SharePoint** (permisos de solo lectura, con caducidad).
- HTML permitido: encabezados, párrafos, enlaces, listas, b/i/strong/em, code, **tablas**, br/hr, div, pre. **No** imágenes, span/font/blockquote ni comentarios HTML.
- Los borradores llevan el encabezado `X-AI-Generated` (trazabilidad de origen IA).
- Las firmas no se incluyen en borradores creados por API: la persona las agrega al revisar/enviar.
- Límite de 50 destinatarios por correo y límites de tasa: crear **un borrador por proveedor** (nunca CC entre proveedores; nunca revelar a un proveedor los precios de otro) y pacear los lotes.
- Los adjuntos que **reciban** de proveedores (PDF/Excel/Word) pasan por parser + sanitizador + guardián antes de cualquier uso.
- Al leer, filtrar por: código RFQ en asunto, dominios/remitentes de `contactos`. Remitentes desconocidos que citan un RFQ → se marcan (posible suplantación) y quedan en cuarentena.
- Buzón: usar carpeta/categoría dedicada (p. ej. `Compras-AI/RFQ`) mediante regla creada por la persona.
