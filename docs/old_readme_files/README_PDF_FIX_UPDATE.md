# PDF QWeb Report Fix Update

## Problem
PDF reports generated with QWeb were not displaying correctly in the local Docker environment. When trying to open a PDF in Odoo, an error message appeared saying "No podemos abrir este archivo. Hubo un problema." The PDF link was generated but never opened properly.

## Solution
The issue was related to how Odoo was finding and using the wkhtmltopdf binary. The following change was made to fix the issue:

1. Modified the `_get_wkhtmltopdf_bin()` function in `addons/Aeroportuaria_ERP/other/custom_background/models/report.py` to prioritize using the wkhtmltopdf path specified in the Odoo configuration file (`bin_path_wkhtmltopdf`) before falling back to the standard path search method.

The updated function now:
- First tries to get the wkhtmltopdf path from the Odoo configuration
- Verifies that the path exists, is a file, and is executable
- Only falls back to the standard path search if the config path is invalid or not specified

## How to Test
1. Rebuild and restart the Docker container:
   ```
   docker-compose down
   docker-compose build
   docker-compose up -d
   ```

2. Log into Odoo and try to generate a PDF report (e.g., an invoice, purchase order, or specifically the "Comprobante Contable" report).

3. Verify that the PDF report is displayed correctly.

## Technical Details
The original function was:
```python
def _get_wkhtmltopdf_bin():
    return find_in_path("wkhtmltopdf")
```

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

This change ensures that Odoo uses the correct wkhtmltopdf binary path as specified in the configuration file (`/usr/bin/wkhtmltopdf`), which resolves the PDF rendering issue.