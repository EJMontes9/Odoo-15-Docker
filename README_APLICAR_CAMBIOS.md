# Aplicar Cambios Sin Perder Datos

Este documento explica cómo aplicar los cambios para solucionar el problema de visualización de PDFs QWeb sin perder los datos de la base de datos que está ejecutándose actualmente en Docker.

## Cambios Realizados

Los siguientes archivos fueron modificados o creados para solucionar el problema:

1. `config/odoo.conf` - Se actualizó la ruta del binario wkhtmltopdf
2. `scripts/shell/setup_wkhtmltopdf_link.sh` - Script para crear un enlace simbólico (actualizado para manejar ambas direcciones)
3. `entrypoint.sh` - Se modificó para ejecutar el script de configuración
4. `scripts/shell/check_wkhtmltopdf.sh` - Script para verificar la instalación de wkhtmltopdf
5. `README_PDF_FIX.md` - Documentación de la solución

## Instrucciones para Aplicar los Cambios Sin Perder Datos

Sigue estos pasos para aplicar los cambios sin reconstruir completamente el contenedor Docker:

### 1. Copiar los Archivos Nuevos al Contenedor

```powershell
# Copiar el script de configuración de wkhtmltopdf al contenedor
docker cp scripts/shell/setup_wkhtmltopdf_link.sh odoo-app:/opt/scripts/shell/

# Copiar el script de verificación de wkhtmltopdf al contenedor
docker cp scripts/shell/check_wkhtmltopdf.sh odoo-app:/opt/scripts/shell/

# Asegurarse de que los scripts tengan permisos de ejecución
docker exec odoo-app chmod +x /opt/scripts/shell/setup_wkhtmltopdf_link.sh
docker exec odoo-app chmod +x /opt/scripts/shell/check_wkhtmltopdf.sh
```

### 2. Actualizar el Archivo de Configuración de Odoo

```powershell
# Copiar el archivo de configuración actualizado al contenedor
docker cp config/odoo.conf odoo-app:/etc/odoo/odoo.conf
```

### 3. Actualizar el Script de Entrada

```powershell
# Copiar el entrypoint.sh actualizado al contenedor
docker cp entrypoint.sh odoo-app:/entrypoint.sh
docker exec odoo-app chmod +x /entrypoint.sh
```

### 4. Ejecutar el Script de Configuración de wkhtmltopdf

```powershell
# Ejecutar el script para crear el enlace simbólico
docker exec odoo-app /opt/scripts/shell/setup_wkhtmltopdf_link.sh
```

El script actualizado ahora detectará automáticamente dónde está instalado wkhtmltopdf y creará el enlace simbólico en la dirección correcta:
- Si wkhtmltopdf está en `/usr/local/bin/` pero no en `/usr/bin/`, creará un enlace de `/usr/local/bin/wkhtmltopdf` a `/usr/bin/wkhtmltopdf`
- Si wkhtmltopdf está en `/usr/bin/` pero no en `/usr/local/bin/`, creará un enlace de `/usr/bin/wkhtmltopdf` a `/usr/local/bin/wkhtmltopdf`

### 5. Reiniciar el Contenedor de Odoo

```powershell
# Reiniciar solo el contenedor de Odoo (no la base de datos)
docker restart odoo-app
```

### 6. Verificar la Instalación

```powershell
# Verificar que wkhtmltopdf esté correctamente configurado
docker exec odoo-app /opt/scripts/shell/check_wkhtmltopdf.sh
```

El script de verificación mejorado ahora proporciona información más detallada:
- Muestra la ubicación y versión de wkhtmltopdf
- Verifica si el binario existe en ambas rutas (/usr/bin/ y /usr/local/bin/)
- Comprueba la configuración en el archivo odoo.conf
- Verifica si existen enlaces simbólicos y muestra a dónde apuntan

## Verificación

Después de aplicar estos cambios y reiniciar el contenedor de Odoo, deberías poder generar y ver los informes PDF correctamente. Para probar:

1. Inicia sesión en Odoo
2. Genera un informe PDF (por ejemplo, una factura o pedido de compra)
3. Verifica que el PDF se muestre correctamente

## Solución de Problemas

Si sigues teniendo problemas después de aplicar estos cambios:

1. Verifica los logs de Odoo para ver si hay errores:
   ```powershell
   docker logs odoo-app | findstr "wkhtmltopdf"
   ```

2. Asegúrate de que el enlace simbólico se haya creado correctamente:
   ```powershell
   docker exec odoo-app ls -la /usr/local/bin/wkhtmltopdf
   ```

3. Verifica que la configuración de Odoo esté utilizando la ruta correcta:
   ```powershell
   docker exec odoo-app grep -A 1 "bin_path_wkhtmltopdf" /etc/odoo/odoo.conf
   ```

Si los problemas persisten, consulta el archivo `README_PDF_FIX.md` para obtener información adicional sobre la solución implementada.
