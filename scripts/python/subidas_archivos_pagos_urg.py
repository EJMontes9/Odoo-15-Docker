#!/usr/bin/python
import sys
import psycopg2
import os
import pathlib
import hashlib
import shutil
import mimetypes
from datetime import datetime,timezone,date, timedelta

#Base de datos
conn = psycopg2.connect(
  database="odoo", user='odoo', password='odoo', host='db', port='5432'
)

hora_file = date.today()
hora = datetime.now(timezone.utc) - timedelta(hours=5)
day_hour = hora.strftime('%Y-%m-%d--%H-%M')

log_archivos = []
log_file_odoo = []
log_sql = []
termino = 0

#Variables
contenido = pathlib.Path('/home/odoo/PY/archivos/')
contenido_odoo = "/var/lib/odoo/filestore/odoo/"
archivo_log = "/home/odoo/PY/logs/"

def log(log):
 archi1=open(archivo_log+"log_subida_pagos-especial-"+str(day_hour)+".log","a")
 archi1.write(log)
 archi1.close()

def archi(archivos, icontrato, conn):
 global termino
 #Datos del archivos
 #  print(archivos)
 a = str(archivos)
 e = os.stat(archivos)
 arc = a.split("/")

 # se obtiene el path del archivo
 n = len(arc) - 1
 direc = "/"
 i = 0
 for le in x:
  if ((i > 0) and (i < n)):
   direc += le + "/"
  i = i + 1
 # print(direc)

 #Tipo de archivo
 tipo = mimetypes.guess_type(str(archivos))
 # print("tipo",tipo)

 # HASH para el checksum
 hash = hashlib.sha1(open(archivos, 'rb').read()).hexdigest()
 # print('hash',hash)

 # Obtengo los 2 primeros item para la carpeta
 dir = hash[0:2]
 print ('dir',dir)

 # Armo la direccion de la carpeta con el archivo
 ti=''
 dh = str(dir + '/' + hash)
 print ('dh',dh)

 # Verificamos si existe el archivo
 direx = os.path.exists(contenido_odoo + dir)
 #  print (direx)
 if (direx == True):
  print("Existe")
  o = "ok"
 else:
  print("no Existe",contenido_odoo + dir)
  os.mkdir(contenido_odoo + dir)

 # Obtenemos el tamaño del archivo
 size = str(e.st_size)
 print('size',size)

 #Obtenemos la carpeta contenedora
 name_etapa = arc[6].replace(" ", "_")
 print('etapa',name_etapa)

 #vemos la carpeta es de pago
 print (arc)
 if arc[6] == 'PAGOS':
  pag = arc[7].split(" ")
  ti = arc[5] +"-PA-"+pag[1]
  print("ti",ti)

  if termino == 0:
   # Se agrega al archivo log
   logs = "-*-*-*-*-*-*-*-*-*- Se comienza a procesar pago " + ti+"-*-*-*-*-*-*-*-*-*- \n"
   log(logs)
   print("-*-*-*-*-*-*-*-*-*- Se comienza a procesar pago " + ti+"-*-*-*-*-*-*-*-*-*-")
   termino = 1

  sql_select = """SELECT id FROM public.foldergroups_odoo where name = '""" + arc[8] + """' and active = True"""
  cursor = conn.cursor()
  cursor.execute(sql_select)
  print("busqueda", sql_select)
  id_fol = cursor.fetchall()

  if len(id_fol) > 0:
    #obtenemos los nombre de los archivos y sus extensiones
    name_archivo = arc[9].replace(" ", "_")

    sql_select = """select id from payment_process where nro_pago = '"""+ti+"""' and estado = True"""
    cursor = conn.cursor()
    cursor.execute(sql_select)
    #  print("busqueda",sql_select)
    id_pago = cursor.fetchall()

    if len(id_pago) > 0:
     # Se agrega al archivo log
     logs = "-" + str(hora) + ": Archivo: " + str(archivos) + " \n"
     log_archivos.append(logs)

     ipa = str(id_pago[0][0])
     ifo = str(id_fol[0][0])

     #se crea el query para guardarse en la base de datos
     sqli = "'" + name_archivo + "',null, null, null, null, 1, 'binary',null,true,null,null,'" + str(
      dh) + "'," + size + ",'" + str(hash) + "','" + str(
      tipo[0]) + "','application',11,CURRENT_TIMESTAMP,11,CURRENT_TIMESTAMP,null,null,null,1,1,true,null,null,1,1,null,null,1,1,"
     sql = ""+ipa+",'Pagos',"+ifo+",1,null,null,'Contratista',null,null,null,'Servicio Basicos Contrato',1,1,null,null,null,1,1"
     query = 'INSERT INTO public.ir_attachment(name, description, res_model, res_field, res_id, company_id, type, url, public, access_token, db_datas, store_fname, file_size, checksum, mimetype, index_content, create_uid, create_date, write_uid, write_date, original_id, "id_Proceso_pre", etapa_pre, folder_principal, folder_secundaria, bool_secu, "id_Proceso_precon", etapa_precon, folder_principal_pc, folder_secundaria_pc, "id_Proceso_con", etapa_con, folder_principal_co, folder_secundaria_co, id_pagos, process, etapa_pagos, etapa_pagos_sec, id_pagos_con, doc_groups, process_contra, "Tipo_Doc_contratista", id_list_sp, id_nro_sp, process_doc, etapa_pagos_sp, etapa_pagos_sec_sp, warranty_id, id_list_sbc, id_nro_sbc, etapa_pagos_sbc, etapa_pagos_sec_sbc) VALUES ('
     queryf = ')'
     # print("sql", query+sqli+sql+queryf)
     sqlll = query+sqli+sql+queryf
     try:
      cursor = conn.cursor()
      cursor.execute(sqlll)
      conn.commit()
     except Exception as e:
      if conn:
       # Se agrega al archivo log
       error = (f"Query con errores: {e}")
       logs = "-" + str(hora) + ": " + str(error) + " \n"
       log(logs)
       quit()
     finally:
      # Se agrega al archivo log
      logs = "-" + str(hora) + ": Query ejecutado: " + str(sqlll) + " \n"
      log_sql.append(logs)

      # Renombramos el archivo con el checksum
      final = str(direc) + hash
      # final = hash
      os.rename(archivos, final)
      # print("final",final)
      # print("archivos",archivos)

      # Movemos el archivo a su direccion final
      shutil.move(final, str(contenido_odoo) + str(dir) + "/" + hash)
      # print(str(contenido_odoo)+str(dir)+"/"+hash)

      f = str(contenido_odoo) + str(dir) + "/" + hash

      # Se agrega al archivo log
      logs = "-" + str(hora) + ": Se cambio el nombre y se movio el archivo -" + str(archivos) + "- a -" + str(f) + "- \n"
      log_file_odoo.append(logs)
  else:
   # Se agrega al archivo log
   logs = "-*-*-*-*-*-*-*-*-*- Se comienza a procesar pago " + ti + "-*-*-*-*-*-*-*-*-*- \n"
   log(logs)
   print("-*-*-*-*-*-*-*-*-*- Se comienza a procesar pago " + ti + "-*-*-*-*-*-*-*-*-*-")
   logs = "-*-*-*-*-*-*-*-*-*- No exite carpeta con ese nombre en la BD: " + arc[9] + "-*-*-*-*-*-*-*-*-*- \n"
   log(logs)
   print("-*-*-*-*-*-*-*-*-*- No exite carpeta con ese nombre en la BD: " + arc[9] + "-*-*-*-*-*-*-*-*-*-")
 else:
  # Se agrega al archivo log
  logs = "-*-*-*-*-*-*-*-*-*- Se comienza a procesar pago " + ti + "-*-*-*-*-*-*-*-*-*- \n"
  log(logs)
  print("-*-*-*-*-*-*-*-*-*- Se comienza a procesar pago " + ti + "-*-*-*-*-*-*-*-*-*-")
  termino = 0

