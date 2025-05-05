# Usar Ubuntu 20.04 como base para mejor compatibilidad
FROM ubuntu:20.04

# Configurar variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    ODOO_VERSION=15.0 \
    PYTHON_VERSION=3.8 \
    WKHTMLTOPDF_VERSION=0.12.5

# Instalar dependencias del sistema y Python
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-wheel \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    wget \
    git \
    build-essential \
    cron \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias específicas para wkhtmltopdf primero
RUN apt-get update && apt-get install -y \
    xfonts-75dpi \
    xfonts-base \
    fontconfig \
    libjpeg-turbo8 \
    libxrender1 \
    libxext6 \
    xfonts-utils \
    && rm -rf /var/lib/apt/lists/*

# Instalar wkhtmltopdf desde el repositorio oficial
RUN wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}-1.bionic_amd64.deb \
    && apt-get install -y --no-install-recommends /tmp/wkhtmltox.deb \
    && rm -f /tmp/wkhtmltox.deb

# Instalar Odoo 15 desde fuente
RUN wget -q https://github.com/odoo/odoo/archive/${ODOO_VERSION}.tar.gz \
    && tar -xf ${ODOO_VERSION}.tar.gz \
    && mv odoo-${ODOO_VERSION} /opt/odoo \
    && rm ${ODOO_VERSION}.tar.gz

# Instalar dependencias base críticas primero
RUN pip3 install --no-cache-dir \
    wheel==0.37.1 \
    setuptools==59.6.0 \
    cython==0.29.33 \
    psycopg2-binary

# Copiar tu archivo requirements.txt al contenedor
COPY requirements.txt /tmp/requirements.txt

# Instalar tus dependencias específicas antes que las de Odoo
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Instalar dependencias de Odoo después para evitar conflictos
RUN pip3 install --no-cache-dir -r /opt/odoo/requirements.txt

# Configuración del usuario y directorios
RUN useradd -m -d /opt/odoo -U -r -s /bin/bash odoo \
    && mkdir -p /mnt/extra-addons \
    && mkdir -p /var/lib/odoo/sessions \
    && mkdir -p /home/odoo/PY/archivos \
    && mkdir -p /home/odoo/PY/logs \
    && mkdir -p /home/odoo/PY/scripts \
    && mkdir -p /opt/scripts/shell \
    && chown -R odoo:odoo /opt/odoo \
    && chown -R odoo:odoo /mnt/extra-addons \
    && chown -R odoo:odoo /var/lib/odoo \
    && chown -R odoo:odoo /home/odoo/PY \
    && chmod 755 /var/lib/odoo

# Copiar módulos y configuración
COPY addons/Aeroportuaria_ERP /mnt/extra-addons/Aeroportuaria_ERP
COPY config/odoo.conf /etc/odoo/odoo.conf
COPY scripts/python/subidas_archivos_pagos_urg.py /home/odoo/PY/scripts/
COPY scripts/shell/ /opt/scripts/shell/

# Configurar permisos
RUN chown odoo:odoo /etc/odoo/odoo.conf \
    && chmod +x /opt/scripts/shell/*.sh

# Configurar cron
RUN echo "*/5 * * * * odoo /usr/bin/python3 /home/odoo/PY/scripts/subidas_archivos_pagos_urg.py >> /home/odoo/PY/logs/script.log 2>&1" >> /etc/cron.d/odoo-cron \
    && chmod 0644 /etc/cron.d/odoo-cron

# Crear archivo para logs
RUN touch /var/log/cron.log \
    && chown odoo:odoo /var/log/cron.log

# Script de inicio
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# Configurar entorno
WORKDIR /opt/odoo
EXPOSE 8069 8072

COPY scripts/python/wait-for-it.py /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-it.py \
    && sed -i 's/\r$//' /usr/local/bin/wait-for-it.py


#Definir el punto de entrada y el comando
ENTRYPOINT ["/entrypoint.sh"]
#CMD ["python3", "/opt/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf"]
