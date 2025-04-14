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
    cython==0.29.33

# Copiar tu archivo requirements.txt al contenedor
COPY requirements.txt /tmp/requirements.txt

# Instalar tus dependencias específicas antes que las de Odoo
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Instalar dependencias de Odoo después para evitar conflictos
RUN pip3 install --no-cache-dir -r /opt/odoo/requirements.txt

# Configuración del usuario y directorios
RUN useradd -m -d /opt/odoo -U -r -s /bin/bash odoo \
    && mkdir -p /mnt/extra-addons \
    && chown odoo:odoo /mnt/extra-addons

# Copiar módulos y configuración
COPY addons/Aeroportuaria_ERP /mnt/extra-addons/Aeroportuaria_ERP
COPY config/odoo.conf /etc/odoo/odoo.conf
RUN chown odoo:odoo /etc/odoo/odoo.conf

# Crear directorio de sesiones y asignar permisos
RUN mkdir -p /var/lib/odoo/sessions \
    && chown -R odoo:odoo /var/lib/odoo \
    && chmod 755 /var/lib/odoo


# Configurar entorno
WORKDIR /opt/odoo
USER odoo
EXPOSE 8069

CMD ["python3", "/opt/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf"]