#Recorre las carpetas en busqueda de archivos
def recorrer(path,icontrato,conn):
  for archivos in path.iterdir():
   file = archivos.is_file()
   if (file):
    archi(archivos,icontrato,conn)
   else:
     recorrer(archivos,icontrato,conn)

###comienzo el pograma###
print("----------COMIENZA EL PROGRAMA 555555 -----------")
# Se agrega al archivo log
logs = "-*-*-*-*-*-*-*-*-*- Dia y hora del reporte: " + str(hora) + "-*-*-*-*-*-*-*-*-*- \n"
log(logs)
print("-*-*-*-*-*-*-*-*-*- Fecha del inicio de proceso: " + str(hora) + "-*-*-*-*-*-*-*-*-*-")
for path in contenido.iterdir():
 if path.is_file():
  print("archivo")
 else:
  #carpeta principal donde esta el nombre de la
  fx = str(path)

  x = fx.split("/")
  id_contract = x[5]

  sql_select = """SELECT id FROM public.hiring_process where name = '""" + id_contract + """' and estado = True"""
  cursor = conn.cursor()
  cursor.execute(sql_select)
  #  print("busqueda",sql_select)
  id_hp = cursor.fetchall()

  if len(id_hp) > 0:
   # Se agrega al archivo log
   logs = "-*-*-*-*-*-*-*-*-*- Carpeta principal: " + str(path) + "-*-*-*-*-*-*-*-*-*- \n"
   log(logs)
   print("-*-*-*-*-*-*-*-*-*- Procesando carpeta: " + str(path) + "-*-*-*-*-*-*-*-*-*-")

   for path2 in path.iterdir():
    # print(str(path2))
    # print(str(id_hp[0][0]))
    recorrer(path2,str(id_hp[0][0]),conn)

    for i in range(len(log_archivos)):
     log(log_archivos[i])
    for i in range(len(log_sql)):
     log(log_sql[i])
    for i in range(len(log_file_odoo)):
     log(log_file_odoo[i])
    log_archivos = []
    log_sql = []
    log_file_odoo = []
  else:
   # Se agrega al archivo log
   logs = "-*-*-*-*-*-*-*-*-*- Carpeta " + str(path) + " no existe en la base de datos -*-*-*-*-*-*-*-*-*- \n"
   log(logs)
   print("-*-*-*-*-*-*-*-*-*- Procesando carpeta: No existe la carpeta en la base " + str(path) + "-*-*-*-*-*-*-*-*-*-")

print("----------TERMINO EL PROGRAMA BUSCAR EL LOG EN '"+archivo_log+"'-----------")

