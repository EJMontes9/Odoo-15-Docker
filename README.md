# Odoo 15 + PostgreSQL Docker Setup

Este proyecto configura un entorno Odoo con PostgreSQL mediante Docker. Incluye un contenedor para la base de datos PostgreSQL y otro para la aplicación Odoo.

## Servicios

### 1. **PostgreSQL (`odoo-db`)**:
- Imagen: `postgres:13`
- Propósito: Proveer el backend de base de datos para Odoo.
- Puertos: No expone puertos al host, solo es accesible a través de la red interna de Docker.
- Variables de entorno:
  - `POSTGRES_DB`: Nombre de la base de datos inicial (`postgres`).
  - `POSTGRES_USER`: Usuario administrador para PostgreSQL (`odoo`).
  - `POSTGRES_PASSWORD`: Contraseña del usuario administrador (`odoo`).
- Volúmenes:
  - `odoo-db-data`: Almacena los datos de PostgreSQL.
  - `./db/backups`: Carpeta de backups donde puedes colocar archivos `.dump`.

### 2. **Odoo (`odoo-app`)**:
- Imagen base: `ubuntu:20.04`
- Propósito: Levantar un servidor Odoo con los módulos personalizados.
- Puertos:
  - `8069`: Puerto para la interfaz web de Odoo.
  - `8072`: Puerto de largo polling para notificaciones.
- Variables de entorno:
  - `HOST`: Dirección del servicio de la base de datos (`db`).
  - `USER` y `PASSWORD`: Credenciales para conectarse al servicio PostgreSQL.
  - `ADDONS_PATH`: Rutas de directorios con módulos personalizados.
  - `ADMIN_PASSWD`: Contraseña de administrador para el backend de Odoo (por defecto: `admin123`).
- Volúmenes:
  - Configuración: `./config/odoo.conf` montado en `/etc/odoo/odoo.conf`.
  - Directorios personalizados montados en `/mnt/extra-addons`.

## Cómo levantar el entorno

1. Asegúrate de tener Docker y Docker Compose instalados en tu máquina.
2. Levanta los servicios usando el comando:

   ```bash
   docker-compose up -d
   ```

   Esto iniciará los contenedores `odoo-db` y `odoo-app`.

## Configuración de la base de datos

Odoo busca una base de datos que se llame `odoo` (o la configurada en el parámetro `dbfilter` del archivo `odoo.conf`). Si aún no la tienes configurada, puedes crearla siguiendo estos pasos.

---

### **Cómo crear y restaurar una base de datos llamada `odoo`**

**1. Crear la base de datos `odoo`:**
1. Accede al contenedor de la base de datos:
   ```bash
   docker exec -it odoo-db bash
   ```
   
2. Ingresa al cliente PostgreSQL:
   ```bash
   psql -U odoo -d postgres
   ```

3. Crea la base de datos `odoo` y asígnala al usuario `odoo`:
   ```sql
   CREATE DATABASE odoo OWNER odoo;
   ```

4. Verifica que la base de datos fue creada correctamente:
   ```sql
   \l
   ```

   Esto debería mostrar algo como:
   ```
      Name  | Owner | Encoding | Collate |   Ctype   |
   ---------+-------+----------+---------+-----------+
    odoo    | odoo  | UTF8     | en_US   | en_US.UTF8 |
    postgres| odoo  | UTF8     | en_US   | en_US.UTF8 |
   ```

5. Sal del cliente PostgreSQL:
   ```sql
   \q
   ```

---

**2. Restaurar la base de datos `odoo` desde un archivo `.dump`:**
1. Coloca el archivo `.dump` en la carpeta `./db/backups` en tu máquina anfitriona. Ejemplo:
   ```bash
   cp /ruta/al/archivo.dump ./db/backups
   ```

2. Accede nuevamente al contenedor del servicio PostgreSQL:
   ```bash
   docker exec -it odoo-db bash
   ```

3. Dentro del contenedor, restaura el `.dump` en la base de datos `odoo`:
   - Para un archivo `.dump` en formato personalizado:
     ```bash
     pg_restore -U odoo -d odoo /backups/archivo.dump
     ```
   - Para un archivo SQL plano:
     ```bash
     psql -U odoo -d odoo -f /backups/archivo.dump
     ```

4. Verifica que las tablas se restauraron correctamente:
   ```bash
   psql -U odoo -d odoo -c "\dt"
   ```

---

## Acceso a la aplicación Odoo

1. Abre tu navegador y accede a la interfaz web de Odoo en:
   [http://localhost:8069](http://localhost:8069)

2. Inicia sesión con el usuario administrador (`admin`) y la contraseña configurada en tu archivo `docker-compose.yml` (por defecto: `admin123`).

---

## Directorios importantes
- **`./db/backups`**: Carpeta en el anfitrión donde puedes guardar y restaurar backups de la base de datos.
- **`./addons`**: Contiene tus módulos personalizados para Odoo.
- **`./config/odoo.conf`**: Archivo de configuración de Odoo.

## Comandos útiles

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
