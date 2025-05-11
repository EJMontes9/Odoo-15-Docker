# Solución para Problemas de Generación de PDF / PDF Generation Troubleshooting

## Problema / Problem

Los informes PDF generados con QWeb no se mostraban correctamente en el entorno Docker local. Al intentar abrir un PDF en Odoo, aparecía un mensaje de error diciendo "No podemos abrir este archivo. Hubo un problema." El enlace del PDF se generaba pero nunca se abría correctamente.

PDF reports generated with QWeb were not displaying correctly in the local Docker environment. When trying to open a PDF in Odoo, an error message appeared saying "We cannot open this file. There was a problem." The PDF link was generated but never opened properly.

## Diagnóstico / Diagnosis

Después de analizar la salida del script `check_wkhtmltopdf.sh`, se identificó que:

After analyzing the output of the `check_wkhtmltopdf.sh` script, it was identified that:

1. El binario wkhtmltopdf estaba instalado en `/usr/local/bin/wkhtmltopdf`
   
   The wkhtmltopdf binary was installed in `/usr/local/bin/wkhtmltopdf`

2. No existía en `/usr/bin/wkhtmltopdf` donde Odoo estaba configurado para buscarlo
   
   It did not exist in `/usr/bin/wkhtmltopdf` where Odoo was configured to look for it

3. El script original de configuración no creaba el enlace simbólico correctamente
   
   The original configuration script did not create the symbolic link correctly

## Solución Implementada / Implemented Solution

Se realizaron los siguientes cambios para solucionar el problema:

The following changes were made to solve the problem:

### 1. Actualización de la Configuración de Odoo / Odoo Configuration Update

Se actualizó el archivo de configuración de Odoo (`config/odoo.conf`) para usar la ruta correcta para wkhtmltopdf:
- `bin_path_wkhtmltopdf = /usr/bin/wkhtmltopdf`

The Odoo configuration file (`config/odoo.conf`) was updated to use the correct path for wkhtmltopdf:
- `bin_path_wkhtmltopdf = /usr/bin/wkhtmltopdf`

### 2. Mejora del Script de Configuración / Configuration Script Improvement

Se actualizó el script `setup_wkhtmltopdf_link.sh` para:
- Detectar automáticamente dónde está instalado wkhtmltopdf
- Crear el enlace simbólico en la dirección correcta según la ubicación del binario
- Manejar ambos escenarios posibles (binario en `/usr/local/bin/` o en `/usr/bin/`)

The `setup_wkhtmltopdf_link.sh` script was updated to:
- Automatically detect where wkhtmltopdf is installed
- Create the symbolic link in the correct direction based on the binary location
- Handle both possible scenarios (binary in `/usr/local/bin/` or in `/usr/bin/`)

### 3. Mejora del Script de Diagnóstico / Diagnostic Script Improvement

Se mejoró el script `check_wkhtmltopdf.sh` para:
- Mostrar información más detallada sobre la instalación
- Verificar la existencia del binario en ambas rutas
- Comprobar la configuración en odoo.conf
- Verificar los enlaces simbólicos y mostrar a dónde apuntan

The `check_wkhtmltopdf.sh` script was improved to:
- Show more detailed information about the installation
- Verify the existence of the binary in both paths
- Check the configuration in odoo.conf
- Verify symbolic links and show where they point to

### 4. Modificación del Código de Odoo / Odoo Code Modification

Se modificó la función `_get_wkhtmltopdf_bin()` en `addons/Aeroportuaria_ERP/other/custom_background/models/report.py` para priorizar el uso de la ruta de wkhtmltopdf especificada en el archivo de configuración de Odoo (`bin_path_wkhtmltopdf`) antes de recurrir al método de búsqueda de ruta estándar.

The `_get_wkhtmltopdf_bin()` function in `addons/Aeroportuaria_ERP/other/custom_background/models/report.py` was modified to prioritize using the wkhtmltopdf path specified in the Odoo configuration file (`bin_path_wkhtmltopdf`) before falling back to the standard path search method.

La función actualizada ahora:
- Primero intenta obtener la ruta de wkhtmltopdf desde la configuración de Odoo
- Verifica que la ruta exista, sea un archivo y sea ejecutable
- Solo recurre a la búsqueda de ruta estándar si la ruta de configuración no es válida o no está especificada

The updated function now:
- First tries to get the wkhtmltopdf path from the Odoo configuration
- Verifies that the path exists, is a file, and is executable
- Only falls back to the standard path search if the config path is invalid or not specified

#### Detalles Técnicos / Technical Details

La función original era:

The original function was:
```python
def _get_wkhtmltopdf_bin():
    return find_in_path("wkhtmltopdf")
```

