# PDF QWeb Report Fix

## Problem
The PDF reports generated with QWeb were not displaying correctly in the local Docker environment, while they worked fine in production.

## Solution
The issue was related to the wkhtmltopdf binary path configuration. The following changes were made to fix the issue:

1. Updated the Odoo configuration file (`config/odoo.conf`) to use the correct path for wkhtmltopdf:
   - Set `bin_path_wkhtmltopdf = /usr/bin/wkhtmltopdf`

2. Created a script (`scripts/shell/setup_wkhtmltopdf_link.sh`) to create a symbolic link between `/usr/bin/wkhtmltopdf` and `/usr/local/bin/wkhtmltopdf` during container startup.
   - The script now intelligently detects where wkhtmltopdf is installed and creates the symbolic link in the appropriate direction
   - If wkhtmltopdf exists in `/usr/local/bin/` but not in `/usr/bin/`, it creates a link from `/usr/local/bin/wkhtmltopdf` to `/usr/bin/wkhtmltopdf`
   - If wkhtmltopdf exists in `/usr/bin/` but not in `/usr/local/bin/`, it creates a link from `/usr/bin/wkhtmltopdf` to `/usr/local/bin/wkhtmltopdf`

3. Modified the entrypoint script (`entrypoint.sh`) to run the setup_wkhtmltopdf_link.sh script during container startup.

4. Created a diagnostic script (`scripts/shell/check_wkhtmltopdf.sh`) to verify the wkhtmltopdf installation and configuration:
   - Shows the location and version of wkhtmltopdf
   - Verifies if the binary exists in both paths
   - Checks the Odoo configuration
   - Verifies symbolic links and shows where they point to

## How to Test
1. Rebuild and restart the Docker container:
   ```
   docker-compose down
   docker-compose build
   docker-compose up -d
   ```

2. Log into Odoo and try to generate a PDF report (e.g., an invoice, purchase order, or any other report that uses QWeb).

3. Verify that the PDF report is displayed correctly.

## Troubleshooting
If you still encounter issues with PDF reports, you can check the wkhtmltopdf installation in the Docker container:

1. Run the check_wkhtmltopdf.sh script in the container:
   ```
   docker exec -it odoo-app /opt/scripts/shell/check_wkhtmltopdf.sh
   ```

2. Check the Odoo logs for any errors related to wkhtmltopdf:
   ```
   docker logs odoo-app | grep -i wkhtmltopdf
   ```

If you see errors related to missing dependencies for wkhtmltopdf, you may need to install additional packages in the Dockerfile.
