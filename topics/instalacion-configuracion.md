# Instalación y Configuración

## Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Servicios

Este proyecto configura un entorno Odoo con PostgreSQL mediante Docker. Incluye dos contenedores principales:

### 1. PostgreSQL (odoo-db)

- **Imagen**: `postgres:13`
- **Propósito**: Proveer el backend de base de datos para Odoo
- **Puertos**: No expone puertos al host, solo es accesible a través de la red interna de Docker
- **Variables de entorno**:
  - `POSTGRES_DB`: Nombre de la base de datos inicial (`postgres`)
  - `POSTGRES_USER`: Usuario administrador para PostgreSQL (`odoo`)
  - `POSTGRES_PASSWORD`: Contraseña del usuario administrador (`odoo`)
- **Volúmenes**:
  - `odoo-db-data`: Almacena los datos de PostgreSQL
  - `./db/backups`: Carpeta de backups donde puedes colocar archivos `.dump`

### 2. Odoo (odoo-app)

- **Imagen base**: `ubuntu:20.04`
- **Propósito**: Levantar un servidor Odoo con los módulos personalizados
- **Puertos**:
  - `8069`: Puerto para la interfaz web de Odoo
  - `8072`: Puerto de largo polling para notificaciones
- **Variables de entorno**:
  - `HOST`: Dirección del servicio de la base de datos (`db`)
  - `USER` y `PASSWORD`: Credenciales para conectarse al servicio PostgreSQL
  - `ADDONS_PATH`: Rutas de directorios con módulos personalizados
  - `ADMIN_PASSWD`: Contraseña de administrador para el backend de Odoo (default: `admin123`)
- **Volúmenes**:
  - Configuración: `./config/odoo.conf` montado en `/etc/odoo/odoo.conf`
  - Directorios personalizados montados en `/mnt/extra-addons`

## Cómo Levantar el Entorno

1. Clona este repositorio:
   ```bash
   git clone <repository-url>
   cd Odoo-15-Docker
   ```

2. Levanta los servicios usando el comando:
   ```bash
   docker-compose up -d
   ```
   Esto iniciará los contenedores `odoo-db` y `odoo-app`

3. Configura la base de datos siguiendo las instrucciones en [Gestión de Base de Datos](gestion-base-datos.md)

4. Accede a la aplicación Odoo en tu navegador:
   [http://localhost:8069](http://localhost:8069)

## Estructura de Directorios

- **`./addons`**: Contiene tus módulos personalizados para Odoo
- **`./backups/db`**: Carpeta en el anfitrión donde puedes guardar y restaurar backups de la base de datos
- **`./config`**: Contiene archivos de configuración
  - **`./config/odoo.conf`**: Archivo de configuración de Odoo
- **`./docs`**: Documentación del proyecto
- **`./scripts`**: Scripts de utilidad
  - **`./scripts/python`**: Scripts de Python
  - **`./scripts/shell`**: Scripts de shell

## Comandos Útiles

### Verificar si un contenedor está corriendo:
```bash
docker ps
```

### Entrar a un contenedor:
```bash
docker exec -it <container_name> bash
```

### Leer logs de un contenedor:
```bash
docker logs -f odoo-app
```

### Parar los servicios:
```bash
docker-compose down
```

### Ejecutar un script de Python en el contenedor:
```bash
docker exec -it odoo-app python3 /home/odoo/PY/scripts/<script_name>.py
```

## Notas Importantes

- Asegúrate de que el archivo `entrypoint.sh` tenga formato de línea LF en vez de CRLF o CR
- Para más detalles sobre la configuración de la base de datos, consulta [Gestión de Base de Datos](gestion-base-datos.md)
- Si encuentras problemas con la generación de PDFs, consulta [Solución para Problemas de Generación de PDF](generacion-pdf.md)
- Si encuentras problemas con el filestore, consulta [Solución para Problemas del Filestore](filestore.md)
