# Instalación y Configuración / Installation and Setup

## Requisitos Previos / Prerequisites

Antes de comenzar, asegúrate de tener instalado:

Before starting, make sure you have installed:

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Servicios / Services

Este proyecto configura un entorno Odoo con PostgreSQL mediante Docker. Incluye dos contenedores principales:

This project sets up an Odoo environment with PostgreSQL using Docker. It includes two main containers:

### 1. PostgreSQL (`odoo-db`)

- **Imagen / Image**: `postgres:13`
- **Propósito / Purpose**: Proveer el backend de base de datos para Odoo / Provide the database backend for Odoo
- **Puertos / Ports**: No expone puertos al host, solo es accesible a través de la red interna de Docker / Does not expose ports to the host, only accessible through Docker's internal network
- **Variables de entorno / Environment variables**:
  - `POSTGRES_DB`: Nombre de la base de datos inicial / Initial database name (`postgres`)
  - `POSTGRES_USER`: Usuario administrador para PostgreSQL / Administrator user for PostgreSQL (`odoo`)
  - `POSTGRES_PASSWORD`: Contraseña del usuario administrador / Administrator user password (`odoo`)
- **Volúmenes / Volumes**:
  - `odoo-db-data`: Almacena los datos de PostgreSQL / Stores PostgreSQL data
  - `./db/backups`: Carpeta de backups donde puedes colocar archivos `.dump` / Backup folder where you can place `.dump` files

### 2. Odoo (`odoo-app`)

- **Imagen base / Base image**: `ubuntu:20.04`
- **Propósito / Purpose**: Levantar un servidor Odoo con los módulos personalizados / Run an Odoo server with custom modules
- **Puertos / Ports**:
  - `8069`: Puerto para la interfaz web de Odoo / Port for Odoo web interface
  - `8072`: Puerto de largo polling para notificaciones / Long polling port for notifications
- **Variables de entorno / Environment variables**:
  - `HOST`: Dirección del servicio de la base de datos / Database service address (`db`)
  - `USER` y `PASSWORD`: Credenciales para conectarse al servicio PostgreSQL / Credentials to connect to the PostgreSQL service
  - `ADDONS_PATH`: Rutas de directorios con módulos personalizados / Directory paths with custom modules
  - `ADMIN_PASSWD`: Contraseña de administrador para el backend de Odoo / Administrator password for Odoo backend (default: `admin123`)
- **Volúmenes / Volumes**:
  - Configuración / Configuration: `./config/odoo.conf` montado en / mounted at `/etc/odoo/odoo.conf`
  - Directorios personalizados montados en / Custom directories mounted at `/mnt/extra-addons`

## Cómo Levantar el Entorno / How to Start the Environment

1. Clona este repositorio / Clone this repository:
   ```bash
   git clone <repository-url>
   cd Odoo-15-Docker
   ```

2. Levanta los servicios usando el comando / Start the services using the command:
   ```bash
   docker-compose up -d
   ```
   Esto iniciará los contenedores `odoo-db` y `odoo-app` / This will start the `odoo-db` and `odoo-app` containers

3. Configura la base de datos siguiendo las instrucciones en [Gestión de Base de Datos](database-management.md) / Configure the database following the instructions in [Database Management](database-management.md)

4. Accede a la aplicación Odoo en tu navegador / Access the Odoo application in your browser:
   [http://localhost:8069](http://localhost:8069)

## Estructura de Directorios / Directory Structure

- **`./addons`**: Contiene tus módulos personalizados para Odoo / Contains your custom modules for Odoo
- **`./backups/db`**: Carpeta en el anfitrión donde puedes guardar y restaurar backups de la base de datos / Folder on the host where you can save and restore database backups
- **`./config`**: Contiene archivos de configuración / Contains configuration files
  - **`./config/odoo.conf`**: Archivo de configuración de Odoo / Odoo configuration file
- **`./docs`**: Documentación del proyecto / Project documentation
- **`./scripts`**: Scripts de utilidad / Utility scripts
  - **`./scripts/python`**: Scripts de Python / Python scripts
  - **`./scripts/shell`**: Scripts de shell / Shell scripts

## Comandos Útiles / Useful Commands

### Verificar si un contenedor está corriendo / Check if a container is running:
```bash
docker ps
```

### Entrar a un contenedor / Enter a container:
```bash
docker exec -it <container_name> bash
```

### Leer logs de un contenedor / Read container logs:
```bash
docker logs -f odoo-app
```

### Parar los servicios / Stop services:
```bash
docker-compose down
```

### Ejecutar un script de Python en el contenedor / Run a Python script in the container:
```bash
docker exec -it odoo-app python3 /home/odoo/PY/scripts/<script_name>.py
```

## Notas Importantes / Important Notes

- Asegúrate de que el archivo `entrypoint.sh` tenga formato de línea LF en vez de CRLF o CR / Make sure the `entrypoint.sh` file has LF line format instead of CRLF or CR
- Para más detalles sobre la configuración de la base de datos, consulta [Gestión de Base de Datos](database-management.md) / For more details on database configuration, see [Database Management](database-management.md)
- Si encuentras problemas con la generación de PDFs, consulta [Solución para Problemas de Generación de PDF](pdf-generation.md) / If you encounter problems with PDF generation, see [PDF Generation Troubleshooting](pdf-generation.md)
- Si encuentras problemas con el filestore, consulta [Solución para Problemas del Filestore](filestore.md) / If you encounter problems with the filestore, see [Filestore Troubleshooting](filestore.md)