La función actualizada es:

The updated function is:
```python
def _get_wkhtmltopdf_bin():
    # First try to use the path from Odoo config
    try:
        from odoo.tools.config import config
        wkhtmltopdf_path = config.get('bin_path_wkhtmltopdf')
        if wkhtmltopdf_path and os.path.isfile(wkhtmltopdf_path) and os.access(wkhtmltopdf_path, os.X_OK):
            return wkhtmltopdf_path
    except Exception as e:
        _logger.warning("Error getting wkhtmltopdf path from config: %s", e)
    
    # Fallback to find_in_path
    return find_in_path("wkhtmltopdf")
```

## Cómo Aplicar los Cambios / How to Apply the Changes

### Opción 1: Reconstruir la Imagen Docker / Rebuild Docker Image

Para aplicar todos los cambios de manera permanente:

To apply all changes permanently:

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

### Opción 2: Aplicar Cambios Sin Reconstruir / Apply Changes Without Rebuilding

Para aplicar los cambios sin reconstruir la imagen Docker (útil para entornos en producción):

To apply changes without rebuilding the Docker image (useful for production environments):

1. Copiar los scripts al contenedor / Copy scripts to the container:
   ```bash
   docker cp scripts/shell/setup_wkhtmltopdf_link.sh odoo-app:/opt/scripts/shell/
   docker cp scripts/shell/check_wkhtmltopdf.sh odoo-app:/opt/scripts/shell/
   docker exec odoo-app chmod +x /opt/scripts/shell/setup_wkhtmltopdf_link.sh
   docker exec odoo-app chmod +x /opt/scripts/shell/check_wkhtmltopdf.sh
   ```

2. Actualizar el archivo de configuración / Update configuration file:
   ```bash
   docker cp config/odoo.conf odoo-app:/etc/odoo/odoo.conf
   ```

3. Actualizar el script de entrada / Update entrypoint script:
   ```bash
   docker cp entrypoint.sh odoo-app:/entrypoint.sh
   docker exec odoo-app chmod +x /entrypoint.sh
   ```

4. Ejecutar el script de configuración / Run configuration script:
   ```bash
   docker exec odoo-app /opt/scripts/shell/setup_wkhtmltopdf_link.sh
   ```

5. Reiniciar el contenedor / Restart container:
   ```bash
   docker restart odoo-app
   ```

## Verificación / Verification

Para verificar que la solución funciona correctamente:

To verify that the solution works correctly:

1. Ejecutar el script de diagnóstico / Run diagnostic script:
   ```bash
   docker exec odoo-app /opt/scripts/shell/check_wkhtmltopdf.sh
   ```

2. Verificar que wkhtmltopdf esté correctamente configurado / Verify that wkhtmltopdf is correctly configured:
   - Debe mostrar la versión correcta (0.12.5 con qt parcheado) / Should show the correct version (0.12.5 with patched qt)
   - El binario debe estar disponible en al menos una de las rutas / The binary should be available in at least one of the paths
   - Debe existir un enlace simbólico entre ambas ubicaciones / A symbolic link should exist between both locations

3. Generar un informe PDF en Odoo / Generate a PDF report in Odoo:
   - Iniciar sesión en Odoo / Log in to Odoo
   - Generar un informe PDF (por ejemplo, una factura o un comprobante contable) / Generate a PDF report (e.g., an invoice or accounting voucher)
   - Verificar que el PDF se muestre correctamente / Verify that the PDF displays correctly

## Solución de Problemas / Troubleshooting

Si sigues teniendo problemas después de aplicar estos cambios:

If you still have problems after applying these changes:

1. Verificar los logs de Odoo / Check Odoo logs:
   ```bash
   docker logs odoo-app | grep -i wkhtmltopdf
   ```

2. Asegurarse de que el enlace simbólico se haya creado correctamente / Make sure the symbolic link has been created correctly:
   ```bash
   docker exec odoo-app ls -la /usr/bin/wkhtmltopdf
   docker exec odoo-app ls -la /usr/local/bin/wkhtmltopdf
   ```

3. Verificar que la configuración de Odoo esté utilizando la ruta correcta / Verify that the Odoo configuration is using the correct path:
   ```bash
   docker exec odoo-app grep -A 1 "bin_path_wkhtmltopdf" /etc/odoo/odoo.conf
   ```

4. Si ves errores relacionados con dependencias faltantes para wkhtmltopdf, es posible que necesites instalar paquetes adicionales en el Dockerfile / If you see errors related to missing dependencies for wkhtmltopdf, you may need to install additional packages in the Dockerfile.