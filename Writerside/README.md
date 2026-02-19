# Documentación AAG ERP - Writerside

Este directorio contiene la documentación técnica del sistema ERP Odoo 15 para la Autoridad Aeroportuaria de Guayaquil.

## 🔨 Compilación Automática

La documentación se compila automáticamente en GitLab CI/CD cuando haces push a las ramas `main` o `master`.

## 📚 Ver Documentación

Una vez desplegada, la documentación estará disponible en:
```
https://[tu-usuario].gitlab.io/[nombre-proyecto]/
```

## 🏗️ Estructura

```
Writerside/
├── topics/                      # Archivos de documentación
│   ├── modulos/                # Documentación por módulos
│   │   └── presupuesto/       # Módulo Presupuesto v1.0
│   ├── *.md                   # Guías generales
│   └── Starter.topic          # Página de inicio
├── aag.tree                    # Árbol de navegación
└── writerside.cfg             # Configuración Writerside
```

## 🔐 Privacidad

- ✅ Repositorio privado
- ✅ Documentación privada (solo usuarios autorizados)
- ✅ Sin costo

## 🛠️ Compilar Localmente (Opcional)

Si necesitas compilar la documentación localmente:

```bash
docker run --rm \
  -v $(pwd):/opt/sources \
  -e MODULE_INSTANCE=Writerside/aag \
  -e SOURCE_DIR=/opt/sources \
  -e OUTPUT_DIR=/opt/sources/output \
  jetbrains/writerside-builder:2026.02.8644
```

El resultado estará en `output/`.
