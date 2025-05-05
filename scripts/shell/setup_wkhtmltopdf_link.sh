#!/bin/bash
# Create a symbolic link for wkhtmltopdf if it doesn't exist
echo "Setting up wkhtmltopdf symbolic link..."
if [ -f /usr/local/bin/wkhtmltopdf ] && [ ! -f /usr/bin/wkhtmltopdf ]; then
    mkdir -p /usr/bin
    ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf
    echo "Created symbolic link from /usr/local/bin/wkhtmltopdf to /usr/bin/wkhtmltopdf"
elif [ -f /usr/bin/wkhtmltopdf ] && [ ! -f /usr/local/bin/wkhtmltopdf ]; then
    mkdir -p /usr/local/bin
    ln -s /usr/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf
    echo "Created symbolic link from /usr/bin/wkhtmltopdf to /usr/local/bin/wkhtmltopdf"
else
    echo "No need to create symbolic link for wkhtmltopdf"
fi
