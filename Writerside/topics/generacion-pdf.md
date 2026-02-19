# Solución para Problemas de Generación de PDF

## Problema

Los informes PDF generados con QWeb no se mostraban correctamente en el entorno Docker local. Al intentar abrir un PDF en Odoo, aparecía un mensaje de error diciendo "No podemos abrir este archivo. Hubo un problema." El enlace del PDF se generaba pero nunca se abría correctamente.

## Diagnóstico

Después de analizar la salida del script `check_wkhtmltopdf.sh`, se identificó que:

1. El binario wkhtmltopdf estaba instalado en `/usr/local/bin/wkhtmltopdf`

2. No existía en `/usr/bin/wkhtmltopdf` donde Odoo estaba configurado para buscarlo

3. El script original de configuración no creaba el enlace simbólico correctamente

## Solución Implementada

Se realizaron los siguientes cambios para solucionar el problema:

### 1. Actualización de la Configuración de Odoo

Se actualizó el archivo de configuración de Odoo (`config/odoo.conf`) para usar la ruta correcta para wkhtmltopdf:
- `bin_path_wkhtmltopdf = /usr/bin/wkhtmltopdf`

### 2. Mejora del Script de Configuración

Se actualizó el script `setup_wkhtmltopdf_link.sh` para:
- Detectar automáticamente dónde está instalado wkhtmltopdf
- Crear el enlace simbólico en la dirección correcta según la ubicación del binario
- Manejar ambos escenarios posibles (binario en `/usr/local/bin/` o en `/usr/bin/`)

### 3. Mejora del Script de Diagnóstico

Se mejoró el script `check_wkhtmltopdf.sh` para:
- Mostrar información más detallada sobre la instalación
- Verificar la existencia del binario en ambas rutas
- Comprobar la configuración en odoo.conf
- Verificar los enlaces simbólicos y mostrar a dónde apuntan

### 4. Modificación del Código de Odoo

Se modificó la función `_get_wkhtmltopdf_bin()` en `addons/Aeroportuaria_ERP/other/custom_background/models/report.py` para priorizar el uso de la ruta de wkhtmltopdf especificada en el archivo de configuración de Odoo (`bin_path_wkhtmltopdf`) antes de recurrir al método de búsqueda de ruta estándar.

La función actualizada ahora:
- Primero intenta obtener la ruta de wkhtmltopdf desde la configuración de Odoo
- Verifica que la ruta exista, sea un archivo y sea ejecutable
- Solo recurre a la búsqueda de ruta estándar si la ruta de configuración no es válida o no está especificada

#### Detalles Técnicos

La función original era:

```python
def _get_wkhtmltopdf_bin():
    return find_in_path("wkhtmltopdf")
```

La función actualizada es:

<code-block lang="python" ignore-vars="true">
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
</code-block>

## Cómo Aplicar los Cambios

### Opción 1: Reconstruir la Imagen Docker

Para aplicar todos los cambios de manera permanente:

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

### Opción 2: Aplicar Cambios Sin Reconstruir

Para aplicar los cambios sin reconstruir la imagen Docker (útil para entornos en producción):

1. Copiar los scripts al contenedor:
   ```bash
   docker cp scripts/shell/setup_wkhtmltopdf_link.sh odoo-app:/opt/scripts/shell/
   docker cp scripts/shell/check_wkhtmltopdf.sh odoo-app:/opt/scripts/shell/
   docker exec odoo-app chmod +x /opt/scripts/shell/setup_wkhtmltopdf_link.sh
   docker exec odoo-app chmod +x /opt/scripts/shell/check_wkhtmltopdf.sh
   ```

2. Actualizar el archivo de configuración:
   ```bash
   docker cp config/odoo.conf odoo-app:/etc/odoo/odoo.conf
   ```

3. Actualizar el script de entrada:
   ```bash
   docker cp entrypoint.sh odoo-app:/entrypoint.sh
   docker exec odoo-app chmod +x /entrypoint.sh
   ```

4. Ejecutar el script de configuración:
   ```bash
   docker exec odoo-app /opt/scripts/shell/setup_wkhtmltopdf_link.sh
   ```

5. Reiniciar el contenedor:
   ```bash
   docker restart odoo-app
   ```

## Verificación

Para verificar que la solución funciona correctamente:

1. Ejecutar el script de diagnóstico:
   ```bash
   docker exec odoo-app /opt/scripts/shell/check_wkhtmltopdf.sh
   ```

2. Verificar que wkhtmltopdf esté correctamente configurado:
   - Debe mostrar la versión correcta (0.12.5 con qt parcheado)
   - El binario debe estar disponible en al menos una de las rutas
   - Debe existir un enlace simbólico entre ambas ubicaciones

3. Generar un informe PDF en Odoo:
   - Iniciar sesión en Odoo
   - Generar un informe PDF (por ejemplo, una factura o un comprobante contable)
   - Verificar que el PDF se muestre correctamente

## Solución de Problemas

Si sigues teniendo problemas después de aplicar estos cambios:

1. Verificar los logs de Odoo:
   ```bash
   docker logs odoo-app | grep -i wkhtmltopdf
   ```

2. Asegurarse de que el enlace simbólico se haya creado correctamente:
   ```bash
   docker exec odoo-app ls -la /usr/bin/wkhtmltopdf
   docker exec odoo-app ls -la /usr/local/bin/wkhtmltopdf
   ```

3. Verificar que la configuración de Odoo esté utilizando la ruta correcta:
   ```bash
   docker exec odoo-app grep -A 1 "bin_path_wkhtmltopdf" /etc/odoo/odoo.conf
   ```

4. Si ves errores relacionados con dependencias faltantes para wkhtmltopdf, es posible que necesites instalar paquetes adicionales en el Dockerfile.
