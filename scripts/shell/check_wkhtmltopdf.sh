#!/bin/bash
# Check if wkhtmltopdf is installed and where
echo "Checking wkhtmltopdf installation..."
which wkhtmltopdf
echo "wkhtmltopdf version:"
wkhtmltopdf --version
echo "Checking if wkhtmltopdf binary exists in specified paths:"
ls -la /usr/bin/wkhtmltopdf 2>/dev/null || echo "Not found in /usr/bin/ (this is OK if it exists in /usr/local/bin/)"
ls -la /usr/local/bin/wkhtmltopdf 2>/dev/null || echo "Not found in /usr/local/bin/ (this is OK if it exists in /usr/bin/)"

# Check Odoo configuration
echo "Checking Odoo configuration for wkhtmltopdf:"
grep -A 1 "bin_path_wkhtmltopdf" /etc/odoo/odoo.conf

# Verify symbolic links
echo "Checking for symbolic links:"
if [ -L /usr/bin/wkhtmltopdf ]; then
    echo "/usr/bin/wkhtmltopdf is a symbolic link pointing to: $(readlink -f /usr/bin/wkhtmltopdf)"
elif [ -f /usr/bin/wkhtmltopdf ]; then
    echo "/usr/bin/wkhtmltopdf is a regular file"
fi

if [ -L /usr/local/bin/wkhtmltopdf ]; then
    echo "/usr/local/bin/wkhtmltopdf is a symbolic link pointing to: $(readlink -f /usr/local/bin/wkhtmltopdf)"
elif [ -f /usr/local/bin/wkhtmltopdf ]; then
    echo "/usr/local/bin/wkhtmltopdf is a regular file"
fi
