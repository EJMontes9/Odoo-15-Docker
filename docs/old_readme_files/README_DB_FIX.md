# Solución para el Error de PostgreSQL Client

## Problema
Se detectó un error en el script de configuración automática de la base de datos (`setup_odoo_db.sh`):
```
/opt/scripts/shell/setup_odoo_db.sh: line 12: psql: command not found
```

Este error ocurría porque el contenedor de Odoo no tenía instaladas las herramientas cliente de PostgreSQL, necesarias para ejecutar los comandos `psql` y `pg_restore` que utiliza el script.

## Solución
Se modificó el Dockerfile para incluir el paquete `postgresql-client`, que proporciona las herramientas necesarias:

```dockerfile
RUN apt-get update && apt-get install -y \
    # ... otras dependencias ... \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*
```

## Cómo Aplicar la Solución
Para aplicar esta solución, es necesario reconstruir la imagen Docker:

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

## Verificación
Después de aplicar la solución, puedes verificar que funciona correctamente revisando los logs del contenedor:

```bash
docker logs odoo-app
```

Deberías ver mensajes como:
- "Verificando si la base de datos 'odoo' existe..."
- "La base de datos 'odoo' ya existe. No se realizará ninguna acción." (o mensajes de creación si es la primera vez)

También puedes ejecutar manualmente el script para verificar:

```bash
docker exec odoo-app /opt/scripts/shell/setup_odoo_db.sh
```

## Notas Adicionales
- Esta solución no afecta a la funcionalidad existente, solo agrega las herramientas necesarias para que el script de configuración automática funcione correctamente.
- No es necesario modificar el script `setup_odoo_db.sh` ya que estaba correctamente implementado, solo faltaban las herramientas en el contenedor.