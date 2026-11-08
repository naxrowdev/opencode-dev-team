# Modelos por rol (opcional)

El kit **no elige modelos por ti**. Por defecto, todos los roles trabajan con el mismo
modelo: el que seleccionas en la sesión con `/models`. Asignar un modelo distinto a cada
rol es opcional y se hace en un solo bloque de `opencode.jsonc`.

## Cómo se resuelve el modelo de un rol

| Situación | Modelo que se usa |
|---|---|
| El rol tiene `model` configurado | Ese modelo |
| El rol no tiene `model` (default del kit) | El modelo de la sesión (`/models`) |
| La sesión no tiene selección explícita | El `model` raíz de `opencode.jsonc`, si existe; si no, el default del catálogo |

Los subagentes sin `model` heredan el modelo del orquestador. Para cambiar el modelo del
orquestador en caliente, usa `/models`: la selección de la sesión manda sobre lo
configurado, y una sesión que ya eligió modelo lo conserva. `agents.tech-lead.model` se
aplica al agente; compruébalo con `opencode debug agents`.

## Activar modelos por rol

1. Abre `opencode.jsonc` en la raíz del proyecto.
2. Descomenta el bloque `// ── Modelos por rol (OPCIONAL) ──` (está completo, con los 12 IDs).
3. Reemplaza cada `"provider/model"` por un ID real del proyecto:

   ```sh
   opencode models      # lista los IDs disponibles en este proyecto
   ```

4. Guarda. La configuración recarga sola; si una sesión abierta no lo toma, fuerza `/reload`.

Cualquier proveedor sirve (nube, free, local) mientras el ID aparezca en
`opencode/models`:

```jsonc
{
  "agents": {
    "tech-lead":   { "model": "anthropic/claude-sonnet-5-5" },
    "backend-dev": { "model": "ollama/qwen3-coder:30b" },
    "tech-writer": { "model": "opencode/glm-5.3-flash-free" }
  }
}
```

Los roles que no aparezcan en el bloque siguen heredando el modelo de la sesión: puedes
fijar solo los que te importan.

## Cambiar de modelo cuando se agotan los tokens

| Necesidad | Mecanismo | Alcance |
|---|---|---|
| El orquestador se quedó sin tokens | `/models` en la sesión | inmediato, sin editar archivos |
| Un rol con `model` fijo se quedó sin tokens | edita su línea en el bloque y guarda | las delegaciones siguientes |
| Un solo rol, una sola vez | pide al tech-lead que delegue con `model` explícito (la herramienta `subagent` lo acepta) | esa llamada |
| Volver a un solo modelo | comenta el bloque completo | todo el equipo |

## Tiers sugeridos (no es un default)

Si quieres repartir costo/capacidad, tres tiers cubren el pipeline:

| Tier | Roles | Criterio |
|---|---|---|
| Profundo | `tech-lead`, `architect`, `security-engineer`, `code-reviewer` | razonamiento y contexto largo |
| Estándar | `backend-dev`, `frontend-dev`, `qa-engineer`, `devops-sre`, `ux-designer` | código y verificación |
| Liviano | `product-owner`, `business-analyst`, `tech-writer` | prosa y plantillas, costo bajo |

Es una sugerencia editable: el kit no impone ningún reparto.

## Límites que conviene conocer

- **No hay failover automático.** Si el proveedor devuelve un error de cuota o de tokens,
  la sesión falla: cambias el modelo y repites el turno. OpenCode V2 no encadena modelos
  de respaldo.
- `/models` no cambia a los subagentes que tienen `model` fijo; esos dependen del bloque.
- Los IDs y la disponibilidad son **por proyecto**: un modelo que funciona en un repo
  puede no estar disponible en otro. Valida siempre con `opencode models`.
- `{env:VAR}` en `model` no es recomendable como única capa: si la variable no está
  definida, se sustituye por un string vacío y el modelo queda inválido.
- V2 todavía no aplica `temperature` por agente (`agents.*.request` se guarda pero no se
  envía); lo único afinable por rol es el modelo y su variante (`#high`, `#low`, ...,
  cuando el catálogo la define).

## Verificación rápida

1. `opencode models | grep <modelo>` confirma que el ID existe en el proyecto.
2. Descomenta el bloque y guarda.
3. `opencode debug agents` muestra, por agente, el `model` resuelto: si el rol elegido
   aparece con `providerID` + `id` y los demás no, la capa quedó aplicada.
4. Si un rol falla con "modelo no disponible", el ID es inválido o el proveedor no está
   habilitado en este proyecto.
