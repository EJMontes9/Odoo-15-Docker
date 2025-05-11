# Solución para Problemas del Filestore / Filestore Troubleshooting

## Problema / Problem

Se detectó un error al acceder a archivos en el filestore de Odoo:

An error was detected when accessing files in the Odoo filestore:

```
FileNotFoundError: [Errno 2] No such file or directory: '/var/lib/odoo/filestore/odoo/04/04c431a00d8a3a83affce217ef7291a775a6abb3'
```

Este error ocurre cuando Odoo intenta acceder a un archivo adjunto (attachment) que debería estar en el directorio filestore, pero el directorio no existe o no tiene los permisos adecuados.

This error occurs when Odoo tries to access an attachment that should be in the filestore directory, but the directory does not exist or does not have the appropriate permissions.

## Causa / Cause

El problema se debe a que la estructura de directorios del filestore no se crea automáticamente al iniciar el contenedor de Odoo. Aunque el volumen `/var/lib/odoo` está montado correctamente, los subdirectorios necesarios (`filestore/odoo`) no se crean automáticamente.

The problem is due to the filestore directory structure not being created automatically when starting the Odoo container. Although the `/var/lib/odoo` volume is mounted correctly, the necessary subdirectories (`filestore/odoo`) are not created automatically.

## Solución / Solution

Se modificó el script de inicio (`entrypoint.sh`) para asegurar que la estructura de directorios del filestore exista y tenga los permisos adecuados antes de iniciar Odoo:

The startup script (`entrypoint.sh`) was modified to ensure that the filestore directory structure exists and has the appropriate permissions before starting Odoo:

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

These commands:
1. Create the `/var/lib/odoo/filestore/odoo` directory if it doesn't exist
2. Assign ownership of the entire `/var/lib/odoo` directory to the odoo user
3. Set 755 permissions (rwxr-xr-x) on the entire `/var/lib/odoo` directory

## Cómo Aplicar la Solución / How to Apply the Solution

### Opción 1: Usando los scripts de corrección rápida / Using quick fix scripts

Se han creado scripts para aplicar la corrección sin necesidad de reconstruir la imagen Docker:

Scripts have been created to apply the fix without rebuilding the Docker image:

**Para Linux/Mac / For Linux/Mac:**
```bash
./scripts/shell/fix_filestore.sh
```

**Para Windows (PowerShell) / For Windows (PowerShell):**
```powershell
.\scripts\shell\fix_filestore.ps1
```

Estos scripts crean la estructura de directorios necesaria, establecen los permisos correctos y reinician el contenedor de Odoo para aplicar los cambios.

These scripts create the necessary directory structure, set the correct permissions, and restart the Odoo container to apply the changes.

### Opción 2: Reconstruyendo la imagen Docker / Rebuilding the Docker image

Si prefieres aplicar la solución de manera permanente, puedes reconstruir la imagen Docker:

If you prefer to apply the solution permanently, you can rebuild the Docker image:

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

## Verificación / Verification

Después de aplicar la solución, puedes verificar que funciona correctamente revisando los logs del contenedor:

After applying the solution, you can verify that it works correctly by checking the container logs:

```bash
docker logs odoo-app
```

Deberías ver un mensaje como:
- "Configurando estructura de directorios para filestore..."

You should see a message like:
- "Configurando estructura de directorios para filestore..."

También puedes verificar que la estructura de directorios se ha creado correctamente:

You can also verify that the directory structure has been created correctly:

```bash
docker exec odoo-app ls -la /var/lib/odoo/filestore
```

## Notas Adicionales / Additional Notes

- Esta solución asegura que la estructura de directorios del filestore exista y tenga los permisos adecuados cada vez que se inicia el contenedor de Odoo.
  
  This solution ensures that the filestore directory structure exists and has the appropriate permissions every time the Odoo container starts.

- Si ya tienes archivos en el filestore, no se verán afectados por esta solución, ya que solo crea los directorios si no existen.
  
  If you already have files in the filestore, they will not be affected by this solution, as it only creates the directories if they don't exist.

- Si estás utilizando un volumen persistente para `/var/lib/odoo`, la estructura de directorios se mantendrá entre reinicios del contenedor.
  
  If you are using a persistent volume for `/var/lib/odoo`, the directory structure will be maintained between container restarts.