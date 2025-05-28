# Usar Ubuntu 20.04 como base para mejor compatibilidad
FROM ubuntu:20.04

# Configurar variables de entorno
ENV DEBIAN_FRONTEND=noninteractive \
    ODOO_VERSION=15.0 \
    PYTHON_VERSION=3.10.12 \
    WKHTMLTOPDF_VERSION=0.12.5

# Instalar dependencias del sistema y Python
RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y \
    python3.10 \
    python3.10-dev \
    python3.10-venv \
    python3.10-distutils \
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
    && rm -rf /var/lib/apt/lists/* \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10 \
    && ln -sf /usr/bin/python3.10 /usr/bin/python3

RUN apt-get update && apt-get install -y \
    libreoffice \
    libreoffice-writer \
    && rm -rf /var/lib/apt/lists/*

# Instalar las dependencias de Python para py3o
RUN python3.10 -m pip install --no-cache-dir \
    py3o.template \
    py3o.formats

# Instalar locales necesarios
RUN apt-get update && apt-get install -y locales

# Generar locales para Ecuador y otros que puedas necesitar
RUN sed -i -e 's/# es_EC.UTF-8 UTF-8/es_EC.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# Establecer variables de entorno para locale
ENV LANG es_EC.UTF-8
ENV LANGUAGE es_EC:es
ENV LC_ALL es_EC.UTF-8


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
RUN python3.10 -m pip install --no-cache-dir \
    wheel==0.37.1 \
    setuptools==59.6.0 \
    cython==0.29.33 \
    psycopg2-binary \
    gevent==23.9.1 \
    greenlet==3.1.1 \
    Jinja2==2.11.3 \
    MarkupSafe==1.1.0 \
    Pillow==9.0.1 \
    PyPDF2==1.26.0 \
    reportlab==3.5.59 \
    lxml==4.6.5 \
    libsass==0.18.0 \
    psutil==5.6.7 \
    pyOpenSSL==19.0.0 \
    python-ldap==3.4.0 \
    pyusb==1.0.2 \
    requests==2.25.1 \
    urllib3==1.26.5 \
    Werkzeug==2.0.2 \
    xlrd==1.2.0

# Copiar tu archivo requirements.txt al contenedor
COPY requirements.txt /tmp/requirements.txt

# Instalar cryptography primero en la versión específica
# Nota: Usando una versión más reciente compatible con Python 3.10
RUN python3.10 -m pip install --no-cache-dir cryptography==36.0.2

# Instalar PyYAML por separado para evitar problemas de compilación
RUN python3.10 -m pip install --no-cache-dir --no-build-isolation --global-option="--without-libyaml" PyYAML==5.4.1

# Crear un nuevo requirements sin PyYAML y sin cryptography
RUN grep -v "PyYAML\|cryptography" /tmp/requirements.txt > /tmp/requirements_filtered.txt

# Instalar el resto de dependencias
RUN python3.10 -m pip install --no-cache-dir -r /tmp/requirements_filtered.txt


# Crear un requirements filtrado para Odoo excluyendo paquetes problemáticos
RUN grep -v -E "gevent|greenlet|cryptography|Jinja2|libsass|lxml|MarkupSafe|ofxparse|Pillow|psutil|psycopg2|pyopenssl|PyPDF2|pypiwin32|python-ldap|pyusb|reportlab|requests|urllib3|Werkzeug|xlrd" /opt/odoo/requirements.txt > /tmp/odoo_requirements_filtered.txt

# Instalar dependencias de Odoo después para evitar conflictos
RUN python3.10 -m pip install --no-cache-dir -r /tmp/odoo_requirements_filtered.txt

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
RUN echo "*/5 * * * * odoo /usr/bin/python3.10 /home/odoo/PY/scripts/subidas_archivos_pagos_urg.py >> /home/odoo/PY/logs/script.log 2>&1" >> /etc/cron.d/odoo-cron \
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
