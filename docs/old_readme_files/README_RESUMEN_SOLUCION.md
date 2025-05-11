# Resumen de la Solución para PDFs QWeb

## Problema Original
Los informes PDF generados con QWeb no se mostraban correctamente en el entorno Docker local, mientras que funcionaban bien en producción.

## Diagnóstico
Después de analizar la salida del script `check_wkhtmltopdf.sh`, se identificó que:

1. El binario wkhtmltopdf estaba instalado en `/usr/local/bin/wkhtmltopdf`
2. No existía en `/usr/bin/wkhtmltopdf` donde Odoo estaba configurado para buscarlo
3. El script original de configuración no creaba el enlace simbólico correctamente

## Solución Implementada

### 1. Mejora del Script de Configuración
Se actualizó `setup_wkhtmltopdf_link.sh` para:
- Detectar automáticamente dónde está instalado wkhtmltopdf
- Crear el enlace simbólico en la dirección correcta según la ubicación del binario
- Manejar ambos escenarios posibles (binario en `/usr/local/bin/` o en `/usr/bin/`)

### 2. Mejora del Script de Diagnóstico
Se mejoró `check_wkhtmltopdf.sh` para:
- Mostrar información más detallada sobre la instalación
- Verificar la existencia del binario en ambas rutas
- Comprobar la configuración en odoo.conf
- Verificar los enlaces simbólicos y mostrar a dónde apuntan

### 3. Documentación Actualizada
Se actualizaron los archivos de documentación:
- `README_PDF_FIX.md`: Documentación general de la solución
- `README_APLICAR_CAMBIOS.md`: Instrucciones para aplicar los cambios sin perder datos

## Verificación
La solución se puede verificar ejecutando:
```
docker exec odoo-app /opt/scripts/shell/check_wkhtmltopdf.sh
```

El resultado debería mostrar:
1. wkhtmltopdf instalado y accesible
2. La versión correcta (0.12.5 con qt parcheado)
3. El binario disponible en al menos una de las rutas (/usr/bin/ o /usr/local/bin/)
4. Un enlace simbólico creado correctamente entre ambas ubicaciones

## Conclusión
Esta solución asegura que Odoo pueda encontrar el binario wkhtmltopdf independientemente de dónde esté instalado, permitiendo la generación correcta de informes PDF sin necesidad de reconstruir completamente el contenedor Docker o perder datos.