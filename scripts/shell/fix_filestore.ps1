# PowerShell script to fix the filestore directory structure in the Odoo container
# This script will:
# 1. Create the filestore directory structure if it doesn't exist
# 2. Set the correct ownership and permissions
# 3. Restart the Odoo container to apply the changes

Write-Host "Fixing filestore directory structure in Odoo container..."

# Create the filestore directory structure in the Odoo container
docker exec odoo-app mkdir -p /var/lib/odoo/filestore/odoo

# Set the correct ownership and permissions
docker exec odoo-app chown -R odoo:odoo /var/lib/odoo
docker exec odoo-app chmod -R 755 /var/lib/odoo

Write-Host "Filestore directory structure fixed. Restarting Odoo container..."

# Restart the Odoo container to apply the changes
docker restart odoo-app

Write-Host "Odoo container restarted. The fix has been applied."
Write-Host "You can verify the fix by checking the logs: docker logs odoo-app"