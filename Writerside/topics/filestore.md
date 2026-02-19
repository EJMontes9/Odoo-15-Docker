# Solución para Problemas del Filestore

## Problema

Se detectó un error al acceder a archivos en el filestore de Odoo:

```
FileNotFoundError: [Errno 2] No such file or directory: '/var/lib/odoo/filestore/odoo/04/04c431a00d8a3a83affce217ef7291a775a6abb3'
```

Este error ocurre cuando Odoo intenta acceder a un archivo adjunto (attachment) que debería estar en el directorio filestore, pero el directorio no existe o no tiene los permisos adecuados.

## Causa

El problema se debe a que la estructura de directorios del filestore no se crea automáticamente al iniciar el contenedor de Odoo. Aunque el volumen `/var/lib/odoo` está montado correctamente, los subdirectorios necesarios (`filestore/odoo`) no se crean automáticamente.

## Solución

Se modificó el script de inicio (`entrypoint.sh`) para asegurar que la estructura de directorios del filestore exista y tenga los permisos adecuados antes de iniciar Odoo:

```bash
# Ensure filestore directory structure exists
echo "Configurando estructura de directorios para filestore..."
mkdir -p /var/lib/odoo/filestore/odoo
chown -R odoo:odoo /var/lib/odoo
chmod -R 755 /var/lib/odoo
```

Estos comandos:
1. Crean el directorio `/var/lib/odoo/filestore/odoo` si no existe
2. Asignan la propiedad de todo el directorio `/var/lib/odoo` al usuario odoo
3. Establecen permisos 755 (rwxr-xr-x) en todo el directorio `/var/lib/odoo`

## Cómo Aplicar la Solución

### Opción 1: Usando los scripts de corrección rápida

Se han creado scripts para aplicar la corrección sin necesidad de reconstruir la imagen Docker:

**Para Linux/Mac:**
```bash
./scripts/shell/fix_filestore.sh
```

**Para Windows (PowerShell):**
```powershell
.\scripts\shell\fix_filestore.ps1
```

Estos scripts crean la estructura de directorios necesaria, establecen los permisos correctos y reinician el contenedor de Odoo para aplicar los cambios.

### Opción 2: Reconstruyendo la imagen Docker

Si prefieres aplicar la solución de manera permanente, puedes reconstruir la imagen Docker:

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

Deberías ver un mensaje como:
- "Configurando estructura de directorios para filestore..."

También puedes verificar que la estructura de directorios se ha creado correctamente:

```bash
docker exec odoo-app ls -la /var/lib/odoo/filestore
```

## Notas Adicionales

- Esta solución asegura que la estructura de directorios del filestore exista y tenga los permisos adecuados cada vez que se inicia el contenedor de Odoo.

- Si ya tienes archivos en el filestore, no se verán afectados por esta solución, ya que solo crea los directorios si no existen.

- Si estás utilizando un volumen persistente para `/var/lib/odoo`, la estructura de directorios se mantendrá entre reinicios del contenedor.
