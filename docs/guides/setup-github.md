# Publicar este proyecto en GitHub

Comandos para la primera subida (LOS EJECUTA EL USUARIO — el equipo no corre git destructivo ni push).

## Requisitos

- Tener `git` configurado (`git config --global user.name` / `user.email`).
- Crear el repo **sin** README ni LICENSE inicial para evitar conflictos del primer push. *(Naxrow ya lo creó: `github.com/naxrowdev/opencode-dev-team`)*
- Descripción y topics sugeridos al configurar el repo:

  > Equipo de desarrollo de software agéntico para OpenCode: 1 tech-lead orquestador + 11 subagentes por rol (producto, arquitectura, backend, frontend, QA, seguridad, DevOps). 55 skills curated, Context7 MCP, permisos por rol y memoria entre sesiones sin plugins.

  Topics: `opencode` · `ai-agents` · `agents` · `llm` · `agentic` · `devtools` · `prompt-engineering` · `typescript`

## 1. Inicializar y primer commit

```bash
cd agentic
git init -b main
git add .
git status   # revisar que solo suba lo esperado: .opencode/, docs/, AGENTS.md, README.md, CHANGELOG.md, VERSION, opencode.jsonc, .env.example, .gitignore, *.md raíz
git commit -m "feat(config): agentic dev team v0.1.0 — 12 agentes, 55 skills, context7 mcp, permisos por rol"
```

> `.env` está en `.gitignore`: aunque exista localmente, no entra al commit. Verifica con `git status` que no aparezca.

## 2. Conectar y subir

```bash
git remote add origin git@github.com:naxrowdev/opencode-dev-team.git
git push -u origin main

# Tag de release: la skill docs-updater usa el último tag como base del diff para el próximo CHANGELOG
git tag -a v0.1.0 -m "Agentic dev team 0.1.0 — pre-release"
git push origin v0.1.0
```

## 3. Publicar la Release del tag

El instalador en modo curl resuelve **la última GitHub Release** vía
`https://github.com/<repo>/releases/latest`. Un tag sin release no alcanza: el redirect no
existe y el one-liner corta pidiendo `--ref`.

Desde la web: **Releases → Draft a new release →** elegir el tag `v0.3.0` → publicar.

O con GitHub CLI:

```bash
gh release create v0.3.0 --title "v0.3.0" --notes-file CHANGELOG.md
```

Repite tag + release en cada versión publicada.

## 4. Distribuir a otro proyecto (después de publicar)

El kit se inyecta con el instalador — no se copia a mano. La guía completa está en
`docs/guides/installing-into-a-project.md`.

```bash
cd ~/Proyectos/mi-proyecto
# última estable
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh
# versión fijada
curl -fsSL https://raw.githubusercontent.com/naxrowdev/opencode-dev-team/main/kit/install.sh | sh -s -- --ref v0.3.0
```

Alternativa sin curl (clonar y ejecutar el instalador local):

```bash
git clone git@github.com:naxrowdev/opencode-dev-team.git /tmp/opencode-dev-team
sh /tmp/opencode-dev-team/kit/install.sh --dry-run /ruta/a/mi-proyecto   # previsualizar
sh /tmp/opencode-dev-team/kit/install.sh /ruta/a/mi-proyecto             # instalar
cd /ruta/a/mi-proyecto && opencode
```

El proyecto destino arranca con `docs/context/STATE.md` vacío: la memoria del kit no viaja. `git add` y push los ejecuta el usuario en el proyecto destino.

## Checklist antes de push

- [ ] `git status` no lista `.env` ni archivos basura.
- [ ] No hay secretos en el código (verificado el 2026-11-06; repetir con `grep -rIn "sk-\|ghp_" .` si tocaste archivos).
- [ ] `opencode mcp list` → `✓ context7 connected` en el proyecto destino.

## Notas

- Decisión pendiente del usuario: **LICENSE** (el repo mezcla contenido MIT/Apache-2.0 vendido — los originales conservan su licencia, tus agregados necesitan tu elección; `MIT` es lo usual para este tipo de config).
- El README de la raíz documenta igualmente cómo copiar la config; esta guía agrega solo la parte de publicación.
